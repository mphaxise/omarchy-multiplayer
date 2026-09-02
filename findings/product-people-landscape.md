# Where AI-native product people work today, and what a desktop could own

Status: findings, doc-derived, 2026-09-01.

## Bottom line

The product people I am building for already work inside a closed loop. They do not have a desktop that treats that loop as a first-class object. Designers and developers converge on the same task today, editing the same running app. What nobody owns yet is the record of that loop: which agent did what, on whose approval, in which running preview, with what evidence left behind.

## Convergence evidence

Anthropic's analysis of about 400,000 Claude Code sessions from about 235,000 people between October 2025 and April 2026 finds a clear division of labor: people make about 70% of planning decisions and about 20% of execution decisions, so the agent makes about 80% of the execution decisions. Domain expertise, and not coding proficiency, predicts success; every major occupation succeeds at nearly the rate of software engineers, and Arts, Design, and Media is among the largest occupation groups using the tool. Over those seven months the share of sessions spent fixing broken code fell from 33% to 19%, writing and data analysis roughly doubled, and the estimated value of the typical task rose about 27% (Anthropic, "Agentic coding and persistent returns to expertise", 2026-06-16).

OpenAI confirms the shift from the build side. A team that grew from three to seven people shipped on the order of one million lines of code and roughly 1,500 pull requests in five months with no hand-written code; the engineers' job became designing the environment and the feedback loops (OpenAI, "Harness engineering", 2026-02-11).

Stack Overflow's April 2026 pulse survey of 1,100 developers found agent use rising from 31% to 59% year over year, while 63% still rarely or never let an agent run fully on its own and 60% block unapproved system changes (Stack Overflow, "Agents on a leash", 2026-05-27). Figures widely reported as the "2026 developer survey" (84% AI use, 29% trust) belong to the 2025 survey; the 2026 survey opened 2026-06-23 and had no published results when I checked.

Figma's 2026 AI report is cited in search summaries as reporting designers participating in development at 41% and developers doing design at 60%. The report page did not render for my tools, so those figures stay out of this document until I read them on the page.

## Tools

| Tool | Loop it closes | Where it stops | Source |
|---|---|---|---|
| Figma MCP server | Pulls design context into an agent; writes agent output back onto the canvas (beta) | Stops at the file; blind to the deployed app | developers.figma.com/docs/figma-mcp-server |
| Figma Make | Prompt to a working prototype styled from the team's library | Ships a prototype, not the production codebase | help.figma.com (Figma Make FAQs) |
| Figma Agent on Canvas | Intent to canvas edits on the shared multiplayer surface (May 2026) | Stops at the file | techcrunch.com, 2026-05-20 |
| Claude Code | Plan, edit, test, open a PR in one session; subagents and worktrees parallelize; Agent Teams coordinate | No second human joins a session | code.claude.com/docs |
| Codex with Chrome DevTools MCP | Drives the running app, screenshots and records its own fix | Bespoke to one company's harness | openai.com/index/harness-engineering |
| Cursor cloud agents | Runs, tests, opens a PR from an isolated VM | Teammates watch until an admin enables follow-ups | cursor.com/docs/cloud-agent |
| Zed threads and Delta | Threads with worktrees; Delta adds a replicated shared space with roles (beta) | One project at a time; code-editor screen | zed.dev; delta.dev |
| Google Stitch | Prompt or wireframe to multi-screen UI and code with a portable DESIGN.md | Stops at generated front-end code | stitch.withgoogle.com |
| Paper | Code-native canvas exposed to any agent over MCP | Stops before a deployed app or usage evidence | paper.design/docs/mcp |
| Amp orbs and Multiplayer | Any invited teammate prompts, reads the terminal, uses the running preview | Time-boxed; one thread at a time | ampcode.com/docs/orbs/multiplayer |
| v0, Lovable, Bolt | Prompt to a deployed app with versions | No shared session; no path back to a design file | v0.app/docs; lovable.dev; bolt.new |

## Collaboration surfaces

Two products let a designer and a developer sit inside the same agent session now. Amp's Multiplayer puts every invited workspace member in one thread with the terminal, file changes, and the live preview portal; nothing distinguishes a design role from an engineering role. Zed's Delta shows named participants with owner or can-edit roles and keeps comments anchored to the line or turn that produced them. Cursor's cloud agents let a viewer watch a run; writing back needs an admin-granted permission. Warp's session sharing shows prompts, tool calls, and terminal output live to viewers who install nothing, with edit access as a separate grant. None of them separates a design vocabulary from a code vocabulary inside the shared session; the canvas and the running app stay two surfaces even when the people are in one place.

