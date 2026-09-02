---
pattern: Explicit visibility and drafts
source: https://docs.openclaw.ai/concepts/multi-user.md, https://docs.openclaw.ai/concepts/session.md
observed: 2026-09-01
openclaw_version: 2026.8.1
omarchy_surface: none yet
slice: 2
---

# Explicit visibility and drafts

## What OpenClaw does

Starting a session as a draft keeps it out of teammates' sidebars until it is published. Admins are the one exception and see other people's drafts with a faded ghost marker. The docs class this as a coordination feature with no security guarantee, the same framing used for ownership. Visibility is rechecked live: catalog listings and progress updates recheck who can currently see a session, and a cached result does not preserve access to something that has since become a draft or gone incognito. A separate and stricter mechanism, incognito sessions, keeps a thread's transcript and state in process memory only, skips the automatic memory flush, never creates a transcript archive, and is visible only to admin-scope connections; it disappears entirely on a Gateway restart. Drafts hide work that looks finished from peers. Incognito hides the existence of the work from storage and from everyone but admins. They solve different problems and the docs keep them separate.

## What Omarchy has today

Nothing. The session record in `spec/01-session-model.md` has no visibility field at all, because slice 1 has exactly one human, so every session that exists is visible to the only person who could see it. There is also no notion of publishing a session; a session is visible from `starting` onward.

## What porting it means

This pattern only matters once a second viewer exists, so its smallest version is a `visibility` field next to the existing `labels` field, for example `draft` or `shared`, defaulting to `shared` so slice 1 stays unchanged. A `session.visibility_changed` event fits the same log already used for `session.renamed` and `owner.assigned`. The panel filters `draft` sessions out of anyone's view except the creator, treating the single OS user as the admin exception until slice 2 defines what an Omarchy admin actually is. Incognito is out of scope here: it is a stronger, storage-level guarantee that touches durability invariant 7, no command in slice 1 deletes history, so it deserves its own decision instead of riding in with drafts.

## Open questions

- Who counts as the admin equivalent on a single-user Linux desktop once a second human is involved?
- Should `visibility` live on the session or on a per-viewer grant, given slice 2's actor space is still open?
- Does the panel need a ghost marker, or is a simple filter enough for a first cut?

## Sources

- Multi-user mode, https://docs.openclaw.ai/concepts/multi-user.md, observed 2026-09-01
- Session management, https://docs.openclaw.ai/concepts/session.md, observed 2026-09-01
