# Schemas and contracts

Closed Loop has no server of its own. Its "API" is:
1. **cartwheel HTTP API**: `openapi.yaml` (the target app).
2. **Handoff message grammar**: how agents and the human talk in chat so that @mention routing is reliable.
3. **Room document schemas**: `cl-loop-ledger` and `cl-known-issues`.
4. **GitHub conventions**: issue/PR/branch formats.
5. **Switch template schema**: the shape of `switch/closed-loop.template.yaml` (draft below).

---

## 1. Loop ids
- Format `LOOP-<n>`, n = 1, 2, 3… assigned by `cl-support` = (max n in `cl-loop-ledger`) + 1.
- One loop = one distinct bug. Duplicate reporters join an existing loop as watchers.

## 2. Handoff message grammar

Every agent-to-agent handoff is **one first line** in this exact shape, then optional free text below it:

```
@<target> <VERB> LOOP-<n> key=value key="value with spaces" ...
```

| Verb | From → To | Room | Required keys | Meaning |
|---|---|---|---|---|
| `ESCALATE` | cl-support → `@fixer` | cl-eng | `issue=#N` `severity=low\|med\|high` `summary="…"` | New confirmed bug, please reproduce + fix |
| `NEEDS-INFO` | fixer → `@cl-support` | cl-eng | `question="…"` | Can't reproduce; ask the reporter this |
| `INFO` | cl-support → `@fixer` | cl-eng | `answer="…"` | Reporter's answer, relayed |
| `HANDOFF` | fixer → `@reviewer` | cl-eng | `pr=#N` `branch=loop-<n>` | PR ready for review |
| `REVIEW` | reviewer → maintainer (by name) | cl-eng | `pr=#N` `verdict=APPROVE-RECOMMENDED\|CHANGES-REQUESTED` `ci=green\|red\|pending` | Review result; waits for the human |
| `CHANGES` | reviewer → `@fixer` | cl-eng | `pr=#N` `reason="…"` | Revise (from a review or a human reject) |
| `RESOLVED` | reviewer → `@cl-support` | cl-eng | `pr=#N` `merged=true` `sha=<short>` | Merged, so close the loop with the reporter |
| `WONTFIX` | maintainer or reviewer → `@cl-support` | cl-eng | `reason="…"` | Not fixing; tell the reporter kindly |

Examples:
```
@fixer ESCALATE LOOP-1 issue=#4 severity=high summary="SAVE10 subtracts $10 instead of 10%"
Reporter: @alice in #cl-community. Steps: cart with 1× p_2 ($40), apply SAVE10, total shows 37.39, expected 43.87.

@reviewer HANDOFF LOOP-1 pr=#5 branch=loop-1
Failing test added: test/coupon.test.js "SAVE10 is 10 percent". Now passes. Full suite 14/14.

@sumit REVIEW LOOP-1 pr=#5 verdict=APPROVE-RECOMMENDED ci=green
Diff is 6 lines in src/pricing.js + 1 test. Meets SHIPPING.md (test-first, cents math, no API change). Reply "approve LOOP-1" to merge.

@cl-support RESOLVED LOOP-1 pr=#5 merged=true sha=a1b2c3d
```

### Human commands (maintainer, in #cl-eng)
| Command | Effect | Accepted only from |
|---|---|---|
| `approve LOOP-<n>` | reviewer merges the PR (squash), then sends `RESOLVED` | the maintainer (`{$creator}` / configured maintainer handle) |
| `reject LOOP-<n>: <reason>` | reviewer sends `CHANGES` with the reason to the fixer | maintainer |
| `wontfix LOOP-<n>: <reason>` | reviewer closes the PR/issue and sends `WONTFIX` | maintainer |
| `@cl-support status` | ledger summary of open loops | anyone in the room |

Agents must **ignore** these commands from anyone else and say so briefly.

