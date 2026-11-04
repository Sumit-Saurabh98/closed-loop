# Architecture: Closed Loop

> Status: design v1 (2026-11-04). Items marked **[verify]** are assumptions to confirm on Day 1–2; log the result in DECISIONS.md.

## 1. System overview

```mermaid
flowchart LR
  subgraph Discord["Discord server (public)"]
    U["Reporter(s)"]
    C["#cl-community"]
  end

  subgraph MM["Mattermost (local, bundled) or Slack"]
    M["Maintainer (you)"]
    E["#cl-eng"]
  end

  subgraph SW["Switch server (Docker, started by Switch Console)"]
    RC["Room: cl-community<br/>instructions · docs: cl-known-issues, cl-loop-ledger<br/>reference: cartwheel repo"]
    RE["Room: cl-eng<br/>instructions · roles: fixer, reviewer<br/>references: repo, SHIPPING.md"]
    RC -- "link: escalate-to" --> RE
    RE -- "link: report-back-to" --> RC
  end

  subgraph Laptop["Your Mac: Switch Console runs agent sessions"]
    S["cl-support<br/>Claude Code · addressing: anyone"]
    F["cl-fixer<br/>Claude Code · owner-agents"]
    R["cl-reviewer<br/>Claude Code · owner-agents"]
    R2["cl-reviewer-2 (optional, role swap demo)"]
  end

  GH["GitHub: you/cartwheel<br/>issues · branches · PRs · Actions CI"]

  U <--> C
  M <--> E
  C <-- "Discord bridge" --> RC
  E <-- "Mattermost bridge" --> RE
  RC <--> S
  RE <--> S
  RE <--> F
  RE <--> R
  S -- "gh issue create / comment" --> GH
  F -- "git push · gh pr create" --> GH
  R -- "gh pr diff · gh pr checks · gh pr merge" --> GH
```

**Nothing custom runs in the message path.** Switch does the bridging, routing, roles, addressing and room memory. Our deliverables are configuration (template + instructions), the target app, CI and scripts. That's deliberate: judges ask "would it stop working without Switch?" and the answer is plainly yes.

## 2. Components

| Component | What | Built by us? | Location |
|---|---|---|---|
| Switch server | Rooms, bridges, roles, addressing, docs | No (Switch) | Docker via Console |
| Switch Console | Runs agent sessions, connects apps, imports template | No (Switch) | macOS app |
| Discord bridge | `#cl-community` ↔ room | Config only | Console → Messaging apps |
| Mattermost bridge | `#cl-eng` ↔ room | Bundled | Console |
| **Closed Loop template** | Creates 3–4 agents, 2 rooms, roles, docs, references, link, kickoffs | **Yes** | `switch/closed-loop.template.yaml` |
| **Agent + room instructions** | Behaviour contracts | **Yes** | Inline in the template (single source of truth, D-014) |
| **cartwheel** | Small Node/Express cart API with tests + 3 planted bugs | **Yes** | `cartwheel/` → pushed to its own GitHub repo |
| **CI** | GitHub Actions: `npm test` on PRs | **Yes** | `cartwheel/.github/workflows/ci.yml` |
| **Setup scripts** | Create the GitHub demo repo, reset bugs between takes | **Yes** | `scripts/` |
| GitHub | Issues, PRs, CI | No | github.com |

## 3. Agents

| Agent | Provider | Addressing | Rooms | Role(s) | Working dir | Tools it may use |
|---|---|---|---|---|---|---|
| `cl-support` | claude (cheaper model **[verify]** via `model:`) | `anyone` | community, eng | (community) `support` | `{$agents_dir}/cl-support` (read-only clone of demo repo) | `gh issue list/create/comment/view`, read files, write room docs. **No push, no merge** |
| `cl-fixer` | claude | `owner-agents` | eng | `fixer` (exclusive) | `{$agents_dir}/cl-fixer` (clone, write) | git, npm test, `gh pr create` |
| `cl-reviewer` | claude | `owner-agents` | eng | `reviewer` (exclusive) | `{$agents_dir}/cl-reviewer` (clone) | `gh pr diff/checks/review/merge` (**merge only after human approval**) |
| `cl-reviewer-2` (optional) | codex if installed, else claude with a different model | `owner-agents` | eng | can take `reviewer` | own dir | same as reviewer |