## What an agent-native desktop could own

A cross-tool session ledger. Nothing ties one design file, one agent transcript, and one running preview into a record a non-coder can open. Cursor's per-run URL and Delta's thread come closest; neither reaches the design file.

A durable approval ledger. OpenClaw's owner and participant split and Cursor's read versus follow-up split prove the mechanism; neither is generalized beyond its product, and none records "who approved this, when" as a first-class object.

An evidence store for before-and-after captures. OpenAI's harness wires Chrome DevTools into Codex so the agent proves its fix with a screenshot and a recording. That evidence lives inside one company's repository.

A shared surface a non-coder can drive. Figma Make and Stitch let someone without code produce an interface; the loop stops there. Amp's portal is code-adjacent. No desktop offers the equivalent outside a vendor's app.

Crash-to-agent extended past process crashes. Omarchy hands a coredump to an agent today. Nothing hands a failed usability path or a confused user to the same prompt.

A named reviewer on every turn, tied to role. Delta names the reviewer; nothing ties that identity back to whether the designer, the developer, or the proposing agent judged the change.

One permission model across design and code. Amp and Cursor solve the same problem two ways inside two products the same team opens in one afternoon.

A place to put the receipt. Codex cloud shows Creator, Sharing, and Created at as list columns. No desktop surfaces that receipt at the shell, beside the running app it describes.

## Where the closed-loop hypothesis is borne out, and where it is ahead of the evidence

The core claim, that a person expressing intent and an agent building the interface can share one running canvas, is shipped behavior: Amp's Multiplayer, Zed's Delta, and OpenAI's harness all show it, and Anthropic's decision-attribution data matches the essay's framing of the person supplying intent and the agent supplying execution. The design-system-as-action-vocabulary claim is literal in Figma's write-to-canvas tool and Paper's MCP server.

The hypothesis runs ahead of the evidence in two places. Every collaboration surface I found treats the second participant as another engineer with repository access; no source shows a designer without a code background driving one of these sessions end to end. And the essay's visible, durable approval history with a way to contest an outcome has no deployed counterpart: what exists is transcript visibility. Closed-loop experience design as a desktop-level object remains a proposal, which is what this experiment tests.

## Sources

- Anthropic, "Agentic coding and persistent returns to expertise", anthropic.com/research/claude-code-expertise, published 2026-06-16, observed 2026-09-01
- OpenAI, "Harness engineering", openai.com/index/harness-engineering, published 2026-02-11, observed 2026-09-01
- Stack Overflow, "Agents on a leash", stackoverflow.blog/2026/05/27, observed 2026-09-01; "Closing the developer AI trust gap", stackoverflow.blog/2026/02/18; "The 2026 Developer Survey is now open", stackoverflow.blog/2026/06/23
- Figma MCP server, developers.figma.com/docs/figma-mcp-server and /write-to-canvas, observed 2026-09-01
- Figma Make FAQs, help.figma.com, observed 2026-09-01
- TechCrunch, "Figma adds an AI assistant to its collaborative canvas", 2026-05-20, observed 2026-09-01
- Claude Code docs, code.claude.com/docs/en/overview and /agent-teams, observed 2026-09-01
- Cursor Cloud Agents, cursor.com/docs/cloud-agent and /cloud-agent/settings, observed 2026-09-01
- Zed, zed.dev; Delta, delta.dev, observed 2026-09-01
- Google Stitch, stitch.withgoogle.com/docs/design-md/overview, observed 2026-09-01
- Paper, paper.design/docs/mcp, observed 2026-09-01
- Amp, ampcode.com/news/multiplayer and ampcode.com/docs/orbs/multiplayer, observed 2026-09-01
- Warp, Agent Session Sharing, docs.warp.dev, observed 2026-09-01
- Codex cloud, learn.chatgpt.com/docs/cloud, observed 2026-09-01
- OpenClaw, docs.openclaw.ai/concepts/multi-user, observed 2026-09-01
- Omarchy manual, omarchy.org/manual/ai, observed 2026-09-01
- v0, v0.app/docs; Lovable, lovable.dev; Bolt, bolt.new, observed 2026-09-01
- Praneet Koppula, "Closed-Loop Experience Design", mphaxise.github.io/Praneet_Koppula/writing/closed-loop-experience-design, published July 2026, observed 2026-09-01
