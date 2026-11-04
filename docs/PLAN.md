# PLAN: Closed Loop (solo, Nov 4–7, 2026)

> Hard deadline: **Nov 7, 11:59 PM IST**. Internal deadline: **Nov 7, 8:00 PM IST**.
> Rule: at the end of each work block, update `PROGRESS.md`; log every non-obvious choice in `DECISIONS.md`.
> Dictate prompts, instructions and docs with **Wispr Flow** the whole time (side prize).

## Milestones

| # | Milestone | Done when | Target |
|---|---|---|---|
| M0 | Docs + plan | This folder exists with all docs | Nov 4 ✅ |
| M1 | Switch running | Console installed, Claude Code agent replies in Mattermost | Nov 4 |
| M2 | cartwheel ready | Repo on GitHub, CI green on main, 3 planted bugs each with a hidden failing case | Nov 4–5 |
| M3 | Rooms by hand | Both rooms, agents, roles, docs, references, link working (built in Console/chat) | Nov 5 |
| M4 | **Loop works once** | D1 end-to-end without manual fixes | Nov 5 night |
| M5 | Template | `closed-loop.template.yaml` recreates M3 on a fresh server | Nov 6 |
| M6 | All scenarios | D1–D5 pass in rehearsal | Nov 6 |
| M7 | README + video | Video uploaded, README complete, clean-clone test passed | Nov 7 |
| M8 | **Submitted** | Form submitted + blog + #HowISwitch post + Wispr scorecard | Nov 7, 8 PM IST |

---

## Day 1: Wed Nov 4 (setup + target app)

**Accounts (you, ~20 min)**
- [ ] Register at wemakedevs.org; star the Switch repo; join Discord
- [ ] Wispr Flow (promo `WEMAKEDEVS`), turn on, start dictating
- [ ] Install `gh` (`brew install gh`), `gh auth login`

**Switch (~1 h)**
- [ ] Download Console (Apple silicon dmg), install, open Docker
- [ ] Quickstart: add the local server, set up the Claude Code provider, onboard one test agent, create a room in Mattermost, get a reply
- [ ] `claude mcp add switch-docs --transport http https://docs.switchagents.ai/mcp`
- [ ] Note the Switch version (Console → About) in DECISIONS.md

**cartwheel (~2 h)**: spec in `docs/api/openapi.yaml`
- [ ] Express app: products (paginated), carts, items, coupon, totals, checkout
- [ ] Vitest tests that pass on main and **don't cover** the 3 planted bugs
- [ ] `SHIPPING.md` (review rules the reviewer enforces)
- [ ] GitHub Actions CI
- [ ] `scripts/setup-demo-repo.sh` → creates `cartwheel`, labels `from-community`, `loop`
- [ ] `scripts/reset-demo.sh`

**Ask in Discord**: (1) are 30/25/25/20 the judging weights; (2) any known Discord-bridge issues on the latest Console?

## Day 2: Thu Nov 5 (make the loop work)

- [ ] Discord: create a server "Closed Loop Demo", bot, intents, invite, connect in Console, link account
- [x] Reporter = a friend in the Cartwheel Community Discord (D-015); book slots for Nov 6 rehearsal + Nov 7 final
- [ ] Create agents `cl-support`, `cl-fixer`, `cl-reviewer` in Console (dirs = clones of the demo repo)
- [ ] Room `cl-community` (Discord) + `cl-eng` (Mattermost): instructions, roles, docs, references, link (ask an agent to set them up, or use the Gateway)
- [ ] Set addressing: support `anyone`; fixer/reviewer `owner-agents`
- [ ] Iterate instructions until **D1 passes once** end to end
- [ ] Keep the instructions in `switch/instructions/*.md` as source of truth
- [ ] #HowISwitch post #1 (short clip of the first loop closing)

## Day 3: Fri Nov 6 (reproducible + robust)

- [ ] Capture rooms as a template → clean up into `switch/closed-loop.template.yaml` (params: team prefix, bridges, provider, repo URL, maintainer)
- [ ] Test the template on a fresh server/workspace (or with a new prefix)
- [ ] D2 duplicate, D3 reject→revise, D4 role swap, D5 public user blocked
- [ ] Bugs 2 and 3 as rehearsal material
- [ ] README draft: hero GIF, problem, how it works, **Switch features table**, setup steps, troubleshooting
- [ ] Architecture diagram exported as PNG for README/video
- [ ] Dry-run recording ×2; fix whatever breaks
- [ ] #HowISwitch post #2

## Day 4: Sat Nov 7 (ship)

| Time (IST) | Task |
|---|---|
| 09–12 | Final recording (several takes), edit to ≤3 min |
| 12–14 | Upload video (YouTube); finish README; clean-clone test |
| 14–16 | Blog post (dev.to/Hashnode): "Your first Switch workflow: closing the bug-report loop" |
| 16–18 | Wispr Insights screenshot → `docs/wispr-scorecard.png`; #HowISwitch final post |
| 18–20 | **Submit**; verify links open logged-out |
| 20–24 | Buffer only. No new features |

---

## Demo video script (≤3:00)

| t | Shot | Voiceover |
|---|---|---|
| 0:00–0:20 | Friend shopping in the Cartwheel storefront: SAVE10 shows −$10 on a $40 mat. Then Discord, where reports usually go unanswered | "Every team's community channel looks like this. The worst part isn't the bug, it's nobody telling you it got fixed." |
| 0:20–0:35 | Architecture diagram | "Closed Loop is one Switch template: two linked rooms, a public support agent, private engineering roles, and me as the human gate." |
| 0:35–1:50 | Split screen Discord ↔ Mattermost: D1 live (sped up during agent work) | Narrate each handoff; highlight the failing test, PR, CI, "approve LOOP-1" |
| 1:50–2:10 | D2 duplicate answered instantly | "Room documents are shared memory." |
| 2:10–2:30 | D5 public user tries to command the fixer, nothing happens; D4 `!roles` swap | "Safety comes from Switch's addressing policy, not prompts." |
| 2:30–2:50 | Reporter pinged in Discord: loop closed. `run-shop.sh` redeploys and the storefront now shows −$4.00 | "Report to fix to reply, with two messages from me." |
| 2:50–3:00 | README + template file + repo link | "Clone it, import the template, and run it on your own team." |

## Submission checklist
> Full field list and drafts: [`SUBMISSION.md`](SUBMISSION.md). The README must say **which agents you connected, how the channel is set up, and how to run it**.

- [ ] Public GitHub repo `closed-loop` (MIT license)
- [ ] README: video link at the top, how Switch is used, setup, template
- [ ] Demo video ≤3 min, public/unlisted
- [ ] Track selected: Best Business Workflow
- [ ] Wispr scorecard attached (Code with Wispr)
- [ ] Blog link (Best Blog)
- [ ] #HowISwitch posts
- [ ] No secrets in repo (`git grep -i token`)

## Cut list (if behind schedule, drop in this order)
1. `cl-reviewer-2` / live role swap (show `!roles` only)
2. Bugs 2 and 3 (keep one hero bug)
3. Discord → both rooms on Mattermost
4. Blog post (do it Nov 8 for nothing)

**Never cut:** the human approval gate, the reply to the reporter, the template, the README "how Switch is used" section.
