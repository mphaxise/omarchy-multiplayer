"""Unit and integration tests for omarchy-agent-session-core.

Run with: python3 -m unittest discover -s tests -v   (from build/core/)

Most tests call core.main([...]) in-process (env vars set per test, stdout
captured via redirect_stdout) rather than spawning a subprocess, so a fake
Herdr server running as a thread in this same process can be inspected
directly afterward. One subprocess-level smoke test (test_cli_is_executable)
still exercises the real shebang/executable bit end to end.
"""

import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
import pathlib
import shutil
import socket
import subprocess
import sys
import tempfile
import unittest

TESTS_DIR = pathlib.Path(__file__).resolve().parent
CORE_DIR = TESTS_DIR.parent
CORE_PATH = CORE_DIR / "bin" / "omarchy-agent-session-core"

sys.path.insert(0, str(TESTS_DIR))
from fake_herdr import FakeHerdrServer  # noqa: E402


def load_core():
    loader = importlib.machinery.SourceFileLoader("omarchy_agent_session_core_under_test", str(CORE_PATH))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


core = load_core()


def make_bare_session(store, name, mode="personal", agent_kind="claude", state="working",
                       runtime=None, workspace=None, parent_id=None):
    """Builds and saves a session record directly through the store, for
    tests that don't want a real (or fake-Herdr-backed) `new` launch."""
    session_id = core.new_ulid()
    creator = core.current_human_actor()
    workspace = workspace or {
        "repo_root": None, "worktree_path": None, "branch": None,
        "base_branch": None, "created_by_session": False,
    }
    record = core.new_session_record(
        session_id, name, creator, creator, mode, agent_kind, workspace,
        cwd=None, command=None, parent_id=parent_id,
    )
    ev = store.append_event(session_id, "session.created", creator, {"name": name})
    record["state_version"] = ev["seq"]
    if runtime is not None:
        ev = store.append_event(session_id, "runtime.bound", creator, runtime)
        record["runtime"] = runtime
        record["state_version"] = ev["seq"]
    if state != "starting":
        ev = store.append_event(session_id, "status.changed", creator,
                                 {"from": record["status"]["state"], "to": state, "source": "test", "detail": None})
        record["status"] = {"state": state, "since": ev["ts"], "source": "test", "detail": None}
        record["state_version"] = ev["seq"]
    store.save_session(record)
    return session_id


class CoreTestCase(unittest.TestCase):
    """Common fixture: an isolated sessions dir and a Herdr socket path,
    wired into os.environ so core.main()'s own env lookups pick them up."""

    def setUp(self):
        self._old_environ = dict(os.environ)
        self.sessions_dir = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-sessions-"))
        self.herdr_dir = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-herdr-"))
        self.herdr_socket = self.herdr_dir / "herdr.sock"
        self.plain_dir = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-plain-"))
        os.environ["OMARCHY_SESSIONS_DIR"] = str(self.sessions_dir)
        os.environ["HERDR_SOCKET"] = str(self.herdr_socket)
        self.store = core.SessionStore(self.sessions_dir)
        self.fake_herdr = None

    def tearDown(self):
        if self.fake_herdr is not None:
            self.fake_herdr.stop()
        os.environ.clear()
        os.environ.update(self._old_environ)
        for d in (self.sessions_dir, self.herdr_dir, self.plain_dir):
            shutil.rmtree(d, ignore_errors=True)

    def start_fake_herdr(self, agent_start_result=None):
        self.fake_herdr = FakeHerdrServer(self.herdr_socket)
        # Real Herdr 0.8.2 shapes (verified on the rig 2026-09-02): a
        # workspace.create returns its root pane; agent.start returns the
        # agent whose `name` is the alias the session layer calls agent_id.
        self.fake_herdr.set_result("workspace.create", {
            "root_pane": {"pane_id": "p1", "workspace_id": "w1", "tab_id": "t1"},
            "workspace": {"workspace_id": "w1"},
        })
        self.fake_herdr.set_result("agent.start", agent_start_result or (
            lambda params: {"agent": {"name": params.get("name", "a1"), "agent": params.get("kind"),
                                      "pane_id": params.get("pane_id", "p1"), "workspace_id": "w1", "tab_id": "t1",
                                      "agent_status": "idle"}}))
        self.fake_herdr.set_result("agent.list", {"agents": []})
        self.fake_herdr.set_result("pane.list", {"panes": []})
        self.fake_herdr.set_result("pane.report_metadata", {"type": "ok"})
        self.fake_herdr.start()
        return self.fake_herdr

    def run_cli(self, argv):
        """Calls core.main() in-process, returns (exit_code, stdout, stderr)."""
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            rc = core.main(argv)
        return rc, out.getvalue(), err.getvalue()


# --------------------------------------------------------------------------
# create + list, `new` printing the id, `list --json` shape
# --------------------------------------------------------------------------

