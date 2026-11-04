# Switch: what we know (condensed from docs.switchagents.ai + repo, 2026-11-04)

> Read this instead of the docs. When something here turns out wrong in practice, fix it here and log it in DECISIONS.md.
> Docs index for agents: https://docs.switchagents.ai/llms.txt · Docs MCP: `https://docs.switchagents.ai/mcp`
> Repo: https://github.com/sandbox-quantum/switch (Python core, ~3.5k stars, active daily)

## 1. Mental model

- **Switch** = open-source infra that puts AI agents into team chat. It ships **no agents and no models** and doesn't replace your chat app.
- **Room** = a channel (Slack / Teams / Discord / Mattermost / Telegram) plus a shared log: messages, instructions, roles, tasks, knowledge. Every person and agent reads the same one.
- **Agent** = any AI agent registered with the server (Claude Code on a laptop, a LangChain bot on a server...). It has an owner, name and avatar, and posts under its own name.
- **Session** = a *running copy* of an agent. **A session answers, not the agent.** No session means Switch replies "agent unavailable". Presence ≠ availability.
- **Switch Console** = macOS desktop app. It runs a local server in **Docker**, starts agent sessions on demand, and connects chat apps. Local install ships **Mattermost**.
- **Gateway** = web/admin surface (session-cookie auth).
- **Agent protocol** = events in over WebSocket/SSE (`/agents/{id}/events`), HTTP out (`/agents/*`, Bearer agent API key). Custom agents implement it. A session's host exposes Switch operations to the agent as **MCP tools**.

## 2. What a room holds

| Thing | What | Notes |
|---|---|---|
| **Instructions** | Briefing every agent reads when it joins | An agent keeps the instructions it joined with **until it reconnects** |
| **Roles** (jobs) | `{name, instructions, exclusive}` | Only agents hold roles. Address `@role` and whoever holds it answers. `exclusive: true` = one holder at a time. Survives agent swaps |
| **References** | Pointers to outside material (GitHub repo, Confluence, Jira, a file) + instructions on *when* to use it | Register once, attach to many rooms |
| **Documents** | Content stored in the room `{name, description, instructions, content}` | **Agents can write room documents** |
| **Packages** | Named bundle of references + docs | Only a *person* can create/change one (in Gateway). Templates can't create them |
| **Links** | Room → room with a label ("escalations", "depends on") | A signpost, **doesn't grant access** |
| **Groups** | Folders of rooms | Moving a room between groups can change addressing |

Agents can create rooms, define roles, register references, write room docs and link rooms. A room belongs to the owner of the agent that created it.

## 3. Access: two separate questions

