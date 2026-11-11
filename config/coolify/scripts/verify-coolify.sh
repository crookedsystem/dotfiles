#!/usr/bin/env bash
set -euo pipefail

APP_PORT="${APP_PORT:-8000}"
LOCAL_URL="${LOCAL_URL:-http://127.0.0.1:${APP_PORT}}"
BASE_URL="${BASE_URL:-}"

echo "== Docker containers =="
sudo docker ps --filter 'name=coolify' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

echo
echo "== Local health =="
curl -fsS "${LOCAL_URL}/api/health"
echo

if [ -n "${BASE_URL}" ]; then
  echo
  echo "== External health =="
  curl -fsS "${BASE_URL%/}/api/health"
  echo
fi

echo
echo "== Tailscale Serve status =="
if command -v tailscale >/dev/null 2>&1; then
  sudo tailscale serve status || true
else
  echo "tailscale command not found; skip"
fi