class TestCreateAndList(CoreTestCase):
    def test_new_prints_id_on_stdout_and_creates_record(self):
        self.start_fake_herdr()
        rc, out, err = self.run_cli([
            "new", "--agent", "claude", "--mode", "personal", "--name", "api-refactor",
            "--cwd", str(self.plain_dir), "--no-worktree",
        ])
        self.assertEqual(rc, 0, err)
        session_id = out.strip()
        self.assertTrue(core.looks_like_ulid(session_id), session_id)

        record = self.store.try_load(session_id)
        self.assertIsNotNone(record)
        self.assertEqual(record["name"], "api-refactor")
        self.assertEqual(record["agent"]["kind"], "claude")
        self.assertEqual(record["mode"], "personal")
        self.assertEqual(record["status"]["state"], "working")
        self.assertIsNotNone(record["runtime"])
        self.assertTrue(record["runtime"]["agent_id"])

        # agent.start actually received the Personal-mode flags, and a
        # workspace was created for the pane first.
        self.assertEqual(len(self.fake_herdr.calls("workspace.create")), 1)
        start_calls = self.fake_herdr.calls("agent.start")
        self.assertEqual(len(start_calls), 1)
        self.assertEqual(start_calls[0]["pane_id"], "p1")
        self.assertIn("--permission-mode", start_calls[0]["args"])
        self.assertIn("auto", start_calls[0]["args"])

    def test_started_with_command_reflects_the_actual_argv_not_the_process_argv(self):
        # Regression: started_with.command must be built from the argv
        # main() was actually given, not from sys.argv (which, called
        # in-process as every test here does, would be the test runner's
        # own command line, not "new --agent ...").
        self.start_fake_herdr()
        rc, out, err = self.run_cli([
            "new", "--agent", "claude", "--name", "argv-check",
            "--cwd", str(self.plain_dir), "--no-worktree",
        ])
        self.assertEqual(rc, 0, err)
        record = self.store.try_load(out.strip())
        command = record["started_with"]["command"]
        self.assertIn("--agent claude", command)
        self.assertIn("--name argv-check", command)
        self.assertNotIn("unittest", command)

    def test_new_with_explicit_json_prints_full_record(self):
        self.start_fake_herdr()
        rc, out, err = self.run_cli([
            "new", "--agent", "codex", "--mode", "personal", "--name", "with-json",
            "--cwd", str(self.plain_dir), "--no-worktree", "--json",
        ])
        self.assertEqual(rc, 0, err)
        record = json.loads(out)
        self.assertEqual(record["name"], "with-json")
        self.assertEqual(record["id"], record["id"])  # sanity: valid JSON with an id

    def test_list_is_empty_with_no_sessions_and_no_herdr_call_needed(self):
        # No fake Herdr server started at all -- list must still work.
        rc, out, err = self.run_cli(["list", "--json"])
        self.assertEqual(rc, 0, err)
        self.assertEqual(json.loads(out), {"sessions": []})

    def test_list_after_two_creates(self):
        self.start_fake_herdr()
        rc1, out1, _ = self.run_cli(["new", "--agent", "claude", "--name", "one",
                                      "--cwd", str(self.plain_dir), "--no-worktree"])
        rc2, out2, _ = self.run_cli(["new", "--agent", "claude", "--name", "two",
                                      "--cwd", str(self.plain_dir), "--no-worktree"])
        self.assertEqual((rc1, rc2), (0, 0))
        rc, out, err = self.run_cli(["list", "--json"])
        self.assertEqual(rc, 0, err)
        names = {s["name"] for s in json.loads(out)["sessions"]}
        self.assertEqual(names, {"one", "two"})


class TestListJsonShape(CoreTestCase):
    def test_list_json_shape_matches_spec(self):
        session_id = make_bare_session(self.store, "shape-check", state="working")
        rc, out, err = self.run_cli(["list", "--json"])
        self.assertEqual(rc, 0, err)
        data = json.loads(out)
        self.assertEqual(list(data.keys()), ["sessions"])
        self.assertEqual(len(data["sessions"]), 1)
        entry = data["sessions"][0]
        self.assertEqual(
            set(entry.keys()),
            {"id", "name", "agent", "status", "owner", "workspace", "needs_attention", "children", "state_version"},
        )
        self.assertEqual(set(entry["agent"].keys()), {"kind"})
        self.assertEqual(set(entry["status"].keys()), {"state", "since"})
        self.assertEqual(set(entry["owner"].keys()), {"kind", "id", "label"})
        self.assertEqual(set(entry["workspace"].keys()), {"branch"})
        self.assertIs(entry["needs_attention"], False)
        self.assertEqual(entry["children"], 0)
        self.assertIsInstance(entry["children"], int)
        self.assertEqual(entry["id"], session_id)

    def test_needs_attention_true_exactly_for_waiting_and_blocked(self):
        waiting_id = make_bare_session(self.store, "wait-me", state="waiting")
        blocked_id = make_bare_session(self.store, "block-me", state="blocked")
        idle_id = make_bare_session(self.store, "idle-me", state="idle")
        rc, out, err = self.run_cli(["list", "--json"])
        self.assertEqual(rc, 0, err)
        by_id = {s["id"]: s for s in json.loads(out)["sessions"]}
        self.assertTrue(by_id[waiting_id]["needs_attention"])
        self.assertTrue(by_id[blocked_id]["needs_attention"])
        self.assertFalse(by_id[idle_id]["needs_attention"])

    def test_children_count_reflects_lineage(self):
        parent_id = make_bare_session(self.store, "parent")
        parent = self.store.try_load(parent_id)
        parent["lineage"]["children"] = ["childA", "childB"]
        self.store.save_session(parent)
        rc, out, err = self.run_cli(["list", "--json"])
        self.assertEqual(rc, 0, err)
        entry = next(s for s in json.loads(out)["sessions"] if s["id"] == parent_id)
        self.assertEqual(entry["children"], 2)


