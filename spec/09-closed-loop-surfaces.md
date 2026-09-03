# Closed-loop surfaces for product people

Status: proposed, 2026-09-01; sections 1 through 5 and 7 verified on the rig 2026-09-02 (runs 3 and 4, `findings/closed-loop.md`). Slice 1 except where marked. Builds on `01-session-model.md` and `05-receipts-and-artifacts.md`.

A session that only a developer can drive is not the experiment. This file puts the closed-loop essay's loop directly into the command surface, so a designer who can look at a running product and describe what is wrong can run the whole thing: intent, working interface, situated feedback, implementation change, renewed observation, with the evidence, the approval gates, and the judgment all staying visible. Everything below is slice 1 unless marked otherwise.

## 1. The goal as intent record (slice 1)

`session new --goal` accepts three lines: the outcome, what must stay stable, and what evidence would change it. These map directly to three of the questions the essay puts to a designer shaping a system's behavior: what human outcome should it pursue, which parts of the experience must remain stable, what evidence should cause it to change. Slice 1 stores the three lines verbatim as `goal.text`, stamps `set_by` and `set_at`, and displays them as three lines everywhere the goal appears. It does not parse them into separate fields; a later slice can, without changing what a designer types.

The stability line exists because the failures that matter are the ones nobody wrote down. Design breakdowns concentrate in exactly this gap: an edge case the interface never named, found only once a change touches it (Maudet et al. 2017). Naming what must stay stable, in the goal itself, is how this session model puts that finding into a command.

## 2. The running product as shared canvas (slice 1)

A session may register a `preview`: a URL or a window app id. `session open` then does two things at once: it attaches the terminal to the transcript and focuses the preview, so the running product sits beside the conversation instead of behind it. `capture` defaults to the preview window when one is registered, which is why `05-receipts-and-artifacts.md` treats `preview` as the default capture target.

The preview is a boundary object: the same running window means something different to the designer, who reads it as an experience, and to the agent, which reads it as a target to change, and neither side needs the other's full model to work from it (Star & Griesemer 1989). The session record does not resolve that difference. It just keeps both sides pointed at the same object.

## 3. Situated feedback (slice 1)

`session send` delivers an instruction from the panel while the sender is looking at the preview, not a transcript scrollback. Every instruction already carries an author (`01-session-model.md`); this file adds `--about <artifact-id>`, which ties the instruction to the capture or note it was written in response to. An instruction sent this way is never just text; it is text plus the exact evidence that prompted it.

`--about` exists because feedback about a running interface is otherwise ambiguous: "fix that" means nothing without a shared referent for what "that" is. Tying the instruction to a specific artifact is how the two sides ground the reference before work starts, instead of discovering the mismatch after (Clark & Brennan 1991).

## 4. The evidence trail (slice 1)

Captures and notes carry `proposed` or `live` labels and a timestamp, so a before and an after are never ambiguous about which is which (`05-receipts-and-artifacts.md`). The receipt is the loop's permanent record once the session ends. While the session is live, `session show <id> --loop` renders the same story in progress: the intent, then every instruction in order with the artifact it was about, then every change, meaning the commit it produced, then the result captures, in the order they happened. Nothing in this view is computed specially; it is `events.jsonl` and the git log, joined and ordered.

## 5. Approval gates and the done verdict (slice 1)

Approval gates follow the session's mode, defined in full in `04-permission-modes.md`. In Personal mode most changes proceed without asking, since the harness may run with its own no-prompt flag; only what the harness itself escalates stops for a person. In Shared mode every write, execution, or external call asks, per the design rule that shared mode requires per-operation approval. `session send` and `session done` are available in every mode: giving feedback and closing a loop are never themselves operations that touch the workspace.

`session done <id> --verdict kept|reverted|needs-person --note "<text>"` fires the existing transition into `done` and writes the note as a `note` artifact, authored by the owner and labeled `verdict`. The judgment that closed the loop sits in the receipt's artifact list next to the captures, not off in a separate log.

