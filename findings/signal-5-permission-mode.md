# Signal 5: nothing launches bypass-permissions mode unless Personal and chosen

Status: hands-on, `live`, run 1 on 2026-09-02, unofficial aarch64 port. Verdict: **pass**, with the picker-prompt half flagged.

## Method as run

The harness argv for every session was read from Herdr's pane process info, the exact process list of the pane (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/process-info-after-create.txt`, `timeline.txt` step 16), and compared with Omarchy's own launch flags in `/usr/share/omarchy/bin/omarchy-agent` (`captures/evaluation-run1_hands-on_arm-port_2026-09-02/omarchy-agent-flags.txt`: Claude launches as `claude --permission-mode auto`, Grok as `--permission-mode bypassPermissions`, Amp as `--dangerously-skip-permissions`, Crush as `--yolo`).

## Evidence

- Shared: `eval-shared` ran `claude --permission-mode default`, the harness's ask-first mode, and blocked on its first write.
- Personal: `eval-a`, `eval-b`, `crash-134897`, and `eval-personal` ran `claude --permission-mode auto`, the same flag stock Omarchy uses.
- `started_with.command` on each record carries the mode that was requested.

## Threshold

The Shared argv carries no bypass flag: met. The Personal argv carries one only when the mode prompt was shown and Personal was chosen that run: **flagged**. Personal was chosen on the command line (`--mode personal`), the agent picker never appeared, and `omarchy-default-agent` already held `claude`; the plan says a run where the prompt never appeared is flagged, not passed. The crash session also ran Personal by the wrapper's default with no prompt, which is the design question the review escalated.

## Next

One session created through `omarchy-agent --pick` at the keyboard, with the picker on screen, closes the flag.