# --------------------------------------------------------------------------
# state transitions and event seq monotonicity
# --------------------------------------------------------------------------

class TestStateMachineAndEvents(CoreTestCase):
    def test_valid_transitions_from_spec_table(self):
        valid_pairs = [
            ("starting", "working"), ("working", "waiting"), ("working", "blocked"),
            ("waiting", "working"), ("blocked", "working"), ("working", "idle"),
            ("idle", "working"), ("orphaned", "working"),
            ("working", "done"), ("waiting", "failed"), ("blocked", "stopped"),
            ("idle", "orphaned"),
        ]
        for a, b in valid_pairs:
            self.assertTrue(core.is_valid_transition(a, b), f"{a} -> {b} should be valid")

    def test_invalid_transitions(self):
        invalid_pairs = [
            ("done", "working"), ("failed", "working"), ("stopped", "working"),
            ("starting", "idle"), ("idle", "blocked"), ("waiting", "blocked"),
        ]
        for a, b in invalid_pairs:
            self.assertFalse(core.is_valid_transition(a, b), f"{a} -> {b} should be invalid")

    def test_event_seq_is_monotonic_and_state_version_matches(self):
        session_id = make_bare_session(self.store, "seq-check")
        actor = core.system_actor()
        seqs = []
        for i in range(5):
            ev = self.store.append_event(session_id, "status.changed", actor,
                                          {"from": "working", "to": "working", "source": "test", "detail": str(i)})
            seqs.append(ev["seq"])
        self.assertEqual(seqs, sorted(seqs))
        self.assertEqual(seqs, list(range(seqs[0], seqs[0] + 5)))
        # Never decreases, and a fresh SessionStore (simulating a new
        # process) reading the same directory agrees on the next seq.
        other_store = core.SessionStore(self.sessions_dir)
        next_ev = other_store.append_event(session_id, "status.changed", actor,
                                            {"from": "working", "to": "idle", "source": "test", "detail": None})
        self.assertEqual(next_ev["seq"], seqs[-1] + 1)

    def test_every_event_has_an_actor(self):
        session_id = make_bare_session(self.store, "actor-check")
        for e in self.store.read_events(session_id):
            self.assertIn("actor", e)
            self.assertIn(e["actor"]["kind"], ("human", "agent", "system"))

    def test_state_version_never_decreases_across_saves(self):
        session_id = make_bare_session(self.store, "monotone")
        record = self.store.try_load(session_id)
        versions = [record["state_version"]]
        actor = core.system_actor()
        for _ in range(3):
            ev = self.store.append_event(session_id, "status.changed", actor,
                                          {"from": "working", "to": "working", "source": "test", "detail": None})
            record["state_version"] = ev["seq"]
            self.store.save_session(record)
            versions.append(record["state_version"])
        self.assertEqual(versions, sorted(versions))


# --------------------------------------------------------------------------
# invariant 5: refuse shared/restricted + bypass
# --------------------------------------------------------------------------

class TestInvariant5(CoreTestCase):
    def test_refuses_shared_with_smuggled_bypass_flag(self):
        self.start_fake_herdr()
        rc, out, err = self.run_cli([
            "new", "--agent", "claude", "--mode", "shared", "--name", "sneaky",
            "--cwd", str(self.plain_dir), "--no-worktree",
            "--", "--permission-mode", "auto",
        ])
        self.assertEqual(rc, 5, err)
        self.assertIn("invariant 5", err)
        self.assertEqual(self.store.list_sessions(), [])
        self.assertEqual(self.fake_herdr.calls("agent.start"), [])

    def test_refuses_restricted_for_a_harness_with_no_safe_expression(self):
        # hermes has no config that satisfies restricted's contract at all.
        self.start_fake_herdr()
        rc, out, err = self.run_cli([
            "new", "--agent", "hermes", "--mode", "restricted", "--name", "no-go",
            "--cwd", str(self.plain_dir), "--no-worktree",
        ])
        self.assertEqual(rc, 5, err)
        self.assertEqual(self.store.list_sessions(), [])

    def test_codex_ask_for_approval_never_without_readonly_sandbox_is_refused(self):
        self.start_fake_herdr()
        rc, out, err = self.run_cli([
            "new", "--agent", "codex", "--mode", "shared", "--name", "codex-sneaky",
            "--cwd", str(self.plain_dir), "--no-worktree",
            "--", "--ask-for-approval", "never",
        ])
        self.assertEqual(rc, 5, err)

    def test_codex_ask_for_approval_never_with_readonly_sandbox_is_allowed_shape(self):
        # Direct unit check of the predicate (not a full `new`, since the
        # shared cell's own flags already include a workspace-write
        # sandbox; this exercises check_invariant5 in isolation instead).
        core.check_invariant5("codex", "shared",
                               ["--sandbox", "read-only", "--ask-for-approval", "never"], {})

    def test_personal_mode_is_never_checked(self):
        core.check_invariant5("claude", "personal", ["--permission-mode", "auto"], {})

    def test_new_allows_personal_with_bypass_flags(self):
        self.start_fake_herdr()
        rc, out, err = self.run_cli([
            "new", "--agent", "claude", "--mode", "personal", "--name", "personal-ok",
            "--cwd", str(self.plain_dir), "--no-worktree",
        ])
        self.assertEqual(rc, 0, err)


