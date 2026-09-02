# What forty years of CSCW says about multiplayer agent work

Status: findings, literature, 2026-09-01.

## Bottom line

Five findings bind this design, and each forces one decision. Awareness research says people track collaborators through a small set of cues, so that vocabulary has to be built into the sessions panel's row. Interruption research says a notification's cost is paid on arrival, so notifications time themselves to severity and to the task boundary they would interrupt. Calibrated-trust research says people misjudge automation whose limits they cannot see, so the panel shows its own confidence in a status reading alongside the reading. Boundary-object research says a shared artifact stays itself while meaning something different to each viewer, the job I am handing to the session record and the receipt. Social-technical-gap research says that gap never fully closes, so a manual override sits beside every automated path here, on purpose.

## Awareness

- Dourish & Bellotti (1992), Awareness and coordination in shared workspaces, CSCW'92, https://dl.acm.org/doi/10.1145/143457.143468
- Gutwin & Greenberg (2002), A descriptive framework of workspace awareness, Computer Supported Cooperative Work 11(3-4), https://link.springer.com/article/10.1023/A:1021271517844
- Stefik et al. (1987), WYSIWIS revised, ACM Transactions on Office Information Systems 5(2), https://dl.acm.org/doi/10.1145/27636.28056

Dourish and Bellotti showed awareness works passively, through the shared workspace, and does not depend on questions asked of people. Gutwin and Greenberg reduced it to five elements: who, what, where, when, next. Stefik and colleagues showed a shared view need not be an identical one.

**What this changes in the spec.** `03-sessions-panel.md` builds its row on Gutwin and Greenberg's five elements. The bar badge and its color are passive awareness, visible with the panel closed. Relaxed WYSIWIS licenses the same session looking different in the panel, in Herdr, and in raw `events.jsonl`.

## Articulation work and coordination mechanisms

- Schmidt & Bannon (1992), Taking CSCW seriously, Computer Supported Cooperative Work 1(1-2), https://link.springer.com/article/10.1007/BF00752449
- Schmidt & Simone (1996), Coordination mechanisms, Computer Supported Cooperative Work 5(2-3), https://link.springer.com/article/10.1007/BF00133655

Schmidt and Bannon named the invisible work of meshing separate contributions into one effort: articulation work. Schmidt and Simone argued it needs its own inspectable artifacts, coordination mechanisms, and cannot rest on tacit convention.

**What this changes in the spec.** `events.jsonl` in `01-session-model.md` is articulation work turned into data: every queue, delivery, and approval is a typed event. The schema is the coordination mechanism, fixed and readable by the panel and the receipt renderer alike.

## Common ground

- Clark & Brennan (1991), Grounding in communication, in Perspectives on Socially Shared Cognition, https://web.stanford.edu/~clark/1990s/Clark,%20H.H.%20_%20Brennan,%20S.E.%20_Grounding%20in%20communication_%201991.pdf
- Olson & Olson (2000), Distance matters, Human-Computer Interaction 15(2-3), https://dl.acm.org/doi/10.1207/S15327051HCI1523_4

Clark and Brennan showed grounding, the accumulation of evidence that two parties understand each other, is work. Olson and Olson showed distance makes that work harder, the normal condition between a person and an agent, or between two agents.

**What this changes in the spec.** `01-session-model.md` requires a named author on every instruction and marks inter-agent instructions with a marker line, fixed in `02-command-surface.md`, naming the origin session. That marker is a grounding device: it tells the receiving model whose evidence this is.

## Why groupware fails

- Grudin (1988), Why CSCW applications fail, CSCW'88, https://dl.acm.org/doi/10.1145/62266.62273
- Grudin (1994), Groupware and social dynamics, Communications of the ACM 37(1), https://dl.acm.org/doi/10.1145/175222.175230
- Ackerman (2000), The intellectual challenge of CSCW, Human-Computer Interaction 15(2-3), https://dl.acm.org/doi/10.1207/S15327051HCI1523_5

