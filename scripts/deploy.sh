#!/usr/bin/env bash
set -euo pipefail

SERVER="${SERVER:-ubuntu@193.10.159.205}"
REPO_URL="${REPO_URL:-https://github.com/tuananhdao/dst-server.git}"
APP_DIR="${APP_DIR:-/opt/dst-server}"

ssh "$SERVER" "sudo apt-get update && sudo apt-get install -y ca-certificates curl git"

ssh "$SERVER" '
set -euo pipefail
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
'

ssh "$SERVER" "if [ ! -d '$APP_DIR/.git' ]; then sudo mkdir -p '$APP_DIR' && sudo chown ubuntu:ubuntu '$APP_DIR' && git clone '$REPO_URL' '$APP_DIR'; fi"
ssh "$SERVER" "cd '$APP_DIR' && git pull --ff-only"

ssh "$SERVER" "cd '$APP_DIR' && mkdir -p data/DoNotStarveTogether/Cluster_1"
if [ -n "${DST_CLUSTER_TOKEN:-}" ]; then
  printf '%s\n' "$DST_CLUSTER_TOKEN" | ssh "$SERVER" "cat > '$APP_DIR/data/DoNotStarveTogether/Cluster_1/cluster_token.txt'"
fi
ssh "$SERVER" "cd '$APP_DIR' && sudo docker pull jamesits/dst-server:nightly && sudo ./scripts/update-dst-server.sh && sudo docker compose up -d --force-recreate"
ssh "$SERVER" "cd '$APP_DIR' && sudo docker compose ps"