## 6. Design artifacts (slice 1; live sync is slice 3)

A Figma link, a Paper link, or a `DESIGN.md` attaches the same way any artifact does: `session artifact add <id> --kind url --source <link>` or `--kind file --source DESIGN.md`. Slice 1 stores the link and reads nothing back from it. Figma's MCP server already exposes a write-to-canvas path, in beta, and Paper's MCP server exposes read and write tools against an open design file directly, including `write_html` and `update_styles`. Both are slice-3 candidates: a session that reads the live design state at the start of a loop and writes an approved change back at the end closes a second canvas beside the running product. Slice 1 takes no step toward either integration; it only reserves the artifact kind that would carry the link.

## 7. What the panel adds (slice 1)

A row with a registered preview gets one button, Preview, that focuses it without attaching the terminal. A row with no preview shows nothing extra to click. Every row's detail area gains one line, the loop count: `<n> instructions, <m> captures`, read straight off `events.jsonl`. It stays a detail, not a badge on the collapsed row, so it never competes with the status indicator success signal 1 depends on.

Built 2026-09-02 as `03-sessions-panel.md` describes: the Preview button and `p` run `preview --focus`; the Send field on such a row runs `send --with-capture`, which takes the capture itself (`capture --preview`: the registered window's geometry through `grim`, the whole screen when the window is gone, because Omarchy's `capture screenshot` wants a person to pick a region) and ties the instruction to it, the panel closing first so the capture shows the preview rather than the panel; the loop count leads the row's second line rather than following the goal, so a long goal cannot elide it. Run 4 on the rig: two instructions typed into the panel's Send field, each delivered with the capture it was about, two commits, one verdict, every step in `show --loop` and the receipt.

## 8. The measurement (slice 1)

The test is small and concrete: one designer runs one closed loop of three iterations against a real preview on the rig, a goal, three rounds of situated feedback each tied to a capture, three changes, one verdict, and both `session show --loop` and the final receipt show every step with no gap. Omarchy-UX evaluates agent-facing surfaces on usability, accessibility, and trust-and-handoff design. A closed-loop surface exists to keep responsibility and control legible while work passes between a person and an agent, so trust and handoff is the lens this measurement answers to.

## Scope limits

No live sync with a design tool in slice 1: captures and links are static once attached. No user-research capture: this file is one designer's own working loop, not moderated or unmoderated study tooling. No multi-person loop in slice 1: `session send`, `session done`, and the goal record all assume the one owner the session model already defines.

## Verify on rig

- Whether a non-terminal GUI window can be focused by app id with the same focus-not-duplicate behavior the launcher already gives TUI panes. Answered 2026-09-02 for URL previews: `omarchy-launch-webapp` opens a Chromium app window whose class is `chrome-<host>__<path with / as _>-Default`; `preview --focus` finds it by that class through `hyprctl clients -j` and focuses it by address, launching it only when no window matches (run 4: "launched", then "focused"). App-id previews use the same lookup on the class; untested live.
- Whether `session show --loop`, rendered live against a long-running session, stays fast enough to feel immediate.

## Sources

- Praneet Koppula, "Closed-Loop Experience Design," mphaxise.github.io/Praneet_Koppula/writing/closed-loop-experience-design/, observed 2026-09-01.
- Figma MCP server docs, developers.figma.com/docs/figma-mcp-server/, observed 2026-09-01.
- Paper MCP docs, paper.design/docs/mcp, observed 2026-09-01.
- Omarchy-UX, README.md, local repository, observed 2026-09-01, for the usability, accessibility, and trust-and-handoff evaluation lenses.
- Star, S. L. and Griesemer, J. R., "Institutional Ecology, 'Translations' and Boundary Objects," 1989.
- Clark, H. H. and Brennan, S. E., "Grounding in Communication," 1991.
- Maudet, N. et al., on design breakdowns and unstated edge cases, 2017.