# --------------------------------------------------------------------------
# marker line on send --from
# --------------------------------------------------------------------------

class TestSendMarker(CoreTestCase):
    def test_marker_line_delivered_to_herdr_on_send_from(self):
        self.start_fake_herdr()
        origin_id = make_bare_session(self.store, "origin-session")
        target_runtime = {"backend": "herdr", "session": "s1", "workspace_id": "w1",
                           "tab_id": "t1", "pane_id": "p1", "agent_id": "a1"}
        target_id = make_bare_session(self.store, "target-session", runtime=target_runtime)

        rc, out, err = self.run_cli(["send", target_id, "add a regression test", "--from", origin_id])
        self.assertEqual(rc, 0, err)

        calls = self.fake_herdr.calls("agent.prompt")
        self.assertEqual(len(calls), 1)
        expected = core.format_marked_instruction(origin_id, "origin-session", "add a regression test")
        self.assertEqual(calls[0]["text"], expected)
        self.assertTrue(expected.startswith(f"[omarchy-session-message from={origin_id} name=origin-session]\n\n"))

        # The stored instruction keeps origin_session as structured
        # provenance; instruction.delivered confirms delivery.
        events = self.store.read_events(target_id)
        queued = [e for e in events if e["type"] == "instruction.queued"][0]
        self.assertEqual(queued["data"]["origin_session"], origin_id)
        self.assertEqual(queued["data"]["text"], "add a regression test")
        delivered = [e for e in events if e["type"] == "instruction.delivered"]
        self.assertEqual(len(delivered), 1)

    def test_marker_strips_newlines_and_brackets_from_name(self):
        text = core.format_marked_instruction("01J", "evil]\nname", "hi")
        first_line = text.splitlines()[0]
        self.assertTrue(first_line.startswith("[omarchy-session-message from=01J name="))
        self.assertTrue(first_line.endswith("]"))
        # Everything between "name=" and the marker's own closing "]" must
        # have had embedded "]" and newlines stripped, per spec-02.
        name_segment = first_line[len("[omarchy-session-message from=01J name="):-1]
        self.assertNotIn("]", name_segment)
        self.assertNotIn("\n", name_segment)
        self.assertEqual(name_segment, "evil name")

    def test_human_send_carries_no_marker(self):
        self.start_fake_herdr()
        runtime = {"backend": "herdr", "session": "s1", "workspace_id": "w1",
                   "tab_id": "t1", "pane_id": "p1", "agent_id": "a1"}
        target_id = make_bare_session(self.store, "target-2", runtime=runtime)
        rc, out, err = self.run_cli(["send", target_id, "plain human text"])
        self.assertEqual(rc, 0, err)
        calls = self.fake_herdr.calls("agent.prompt")
        self.assertEqual(calls[0]["text"], "plain human text")

    def test_send_to_unbound_session_stays_queued_no_herdr_call(self):
        # No fake Herdr server running at all.
        target_id = make_bare_session(self.store, "unbound-target", runtime=None, state="starting")
        rc, out, err = self.run_cli(["send", target_id, "queue me"])
        self.assertEqual(rc, 0, err)
        session = self.store.try_load(target_id)
        self.assertEqual(len(session["queue"]), 1)
        self.assertEqual(session["queue"][0]["text"], "queue me")


# --------------------------------------------------------------------------
# receipt computation against a temporary git repo with two commits
# --------------------------------------------------------------------------

