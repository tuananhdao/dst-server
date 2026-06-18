#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-jamesits/dst-server:nightly}"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$APP_DIR"
rm -rf server-bin.new
mkdir -p server-bin.new

docker run --rm \
  --network host \
  -v "$APP_DIR/server-bin.new:/opt/dst_server_fresh" \
  --entrypoint sh \
  "$BASE_IMAGE" \
  -lc 'steamcmd +force_install_dir /opt/dst_server_fresh +login anonymous +app_update 343050 validate +quit && chown -R "${DST_USER}:${DST_GROUP}" /opt/dst_server_fresh'

rm -rf server-bin.prev
if [ -d server-bin ]; then
  mv server-bin server-bin.prev
fi
mv server-bin.new server-bin

printf 'Installed DST dedicated server version: '
cat server-bin/version.txt
