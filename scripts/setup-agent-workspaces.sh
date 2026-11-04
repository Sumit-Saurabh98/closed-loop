#!/usr/bin/env bash
# Prepares each Closed Loop agent's working folder after the template has created the agents:
#   1. clones the product repo into the folder if it is empty, or syncs an existing clone to
#      origin/main (checkout main, hard reset, delete local loop-* branches)
#   2. writes .claude/settings.local.json: the exact commands that agent may run without asking
#      (Claude Code checks these rules before its Auto-mode review, which otherwise blocks `npm test`)
#   3. hides .claude/ and .switch/ from git in that clone, so agents can't commit them
# Merging stays gated: the reviewer's `gh pr merge` is on an "ask" rule, so it always asks in the room.
#
# Usage: ./scripts/setup-agent-workspaces.sh [agents_dir]
#   agents_dir defaults to the folder under ~/.switch/agents that contains <team>-fixer.
# Then restart each agent's session (in the room: !reset @cl-fixer, etc.).
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$HERE/.env" ] && set -a && . "$HERE/.env" && set +a

TEAM="${SWITCH_TEAM_PREFIX:-cl}"
OWNER="${GITHUB_OWNER:-}"
if [ -z "$OWNER" ] || [ "$OWNER" = "your-github-username" ]; then OWNER="$(gh api user --jq .login)"; fi
REPO_URL="https://github.com/$OWNER/${DEMO_REPO_NAME:-cartwheel}"

AGENTS_DIR="${1:-}"
if [ -z "$AGENTS_DIR" ]; then
  AGENTS_DIR="$(dirname "$(find "$HOME/.switch/agents" -maxdepth 2 -type d -name "$TEAM-fixer" | head -1)")"
fi
[ -d "$AGENTS_DIR/$TEAM-fixer" ] || { echo "No $TEAM-fixer folder under ${AGENTS_DIR:-~/.switch/agents}. Run the template first." >&2; exit 1; }
echo "==> Agents folder: $AGENTS_DIR"
echo "==> Repo: $REPO_URL"

# Every agent may write scratch files (issue/PR bodies) in .loop/ (D-030)
loop_files='"Edit(.loop/**)", "Edit(./.loop/**)", "Write(.loop/**)", "Write(./.loop/**)"'

allow_fixer='[
  "Bash(npm test)", "Bash(npm test:*)", "Bash(npm run test:*)", "Bash(npx vitest:*)",
  "Bash(npm install)", "Bash(npm ci)",
  "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)", "Bash(git show:*)",
  "Bash(git fetch:*)", "Bash(git pull:*)", "Bash(git checkout:*)", "Bash(git switch:*)",
  "Bash(git branch:*)", "Bash(git add:*)", "Bash(git commit:*)",
  "Bash(git push -u origin loop-:*)", "Bash(git push origin loop-:*)",
  "Bash(gh pr create:*)", "Bash(gh pr view:*)", "Bash(gh pr checks:*)", "Bash(gh issue view:*)",
  '"$loop_files"'
]'
deny_fixer='[
  "Bash(git push origin main:*)", "Bash(git push --force:*)", "Bash(git push -f:*)",
  "Bash(gh pr merge:*)", "Bash(gh pr close:*)", "Bash(gh issue close:*)", "Bash(gh repo:*)"
]'

allow_reviewer='[
  "Bash(git status:*)", "Bash(git fetch:*)", "Bash(git pull:*)", "Bash(git log:*)", "Bash(git diff:*)", "Bash(git show:*)",
  "Bash(gh pr list:*)", "Bash(gh pr view:*)", "Bash(gh pr diff:*)", "Bash(gh pr checks:*)", "Bash(gh issue view:*)"
]'
deny_reviewer='[
  "Bash(git push:*)", "Bash(git commit:*)", "Bash(gh repo:*)", "Bash(gh issue close:*)"
]'
# Always ask in the room before merging: the second human gate after `approve LOOP-n`.
ask_reviewer='[ "Bash(gh pr merge:*)" ]'

allow_support='[
  "Bash(git status:*)", "Bash(git fetch:*)", "Bash(git pull:*)", "Bash(git log:*)",
  "Bash(gh issue list:*)", "Bash(gh issue view:*)", "Bash(gh issue create:*)", "Bash(gh issue comment:*)",
  "Bash(gh label list:*)",
  '"$loop_files"'
]'
deny_support='[
  "Bash(git push:*)", "Bash(git commit:*)", "Bash(gh pr:*)", "Bash(gh repo:*)",
  "Bash(gh issue close:*)", "Bash(gh issue delete:*)", "Bash(gh issue edit:*)"
]'

prepare() {
  local agent="$1" allow="$2" deny="$3" ask="${4:-[]}"
  local dir="$AGENTS_DIR/$TEAM-$agent"
  echo "--- $TEAM-$agent"
  mkdir -p "$dir"
  if [ -d "$dir/.git" ]; then
    # B3: sync to the remote main (after scripts/reset-demo.sh this is the planted state)
    git -C "$dir" fetch -q --prune origin
    git -C "$dir" checkout -q -f main
    git -C "$dir" reset -q --hard origin/main
    for b in $(git -C "$dir" for-each-ref --format='%(refname:short)' 'refs/heads/loop-*'); do
      git -C "$dir" branch -q -D "$b"
    done
    echo "    synced to origin/main @ $(git -C "$dir" rev-parse --short HEAD); local loop-* branches removed"
  elif [ -z "$(ls -A "$dir")" ]; then
    git clone -q "$REPO_URL" "$dir" && echo "    cloned $REPO_URL"
  else
    echo "    folder not empty and not a git repo; skipping clone" >&2
  fi
  mkdir -p "$dir/.claude"
  cat > "$dir/.claude/settings.local.json" <<JSON
{
  "permissions": {
    "allow": $allow,
    "deny": $deny,
    "ask": $ask
  }
}
JSON
  echo "    wrote .claude/settings.local.json"
  if [ -d "$dir/.git" ]; then
    local ex="$dir/.git/info/exclude"
    mkdir -p "$(dirname "$ex")"; touch "$ex"
    mkdir -p "$dir/.loop"
    for p in ".claude/" ".switch/" ".loop/"; do grep -qxF "$p" "$ex" || echo "$p" >> "$ex"; done
    echo "    git now ignores .claude/, .switch/ and .loop/ in this clone"
  fi
}

prepare fixer    "$allow_fixer"    "$deny_fixer"
prepare reviewer "$allow_reviewer" "$deny_reviewer" "$ask_reviewer"
prepare support  "$allow_support"  "$deny_support"

echo
echo "Done. Restart each agent so it reads its new settings. In the rooms:"
echo "  !reset @$TEAM-fixer    !reset @$TEAM-reviewer    !reset @$TEAM-support"
