# PROGRESS

> Update at the end of every work block. Newest entry on top. Keep "Current status" accurate. It's the first thing to read when resuming.

## Current status
- **Phase**: M5 done → README + publish the `closed-loop` repo, then video
- **Next 3 actions**:
  1. Record the demo video with Monika, following `docs/VIDEO.md` (pre-flight → takes A–I → iMovie edit → YouTube unlisted)
  2. Submit early with repo + description; add the video link when it's up (the form can be edited until the deadline)
  3. Ask the friend to join Cartwheel Community; first dry run of D1
- **Blockers**: none
- **Time left**: until Nov 7, 11:59 PM IST (internal: 8 PM)

## Milestones
| # | Milestone | Status |
|---|---|---|
| M0 | Docs + plan | ✅ done (Nov 4) |
| M1 | Switch running | ✅ done (Nov 4): switch-buddy-admin replied in Mattermost |
| M2 | cartwheel ready | ✅ done (Nov 4): github.com/Sumit-Saurabh98/cartwheel, CI green |
| M3 | Rooms (via template) | ✅ done (Nov 4): template v1 live, 3 agents + roles, allow-lists verified (cl-fixer ran npm test: 21 passed) |
| M4 | Loop works once (D1) | ✅ done (Nov 4): LOOP-1 closed end to end in **11 min** (report 22:27 → reply in the reporter's own Discord thread 22:38), 1 human message, PR #2 merged `6f7e435`, 1 human message; findings F1–F6 in D-019 |
| M5 | Template | ✅ done (Nov 5): fresh `cw` run reproduced agents, rooms, roles, docs, answers (D-028) |
| M6 | All scenarios D1–D5 | ✅ D1, D2, D3, D5 verified with a separate customer account (Nov 5); D4 role swap optional |
| M7 | README + video | 🟡 README done; video next |
| M8 | Submitted | ⬜ |

## Environment facts
| Thing | Value |
|---|---|
| Machine | MacBook Air M1 (2020), **8 GB RAM**: tight, see D-012 |
| Docker | v29.8.2, running ✅, 4.1 GB memory allocated (keep ≤4 GB, D-012) |
| Disk | 53 GB free (enough). Optional cleanup: iOS 27 sim runtime 7.5 GB, sim devices 2.5 GB, Xcode DerivedData 2.8 GB |
| Claude Code | installed ✅ |
| Node / Python | installed ✅ |
| gh CLI | installed (2.103.3), **logged in as Sumit-Saurabh98** ✅ |
| Codex / OpenCode | missing (optional, only for the reviewer-2 swap) |
| Switch Console | **v0.40.1** downloaded to ~/Downloads/switch-console (sha256 verified, notarized, signed by Sb Technology, Inc); install by dragging to Applications |
| Wispr Flow | **not installed** |
| Switch version | Console v0.40.1 (released 2026-10-21); server version: check Console → About after setup |
| Target app / repo | **Cartwheel**: https://github.com/Sumit-Saurabh98/cartwheel (public, tag `v1.0.0-planted`, labels from-community/loop/severity:*, CI green) |
| Discord server | **Cartwheel Community**, bot **Cartwheel Switch**, connected in Console as `Discord` ✅. Reporter = "Monika", the user's second Discord account (D-031) |

## Log

### 2026-11-04: Day 1
- Read the whole hackathon site (Overview, Resources, Schedule, Rules) + Switch docs/template language. Everything is captured in `docs/HACKATHON.md` and `docs/SWITCH_NOTES.md`.
- Chose the project: **Closed Loop**, Track 01 (see DECISIONS D-001, D-002).
- Created the project skeleton and docs: PRD, ARCHITECTURE, PLAN, DECISIONS, PROGRESS, api/openapi.yaml, api/schemas.md, CLAUDE.md, .env.example, README stub.
- `git init` done (branch `main`), nothing committed yet.
- Renamed target app demo-shop → **Cartwheel** (D-011). Noted the 8 GB RAM constraint (D-012).
- GitHub CLI logged in. Checked disk: 53 GB free; Xcode simulators idle (no RAM used), so no cleanup needed.
- Downloaded Switch Console v0.40.1 (arm64 dmg, checksum matches release digest, Apple-notarized). Installer opened.
- Local Switch server **running** (Console v0.40.1, Mattermost 11.9.0 container on 127.0.0.1:58049, about 190 MB). Claude Code provider: Signed in. Auto-created agent: `switch-buddy-admin`. System memory 57% free after start.
- Built **Cartwheel** (`cartwheel/`): Express 5 API per openapi.yaml, 21 Vitest tests (all pass), SHIPPING.md (8 review rules), README, MIT license, CI workflow. `scripts/check-bugs.mjs` confirms **3/3 planted bugs present**; with reference fixes in a scratch copy it reports 0/3 and tests stay 21/21. Wrote `scripts/setup-demo-repo.sh` and `scripts/reset-demo.sh`.
- Pushed Cartwheel to **github.com/Sumit-Saurabh98/cartwheel** (repo already existed empty; the setup script now handles that). Commit b793fb5, tag `v1.0.0-planted`, 5 custom labels, **CI passed on first run**.
- Discord connected (server Cartwheel Community, bot Cartwheel Switch). Reporter role: see D-031 (it's the user's second account).
- Wrote `switch/closed-loop.template.yaml` (v2, D-014): agents cl-support/cl-fixer/cl-reviewer, rooms cl-community (Discord, public) + cl-eng (Mattermost, private), group with 2 links, roles fixer/reviewer, docs known-issues + loop-ledger, 3 github references, kickoffs. Structural check: no problems.
- First import failed: `RoomSpec references` validation error. Traced to a Switch core bug in v2 `_choose` (D-016). Converted the template to v1 (identical content, verified). Possible Track 03 issue/PR (side session `switch-core-fix-v2-templ` started).
- **v1 template imported successfully.** Discord #cl-community: cl-support introduced itself. Mattermost cl-eng: cl-reviewer assumed `reviewer`, cl-fixer assumed `fixer`, support confirmed it's the bridge. Agent dirs: `~/.switch/agents/localhost-58048/<agent>` = the repo clone itself (cl-fixer cloned + `npm install --ignore-scripts`; support/reviewer dirs still empty). **Blocker**: Claude Code Auto mode blocks `npm test` for cl-fixer.
- Ran `scripts/setup-agent-workspaces.sh` (D-017): allow-lists for fixer (23 allow / 7 deny), reviewer (11/4), support (9/7); repo pre-cloned for support + reviewer; `.claude/` hidden from git (all clones clean).
- Switch core fix (side session): branch `fix/v2-choose-collapses-references` @ 87ec25f56 in ~/Desktop/hack/switch-core-fix, 3 new tests + 271 template tests pass; issue/PR texts in CONTRIB_NOTES.md; nothing posted.
- After `!reset`, cl-fixer ran `npm test`: 21 passed. Allow-lists work (D-017 verified).
- Built the **Cartwheel storefront** (`cartwheel/web`, React 19 + Vite 7, D-018); verified all 3 bugs visible in the browser; `scripts/run-shop.sh` deploys latest GitHub main + runs API and shop. Not pushed to GitHub yet.
- **M4 dry run (D1) passed**: Discord report → issue #1 → PR #2 (failing test first, 22/22 after, CI green) → `approve LOOP-1` → squash-merged `6f7e435`, issue closed → RESOLVED → support replied **in the reporter's original Discord thread** at 22:38, @mentioning them (confirmed by screenshot). Verified on GitHub + `check-bugs` on main: BUG-1 fixed, 2/3 remain. Hero cart now returns total 43.870000000000005 (BUG-2 visible). Findings F1–F6 → D-019.
- Applied D-019 fixes (D-020): template no longer makes docs (support creates its own), exact-money rules for fixer/reviewer + SHIPPING.md rule 2, reviewer `ask` on `gh pr merge` (live now). Template structural check: no problems.
- Pushed storefront to cartwheel: main `84667ef`; demo tag `v1.0.0-planted` → `d8159e2` (shop + all 3 bugs, verified 3/3 from a fresh clone); safety tag `v1.0.0-planted-orig` → `b793fb5`. CI on 84667ef queued at time of writing.
- Reset tooling (docs/RESET.md): `reset-demo.sh` now tags `run-<n>-end`, archives every `loop` issue to `demo-archive` (so support's dedupe can't match old runs), force-moves main via the GitHub API, and has `--dry-run` (verified against the real repo: no changes). `setup-agent-workspaces.sh` now syncs each clone to origin/main and deletes local `loop-*` branches (verified: all 3 on main @ 84667ef, clean). Real reset not run yet.
- Doc ownership resolved without deleting (D-022): support owns `cl-known-issues` + `cl-loop-ledger`; template renamed; paste-ready `docs/live/cl-support.instructions.txt` generated. A1 skipped.
- **Demo reset complete (RESET.md A + B)**: cl-support instructions pasted; GitHub main → `d8159e2`, `run-1-end` → `84667ef`, issue #1 → `demo-archive` (0 `loop` issues, 0 open PRs); clones synced to d8159e2; agents `!reset`; cl-support created `cl-known-issues` + `cl-loop-ledger` itself (no 403). Fresh-clone check: 3/3 bugs, web/ present. Local shop/API up: hero cart = discount 10, total 37.39. CI on 84667ef finished green (the earlier queue was just slow).
- **Rehearsal 1 (Monika as reporter) passed** (D-023): issue #3 / LOOP-2 → PR #4 (exact asserts, cents math) → merged `97e1a4a`, CI green → Monika replied in Discord. main now has **1/3 bugs** (pagination). Findings F7–F9. **Pre-video reset** (Nov 5): main → `d8159e2`, `run-2-end` → `60b677f`, issues #1/#3/#5 all deleted (#5 on a second run after the D-029 fix; repo now has 0 issues), clones synced (3/3 bugs), shop redeployed via run-shop.sh (`.live` @ d8159e2, hero cart discount 10 / total 37.39). cl-support got stuck on `!reset` (5 old sessions); fixed by quitting and reopening Switch Console. After that: only one fresh cl-support session alive, docs reset ("no loops listed"), fixer/reviewer start fresh on demand, memory 50% free. Added to RESET.md + VIDEO.md. **README written** (problem, flow + diagram, Switch features table, agents + allow-lists, loop protocol, safety, real results, 6-step setup, reset, lessons) + root LICENSE. Pre-publish scan of the 51 committable files: no secrets, no node_modules; Monika's Discord handle removed from DECISIONS.md. **Published**: https://github.com/Sumit-Saurabh98/closed-loop (public, commit `13ad037`, 51 files, topics added). Fresh-clone check: README links OK, cartwheel 21/21 tests, 3/3 planted bugs, no secrets (only the `sk-ant-xxx` placeholder in .env.example). **M5 verified** (D-028): fresh `cw` template run worked end to end. **Submission form captured** → `docs/SUBMISSION.md` (all fields + drafts; Wispr card not started). **F7 settled** (D-027): `reset-demo.sh --delete-archived` (user-run, typed `DELETE`) removes old demo issues; dry run verified. **After-shot verified**: `run-shop.sh` deployed main `60b677f` to `.live/`; API hero cart = discount 4 / total 43.87, 3 pages, page 3 = Headphone hook + Coffee mug; shop shows SAVE10 −$8.00 on $80, total $77.76, "Page 1 of 3". Monika got her LOOP-3 reply. **D3 verified + all bugs fixed** (D-026): Monika's pagination report → PR #6 → user rejected with boundary-test request → fixer revised on the same PR → approved → merged `60b677f`; main check-bugs **0/3**. **D2 verified** (D-025): a duplicate SAVE10 question was answered from cl-known-issues, with no new issue. **D5 fully verified** (D-024): Switch blocked `@cl-fixer` from Discord ("isn't in this room"), and cl-support refused a "tell the fixer to push" relay with nothing reaching cl-eng. **F2 verified**: the Allow prompt for `gh pr merge` appeared and was clicked.
- Kickoff threads show `<@id>` in Discord thread titles (cosmetic Switch quirk).
