#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_LUA="$PROJECT_DIR/lua/playlist/youtube.lua"
DEST_DIR="$HOME/.local/share/vlc/lua/playlist"
DEST_LUA="$DEST_DIR/youtube.lua"
LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_YTDLP="$LOCAL_BIN_DIR/yt-dlp"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--yt-dlp-path /absolute/path/to/yt-dlp] [--no-install-yt-dlp]

Installs youtube.lua override for VLC into:
  $DEST_LUA

Optional:
  --yt-dlp-path PATH   Create/update ~/.local/bin/yt-dlp wrapper pointing to PATH
  --no-install-yt-dlp  Do not auto-install yt-dlp when missing
EOF
}

YTDLP_PATH=""
NO_INSTALL_YTDLP=0
if [[ ${1:-} == "--help" || ${1:-} == "-h" ]]; then
  usage
  exit 0
fi
if [[ ${1:-} == "--yt-dlp-path" ]]; then
  YTDLP_PATH="${2:-}"
  if [[ -z "$YTDLP_PATH" ]]; then
    echo "[!] Missing value for --yt-dlp-path" >&2
    exit 1
  fi
elif [[ ${1:-} == "--no-install-yt-dlp" ]]; then
  NO_INSTALL_YTDLP=1
fi

mkdir -p "$DEST_DIR"
cp "$SRC_LUA" "$DEST_LUA"

echo "[*] Installed: $DEST_LUA"

if [[ -n "$YTDLP_PATH" ]]; then
  if [[ ! -x "$YTDLP_PATH" ]]; then
    echo "[!] Not executable: $YTDLP_PATH" >&2
    exit 1
  fi
  mkdir -p "$LOCAL_BIN_DIR"
  cat > "$LOCAL_YTDLP" <<WRAP
#!/usr/bin/env bash
exec "$YTDLP_PATH" "\$@"
WRAP
  chmod +x "$LOCAL_YTDLP"
  echo "[*] Wrapper created: $LOCAL_YTDLP -> $YTDLP_PATH"
fi

if [[ -z "$YTDLP_PATH" ]]; then
  if command -v yt-dlp >/dev/null 2>&1; then
    echo "[*] yt-dlp found in PATH: $(command -v yt-dlp)"
  elif [[ -x "$LOCAL_YTDLP" ]]; then
    echo "[*] yt-dlp wrapper found: $LOCAL_YTDLP"
  else
    if [[ "$NO_INSTALL_YTDLP" -eq 1 ]]; then
      echo "[!] yt-dlp not found and auto-install disabled (--no-install-yt-dlp)." >&2
      exit 1
    fi

    echo "[*] yt-dlp not found. Installing via python3 -m pip --user ..."
    if ! command -v python3 >/dev/null 2>&1; then
      echo "[!] python3 not found. Install yt-dlp manually and re-run." >&2
      exit 1
    fi

    python3 -m pip install --user -U yt-dlp

    if command -v yt-dlp >/dev/null 2>&1; then
      echo "[*] yt-dlp installed: $(command -v yt-dlp)"
    elif [[ -x "$HOME/.local/bin/yt-dlp" ]]; then
      echo "[*] yt-dlp installed: $HOME/.local/bin/yt-dlp"
      echo "[!] Note: ~/.local/bin may be missing in PATH for this shell."
    else
      echo "[!] Failed to install yt-dlp automatically. Install manually and re-run." >&2
      exit 1
    fi
  fi
fi

echo "[*] Done. Restart VLC."