Grudin found groupware fails when the person doing the work is not the one who benefits, and again when a tool cannot handle its own exceptions. Ackerman named the deeper problem: a social-technical gap between what a situation needs and what a system can verify, one no engineering effort closes outright.

**What this changes in the spec.** The reconciler in `01-session-model.md` adopts an orphaned Herdr pane into a session automatically, so the beneficiary never does extra work to get a record. Invariant 5 and the `session open` re-bind path are the manual override the gap demands.

## Plans, situated action, mixed initiative

- Suchman (1987), Plans and Situated Actions, Cambridge University Press, https://dl.acm.org/doi/10.5555/38407
- Horvitz (1999), Principles of mixed-initiative user interfaces, CHI'99, http://erichorvitz.com/uiact.htm
- Shneiderman & Maes (1997), Direct manipulation vs. interface agents, ACM Interactions 4(6), https://www.cs.umd.edu/~ben/papers/Shn-Maes-v4n6-1997.pdf

Suchman argued a plan is a resource consulted while improvising. Horvitz weighed the cost of an automated system guessing wrong against the cost of interrupting to ask. Shneiderman and Maes staged direct manipulation against agents as a choice; I read their debate as a coexistence requirement.

**What this changes in the spec.** `goal` in `01-session-model.md` is a resource the agent interprets, kept separate from the situated `queue` of instructions. `delivery: steer` injects at a tool boundary, Horvitz's low-cost moment to interject; every panel row keeps Send and Stop live regardless of the agent's own initiative.

## Interruption and attention

- Iqbal & Horvitz (2007), Disruption and recovery of computing tasks, CHI'07, https://www.microsoft.com/en-us/research/wp-content/uploads/2016/11/CHI_2007_Iqbal_Horvitz-1.pdf
- Mark et al. (2005), No task left behind?, CHI'05, https://dl.acm.org/doi/10.1145/1054972.1055017
- McFarlane & Latorella (2002), The scope and importance of human interruption, Human-Computer Interaction 17(1), https://dl.acm.org/doi/10.1207/S15327051HCI1701_1

Iqbal and Horvitz measured what an interruption costs in resumption time, beyond the time lost mid-task. Mark and colleagues found work is already fragmented before any tool adds to it. McFarlane and Latorella catalogued delivery methods, immediate, negotiated, mediated, scheduled, as a design choice.

**What this changes in the spec.** `06-notifications.md` reads `status.changed` events, per `01-session-model.md`; this literature is why it cannot fire on every one. `blocked` warrants immediate delivery; `waiting` can negotiate and coalesce against whatever the person is mid-task on.

## Trust in automation

- Bainbridge (1983), Ironies of automation, Automatica 19(6), https://www.sciencedirect.com/science/article/abs/pii/0005109883900468
- Parasuraman, Sheridan & Wickens (2000), A model for types and levels of human interaction with automation, IEEE Transactions on Systems, Man, and Cybernetics Part A 30(3), https://ieeexplore.ieee.org/document/844354
- Lee & See (2004), Trust in automation, Human Factors 46(1), https://journals.sagepub.com/doi/10.1518/hfes.46.1.50_30392

Bainbridge showed the more competent automation gets, the less practiced a person stays for the moment it fails. Parasuraman, Sheridan, and Wickens split automation into stages, acquiring information, analyzing it, deciding, acting, each needing its own oversight. Lee and See made trust a calibration problem.

**What this changes in the spec.** `status.source` in `01-session-model.md` records a Herdr lifecycle hook versus a heuristic reading, Parasuraman's acquisition stage made visible. `03-sessions-panel.md` marks the heuristic case with an outlined dot and a tooltip: Lee and See's calibration.

## Human-AI teaming