class TestReceiptComputation(CoreTestCase):
    def _git(self, repo, *args):
        r = subprocess.run(["git", *args], cwd=str(repo), capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, f"git {args} failed: {r.stderr}")
        return r

    def make_git_repo_with_two_commits(self):
        repo = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-git-"))
        self._git(repo, "init", "-b", "main")
        self._git(repo, "config", "user.email", "test@example.com")
        self._git(repo, "config", "user.name", "Test User")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        self._git(repo, "add", "README.md")
        self._git(repo, "commit", "-m", "base commit")
        self._git(repo, "checkout", "-b", "session/test-branch")
        (repo / "a.txt").write_text("a\n", encoding="utf-8")
        self._git(repo, "add", "a.txt")
        self._git(repo, "commit", "-m", "add a")
        (repo / "b.txt").write_text("b\n", encoding="utf-8")
        self._git(repo, "add", "b.txt")
        self._git(repo, "commit", "-m", "add b")
        return repo

    def test_receipt_fields_computed_from_git(self):
        repo = self.make_git_repo_with_two_commits()
        try:
            workspace = {
                "repo_root": str(repo), "worktree_path": str(repo),
                "branch": "session/test-branch", "base_branch": "main",
                "created_by_session": True,
            }
            session_id = make_bare_session(self.store, "receipt-test", workspace=workspace)
            session = self.store.try_load(session_id)
            receipt = core.compute_receipt(self.store, session)

            self.assertEqual(len(receipt["commits"]), 2)
            self.assertEqual([c["subject"] for c in receipt["commits"]], ["add a", "add b"])
            for c in receipt["commits"]:
                self.assertEqual(c["author"], "Test User")
                self.assertEqual(len(c["sha"]), 40)

            self.assertEqual(receipt["diff_stat"]["files"], 2)
            self.assertEqual(receipt["diff_stat"]["insertions"], 2)
            self.assertEqual(receipt["diff_stat"]["deletions"], 0)

            self.assertFalse(receipt["dirty"])
            self.assertTrue(receipt["unpushed"])  # no remote at all
            self.assertEqual(receipt["session_id"], session_id)
            self.assertEqual(receipt["state_version"], session["state_version"])
        finally:
            shutil.rmtree(repo, ignore_errors=True)

    def test_receipt_dirty_true_with_uncommitted_change(self):
        repo = self.make_git_repo_with_two_commits()
        try:
            (repo / "a.txt").write_text("changed\n", encoding="utf-8")
            workspace = {
                "repo_root": str(repo), "worktree_path": str(repo),
                "branch": "session/test-branch", "base_branch": "main",
                "created_by_session": True,
            }
            session_id = make_bare_session(self.store, "dirty-test", workspace=workspace)
            session = self.store.try_load(session_id)
            receipt = core.compute_receipt(self.store, session)
            self.assertTrue(receipt["dirty"])
        finally:
            shutil.rmtree(repo, ignore_errors=True)

    def test_receipt_write_via_done_command(self):
        repo = self.make_git_repo_with_two_commits()
        try:
            workspace = {
                "repo_root": str(repo), "worktree_path": str(repo),
                "branch": "session/test-branch", "base_branch": "main",
                "created_by_session": True,
            }
            session_id = make_bare_session(self.store, "done-test", workspace=workspace)
            rc, out, err = self.run_cli(["done", session_id, "--verdict", "kept", "--note", "shipped it"])
            self.assertEqual(rc, 0, err)
            session = self.store.try_load(session_id)
            self.assertEqual(session["status"]["state"], "done")
            receipt_path = self.store.receipt_path(session_id)
            self.assertTrue(receipt_path.exists())
            receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
            self.assertEqual(receipt["end_state"], "done")
            self.assertEqual(receipt["end_reason"], "verdict:kept")
            self.assertEqual(len(receipt["artifacts"]), 1)
            self.assertEqual(receipt["artifacts"][0]["label"], "verdict")
        finally:
            shutil.rmtree(repo, ignore_errors=True)


# --------------------------------------------------------------------------
# `open`: bound-and-live, orphan-with-ref resume, orphan-without-ref,
# nothing-to-open, and Herdr-unreachable
# --------------------------------------------------------------------------

