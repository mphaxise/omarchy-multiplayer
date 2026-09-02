# Capture Labeling Rules

Every artifact in this directory carries these labels in its filename or front matter:

1. **Provenance**, one of:
   - `doc-derived`: claim comes from Omarchy or OpenClaw documentation, release notes, or source.
   - `video-derived`: claim comes from recorded demos or third-party video.
   - `hands-on`: captured from a running system I operated. Record the environment (hardware, VM, emulation).
2. **Version**: the Omarchy version evaluated (e.g. `4.0.2`), and the OpenClaw version when one is involved (e.g. `2026.8.1`).
3. **Date**: capture date, ISO format.
4. **State**, for anything this project introduces:
   - `proposed`: a screen, command, or behavior that does not yet run on the rig. Mockups and spec drawings carry this label.
   - `live`: the same thing captured from the rig after it runs there.

Example: `sessions-panel_hands-on_4.0.2_2026-09-10_live.png`

Findings cite captures; captures never assert conclusions. Performance observations under emulation are recorded and excluded from performance findings. Findings from the ARM rig carry the unofficial-port caveat; installer and first-boot claims wait for the x86-64 rig.

Session notes go in `sessions/`, screenshots and recordings in `screenshots/`.
