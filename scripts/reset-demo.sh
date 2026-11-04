#!/usr/bin/env bash
# Resets YOUR Cartwheel demo repo to the planted-bug state between demo takes (docs/RESET.md, Part B):
#   B1  tags the current main as run-<n>-end, so the last run's history stays findable
#   B2  closes open PRs (deleting their branches) and open "loop" issues,
#       moves EVERY "loop" issue (open or closed) to the "demo-archive" label,
#       so the support agent's duplicate check can't match the previous run,
#       then force-pushes tag v1.0.0-planted back onto main
# Destructive for the demo repo only. Asks you to type the repo name first.
#   B2b (opt-in, --delete-archived) PERMANENTLY deletes every "demo-archive" issue, so the support
#       agent can't find old runs by text search (D-027). Asks you to type DELETE first.
# Usage: ./scripts/reset-demo.sh [--dry-run] [--delete-archived]
#        --dry-run prints every action and changes nothing
# Afterwards: ./scripts/setup-agent-workspaces.sh  (syncs the agents' clones), then !reset each agent.
set -euo pipefail

DRY=no; DELETE_ARCHIVED=no
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=yes ;;
    --delete-archived) DELETE_ARCHIVED=yes ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
run() { if [ "$DRY" = yes ]; then echo "    [dry-run] $*"; else "$@"; fi; }

HERE="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$HERE/.env" ] && set -a && . "$HERE/.env" && set +a

OWNER="${GITHUB_OWNER:-}"
if [ -z "$OWNER" ] || [ "$OWNER" = "your-github-username" ]; then OWNER="$(gh api user --jq .login)"; fi
REPO="$OWNER/${DEMO_REPO_NAME:-cartwheel}"
TAG="v1.0.0-planted"

TAG_SHA="$(gh api "repos/$REPO/commits/$TAG" --jq .sha)"
MAIN_SHA="$(gh api "repos/$REPO/commits/main" --jq .sha)"
echo "Repo:  $REPO"
echo "main:  ${MAIN_SHA:0:7}    $TAG: ${TAG_SHA:0:7}    dry-run: $DRY"

if [ "$DRY" = no ]; then
  echo "This will close open PRs and loop issues, archive all loop issues, and force main back to $TAG."
  read -r -p "Type the repo name to confirm ($REPO): " answer
  [ "$answer" = "$REPO" ] || { echo "Aborted."; exit 1; }
fi

echo "==> B1 Save the end of the last run"
if [ "$MAIN_SHA" = "$TAG_SHA" ]; then
  echo "    main is already at $TAG; nothing to save"
else
  n=1
  while gh api "repos/$REPO/git/ref/tags/run-$n-end" >/dev/null 2>&1; do n=$((n + 1)); done
  run gh api "repos/$REPO/git/refs" -f "ref=refs/tags/run-$n-end" -f "sha=$MAIN_SHA" --silent
  echo "    run-$n-end -> ${MAIN_SHA:0:7}"
fi

echo "==> B2 Close open PRs"
for pr in $(gh pr list --repo "$REPO" --state open --json number --jq '.[].number'); do
  echo "    PR #$pr"; run gh pr close "$pr" --repo "$REPO" --delete-branch --comment "Demo reset"
done

echo "==> B2 Close open loop issues"
for issue in $(gh issue list --repo "$REPO" --state open --label loop --json number --jq '.[].number'); do
  echo "    issue #$issue"; run gh issue close "$issue" --repo "$REPO" --comment "Demo reset"
done

echo "==> B2 Archive every loop issue (label loop -> demo-archive)"
run gh label create demo-archive --repo "$REPO" --color BFBFBF --description "Issue from an earlier demo run" --force
for issue in $(gh issue list --repo "$REPO" --state all --label loop --limit 200 --json number --jq '.[].number'); do
  echo "    issue #$issue"; run gh issue edit "$issue" --repo "$REPO" --remove-label loop --add-label demo-archive
done

if [ "$DELETE_ARCHIVED" = yes ]; then
  echo "==> B2b Permanently delete demo-archive issues"
  # demo-archive issues, plus loop issues (in a dry run the step above didn't relabel them)
  ids=$( { gh issue list --repo "$REPO" --state all --label demo-archive --limit 200 --json number --jq '.[].number'
           gh issue list --repo "$REPO" --state all --label loop --limit 200 --json number --jq '.[].number'; } | sort -nu | tr '\n' ' ')
  if [ -z "${ids// /}" ]; then
    echo "    none"
  else
    echo "    issues: $ids"
    if [ "$DRY" = no ]; then
      read -r -p "    This cannot be undone. Type DELETE to delete these issues: " really
      [ "$really" = "DELETE" ] || { echo "    Skipped deleting issues."; ids=""; }
    fi
    for issue in $ids; do
      echo "    deleting #$issue"; run gh issue delete "$issue" --repo "$REPO" --yes
    done
  fi
fi

echo "==> B2 Force main back to $TAG (${TAG_SHA:0:7})"
if [ "$MAIN_SHA" = "$TAG_SHA" ]; then
  echo "    already there"
else
  run gh api -X PATCH "repos/$REPO/git/refs/heads/main" -f "sha=$TAG_SHA" -F force=true --silent
fi

echo
if [ "$DRY" = yes ]; then echo "Dry run only: nothing was changed."; else echo "GitHub reset done."; fi
echo "Next (docs/RESET.md): ./scripts/setup-agent-workspaces.sh, then !reset each agent and ask cl-support to reset its documents."