class TestOpen(CoreTestCase):
    def test_open_bound_and_live_confirms_binding(self):
        self.start_fake_herdr()
        self.fake_herdr.set_result("agent.get", {"agent": {"name": "a1", "agent_status": "working"}})
        runtime = {"backend": "herdr", "session": "s1", "workspace_id": "w1",
                   "tab_id": "t1", "pane_id": "p1", "agent_id": "a1"}
        session_id = make_bare_session(self.store, "bound-live", runtime=runtime, state="working")
        rc, out, err = self.run_cli(["open", session_id])
        self.assertEqual(rc, 0, err)
        self.assertEqual(self.fake_herdr.calls("agent.get"), [{"target": "a1"}])

    def test_open_orphaned_with_ref_resumes(self):
        self.start_fake_herdr()
        session_id = make_bare_session(self.store, "orphan-with-ref", runtime=None, state="orphaned")
        record = self.store.try_load(session_id)
        record["agent"]["harness_session_ref"] = "abc123"
        self.store.save_session(record)

        rc, out, err = self.run_cli(["open", session_id])
        self.assertEqual(rc, 0, err)
        record = self.store.try_load(session_id)
        self.assertEqual(record["status"]["state"], "working")
        self.assertIsNotNone(record["runtime"])
        start_flags = self.fake_herdr.calls("agent.start")[-1]["args"]
        self.assertEqual(start_flags[:2], ["--resume", "abc123"])

    def test_open_orphaned_without_ref_starts_fresh(self):
        self.start_fake_herdr()
        session_id = make_bare_session(self.store, "orphan-no-ref", runtime=None, state="orphaned")
        rc, out, err = self.run_cli(["open", session_id])
        self.assertEqual(rc, 0, err)
        record = self.store.try_load(session_id)
        self.assertEqual(record["status"]["state"], "working")
        self.assertEqual(record["status"]["detail"], "no transcript to resume")

    def test_open_with_nothing_to_open_is_a_conflict(self):
        session_id = make_bare_session(self.store, "nothing-to-open", runtime=None, state="starting")
        rc, out, err = self.run_cli(["open", session_id])
        self.assertEqual(rc, 5, err)

    def test_open_bound_but_herdr_unreachable_exits_4(self):
        # No fake server started.
        runtime = {"backend": "herdr", "session": "s1", "workspace_id": "w1",
                   "tab_id": "t1", "pane_id": "p1", "agent_id": "a1"}
        session_id = make_bare_session(self.store, "bound-no-herdr", runtime=runtime, state="working")
        rc, out, err = self.run_cli(["open", session_id])
        self.assertEqual(rc, 4, err)


# --------------------------------------------------------------------------
# Worktree cleanup at stop/done (07-worktrees.md's keep/remove table)
# --------------------------------------------------------------------------

class TestWorktreeCleanup(CoreTestCase):
    def _git(self, cwd, *args):
        r = subprocess.run(["git", *args], cwd=str(cwd), capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, f"git {args} failed: {r.stderr}")
        return r

    def make_repo_with_real_worktree(self):
        repo = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-repo-"))
        self._git(repo, "init", "-b", "main")
        self._git(repo, "config", "user.email", "test@example.com")
        self._git(repo, "config", "user.name", "Test User")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        self._git(repo, "add", "README.md")
        self._git(repo, "commit", "-m", "base commit")
        wt = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-wt-parent-")) / "wt"
        self._git(repo, "worktree", "add", str(wt), "-b", "session/cleanup-test", "main")
        (wt / "a.txt").write_text("a\n", encoding="utf-8")
        self._git(wt, "add", "a.txt")
        self._git(wt, "commit", "-m", "add a")
        return repo, wt

    def test_keeps_dirty_worktree(self):
        repo, wt = self.make_repo_with_real_worktree()
        try:
            (wt / "a.txt").write_text("dirty\n", encoding="utf-8")
            should_remove, reason = core.decide_worktree_cleanup(str(wt), "session/cleanup-test", "main")
            self.assertFalse(should_remove)
            self.assertIn("uncommitted", reason)
            self.assertTrue(wt.exists())
        finally:
            shutil.rmtree(repo, ignore_errors=True)
            shutil.rmtree(wt.parent, ignore_errors=True)

    def test_keeps_clean_unmerged_unpushed_worktree(self):
        repo, wt = self.make_repo_with_real_worktree()
        try:
            should_remove, reason = core.decide_worktree_cleanup(str(wt), "session/cleanup-test", "main")
            self.assertFalse(should_remove)
            self.assertIn("not pushed", reason)
        finally:
            shutil.rmtree(repo, ignore_errors=True)
            shutil.rmtree(wt.parent, ignore_errors=True)

    def test_removes_clean_merged_worktree_but_keeps_branch(self):
        repo, wt = self.make_repo_with_real_worktree()
        try:
            self._git(repo, "merge", "--no-ff", "session/cleanup-test", "-m", "merge it")
            should_remove, reason = core.decide_worktree_cleanup(str(wt), "session/cleanup-test", "main")
            self.assertTrue(should_remove)
            self.assertIn("merged", reason)

            session = {"workspace": {
                "repo_root": str(repo), "worktree_path": str(wt),
                "branch": "session/cleanup-test", "base_branch": "main", "created_by_session": True,
            }}
            core.cleanup_workspace_if_owned(session, herdr=None)
            self.assertFalse(wt.exists())
            self.assertTrue(session["workspace"]["worktree_removed"])
            branches = self._git(repo, "branch", "--list", "session/cleanup-test").stdout
            self.assertIn("session/cleanup-test", branches)  # invariant 7: branch kept
        finally:
            shutil.rmtree(repo, ignore_errors=True)
            shutil.rmtree(wt.parent, ignore_errors=True)

    def test_stop_command_triggers_cleanup_and_persists_it(self):
        repo, wt = self.make_repo_with_real_worktree()
        try:
            self._git(repo, "merge", "--no-ff", "session/cleanup-test", "-m", "merge it")
            workspace = {
                "repo_root": str(repo), "worktree_path": str(wt),
                "branch": "session/cleanup-test", "base_branch": "main", "created_by_session": True,
            }
            session_id = make_bare_session(self.store, "stop-cleanup", workspace=workspace, state="idle")
            rc, out, err = self.run_cli(["stop", session_id])
            self.assertEqual(rc, 0, err)
            self.assertFalse(wt.exists())
            record = self.store.try_load(session_id)
            self.assertTrue(record["workspace"]["worktree_removed"])
        finally:
            shutil.rmtree(repo, ignore_errors=True)
            shutil.rmtree(wt.parent, ignore_errors=True)

    def test_never_touches_a_worktree_this_session_did_not_create(self):
        repo, wt = self.make_repo_with_real_worktree()
        try:
            self._git(repo, "merge", "--no-ff", "session/cleanup-test", "-m", "merge it")
            session = {"workspace": {
                "repo_root": str(repo), "worktree_path": str(wt),
                "branch": "session/cleanup-test", "base_branch": "main", "created_by_session": False,
            }}
            core.cleanup_workspace_if_owned(session, herdr=None)
            self.assertTrue(wt.exists())
            self.assertNotIn("worktree_removed", session["workspace"])
        finally:
            shutil.rmtree(repo, ignore_errors=True)
            shutil.rmtree(wt.parent, ignore_errors=True)


