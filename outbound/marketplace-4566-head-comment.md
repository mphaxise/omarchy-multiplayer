# Comment for omacom/omarchy-plugin-marketplace#4566: the review should land on HEAD

Status: drafted 2026-09-03; the tool gate refused to post it, so it waits for Praneet to paste it (or to file the "Verify or update a listed plugin" form once the plugin is listed). The SHA below is 0.3.1's listing commit; if 0.3.1 is not pushed, use 0.3.0's, `aa0c888`, and say 0.3.0.

---

The repository has moved on since validation ran at `b96ecbc`. HEAD is now `3dc29359dfc877098fcae4726fed84fc7e35ac71`: Keepalive 0.3.1, which adds lanes (a second agent in one session, on its own worktree, merged back with `done --lane`), pause and resume, history, watchers, and a README that describes them.

Nothing changed in what the plugin writes or needs: the same two user units, the same `install.sh`, no root, no downloads.

If the review lands on the current HEAD, that is the commit to snapshot. If it lands on `b96ecbc`, I will file the newer-commit form once the listing exists.
