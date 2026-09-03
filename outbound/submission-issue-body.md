### Repository URL

https://github.com/mphaxise/omarchy-agent-sessions

### Category

Developer Tools

### Tags

ai, bar, quickshell

### Suggest a missing tag

_No response_

### Maintainer notes

Durable, named coding-agent sessions on top of Herdr, with a bar widget and panel, notifications, receipts, and permission modes. `omarchy plugin add` installs the widget; the repository's `install.sh` then links the commands into `~/.local/bin/` and installs two user units (a Herdr server keepalive and the notifier), and `uninstall.sh` removes exactly those. Nothing runs as root, nothing is downloaded at install or run time, and the plugin changes no Omarchy configuration. Tested on Omarchy Quattro `0b3f1b7` on the community aarch64 port with Claude Code; other agents are untested live. Tests: `python3 -m unittest discover -s tests`.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