### Public-facing replies (cl-support in #cl-community)
| Moment | Template |
|---|---|
| Filed | "Thanks @user, I can reproduce the description. Filed as **LOOP-n** (issue #N). I'll ping you right here when it's fixed." |
| Duplicate | "Thanks @user, this is a known issue: **LOOP-n**, status *<status>*. I've added you, so you'll be pinged when it's fixed." |
| Need info | "Quick question so the team can reproduce it: <question>" |
| Resolved | "@user (and @watchers): **LOOP-n is fixed** in PR #N, merged to main. Thanks for reporting! 🙌" |
| Won't fix | "@user, update on LOOP-n: the team decided not to change this because <reason>. <workaround if any>" |

## 3. Room document: `cl-loop-ledger` (in cl-community)

Markdown table. One row per loop. `cl-support` is the only writer.

```markdown
| loop | status | severity | summary | reporter | watchers | thread_ref | issue | pr | opened | closed |
|------|--------|----------|---------|----------|----------|------------|-------|----|--------|--------|
| LOOP-1 | resolved | high | SAVE10 subtracts $10 not 10% | @alice | @bob | discord:#cl-community/1234567 | #4 | #5 | 2026-11-05T10:02Z | 2026-11-05T10:14Z |
```

| Field | Type | Values / format |
|---|---|---|
| `loop` | string | `LOOP-<n>` |
| `status` | enum | `clarifying` → `open` → `fixing` → `in-review` → `awaiting-approval` → `resolved` \| `wontfix` \| `needs-info` |
| `severity` | enum | `low` \| `med` \| `high` |
| `summary` | string | ≤ 80 chars |
| `reporter` | string | chat handle of the first reporter |
| `watchers` | string | space-separated handles of duplicate reporters |
| `thread_ref` | string | `<app>:<channel>/<message or thread id>`, enough for support to reply in place |
| `issue`, `pr` | string | `#N` or empty |
| `opened`, `closed` | string | ISO-8601 UTC |

Status transitions are owned by: support (`clarifying`, `open`, `needs-info`, `resolved`, `wontfix`); support updates `fixing` / `in-review` / `awaiting-approval` when it sees the handoffs in cl-eng (best effort; not critical).

## 4. Room document: `cl-known-issues` (in cl-community)

Human-readable; support reads it **before** filing anything.

```markdown
# Known issues: cartwheel

## LOOP-1 · SAVE10 coupon takes $10 off instead of 10%   [FIXED 2026-11-05, PR #5]
Symptoms: total too low with SAVE10 on carts under $100, too high over $100.
Workaround (before fix): none.

## LOOP-2 · Totals show long decimals like 29.999999   [OPEN]
...
```

## 5. GitHub conventions

| Thing | Format |
|---|---|
| Issue title | `[LOOP-n] <summary>` |
| Issue labels | `from-community`, `loop`, `severity:<low\|med\|high>` |
| Issue body | Steps / Expected / Actual / Reporter (chat handle, no personal data) / Thread ref |
| Branch | `loop-<n>` |
| PR title | `fix: <summary> (LOOP-n)` |
| PR body | `Closes #<issue>` + "Failing test before" output + "After" output |
| Merge | squash, only after `approve LOOP-n` |

## 6. Switch template schema (v0 draft, **superseded**)

> **The real template is `switch/closed-loop.template.yaml` (version 2, D-014).** The v1 draft below is kept only for history; don't edit it.

Follows Switch template language v1 (`docs/SWITCH_NOTES.md` §5). **Draft. Not yet run.** The real file will be `switch/closed-loop.template.yaml`.