# --------------------------------------------------------------------------
# reconcile marking an orphan
# --------------------------------------------------------------------------

class TestReconcile(CoreTestCase):
    def test_reconcile_marks_missing_pane_orphaned(self):
        self.start_fake_herdr()
        self.fake_herdr.set_result("agent.list", {"agents": []})
        self.fake_herdr.set_result("pane.list", {"panes": []})
        runtime = {"backend": "herdr", "session": "s1", "workspace_id": "w1",
                   "tab_id": "t1", "pane_id": "p1", "agent_id": "a1"}
        session_id = make_bare_session(self.store, "will-be-orphaned", runtime=runtime, state="working")

        rc, out, err = self.run_cli(["reconcile", "--json"])
        self.assertEqual(rc, 0, err)

        session = self.store.try_load(session_id)
        self.assertEqual(session["status"]["state"], "orphaned")
        self.assertIsNone(session["runtime"])

        result = json.loads(out)
        self.assertIn(session_id, result["orphaned"])

        events = self.store.read_events(session_id)
        types = [e["type"] for e in events]
        self.assertIn("status.changed", types)
        self.assertIn("runtime.unbound", types)

    def test_reconcile_leaves_a_still_present_pane_alone(self):
        self.start_fake_herdr()
        self.fake_herdr.set_result("agent.list", {"agents": [{"name": "a1", "agent": "claude", "pane_id": "p1"}]})
        self.fake_herdr.set_result("pane.list", {"panes": [{"pane_id": "p1"}]})
        runtime = {"backend": "herdr", "session": "s1", "workspace_id": "w1",
                   "tab_id": "t1", "pane_id": "p1", "agent_id": "a1"}
        session_id = make_bare_session(self.store, "still-alive", runtime=runtime, state="working")

        rc, out, err = self.run_cli(["reconcile", "--json"])
        self.assertEqual(rc, 0, err)
        session = self.store.try_load(session_id)
        self.assertEqual(session["status"]["state"], "working")
        self.assertIsNotNone(session["runtime"])

    def test_reconcile_adopts_an_unmatched_herdr_agent(self):
        self.start_fake_herdr()
        self.fake_herdr.set_result("agent.list", {"agents": [{"name": "orphan-agent", "agent": "claude", "pane_id": "orphan-pane", "workspace_id": "w9", "tab_id": "w9:t1"}]})
        self.fake_herdr.set_result("pane.list", {"panes": [{"pane_id": "orphan-pane"}]})

        rc, out, err = self.run_cli(["reconcile", "--json"])
        self.assertEqual(rc, 0, err)
        result = json.loads(out)
        self.assertEqual(len(result["adopted"]), 1)
        adopted_id = result["adopted"][0]
        session = self.store.try_load(adopted_id)
        self.assertEqual(session["created_by"]["kind"], "system")
        self.assertEqual(session["runtime"]["agent_id"], "orphan-agent")
        self.assertEqual(session["status"]["state"], "working")

    def test_reconcile_exits_4_when_herdr_unreachable(self):
        # No fake server started -- socket path has nothing listening.
        rc, out, err = self.run_cli(["reconcile"])
        self.assertEqual(rc, 4, err)


# --------------------------------------------------------------------------
# Supplementary coverage: ULIDs, atomic writes, actors, aliases, invariant 6
# --------------------------------------------------------------------------

class TestUlid(unittest.TestCase):
    def test_format_and_uniqueness(self):
        ulids = {core.new_ulid() for _ in range(200)}
        self.assertEqual(len(ulids), 200)
        for u in ulids:
            self.assertEqual(len(u), 26)
            self.assertTrue(core.looks_like_ulid(u))
            self.assertNotIn("I", u)
            self.assertNotIn("L", u)
            self.assertNotIn("O", u)
            self.assertNotIn("U", u)

    def test_timestamp_orders_lexicographically(self):
        a = core.new_ulid(now_ms=1000)
        b = core.new_ulid(now_ms=2000)
        self.assertLess(a[:10], b[:10])