- Amershi et al. (2019), Guidelines for human-AI interaction, CHI'19, https://www.microsoft.com/en-us/research/wp-content/uploads/2019/01/Guidelines-for-Human-AI-Interaction-camera-ready.pdf
- Seeber et al. (2020), Machines as teammates, Information & Management 57(2), https://www.inf.uni-hamburg.de/inst/ab/wists/publications/_docs/seeber-et-al-2020-im-machines-as-teammates.pdf
- Bansal et al. (2019), Beyond accuracy, HCOMP 2019, https://ojs.aaai.org/index.php/HCOMP/article/view/5285
- Wang et al. (2019), Human-AI collaboration in data science, PACM on Human-Computer Interaction 3(CSCW), https://arxiv.org/abs/1909.02309

Amershi and colleagues turned scattered findings into 18 checkable guidelines, led by making capability and limits clear. Seeber and colleagues argued a machine teammate needs a human teammate's coordination structure. Bansal and colleagues tied team performance to the human's model of where the AI errs. Wang and colleagues found data scientists wanted control kept stage by stage.

**What this changes in the spec.** The agent's own actor identity in `01-session-model.md`, `agent:<session-id>`, a shape `08-identity.md` extends with verified identities in slice 2, is Seeber's teammate structure. Bansal's error-boundary finding is `status.source` again. Wang's stage-by-stage control is why `04-permission-modes.md` grants approval per operation in shared mode.

## AI pair programming and agentic coding

- Vaithilingam, Zhang & Glassman (2022), Expectation vs. experience, CHI EA'22, https://dl.acm.org/doi/10.1145/3491101.3519665
- Barke, James & Polikarpova (2023), Grounded Copilot, OOPSLA 2023, https://cseweb.ucsd.edu/~npolikarpova/publications/oopsla23-copilot.pdf
- Mozannar et al. (2024), Reading between the lines, CHI'24, https://dl.acm.org/doi/10.1145/3613904.3641936
- Chen et al. (2026), Code with me or for me?, CHI'26, https://arxiv.org/abs/2507.08149

Vaithilingam and colleagues found people preferred Copilot without a measurable speed gain. Barke and colleagues split usage into accelerating a known plan or exploring an unknown one. Mozannar and colleagues taxonomized programmer activity around a suggestion and priced each in time. Chen and colleagues found an agent finishes more than a copilot, and the job becomes review.

**What this changes in the spec.** Chen's finding is why `05-receipts-and-artifacts.md` centers on commits, diff stat, and a fixed-order rendering, exactly what review needs. Barke's two modes argue for tighter default approval in `04-permission-modes.md` for a session that opens exploring, looser for one that opens already knowing its plan. Mozannar's cost taxonomy is a candidate metric for `10-evaluation-plan.md` beyond task completion.

## Designer-developer collaboration

- Star & Griesemer (1989), Institutional ecology, translations and boundary objects, Social Studies of Science 19(3), https://journals.sagepub.com/doi/10.1177/030631289019003001
- Maudet et al. (2017), Design breakdowns, CSCW 2017, https://dl.acm.org/doi/10.1145/2998181.2998190
- Zhang et al. (2025), Who is to blame, PACM on Human-Computer Interaction (CSCW), https://arxiv.org/abs/2501.11748

Star and Griesemer defined a boundary object: robust enough to keep one identity, plastic enough to mean something different to each group using it. Maudet and colleagues found designers and developers break down over exactly the details a boundary object should carry: unstated edge cases, dropped constraints. Zhang and colleagues reviewed forty-five papers since 2004 and found the same friction, unresolved by better handoff tools alone.

**What this changes in the spec.** The session record, the receipt, and the running preview `09-closed-loop-surfaces.md` exposes are the boundary object this design bets on: one object read as a panel row, a plain-text receipt, a live preview, or raw JSON, depending on who is looking. `goal` is required and kept verbatim in the receipt to close Maudet's unstated-edge-case gap.

## Real-time collaborative editing

- Ellis & Gibbs (1989), Concurrency control in groupware systems, ACM SIGMOD Record 18(2), https://dl.acm.org/doi/10.1145/66926.66963
- Olson et al. (1992), How a group editor changes the character of a design meeting, CSCW'92, https://dl.acm.org/doi/10.1145/143457.143466
- Wallace / Figma (2019), How Figma's multiplayer technology works, Figma Blog, https://www.figma.com/blog/how-figmas-multiplayer-technology-works/

