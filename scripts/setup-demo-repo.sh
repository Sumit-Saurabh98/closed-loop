#!/usr/bin/env bash
# Creates YOUR GitHub copy of Cartwheel (with the planted bugs) for the agents to work on.
# Needs: gh (logged in), git, node. Reads ../.env if present (GITHUB_OWNER, DEMO_REPO_NAME, DEMO_REPO_VISIBILITY).
# Usage: ./scripts/setup-demo-repo.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$HERE/.env" ] && set -a && . "$HERE/.env" && set +a

OWNER="${GITHUB_OWNER:-}"
if [ -z "$OWNER" ] || [ "$OWNER" = "your-github-username" ]; then
  OWNER="$(gh api user --jq .login)"
fi
NAME="${DEMO_REPO_NAME:-cartwheel}"
VISIBILITY="${DEMO_REPO_VISIBILITY:-public}"
REPO="$OWNER/$NAME"
TAG="v1.0.0-planted"

echo "==> Target repo: $REPO ($VISIBILITY)"
EXISTS=no
if gh repo view "$REPO" >/dev/null 2>&1; then
  if [ "$(gh repo view "$REPO" --json isEmpty --jq .isEmpty)" = "true" ]; then
    EXISTS=empty
    echo "    $REPO exists and is empty; pushing into it."
  else
    echo "Repo $REPO already exists and has content. Set DEMO_REPO_NAME in .env to another name, then rerun." >&2
    exit 1
  fi
fi

echo "==> Checking the planted bugs are present"
node "$HERE/scripts/check-bugs.mjs" "$HERE/cartwheel" && { echo "Expected 3 planted bugs, found 0." >&2; exit 1; } || true

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
rsync -a --exclude node_modules --exclude coverage "$HERE/cartwheel/" "$WORK/"

cd "$WORK"
git init -q -b main
git add -A
git commit -q -m "Cartwheel 1.0.0"
git tag "$TAG"

DESC="Cartwheel: a tiny cart and checkout API (target app for the Closed Loop Switch demo)"
if [ "$EXISTS" = "empty" ]; then
  echo "==> Pushing to existing $REPO"
  gh repo edit "$REPO" --description "$DESC" >/dev/null
  git remote add origin "https://github.com/$REPO.git"
  git push -q -u origin main
else
  echo "==> Creating $REPO and pushing"
  gh repo create "$REPO" "--$VISIBILITY" --source . --push --description "$DESC"
fi
git push -q origin "$TAG"

echo "==> Creating labels"
gh label create from-community --repo "$REPO" --color 1D76DB --description "Reported in the community room" --force
gh label create loop           --repo "$REPO" --color 5319E7 --description "Tracked as a Closed Loop LOOP-n" --force
gh label create severity:low   --repo "$REPO" --color C2E0C6 --force
gh label create severity:med   --repo "$REPO" --color FBCA04 --force
gh label create severity:high  --repo "$REPO" --color D93F0B --force

echo
echo "Done: https://github.com/$REPO  (tag $TAG = clean demo state)"
echo "Next: use this URL as repo_url in the Closed Loop template."
