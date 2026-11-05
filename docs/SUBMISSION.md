# Submission form: fields and draft answers

> Form: https://www.wemakedevs.org/hackathons/switch/submit (sign-in required). Captured from screenshots on 2026-11-05.
> You can **edit the submission until the deadline** (Nov 7, 11:59 PM IST), so submit early and update.
> Progress bar on the form: "0 of 7 answered" (5 in Part 1 + 2 in Part 3 are required; Part 2 is optional).

## "What you submit" (box at the top of the form)
- [ ] A **public project repository**
- [ ] A **short demo video** of your workflow running
- [ ] A **README that explains how you used Switch**: *which agents you connected, how the channel is set up, and how to run it*
- [ ] A blog post (optional; enters Best Blog)
- [ ] For Code with Wispr: the Wispr usage scorecard (Insights screenshot)

---

## Part 1 of 3: Project Details (5 required)

### 1. Project title *
Draft: **Closed Loop: from a community bug report to a merged fix and a reply, with Switch**

### 2. Tracks you are submitting for * (checkboxes, more than one allowed)
- [x] **Best Business Workflow**
- [ ] Best Personal or Creative Workflow
- [ ] Best Core Contribution: tick only if the Switch core PR is open (issue labelled `hackathon` and assigned first; see `~/Desktop/hack/switch-core-fix/CONTRIB_NOTES.md`)
- Note on the form: *everyone with a submission is considered for Code with Wispr, as long as they upload their Wispr usage card in Track Details.*

### 3. Project description * ("What problem does your project solve, and who is it for?")
Draft:
> Small SaaS and open-source teams get bug reports in a public Discord, and the loop rarely closes: someone has to notice, ask for details, dedupe, file, reproduce, fix, review, merge, and then remember to tell the reporter. Closed Loop puts that whole loop into chat with Switch. A public support agent in Discord clarifies the report, answers known issues from room memory, files a GitHub issue and escalates to a private Mattermost room. There, a fixer agent writes a failing test and opens a PR, a reviewer agent checks it against the team's shipping rules and CI, and the human maintainer approves the merge in chat. Then the support agent replies to the original reporter, in their own thread. It's for any team that runs a community channel and wants every report answered, fixed and closed, with a human in control of every merge.

### 4. GitHub Repository or contribution * (URL)
- Track 1 & 2: *public repository, with a README that explains how to set it up*
- Track 3: *your main pull request*
- "This is what your project gets listed and opened by."
- **Final**: `https://github.com/Sumit-Saurabh98/closed-loop` (public, published 2026-11-05; README links the demo repo `Sumit-Saurabh98/cartwheel`)

### 5. Demo video * (URL)
- *Keep it under 3 minutes. Host it on YouTube or Loom, public or unlisted.*
- *Track 1 & 2: show the agent working in a real chat with your teammates.* → Monika as reporter in Discord + you as maintainer in Mattermost.
- **Final**: `https://youtu.be/kRZiOfRAmC8` (YouTube, unlisted, uploaded 2026-11-05)

### Live demo or deployment (optional, URL)
"Leave blank if your project doesn't have a live demo." → leave blank (the shop runs locally).

---

## Part 2 of 3: Track Details (optional)

| Field | Notes | Draft |
|---|---|---|
| **Pull requests** (up to 10 links) | Required for Best Core Contribution | Switch core PR, if opened (D-016 fix) |
| **Blog post** (URL) | Best blog wins AirPods 5 | _(dev.to or Hashnode)_ |
| **Your Wispr usage card** (images: JPG/PNG/WebP/GIF/AVIF, ≤5 MB each, up to 10) | Required for Code with Wispr. Wispr Flow desktop app → **Insights** → **Your usage** → **Share** → upload the card | ⚠️ Wispr Flow not used yet |
| **Your #HowISwitch post** (URL) | Top 5 posts win a Logitech keyboard | _(X/LinkedIn post link)_ |

---

## Part 3 of 3: How you used Switch (2 required)

### 6. How did you use Switch in your project? *
Prompts on the form: *Which agent did you connect? Which platforms does it run on? What real work does it do, and how do your teammates work with it?*

Draft:
> **Agents**: three Claude Code agents created from one Switch template (`switch/closed-loop.template.yaml`) and run as managed agents by Switch Console: `cl-support` (public, `addressing: anyone`), `cl-fixer` and `cl-reviewer` (private, `owner-agents`).
> **Platforms**: two rooms in one Switch group, bridged to two apps. `#cl-community` on **Discord** for users, `cl-eng` on **Mattermost** for the team, linked as `escalate-to` / `report-back-to`.
> **Real work**: support clarifies a report, checks its own room documents (`cl-known-issues`, `cl-loop-ledger`) for duplicates, files a GitHub issue and escalates with a fixed handoff format. The agent holding the `fixer` role writes a failing test, fixes the bug and opens a PR; the `reviewer` role checks it against SHIPPING.md and CI and recommends. The maintainer approves with `approve LOOP-n` (plus an Allow prompt on merge) or rejects with a reason, and the fixer revises on the same PR. Support then replies to the reporter in their original Discord thread.
> **Teammates**: in the demo I play both sides: a customer account ("Monika", a second Discord account) reports bugs in the public channel, and I'm the maintainer in Mattermost. All three planted bugs went from report to merged fix to a reply in the customer's thread, with one or two messages from me. Public users can't reach the code agents: Switch room membership and addressing block it, and the support agent refuses relay requests.

### 7. What did you like about Switch, and what would you improve? *
Prompt: *What worked, what got in the way, and what you'd want Switch to do next.*

Draft (all from real findings, see DECISIONS.md):
> **Liked**: one YAML template creates agents, rooms, roles, references, links and kickoffs, so the whole workflow is reproducible. Roles worked exactly as promised (`@reviewer` reaches whoever holds the job). Addressing policy made the security story real rather than prompt-based. The Discord bridge needed no public URL, and agents post under their own names.
> **Got in the way**: (1) in v0.40.x a version 2 template can't hold inline `references:`, because `_choose` in `template_v2.py` reads any list whose items all have a `value` key as an if/value choice (we used v1, and prepared a fix with tests). (2) Room documents made by a template are read-only for agents (only the creating agent can edit), which isn't obvious from the docs, and Console has no screen to delete room documents. (3) The local server doesn't serve the dashboard pages (they return 401). (4) Claude Code Auto mode blocked `npm test` until we added per-agent allow-lists.
> **Next**: a document owner setting in templates (for example "owned by agent X"), a room-documents view in Console, and a template lint command we can run in CI.
