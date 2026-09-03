### Repository URL

https://github.com/mphaxise/omarchy-keepalive

### Category

Developer Tools

### Tags

ai, bar, quickshell

### Suggest a missing tag

_No response_

### Maintainer notes

Keepalive keeps coding agents running on the desktop as named sessions on top of Herdr. It adds a bar widget and panel, notifications, receipts, and permission modes. `omarchy plugin add` installs the widget. The repo's `install.sh` links the commands into `~/.local/bin/` and installs two user units: one keeps the Herdr server running, one sends notifications. `uninstall.sh` removes exactly those. Nothing runs as root. Nothing is downloaded at install or run time. The plugin changes no Omarchy configuration. Tested on Omarchy Quattro `0b3f1b7` on the community aarch64 port with Claude Code. Other agents are untested live. Tests: `python3 -m unittest discover -s tests`.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
