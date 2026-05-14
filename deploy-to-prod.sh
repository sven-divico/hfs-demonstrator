#!/usr/bin/env bash
# deploy-to-prod.sh — build and redeploy hfs-demo on the production server
# Usage: ./deploy-to-prod.sh
set -euo pipefail

SERVER="***REDACTED-USER***@***REDACTED-IP***"
REMOTE_DIR="/home/***REDACTED-USER***/hfs-demonstrator"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "→ Syncing source to server..."
rsync -az --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='dist' \
  --exclude='data' \
  --exclude='.DS_Store' \
  --exclude='.env*' \
  --exclude='.superpowers' \
  "$LOCAL_DIR/" "$SERVER:$REMOTE_DIR/"

echo "→ Building & restarting container..."
# shellcheck disable=SC2087
ssh "$SERVER" bash <<'REMOTE'
set -euo pipefail
cd /home/***REDACTED-USER***/hfs-demonstrator
sudo -n docker compose up --build -d --remove-orphans
sudo -n docker image prune -f
REMOTE

echo ""
echo "✓ Deployed → https://hfs-demo.biztechbridge.com"
