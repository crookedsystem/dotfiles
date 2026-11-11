#!/usr/bin/env bash
set -euo pipefail

APP_PORT="${APP_PORT:-8000}"

echo "Tailscale Serve 설정: http://<tailnet-host>/ -> http://127.0.0.1:${APP_PORT}"
sudo tailscale serve --bg --http=80 "http://127.0.0.1:${APP_PORT}"
sudo tailscale serve status