class TestAtomicWrite(unittest.TestCase):
    def test_atomic_write_json_roundtrip_and_no_stray_temp_files(self):
        d = pathlib.Path(tempfile.mkdtemp())
        try:
            path = d / "sub" / "session.json"
            core.atomic_write_json(path, {"a": 1})
            self.assertEqual(json.loads(path.read_text(encoding="utf-8")), {"a": 1})
            core.atomic_write_json(path, {"a": 2})
            self.assertEqual(json.loads(path.read_text(encoding="utf-8")), {"a": 2})
            leftovers = [p for p in path.parent.iterdir() if p.name != "session.json"]
            self.assertEqual(leftovers, [])
        finally:
            shutil.rmtree(d, ignore_errors=True)


class TestActors(unittest.TestCase):
    def test_actor_string_roundtrip(self):
        actor = core.parse_actor_string("human:praneet@rig")
        self.assertEqual(actor, {"kind": "human", "id": "praneet@rig", "label": "praneet"})
        self.assertEqual(core.actor_to_string(actor), "human:praneet@rig")

    def test_invalid_actor_string_rejected(self):
        with self.assertRaises(core.UsageError):
            core.parse_actor_string("not-an-actor")
        with self.assertRaises(core.UsageError):
            core.parse_actor_string("robot:x")


class TestAliasDerivation(unittest.TestCase):
    def test_lowercases_and_collapses_runs(self):
        self.assertEqual(core.derive_herdr_alias("API Refactor!!", "01J8Z3K9QY7NX8V2H5T6M4R1WB"), "api-refactor")

    def test_prefixes_when_not_starting_with_letter(self):
        alias = core.derive_herdr_alias("123-go", "01J8Z3K9QY7NX8V2H5T6M4R1WB")
        self.assertTrue(alias[0].isalpha())

    def test_truncates_to_32(self):
        alias = core.derive_herdr_alias("x" * 50, "01J8Z3K9QY7NX8V2H5T6M4R1WB")
        self.assertLessEqual(len(alias), 32)

    def test_collision_appends_last_four_id_chars(self):
        alias = core.derive_herdr_alias("api-refactor", "01J8Z3K9QY7NX8V2H5T6M4R1WB",
                                         existing_aliases={"api-refactor"})
        self.assertNotEqual(alias, "api-refactor")
        self.assertTrue(alias.endswith("1wb"))


class TestInvariant6(CoreTestCase):
    def test_refuses_sharing_a_worktree_that_was_auto_created(self):
        auto_ws = {"repo_root": "/r", "worktree_path": "/r/wt", "branch": "session/x",
                   "base_branch": "main", "created_by_session": True}
        make_bare_session(self.store, "auto-creator", workspace=auto_ws)
        joining_ws = dict(auto_ws, created_by_session=False)
        with self.assertRaises(core.ConflictError):
            core.check_invariant6(self.store, joining_ws, new_session_created_by_session=False)

    def test_allows_sharing_a_hand_made_worktree(self):
        hand_ws = {"repo_root": "/r", "worktree_path": "/r/wt-manual", "branch": "manual",
                   "base_branch": None, "created_by_session": False}
        make_bare_session(self.store, "first-joiner", workspace=hand_ws)
        core.check_invariant6(self.store, hand_ws, new_session_created_by_session=False)  # must not raise


class TestNoDeleteCommand(unittest.TestCase):
    def test_no_delete_subcommand_exists(self):
        # Invariant 7: no slice-1 command deletes a session directory.
        parser = core.build_parser()
        sub_actions = [a for a in parser._subparsers._group_actions if hasattr(a, "choices")]
        subcommands = set(sub_actions[0].choices.keys())
        self.assertNotIn("delete", subcommands)
        self.assertNotIn("rm", subcommands)
        self.assertNotIn("prune", subcommands)


class TestCliIsExecutable(unittest.TestCase):
    """One true subprocess-level test, proving the shebang and the
    executable bit work end to end, not just the in-process import path."""

    def test_cli_runs_as_a_real_program(self):
        sessions_dir = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-sessions-subproc-"))
        herdr_dir = pathlib.Path(tempfile.mkdtemp(prefix="omarchy-herdr-subproc-"))
        try:
            env = dict(os.environ)
            env["OMARCHY_SESSIONS_DIR"] = str(sessions_dir)
            env["HERDR_SOCKET"] = str(herdr_dir / "herdr.sock")  # nothing listening; `list` needs no Herdr
            result = subprocess.run([str(CORE_PATH), "list", "--json"],
                                     capture_output=True, text=True, env=env, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout), {"sessions": []})

            result = subprocess.run([str(CORE_PATH)], capture_output=True, text=True, env=env, timeout=10)
            self.assertEqual(result.returncode, 2)  # usage error: no subcommand
        finally:
            shutil.rmtree(sessions_dir, ignore_errors=True)
            shutil.rmtree(herdr_dir, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