- **Authorization**: may this *user* touch this resource? Order: admin → owner → (delete? deny) → public visibility. **An agent inherits exactly its owner's permissions.**
- **Addressing**: may this sender make this agent respond?
  - v1 values: `owner` | `owner-agents` (owner + owner's other agents) | `anyone`
  - v2 adds `{anyone_in: [room keys]}`
  - Policy rules can scope by `rooms`, `room_groups`, `users`, `agents`.
  - **A new agent answers only its owner (and the owner's agents) until permitted.**
- Agent settings (Console → Your Agents): Agent instructions (every room), **Auto mode** (default on; Claude Code self-reviews actions, posts a permission request in the room for the rest), **Bypass permissions** (off; never asks), Can manage agents, Who can talk to your agent, Service access (connectors), Advanced config (model, tools, permission mode).

## 4. Room commands (type at the start of a message)

```
!help  !list-agents  !agents-status  !roles  !list-aliases  !list-documents
!list-references  !room-url  !list-switch-agents
!invite-agent @agent   !set-alias @agent @alias   !remove-alias @alias
!follow-ups on|off     !assign-agent @agent   !unassign-agent      (Switch 0.31+)
!run-cmd [@agent] [@role]   !interrupt @agent   !compact @agent   !reset @agent
!agents-greet   !interrupt-all-agents  !compact-all-agents  !reset-all-agents
```
- Only `!` at the **first character** triggers. Backticks don't make it inert (pasting `!reset` runs it).
- Teams: mention the Switch bot before the command.
- A role name works wherever an agent name does.

## 5. Templates (YAML), the key to reproducibility

Full reference: `docs/TEMPLATES.md` in the repo. Examples: `examples/agent-templates/{triage-pair, support-desk, jq-expert, switch-expert.v2}.template.yaml`, `examples/room-templates/red-blue-workroom.template.yaml`.

Top-level keys: `version` (1 or 2), `params`, `agent` | `agents`, `room` | (`group` + `rooms` + `links`), `kickoff`, `form`.

**params**: `type: string|number|boolean|enum|agent|bridge|room|user|provider|location|directory|machine`, plus `description, label, default (value or fallback list; $first, $new), required, input: ask|advanced|fixed, enum, multiline, pattern, min, max`. Use as `{name}` anywhere.

**Builtins**: `{$creator}` (deployer's linked chat identity), `{$creator_email}`, `{$date}`, `{$timestamp}`, `{$agents_dir}`, `{agent}`.

**Agent block**:
```yaml
name, display_name, icon_url, description, instructions,
provider: claude|codex|opencode|antigravity|cursor,
machine | location: local|<ssh host>, directory, model, advanced_config: {},
isolation: shared|isolated, auto_mode, auto_approve, can_manage_agents,
connections: [service | {service, access, repos}], repo: URL, sources: [{label,url}],
addressing: owner|owner-agents|anyone, join: [rooms], allow_existing: true|false
```
Every created agent **must** have provider + location/machine + directory.

**Room block** (same shape as `POST /rooms/from-yaml` and `GET /rooms/{id}/yaml`):
```yaml
name, description, instructions, bridge, channel_type: channel_public|channel_private,
read_visibility, write_visibility, agents: [...], users: [...],
roles: [{name, instructions, exclusive}],
references: [{id}|{name}|{type, name, description, instructions, value: {urls: [...]}}],
packages: [{id}|{name}], docs: [{name, description, instructions, content}],
aliases: {agent: alias}
```
**Groups**: `group: {name, description, color}`, `rooms: [<room block> + kickoff]`, `links: [{from, to, label}]`. With a group, a top-level `kickoff` is an error; put kickoff inside each room.

**Kickoff**: posted on the deployer's behalf after provisioning. **Agents only wake when addressed, so mention them in the kickoff.**

**Capture**: Console → room → Configuration → *Capture as template* (doesn't capture group/links, names references by id). **Check the `agents:` list** after capture.

Validation failures return reason codes: `controller_offline`, `provider_not_installed`, `provider_login_missing`, `name_taken`, `connector_not_connected`.

## 6. Messaging apps

| App | Needs | Notes |
|---|---|---|
| **Mattermost** | Nothing (bundled locally) | Each agent gets its own bot account. Best for local demo |
| **Discord** | Bot app, token, Guild ID | Nothing needs to be public. One bot for the whole server, a webhook per channel, so agents post under their own names. **Posting a message in a channel creates the room.** |
| Slack | Workspace app | Slack reserves `/status`, hence `!agents-status` |
| Teams | Switch reachable from the internet + M365 admin | Avoid for the hackathon |
| Telegram | One bot + one setting | Groups and channels |

**Discord setup (exact):**
1. https://discord.com/developers/applications → New Application → Bot tab → copy token.
2. Privileged Gateway Intents: **Server Members** + **Message Content** → Save.
3. OAuth2 → URL Generator → scopes `bot` + `applications.commands`; permissions: View Channels, Send Messages, Send Messages in Threads, **Manage Webhooks**, Manage Channels, Manage Roles, Read Message History, Attach Files, Add Reactions → open URL, add to server.
4. Discord User Settings → Developer → Developer Mode → right-click server → Copy Server ID (= Guild Id).
5. Console → server Home → Messaging apps → Connect → Discord → name it, paste Bot Token + Guild Id → Connect.
6. **Link your Discord account** ("This is me"), otherwise your agents don't recognize you as owner.
7. Post any message in the channel, and it appears under Your Rooms.

## 7. Use cases already in the docs (judges know these, so don't copy)
Incident response overnight · hand off engineering across time zones · Switch Trust PII guardrails · product launch · customer meeting prep · customer onboarding · vendor purchase review · open-source contribution review. The homepage hero demo = incident rollback.
Repo templates: triage-pair (triager → repro), **support-desk (greeter in intake + escalations, engineer)**, red-blue-workroom (coder/reviewer loop + human gate), jq-expert, switch-expert.

## 8. Gotchas
- **An agent can only edit room documents it created itself** (`update_room_document` checks `created_by_agent_id`). Docs made by a template belong to the deployer and are read-only for agents, so let the agent that maintains a doc create it (D-019 F1).
- Claude Code `permissions.ask` rules force an Allow prompt in the room even under Auto mode. Used for `gh pr merge` (D-020 F2).
- Agent working dir (`~/.switch/agents/<server>/<agent>`) **is** the repo clone when `repo:` is set; the agent clones on first need, not at creation.
- Claude Code **Auto mode can block `npm test`** (running repo code). Allow specific commands per agent via `.claude/settings.local.json` in the agent dir, or Console → agent → Advanced configuration.
- **v0.40.x bug: v2 templates can't hold inline `references:`.** Any list whose items all have a `value` key is parsed as `[{if, value}]` and collapses. Use **version 1** for templates with inline references (D-016).
- An agent that nobody addressed looks the same as one that's running.
- Instructions changes reach an agent only after it reconnects (`!reset @agent`).
- Agents act only on messages that `@mention` them (or follow-ups / `!assign-agent`).
- `{$creator}` in a bridged room needs your chat account linked.
- Teams needs a public URL; skip it.
- On OpenCode, Auto mode = approve everything.

## 9. Local setup runbook (Console v0.40.1, from the quickstart)
1. **Settings → Agent providers**: Claude Code must read **Signed in** (not just "Installed"). If not: `claude auth login`, then **Recheck**. If it shows "CLI not installed", quit Console with Cmd+Q and reopen (it reads PATH once).
2. **Add a server → Run a server on this computer** → wait for **"Docker is ready."** → **Start**. The first start downloads **a few GB**. When done, the sidebar reads **"Running locally"**. Console picks the ports, creates an admin account and signs itself in (no URL or secret needed).
3. **Mattermost sign-in**: server **Home** → Messaging apps → Mattermost row menu → **Sign-in details…** → **Open in Mattermost**. Your Mattermost account is linked automatically.
4. **Validate** (**v0.40.1 differs from the docs**: the only official template is **switch-buddy**, and Console **auto-creates your own buddy** (`switch-buddy-admin`) in the sidebar on first use. It's a managed agent with `can_manage_agents: true`, `addressing: owner-agents`, and the Switch repo cloned into its directory, so **it can create agents and rooms for us**. Click it in the sidebar to chat.) Older docs flow: Templates → **Switch expert** (Official) → **Use** → turn on **Start it in a room** → **Create agent and room**. It creates the private room **"Ask switch-expert"**. Approve its repo download (**Allow for this session**; the request may be hiding in a thread). Address it as `@<exact-agent-name>`.
- Quitting Console leaves the server running, but **it does not restart after a reboot**. Reopen Console and start it.
- Agents run by Console answer **only while Console is running**.
- The local server may report an older version than the latest release (Console pins a server version).
- Agent names: lowercase, digits, `.` `-` `_`; can't be changed later; unique per server. Run location can't be changed later either.
- Agents inherit your machine setup (the `gh` login, MCP servers) but get only a **fixed set of environment variables**, so tools that read API keys from your shell env may fail.
- In Mattermost, **adding an agent to a channel creates the room**. In Discord, **posting a message** creates it.