Ellis and Gibbs showed shared state needs explicit concurrency control once two people can touch it at once. Olson and colleagues found a group editor changes what a meeting produces, beyond how it gets recorded. Wallace described Figma's bet: skip general operational transforms, make each property its own small unit of conflict.

**What this changes in the spec.** Invariant 6 in `01-session-model.md`, the rule `07-worktrees.md` enforces so two sessions never share a worktree unless both records agree, is concurrency control for the one resource agents could collide on. Olson's finding that the tool changes the outcome is why `10-evaluation-plan.md` should measure behavior change, beyond adoption alone.

## Accountability and attribution

- Nissenbaum (1996), Accountability in a computerized society, Science and Engineering Ethics 2(1), https://link.springer.com/article/10.1007/BF02639315
- Viégas, Wattenberg & Dave (2004), Studying cooperation and conflict with history flow visualizations, CHI 2004, https://research.ibm.com/publications/studying-cooperation-and-conflict-between-authors-with-history-flow-visualizations

Nissenbaum named the problem of many hands: a computerized outcome with many contributors ends up with no one accountable for it. Viégas and colleagues showed a simple visualization of who changed what, and when, makes authorship and conflict legible again.

**What this changes in the spec.** `created_by` in `01-session-model.md` is immutable, and every event carries a named actor, invariants 2 and 4, a direct answer to many hands. The receipt's instruction count, distinct authors, and per-commit author list in `05-receipts-and-artifacts.md` are this design's history flow, sized to one session.

## Activity-centric computing

- Moran & Anderson (1990), The workaday world as a paradigm for CSCW design, CSCW'90, https://dl.acm.org/doi/abs/10.1145/99332.99369
- Bardram (2005), Activity-based computing, Personal and Ubiquitous Computing 9(5), https://link.springer.com/article/10.1007/s00779-004-0335-2

Moran and Anderson argued CSCW should design for the actual, messy flow of work. Bardram made the activity itself the durable unit, persisting and moving across devices independent of any one session at a desk.

**What this changes in the spec.** The session in `01-session-model.md` is scoped to one unit of agent work, and to no terminal or machine: Moran and Anderson's paradigm by definition. Surviving terminal close and reboot, then restoring the live transcript on reattach, PLAN.md's second success signal, is Bardram's activity persisting.

## Design principles for this experiment

1. Show state peripherally, before the panel opens; awareness works passively (Dourish & Bellotti 1992).
2. Build every status view from who, what, where, when, and next (Gutwin & Greenberg 2002).
3. Let the same session look different on different surfaces; a shared view is not an identical one (Stefik et al. 1987).
4. Log coordination as typed, inspectable events, so articulation work stays visible (Schmidt & Bannon 1992; Schmidt & Simone 1996).
5. Time a notification to the task it would interrupt (Iqbal & Horvitz 2007; McFarlane & Latorella 2002).
6. Mark every automated reading with its own confidence; trust has to be calibrated (Bainbridge 1983; Lee & See 2004).
7. Keep a manual path beside every automated one; the social-technical gap never fully closes (Ackerman 2000; Grudin 1988).
8. Name every actor and never erase history; many hands need a record or no one answers for the work (Nissenbaum 1996; Viégas et al. 2004).

## Where the literature is silent

Three parts of this design have no literature behind them. Every study above treats a person, or a group of people, as the participant; none treats an agent's own session record as a durable identity with standing of its own. Articulation work between two automated parties, the marked instruction one agent's session sends into another's queue, has no CSCW precedent to draw on. And a boundary object has always sat between groups of people; here it also has to hold between a person and a record of a process no one watched in real time. The experiment should show whether a durable agent identity changes delegation behavior, whether the marker line reads as data, and whether two readers of one receipt converge on the same account of events.

## Not verified this pass

- Brown et al. (2008), on designer-developer collaboration. No bibliographic record could be opened with a confident author and title match, so it is left out.

## Sources