```yaml
version: 1

params:
  team:
    type: string
    description: Prefix for every name this creates
    default: cl
    pattern: "[a-z][a-z0-9-]*"
  repo_url:
    type: string
    description: Your copy of cartwheel on GitHub (from scripts/setup-demo-repo.sh)
  maintainer:
    type: string
    description: Your chat handle in the eng room; the only person who can approve merges
    default: "{$creator}"
  community_bridge:
    type: bridge
    description: Public app for reporters
    default: [Discord, $first]
  eng_bridge:
    type: bridge
    description: Private app for the team
    default: [Mattermost, Slack, $first]
  provider:
    type: provider
    default: [claude, codex, opencode]
    input: advanced
  location:
    type: location
    default: local
    input: advanced
  directory:
    type: directory
    default: "{$agents_dir}/{agent}"
    input: advanced

agents:
  - name: "{team}-support"
    description: Public face. Clarifies, dedupes, files, escalates, and closes the loop with the reporter
    addressing: anyone
    provider: "{provider}"
    location: "{location}"
    directory: "{directory}"
    repo: "{repo_url}"
    instructions: |
      # see switch/instructions/support.md (inlined at build time)
  - name: "{team}-fixer"
    description: Reproduces with a failing test, fixes, opens the PR
    addressing: owner-agents
    provider: "{provider}"
    location: "{location}"
    directory: "{directory}"
    repo: "{repo_url}"
    instructions: |
      # see switch/instructions/fixer.md
  - name: "{team}-reviewer"
    description: Reviews against SHIPPING.md, checks CI, merges only on human approval
    addressing: owner-agents
    provider: "{provider}"
    location: "{location}"
    directory: "{directory}"
    repo: "{repo_url}"
    instructions: |
      # see switch/instructions/reviewer.md

group:
  name: "{team} closed loop"
  description: Community bug reports to merged fixes to replies to the reporter

rooms:
  - name: "{team}-community"
    description: Public room where users report bugs and ask questions
    bridge: "{community_bridge}"
    channel_type: channel_public
    agents: ["{team}-support"]
    users: ["{$creator}"]
    instructions: |
      # see switch/instructions/room-community.md
    references:
      - type: github
        name: "{team} cartwheel repo"
        description: Source of the product users report bugs about
        instructions: Read it for current behaviour. Issues are filed here.
        value: { urls: ["{repo_url}"] }
    docs:
      - name: cl-known-issues
        description: Known bugs and their status
        instructions: Check before filing anything. Keep it current when loops change.
        content: "# Known issues: cartwheel\n\n_None yet._\n"
      - name: cl-loop-ledger
        description: One row per loop. The support agent is the only writer
        instructions: Follow the schema in the header exactly.
        content: "| loop | status | severity | summary | reporter | watchers | thread_ref | issue | pr | opened | closed |\n|---|---|---|---|---|---|---|---|---|---|---|\n"
    kickoff: |
      @{team}-support this is the community room. Introduce yourself in two lines:
      what people can bring here, and that you'll ping them when their bug is fixed.

  - name: "{team}-eng"
    description: Private room where agents and the maintainer fix escalated bugs
    bridge: "{eng_bridge}"
    channel_type: channel_private
    agents: ["{team}-support", "{team}-fixer", "{team}-reviewer"]
    users: ["{$creator}"]
    instructions: |
      # see switch/instructions/room-eng.md (loop protocol + approval rule naming {maintainer})
    roles:
      - name: fixer
        exclusive: true
        instructions: Reproduce with a failing test first, fix on branch loop-<n>, open the PR, hand off to @reviewer.
      - name: reviewer
        exclusive: true
        instructions: Review against SHIPPING.md and CI; recommend; merge only after "approve LOOP-<n>" from {maintainer}.
    references:
      - type: github
        name: "{team} shipping guide"
        description: The review rules
        instructions: Check every PR against this file before recommending approval. Read this file; don't search the repo for it.
        value: { urls: ["{repo_url}/blob/main/SHIPPING.md"] }
    kickoff: |
      @{team}-fixer take the fixer role. @{team}-reviewer take the reviewer role.
      Each of you confirm in one line. @{team}-support will escalate bugs here.

links:
  - from: "{team}-community"
    to: "{team}-eng"
    label: escalate-to
```

Open points for the real template: reference `type` values accepted (`github`?), whether `roles` auto-assign or need the kickoff to tell agents to take them, and whether `{maintainer}` defaulting to `{$creator}` resolves inside params (if not, make it a required `user` param).
