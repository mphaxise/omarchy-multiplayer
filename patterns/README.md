# Pattern catalog

One file per OpenClaw 2.0 pattern that this experiment considers porting. Each entry cites the page it was read from and the date, paraphrases the pattern in my words, names the Omarchy surface it maps to, and assigns it to a slice. A pattern enters `spec/` only from here.

Front matter for every entry:

```yaml
---
pattern: <short name>
source: <docs URL>
observed: <YYYY-MM-DD>
openclaw_version: 2026.8.1
omarchy_surface: <launcher | shell plugin | notifications | hooks | systemd | worktrees | none yet>
slice: <1 | 2 | 3 | 4 | out of scope>
---
```

Body sections: **What OpenClaw does** (paraphrase, no quotes longer than a phrase), **What Omarchy has today** (with the file or command that shows it), **What porting it means** (the smallest Omarchy-shaped version), **Open questions**.

Entries planned from the first reading, 2026-09-01: session as the shared room; three-layer attribution (creator, owner, participants); explicit visibility and drafts; isolated agent identities; delegation with visible lineage; event-driven cross-agent state; structured parallelism; live human control (steer, queue, interrupt, approve); permissions bound to operations and workspaces; outputs as collaborative objects with receipts; interoperability as a boundary; the stated trust boundary.
