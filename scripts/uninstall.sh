#!/usr/bin/env bash
set -euo pipefail

DEST_LUA="$HOME/.local/share/vlc/lua/playlist/youtube.lua"

if [[ -f "$DEST_LUA" ]]; then
  rm -f "$DEST_LUA"
  echo "[*] Removed: $DEST_LUA"
else
  echo "[*] Not found: $DEST_LUA"
fi

echo "[*] Done. Restart VLC."
