#!/usr/bin/env python3
"""Snapshot each evaluation session's Claude transcript: path, line count,
last user/assistant message, mtime. Usage: eval_transcripts.py <label>"""
import glob, json, os, re, sys, time

label = sys.argv[1] if len(sys.argv) > 1 else "snapshot"
ids = [l.split("=")[1] for l in open("/tmp/eval-run2/ids.txt").read().split()]
out = []
for sid in ids:
    s = json.load(open(f"/home/omarchy/.local/state/omarchy/sessions/{sid}/session.json"))
    ref = s["agent"].get("harness_session_ref")
    cwd = s["workspace"].get("worktree_path") or s["started_with"]["cwd"]
    slug = re.sub(r"[/.]", "-", cwd)
    path = f"/home/omarchy/.claude/projects/{slug}/{ref}.jsonl" if ref else None
    last = None
    n = 0
    if path and os.path.exists(path):
        lines = open(path).read().splitlines()
        n = len(lines)
        for l in reversed(lines):
            try:
                d = json.loads(l)
            except Exception:
                continue
            if d.get("type") in ("assistant", "user"):
                m = d.get("message", {})
                c = m.get("content")
                if isinstance(c, str):
                    text = c
                elif isinstance(c, list):
                    text = " ".join(x.get("text", "") for x in c if isinstance(x, dict) and x.get("type") == "text")
                else:
                    text = str(c)
                text = text.strip()
                if text:
                    last = (d.get("type"), text[:200])
                    break
    out.append({"id": sid, "name": s["name"], "state": s["status"]["state"], "ref": ref,
                "transcript": path, "lines": n, "last": last,
                "mtime": os.path.getmtime(path) if path and os.path.exists(path) else None,
                "pane": (s.get("runtime") or {}).get("pane_id"), "at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())})
json.dump(out, open(f"/tmp/eval-run2/transcripts-{label}.json", "w"), indent=1)
for o in out:
    print(o["name"], o["state"], o["lines"], "lines; last:", o["last"])
