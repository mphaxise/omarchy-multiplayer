# Marketplace submission draft: omacom/omarchy-plugin-marketplace

Status: draft, 2026-09-02. Nothing below has been created. The format is the marketplace's own, from `SUBMISSION.md` in `omacom/omarchy-plugin-marketplace` (observed 2026-09-02): the title starts with `[Plugin]:`, the body keeps six headings in this order, the category is one of their nine spelled exactly, the tags are one to three of their thirteen, and all five checklist statements are checked only when they are true. Their guide asks the plugin owner to confirm every checklist statement and to approve the completed text before an agent creates the issue.

Before this can be submitted, in order: the listing repository exists and is public with `manifest.json` at its root (`outbound/build-listing.sh` assembles it); the plugin id is final (`@PLUGIN_ID@` below is filled in by the build; ids are permanent marketplace identifiers); Praneet confirms the five statements; Praneet says post.

## Title

```
[Plugin]: Keepalive
```

## Body

```markdown
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
```

## The five statements, for Praneet to confirm

1. Public repository with install and removal instructions: true once the listing repo is pushed; the README has both sections.
2. License and external dependencies documented: MIT in `LICENSE`; the README's last section names Herdr, the Omarchy shell, Python 3, grim, hyprctl, and states that nothing is downloaded.
3. Ownership of the plugin and the preview: the code is yours (MIT, your authorship); the preview is a capture of your rig showing the default Omarchy wallpaper and bar. If the wallpaper's license worries you, I can swap in a capture over a solid background.
4. No overwriting of user configuration without consent: `install.sh` refuses to replace any file it did not create, writes only symlinks in `~/.local/bin/` and two unit files, and prints the keybinding lines instead of editing `bindings.lua`.
5. Listing is not a security review: acknowledged.

## The command, when approved

```bash
gh issue create \
  --repo omacom/omarchy-plugin-marketplace \
  --title "[Plugin]: Keepalive" \
  --body-file outbound/submission-issue-body.md
```

`outbound/build-listing.sh` writes `submission-issue-body.md` with the id filled in. After the issue opens, their bot posts a validation comment and an Automated Security Baseline comment; a maintainer applies `approved-and-verified` to publish. Their baseline looks for download-to-shell execution, unpinned external Git source execution, passwordless sudoers, and privileged process control from shared temporary state; none of these appear in this plugin.
