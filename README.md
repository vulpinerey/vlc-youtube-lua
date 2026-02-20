# VLC YouTube + yt-dlp bridge

User-local project to fix VLC 3.x YouTube throttling/descramble issues by replacing VLC's YouTube Lua resolver with a script that delegates URL extraction to `yt-dlp`.

## What this does

- Installs custom `youtube.lua` into user scope:
  - `~/.local/share/vlc/lua/playlist/youtube.lua`
- Keeps system VLC package untouched.
- Uses `yt-dlp` to resolve playable stream URL(s) for YouTube links.

## Project structure

- `lua/playlist/youtube.lua` — resolver script
- `scripts/install.sh` — install helper
- `scripts/uninstall.sh` — remove helper

## Requirements

- VLC 3.x (or compatible Lua playlist loading)
- `yt-dlp` available either:
  - in PATH, or
  - via `YTDLP_BIN=/absolute/path/to/yt-dlp`, or
  - through optional wrapper created by installer (`~/.local/bin/yt-dlp`)

## Install

From project root:

1) Make installer executable:

```bash
chmod +x scripts/install.sh scripts/uninstall.sh
```

2) Install script only:

```bash
./scripts/install.sh
```

`install.sh` now checks `yt-dlp` and auto-installs it with `python3 -m pip --user -U yt-dlp` when missing.

3) Optional: install and pin specific yt-dlp binary:

```bash
./scripts/install.sh --yt-dlp-path /absolute/path/to/yt-dlp
```

4) Optional: disable auto-install check/install:

```bash
./scripts/install.sh --no-install-yt-dlp
```

5) Restart VLC.

## Uninstall

```bash
./scripts/uninstall.sh
```

Then restart VLC.

## Verify

Run:

```bash
cvlc -I dummy --play-and-exit --verbose=2 "https://www.youtube.com/watch?v=dQw4w9WgXcQ" 2>&1 | grep -Ei "youtube.lua|yt-dlp"
```

You should see lines indicating VLC is loading:
- `~/.local/share/vlc/lua/playlist/youtube.lua`
- command execution via `yt-dlp`

## Notes

- This is a user-local override. It takes precedence over packaged `youtube.luac`.
- If VLC still cannot find `yt-dlp`, set env before launch:

```bash
export YTDLP_BIN=/absolute/path/to/yt-dlp
vlc
```
