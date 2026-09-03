# Discord showcase post draft: Omacom, #omarchy-plugins-showcase

Target: a new post in the `omarchy-plugins-showcase` forum channel on the Omacom Discord (title, body, up to two images). Status: posted 2026-09-03 about 11:10 PDT by Praneet from his own account, with the lanes line and both images: https://discord.com/channels/1390012484194275541/1532218307065680004/threads/1545155631256703076. The text below is what went out.

What the channel rewards, read from the posts on 2026-09-03: the posts with hundreds of replies (Strata 431, Shibumi Shell 412, Omate 86, the calendar sync 84, Omagotchi 56) share a title of the form "Name - what it is", a one-sentence pitch as the first line, a screenshot or a screen recording as the first attachment, a short feature list, the one-line install command, the repo link, and a direct ask (testers, feedback, a star). Every post with no image sits near zero. Long posts do worse than tight ones. The original poster answers every reply within minutes on the threads that grew.

---

**Title:** Keepalive - coding agents that stay running on the Omarchy desktop

Close the terminal and the agent keeps working. Reboot, press Enter, and it picks up its own transcript.

**What it does**
- A bar icon that turns red when an agent needs you, and a panel you drive from the keyboard: Enter answers, `s` sends an instruction, `x` stops, `n` starts a new session
- Notifications: "api-refactor needs you", "api-refactor finished". Click one to open the terminal or the receipt
- A receipt when a session ends: branch, commits, diff, the files it made, your verdict
- Permission modes. Personal runs without asking, Shared asks first, Restricted is read-only. Only Personal can skip prompts
- Every session is a folder under `~/.local/state/omarchy/sessions/` with a log of everything that happened

Herdr keeps the agent alive. Keepalive keeps the record.

**Install**
```
omarchy plugin add https://github.com/mphaxise/omarchy-keepalive --enable
~/.config/omarchy/plugins/io.github.mphaxise.keepalive/install.sh
```
No root. Two user units and the commands linked into `~/.local/bin`. Repo: https://github.com/mphaxise/omarchy-keepalive. Marketplace: submitted, waiting on review.

I tested with Claude Code on Gabriel Galán's aarch64 UTM image. Nobody has run it on x86 yet. If you try it there, tell me what breaks. The specs and every test run, with screenshots, are at https://github.com/mphaxise/omarchy-multiplayer.

---

**Posted with this line** after "Herdr keeps the agent alive. Keepalive keeps the record.": 0.2.0 adds lanes: a second agent in the same session with its own task and its own worktree, merged back with `done --lane`.

**Images posted:** `outbound/listing/preview.png` (the panel with one session that needs an answer) and `captures/evaluation-run9-lanes_hands-on_arm-port_2026-09-03/panel-lanes-row.jpg`.
