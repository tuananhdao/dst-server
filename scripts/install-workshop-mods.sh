#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-jamesits/dst-server:nightly}"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOD_SETUP="$APP_DIR/data/DoNotStarveTogether/Cluster_1/mods/dedicated_server_mods_setup.lua"
UGC_DIR="$APP_DIR/data/ugc/content/322330"
MODS_DIR="$APP_DIR/data/DoNotStarveTogether/Cluster_1/mods"
WORK_DIR="${WORK_DIR:-/tmp/dstworkshop}"

if [ ! -f "$MOD_SETUP" ]; then
  echo "Missing mod setup file: $MOD_SETUP" >&2
  exit 1
fi

mapfile -t MOD_IDS < <(sed -nE 's/.*ServerModSetup\("([0-9]+)"\).*/\1/p' "$MOD_SETUP")
if [ "${#MOD_IDS[@]}" -eq 0 ]; then
  echo "No ServerModSetup entries found in $MOD_SETUP"
  exit 0
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$UGC_DIR" "$MODS_DIR"

for mod_id in "${MOD_IDS[@]}"; do
  echo "Installing Workshop mod $mod_id"
  rm -rf "$WORK_DIR/steamapps/workshop/content/322330/$mod_id"

  docker run --rm \
    --network host \
    -v "$WORK_DIR:/workshop" \
    --entrypoint sh \
    "$BASE_IMAGE" \
    -lc "steamcmd +force_install_dir /workshop +login anonymous +workshop_download_item 322330 $mod_id validate +quit"

  src="$WORK_DIR/steamapps/workshop/content/322330/$mod_id"
  dst="$UGC_DIR/$mod_id"
  if [ ! -d "$src" ]; then
    echo "Workshop download did not create expected directory: $src" >&2
    exit 1
  fi

  rm -rf "$dst"
  mkdir -p "$dst"

  legacy_bundle="$(find "$src" -maxdepth 1 -name '*_legacy.bin' -type f | head -1 || true)"
  if [ -n "$legacy_bundle" ]; then
    unzip -q "$legacy_bundle" -d "$dst" || true
  else
    cp -a "$src"/. "$dst"/
  fi

  rm -rf "$MODS_DIR/workshop-$mod_id"
  ln -s "../../../ugc/content/322330/$mod_id" "$MODS_DIR/workshop-$mod_id"
done

if [ "${EUID:-$(id -u)}" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
  chown -R "$SUDO_USER:$SUDO_USER" "$APP_DIR/data/ugc" "$MODS_DIR"
fi

echo "Installed Workshop mods: ${MOD_IDS[*]}"