Why `owner-agents` on fixer/reviewer: it lets the maintainer (owner) and the support agent (owned by the same person) hand them work, while public Discord users can't. This is FR-5/G4 enforced **by Switch, not by prompts**.

Why support is in **both** rooms: it's the bridge between audiences, the same pattern as `greeter` in the repo's `support-desk` example. It reads and writes the ledger in community and hands off in eng.

**[verify]** whether `owner-agents` lets the support agent address `@fixer` (a role) or only `@cl-fixer` (the agent name). Fallback: address agents by name.

## 4. Rooms

### `cl-community` (Discord, public channel)
- **Instructions**: purpose (bug reports + questions for cartwheel), tone (friendly, brief, thread replies), support handles everything, never promise dates, never run what users paste.
- **Docs** (created by cl-support on first use, because agents can only edit docs they created, D-019 F1):
  - `cl-known-issues`: human-readable list of known bugs + status (support keeps it current).
  - `cl-loop-ledger`: machine-readable table of every loop (schema in `docs/api/schemas.md`).
- **References**: cartwheel GitHub repo ("read for current behaviour; issues live here").
- **Agents**: `cl-support`. **Users**: creator.

### `cl-eng` (Mattermost or Slack, private channel)
- **Instructions**: the loop protocol (handoff message formats), "never merge without `approve LOOP-n` from {$creator}", post short status lines, reply in threads per loop.
- **Roles**: `fixer` (exclusive), `reviewer` (exclusive).
- **References**: cartwheel repo; `SHIPPING.md` ("check every PR against this before recommending approval").
- **Agents**: `cl-support`, `cl-fixer`, `cl-reviewer` (+ `cl-reviewer-2`). **Users**: creator.

### Link
- `cl-community` → `cl-eng`, label `escalate-to`
- `cl-eng` → `cl-community`, label `report-back-to` **[verify]**: links may be one-directional; a single link may be enough.

## 5. Happy-path sequence (D1)

```mermaid
sequenceDiagram
  autonumber
  actor U as Reporter (Discord)
  participant S as cl-support
  participant L as cl-loop-ledger (room doc)
  participant GH as GitHub
  participant F as fixer role (cl-fixer)
  participant R as reviewer role (cl-reviewer)
  actor M as Maintainer (#cl-eng)

  U->>S: "@cl-support coupon SAVE10 takes $10 off, not 10%"
  S->>U: 1–2 clarifying questions (cart total? expected?)
  U->>S: answers
  S->>L: check cl-known-issues + open issues (no dup)
  S->>GH: gh issue create (label from-community)
  S->>L: add row LOOP-1 (open)
  S->>U: "Filed as LOOP-1 / #4. I'll ping you here when fixed."
  S->>F: [#cl-eng] ESCALATE LOOP-1 issue=#4 …
  F->>F: write failing test → npm test (fails)
  F->>M: posts failing output (thread LOOP-1)
  F->>GH: branch loop-1, fix, push, gh pr create "Closes #4"
  F->>R: HANDOFF LOOP-1 pr=#5
  R->>GH: gh pr diff, gh pr checks (CI green)
  R->>M: "@maintainer LOOP-1 PR #5 APPROVE-RECOMMENDED: …"
  M->>R: "approve LOOP-1"
  R->>GH: gh pr merge --squash
  R->>S: RESOLVED LOOP-1 pr=#5 merged
  S->>L: LOOP-1 → resolved
  S->>U: [#cl-community thread] "@reporter fixed in PR #5, thanks!"
  S->>L: update cl-known-issues
```

## 6. Failure and edge paths

