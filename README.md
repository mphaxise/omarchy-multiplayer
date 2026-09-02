# Omarchy Multiplayer

An experiment on top of [Omarchy](https://omarchy.org): make an agent session a durable, named object that terminals attach to, and give the shell a view of those sessions with their state, owner, and outputs. Omarchy 4.0.2 launches a coding agent as a terminal process from a keybinding. OpenClaw 2.0 treats an agent run as a shared session with a creator, an owner, participants, and receipts. This repository ports the parts of that model that fit Omarchy's shape, as a user shell plugin plus scripts, and measures whether they help.

## The question

One hypothesis, tested on a running system: a durable session object plus a shell panel listing sessions makes concurrent agent work legible and controllable for one user. [`PLAN.md`](PLAN.md) states the five success signals, the phases, and the gates.

## Current slice

Slice 1 covers one user, many agents, one machine. Sessions are created, listed, attached, sent instructions, and stopped; each has a workspace, a permission mode, a status, a parent when spawned, and a receipt when it ends. Two human identities, presence, remote placement, and federation are later slices.

## Status

Phase 0, scaffold. Next: the verified OpenClaw pattern catalog in `patterns/` and the hands-on baseline of Omarchy's current multi-agent experience in `captures/`.

## Relationship to Omarchy-UX

[Omarchy-UX](https://github.com/mphaxise/omarchy-ux) evaluates Omarchy's shipped agent surfaces and contributes fixes upstream. This repository builds a new surface and evaluates it with the same protocol and capture discipline. The test rig is documented there.

## Evidence discipline

Every capture carries provenance, Omarchy version, date, and environment; every proposed screen or command is labeled `proposed` until it runs on the rig, then `live`. Every OpenClaw claim in `patterns/` names its source page and the date it was read. Rules in [`captures/README.md`](captures/README.md).

## Author

Praneet Koppula, product design leader working on AI-native experiences for complex, expert workflows. Built with Claude as dev partner. Related work: [ai-agent-ux-research-platform](https://github.com/mphaxise/ai-agent-ux-research-platform), [design-skill-pack-for-ai-agent-coding-platforms](https://github.com/mphaxise/design-skill-pack-for-ai-agent-coding-platforms).
