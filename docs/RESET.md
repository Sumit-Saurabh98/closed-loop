# Demo reset runbook

> Use before every rehearsal or recording take. Written 2026-11-04 after the first dry run (LOOP-1).
> **Approach: update in place, don't re-create.** Rooms can only be archived (the channel and name stay), and re-created agents need new credentials and invites. Managed agents pick up edited instructions on their next session. Re-running the whole template from scratch is the reproducibility test (M5), done separately with a new prefix.

Legend: 🤖 = Claude does it (script) · 🧑 = you do it (Console / Discord / Mattermost)

---

## Part A: one-time catch-up (bring the live agents up to D-020)

Only needed once, because the live agents were created from the template **before** fixes F1/F3.

### A1 (skipped: nothing is deleted)
The template-made `known-issues` and `loop-ledger` in `cl-community` are read-only for agents and can't be deleted from Console or by an agent (only through the Gateway API, which needs the local admin session). They stay, empty and unused. cl-support creates and owns **`cl-known-issues`** and **`cl-loop-ledger`** instead (D-022).

### A2 🧑 Update the three agents' instructions (Console → Your Agents → agent → General → Agent instructions)
Small find-and-replace edits. Everything else stays as it is.

**cl-fixer**: replace
```
2. Reproduce first: add a test that fails on main, asserting exact two-decimal money values
   (never toBeCloseTo for money).
```
with
```
2. Reproduce first: add a test that fails on main. Assert money with exact number equality,
   e.g. `expect(body.total).toBe(43.87)`. Never use toBeCloseTo or toFixed in money asserts:
   both hide float errors like 43.870000000000005.
```

**cl-reviewer**: replace
```
exact cents math and no toBeCloseTo for money (2)
```
with
```
exact cents math, and money asserted with exact equality (`toBe(43.87)`), never
   toBeCloseTo or toFixed, which hide float errors (2)
```

**cl-support**: replace the **whole** Agent instructions text with the contents of
[`docs/live/cl-support.instructions.txt`](live/cl-support.instructions.txt) (generated from the template with `cl`, your repo URL and `user` filled in). Select all in the box, delete, paste, save.

- **Verify**: re-open each agent's page and check the new text is saved.

---

## Part B: every reset (before each take)

### B1 + B2 🧑 Reset GitHub: `./scripts/reset-demo.sh --delete-archived` (you run it: asks for the repo name, then `DELETE`)
Preview first with `./scripts/reset-demo.sh --dry-run --delete-archived` (prints every action, changes nothing).
- `--delete-archived` **permanently deletes** every old demo issue (D-027), so cl-support's text search can't find earlier runs and a take starts at a clean LOOP-1. You run this step yourself; Claude only runs the dry run. Leave the flag off to keep old issues (archived, labelled `demo-archive`).
- Tag current `main` as `run-<n>-end` (next free number), so the run's history stays findable after the force reset.
- Close open PRs (deleting their branches) and open `loop` issues.
- **New**: move every issue labelled `loop` (open or closed) to label `demo-archive`, so cl-support's duplicate check (`--label loop --state all`) can't match the previous run's issues.
- Force `main` back to tag `v1.0.0-planted` (= `d8159e2`: storefront + all 3 bugs).

### B3 🤖 Sync the agents' clones: `./scripts/setup-agent-workspaces.sh`
For each agent folder: `git fetch`, `git checkout main`, `git reset --hard origin/main`, delete local `loop-*` branches, then rewrite the allow-lists. (Today cl-fixer is still on its old `loop-1` branch.)

### B4 🧑 Clear agent memory
In Mattermost `cl-eng`, one at a time:
```
!reset @cl-fixer
```
```
!reset @cl-reviewer
```
```
!reset @cl-support
```

### B5 🧑 Clear the room documents' contents
Ask cl-support in `cl-eng`:
```
@cl-support demo reset: set cl-known-issues and cl-loop-ledger back to their starting content from your instructions (create them if they don't exist yet).
```
- **Verify**: it confirms both, and `!list-documents` in `#cl-community` shows them.

### B6 🧑 (Optional, for a clean video) tidy the chat history
- Discord `#cl-community`: delete the old test messages and threads, or film only the new thread.
- Mattermost `cl-eng`: older messages can stay. Film the new LOOP thread.

### B7 🤖 Verify the reset
- Fresh clone of `main`: `check-bugs` = **3/3**, `web/` present.
- GitHub: 0 open PRs, 0 issues labelled `loop`.
- Agent clones: all on `main` at the tag commit, clean.
- 🧑 `./scripts/run-shop.sh` (or your running shop): Desk mat + SAVE10 shows **−$10.00 / $37.39**.

---

## Known open items (2026-11-04)
- CI for `84667ef` stayed **queued** for 10+ minutes. Check GitHub → Actions before relying on CI in the next run; the reviewer must not approve on pending CI.
- The local shop at :5173 uses the API from `closed-loop/cartwheel` (the planted copy). Use `scripts/run-shop.sh` for the after-merge "redeploy" shot.