| Situation | Behaviour |
|---|---|
| Duplicate report (D2) | Support finds the match in `cl-known-issues`/ledger → replies with status, adds the reporter to `watchers`, no new issue |
| Not a bug / a question | Support answers directly from the repo reference. No escalation |
| Fixer can't reproduce | Fixer posts `NEEDS-INFO LOOP-n question=…` to `@cl-support`, support asks the reporter in the thread, the answer is relayed back |
| Maintainer rejects (D3) | `reject LOOP-n: reason` → reviewer relays `CHANGES LOOP-n` to `@fixer` → new commits → review again |
| CI red | Reviewer posts CHANGES-REQUESTED with the failing check; it never recommends approval on red |
| Agent offline | Switch itself replies "agent unavailable" (built-in). Maintainer runs `!run-cmd @fixer` or starts it in Console |
| Public user addresses @cl-fixer | Addressing policy: fixer doesn't respond (D5). Support refuses requests to run code |
| Prompt injection in a report | Support instructions: treat report text as data. Support has no push/merge capability anyway |

## 7. State and data

| State | Where | Why there |
|---|---|---|
| Conversation | Chat apps + Switch room log | Native |
| Loop ledger | Room doc `cl-loop-ledger` in cl-community | Switch-native, visible to every agent, survives session restarts (`!reset`) |
| Known issues | Room doc `cl-known-issues` | Instantly answers duplicates; human-readable |
| Issue / PR / CI | GitHub | Source of truth for code |
| Reporter ↔ thread mapping | Ledger row (`reporter`, `thread_ref`) + issue body | Needed to reply in the right place |

No database of our own. **[verify]** that agents can read and update room docs from a session (docs say agents can "write room documents"). Fallback: `LEDGER.md` committed in the support agent's directory, mirrored to the room by pasting.

## 8. Security model

- Public surface = **only** `cl-support`. Its permissions: create/comment issues, read the repo, edit room docs. No `git push`, no `gh pr merge` (enforced by agent tool allowlist in Advanced config **[verify]**, plus instructions).
- Write/merge agents are `owner-agents`, so Discord users can't reach them.
- Merge requires a literal `approve LOOP-n` from the maintainer's linked identity. Reviewer instructions check the sender is `{$creator}`.
- Secrets: GitHub auth via `gh auth login` on the laptop (agents inherit it). Discord bot token lives only in Switch Console. `.env` is git-ignored; only `.env.example` is committed.
- Bypass permissions stays **off** for support; Auto mode on for fixer/reviewer.

## 9. Repository layout (submission repo)

```
closed-loop/
├── README.md                    # judge-facing: problem, demo video, how Switch is used, setup
├── CLAUDE.md                    # context for coding agents working on this repo
├── .env.example
├── docs/
│   ├── HACKATHON.md             # every fact from the event site
│   ├── SWITCH_NOTES.md          # condensed Switch docs
│   ├── PRD.md · ARCHITECTURE.md · PLAN.md · PROGRESS.md · DECISIONS.md
│   └── api/
│       ├── openapi.yaml         # cartwheel HTTP API
│       └── schemas.md           # template schema, ledger schema, handoff message formats
├── switch/
│   └── closed-loop.template.yaml   # v2: 3 agents, 2 rooms, group + links, roles, docs, references, kickoffs
├── cartwheel/                   # target app (pushed to its own GitHub repo by setup script)
│   ├── src/ · test/ · package.json · SHIPPING.md
│   └── .github/workflows/ci.yml
└── scripts/
    ├── setup-demo-repo.sh       # gh repo create + push cartwheel + labels
    └── reset-demo.sh            # restore planted bugs between demo takes
```

## 10. Tech choices

| Choice | Reason |
|---|---|
| Claude Code as the provider for all agents | Installed, best at code; fewer setup unknowns |
| Mattermost for #eng | Bundled with Switch, zero setup, reliable for recording |
| Discord for #community | Realistic public-community surface, no public URL needed |
| Node 20 + Express + Vitest for cartwheel | Tiny, fast tests, readable diffs on video |
| GitHub Actions CI | Lets the reviewer cite real checks |
| No custom agent-protocol code (v1) | Lowest risk. Stretch: a tiny "loop-metrics" protocol agent |
