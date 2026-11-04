# CLAUDE.md: Closed Loop

Context for any coding agent (Claude Code, Codex…) working in this repo. Read this first, every session.

## What this is
**Closed Loop** is our solo entry to the **Flip the Switch Hackathon** (WeMakeDevs × DevTools Academy × Switch), **Track 01: Best Business Workflow ($2,000)**.
It's a Switch setup where a public **support agent** in Discord turns a user's bug report into a GitHub issue, private **fixer/reviewer** agents in Mattermost fix it with a failing test + PR + CI, the **human maintainer approves the merge in chat**, and the support agent **replies to the original reporter** in their thread.

**Deadline: Nov 7, 2026, 11:59 PM IST.** Internal target: 8 PM IST. Today's progress is in `docs/PROGRESS.md`.

## Read before working
| File | When |
|---|---|
| `docs/PROGRESS.md` | **Always first.** Current status + next actions |
| `docs/HACKATHON.md` | Any question about rules, prizes, judging, deadlines. **Don't re-fetch the website** |
| `docs/SWITCH_NOTES.md` | Any Switch question (rooms, roles, templates, addressing, commands). Docs MCP if needed: `https://docs.switchagents.ai/mcp` |
| `docs/PRD.md` | What we're building and why (requirements FR-x, scenarios D1–D5) |
| `docs/ARCHITECTURE.md` | Components, agents, rooms, sequence, security |
| `docs/PLAN.md` | Day-by-day tasks, video script, submission checklist, cut list |
| `docs/DECISIONS.md` | Why things are the way they are + open questions |
| `docs/SUBMISSION.md` | Every submission-form field + draft answers |
| `docs/RESET.md` | Demo reset runbook (before every take) |
| `docs/VIDEO.md` | Video runbook: pre-flight, shot list, voiceover script, edit, upload |
| `docs/api/openapi.yaml` | cartwheel HTTP API (source of truth for the app) |
| `docs/api/schemas.md` | Handoff grammar, ledger schema, GitHub conventions, template draft |

## Rules for agents working here
1. **Update `docs/PROGRESS.md`** at the end of every work block (status, next 3 actions, log entry).
2. **Log decisions** in `docs/DECISIONS.md` (append-only, `D-0xx`). Resolve open questions there.
3. If you learn that Switch behaves differently from `SWITCH_NOTES.md`, **fix that file**.
4. Judging lens for every change: *Use of Switch ~30%, Technical execution ~25%, Creativity/impact ~25%, Presentation ~20%*. Prefer work that makes Switch more central or the demo more reproducible.
5. **Never cut** (see PLAN cut list): human approval gate, reply to reporter, template, README "how Switch is used".
6. Planted bugs in `cartwheel` are **intentional**. Don't fix them on `main`. They're fixed by the agents during the demo. `scripts/reset-demo.sh` restores them.
7. No secrets in git. Use `.env` (ignored); update `.env.example` when adding a variable.
8. Keep the submission repo clean: agent PRs go to the separate demo repo, not this one.
9. Don't commit or push unless the human asks.

## Repo layout
```
CLAUDE.md  README.md  .env.example
docs/      HACKATHON SWITCH_NOTES PRD ARCHITECTURE PLAN PROGRESS DECISIONS api/{openapi.yaml,schemas.md}
switch/    closed-loop.template.yaml   (v2; all agent + room instructions inline: the heart of the project)
cartwheel/ Node 20 + Express + Vitest target app with 3 planted bugs, SHIPPING.md, CI
scripts/   setup-demo-repo.sh, reset-demo.sh
```

## Conventions
- Agent names: `<team>-support|fixer|reviewer` (default team `cl`). Roles: `fixer`, `reviewer` (exclusive).
- Loop ids `LOOP-<n>`; branches `loop-<n>`; handoff verbs `ESCALATE NEEDS-INFO INFO HANDOFF REVIEW CHANGES RESOLVED WONTFIX` (see schemas.md).
- cartwheel money = integer cents internally, 2-decimal numbers in JSON.
- Node: ESM, `npm test` = Vitest. Keep diffs small and readable (they appear on video).

## Commands (fill in as they become real)
```bash
cd cartwheel && npm install && npm test     # tests (planted bugs NOT covered)
npm start                                   # API on :3000
./scripts/setup-demo-repo.sh                # create your GitHub copy of cartwheel
./scripts/reset-demo.sh                     # restore planted bugs between demo takes
node scripts/check-bugs.mjs [path]          # which planted bugs are present (exit code = count)
./scripts/setup-agent-workspaces.sh         # after the template: clone repo + per-agent allow-lists, then !reset agents
./scripts/run-shop.sh                       # deploy latest GitHub main locally: API :3000 + storefront :5173
cd cartwheel && npm run web                 # storefront dev server against a local API
```