- Dourish & Bellotti 1992: https://dl.acm.org/doi/10.1145/143457.143468
- Gutwin & Greenberg 2002: https://link.springer.com/article/10.1023/A:1021271517844
- Stefik et al. 1987: https://dl.acm.org/doi/10.1145/27636.28056
- Schmidt & Bannon 1992: https://link.springer.com/article/10.1007/BF00752449
- Schmidt & Simone 1996: https://link.springer.com/article/10.1007/BF00133655
- Clark & Brennan 1991: https://web.stanford.edu/~clark/1990s/Clark,%20H.H.%20_%20Brennan,%20S.E.%20_Grounding%20in%20communication_%201991.pdf
- Olson & Olson 2000: https://dl.acm.org/doi/10.1207/S15327051HCI1523_4
- Grudin 1988: https://dl.acm.org/doi/10.1145/62266.62273
- Grudin 1994: https://dl.acm.org/doi/10.1145/175222.175230
- Ackerman 2000: https://dl.acm.org/doi/10.1207/S15327051HCI1523_5
- Suchman 1987: https://dl.acm.org/doi/10.5555/38407
- Horvitz 1999: http://erichorvitz.com/uiact.htm
- Shneiderman & Maes 1997: https://www.cs.umd.edu/~ben/papers/Shn-Maes-v4n6-1997.pdf
- Iqbal & Horvitz 2007: https://www.microsoft.com/en-us/research/wp-content/uploads/2016/11/CHI_2007_Iqbal_Horvitz-1.pdf
- Mark et al. 2005: https://dl.acm.org/doi/10.1145/1054972.1055017
- McFarlane & Latorella 2002: https://dl.acm.org/doi/10.1207/S15327051HCI1701_1
- Bainbridge 1983: https://www.sciencedirect.com/science/article/abs/pii/0005109883900468
- Parasuraman, Sheridan & Wickens 2000: https://ieeexplore.ieee.org/document/844354
- Lee & See 2004: https://journals.sagepub.com/doi/10.1518/hfes.46.1.50_30392
- Amershi et al. 2019: https://www.microsoft.com/en-us/research/wp-content/uploads/2019/01/Guidelines-for-Human-AI-Interaction-camera-ready.pdf
- Seeber et al. 2020: https://www.inf.uni-hamburg.de/inst/ab/wists/publications/_docs/seeber-et-al-2020-im-machines-as-teammates.pdf
- Bansal et al. 2019: https://ojs.aaai.org/index.php/HCOMP/article/view/5285
- Wang et al. 2019: https://arxiv.org/abs/1909.02309
- Vaithilingam, Zhang & Glassman 2022: https://dl.acm.org/doi/10.1145/3491101.3519665
- Barke, James & Polikarpova 2023: https://cseweb.ucsd.edu/~npolikarpova/publications/oopsla23-copilot.pdf
- Mozannar et al. 2024: https://dl.acm.org/doi/10.1145/3613904.3641936
- Chen et al. 2026: https://arxiv.org/abs/2507.08149
- Star & Griesemer 1989: https://journals.sagepub.com/doi/10.1177/030631289019003001
- Maudet et al. 2017: https://dl.acm.org/doi/10.1145/2998181.2998190
- Zhang et al. 2025: https://arxiv.org/abs/2501.11748
- Ellis & Gibbs 1989: https://dl.acm.org/doi/10.1145/66926.66963
- Olson et al. 1992: https://dl.acm.org/doi/10.1145/143457.143466
- Wallace / Figma 2019: https://www.figma.com/blog/how-figmas-multiplayer-technology-works/
- Nissenbaum 1996: https://link.springer.com/article/10.1007/BF02639315
- Viégas, Wattenberg & Dave 2004: https://research.ibm.com/publications/studying-cooperation-and-conflict-between-authors-with-history-flow-visualizations
- Moran & Anderson 1990: https://dl.acm.org/doi/abs/10.1145/99332.99369
- Bardram 2005: https://link.springer.com/article/10.1007/s00779-004-0335-2
