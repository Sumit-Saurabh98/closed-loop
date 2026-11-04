#!/usr/bin/env bash
# "Deploys" Cartwheel locally from the latest main on GitHub and runs the API + storefront.
# Run it again after an agent's fix is merged to see the bug disappear in the shop.
#   API  http://localhost:3000     Shop http://localhost:5173
# Usage: ./scripts/run-shop.sh            (Ctrl-C stops both)
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
[ -f "$HERE/.env" ] && set -a && . "$HERE/.env" && set +a

OWNER="${GITHUB_OWNER:-}"
if [ -z "$OWNER" ] || [ "$OWNER" = "your-github-username" ]; then OWNER="$(gh api user --jq .login)"; fi
REPO_URL="https://github.com/$OWNER/${DEMO_REPO_NAME:-cartwheel}"
LIVE="$HERE/.live/cartwheel"

for port in 3000 5173; do
  if lsof -nP -iTCP:$port -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Port $port is already in use. Stop that server first (lsof -nP -iTCP:$port -sTCP:LISTEN)." >&2
    exit 1
  fi
done

echo "==> Deploying latest main from $REPO_URL"
if [ -d "$LIVE/.git" ]; then
  git -C "$LIVE" fetch -q origin
  git -C "$LIVE" reset -q --hard origin/main
else
  mkdir -p "$(dirname "$LIVE")"
  git clone -q "$REPO_URL" "$LIVE"
fi
echo "    at $(git -C "$LIVE" log --oneline -1)"

echo "==> Installing"
npm --prefix "$LIVE" ci --silent
npm --prefix "$LIVE/web" ci --silent

echo "==> Bugs in this deploy:"
node "$HERE/scripts/check-bugs.mjs" "$LIVE" || true

trap 'kill 0' EXIT
npm --prefix "$LIVE" start &
npm --prefix "$LIVE/web" run dev -- --strictPort &
echo
echo "Shop: http://localhost:5173   API: http://localhost:3000   (Ctrl-C to stop)"
wait
