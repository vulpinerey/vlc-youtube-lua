-- VLC YouTube resolver via external yt-dlp
-- Install to: ~/.local/share/vlc/lua/playlist/youtube.lua

local function shell_quote(s)
    if s == nil then return "''" end
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function file_is_executable(path)
    if not path or path == "" then return false end
    local p = io.popen("[ -x " .. shell_quote(path) .. " ] && echo 1 || echo 0")
    if not p then return false end
    local out = p:read("*l")
    p:close()
    return out == "1"
end

local function pick_yt_dlp_binary()
    local env_bin = os.getenv("YTDLP_BIN")
    if env_bin and env_bin ~= "" then
        return env_bin
    end

    local home = os.getenv("HOME") or ""
    local candidates = {
        home .. "/.local/bin/yt-dlp",
        "/usr/local/bin/yt-dlp",
        "/usr/bin/yt-dlp",
    }

    for _, c in ipairs(candidates) do
        if file_is_executable(c) then
            return c
        end
    end

    -- last resort: rely on VLC process PATH
    return "yt-dlp"
end

function probe()
    if not (vlc.access == "http" or vlc.access == "https") then
        return false
    end

    return string.match(vlc.path, "^www%.youtube%.com/")
        or string.match(vlc.path, "^youtube%.com/")
        or string.match(vlc.path, "^m%.youtube%.com/")
        or string.match(vlc.path, "^music%.youtube%.com/")
        or string.match(vlc.path, "^youtu%.be/")
end

local function run_yt_dlp_get_urls(binary, youtube_url, format)
    local cmd = string.format(
        "%s --no-playlist --no-warnings -f %s -g -- %s",
        shell_quote(binary),
        shell_quote(format),
        shell_quote(youtube_url)
    )

    vlc.msg.dbg("[yt-dlp youtube.lua] cmd: " .. cmd)

    local p = io.popen(cmd)
    if not p then
        return "", ""
    end

    local first = p:read("*l")
    local second = p:read("*l")
    p:close()

    first = first and first:gsub("^%s+", ""):gsub("%s+$", "") or ""
    second = second and second:gsub("^%s+", ""):gsub("%s+$", "") or ""

    return first, second
end

function parse()
    local ytdlp = pick_yt_dlp_binary()
    local youtube_url = vlc.access .. "://" .. vlc.path

    vlc.msg.dbg("[yt-dlp youtube.lua] using binary: " .. ytdlp)

    -- preferred: split video+audio for better quality
    local video_url, audio_url = run_yt_dlp_get_urls(ytdlp, youtube_url, "bestvideo+bestaudio/best")

    -- fallback: single combined stream (better compatibility)
    if video_url == "" then
        video_url, audio_url = run_yt_dlp_get_urls(ytdlp, youtube_url, "best")
    end

    if video_url == "" then
        vlc.msg.err("yt-dlp returned empty URL for: " .. youtube_url)
        vlc.msg.err("Ensure yt-dlp is installed and reachable by VLC. Optionally set YTDLP_BIN.")
        return {}
    end

    local item = {
        path = video_url,
        name = "YouTube"
    }

    if audio_url ~= "" and audio_url ~= video_url then
        item.options = { ":input-slave=" .. audio_url }
    end

    return { item }
end
