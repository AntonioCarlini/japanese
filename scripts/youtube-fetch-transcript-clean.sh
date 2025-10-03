#!/usr/bin/env bash
#
# Download and deduplicate auto-subtitles from YouTube.
# Only tested with Japanese videos but no obvious reason why it wouldn't work with anything.
#
# Usage: yt-sub-clean.sh [--keep-timestamps] <url-or-id> [output.srt]
#
# Use
#    YT_DLP_PATH=/path/to/yt-dlp  yt-sub-clean.sh ...
# to force a specific yt-dlp to be used.
# I find the one in the Linux Mint archives is quite old, so I need to override it.
#
# Notes:
#
# Right now deduplication isn't working properly.

set -euo pipefail

# Use the system installed yt-dlp if one exists.
# Otherwise default to $HOME/Downloads.
# However, in either case if the users specifies YT_DLP+PATH=abc on the command line, use that.
if [ -n "${YT_DLP_PATH+x}" ]; then
    # User explicitly supplied a path so honour it
    YT_DLP_PATH="${YT_DLP_PATH%/}"   # strip trailing slash
    YT_DLP="${YT_DLP_PATH}/yt-dlp"
else
    # No override from the command line, auto-detect yt-dlp on PATH otherwise usedefault
    if command -v yt-dlp >/dev/null 2>&1; then
        YT_DLP="$(command -v yt-dlp)"
    else
        YT_DLP_PATH="$HOME/Downloads"
        YT_DLP="${YT_DLP_PATH}/yt-dlp"
    fi
fi

# ---- Helpers ----
die() {
  echo "Error: $*" >&2
  exit 1
}

# ---- Handle Args ----
keep_ts=false
if [[ "${1:-}" == "--keep-timestamps" ]]; then
  keep_ts=true
  shift
fi

[[ $# -lt 1 ]] && die "Need at least one argument (YouTube URL or video ID)."

input="$1"
output="${2:-}"

# ---- Extract video ID ----
if [[ "$input" =~ ^https?:// ]]; then
  if [[ "$input" =~ v=([a-zA-Z0-9_-]{11}) ]]; then
    videoid="${BASH_REMATCH[1]}"
  elif [[ "$input" =~ youtu\.be/([a-zA-Z0-9_-]{11}) ]]; then
    videoid="${BASH_REMATCH[1]}"
  else
    die "Could not extract video ID from URL: $input"
  fi
else
  videoid="$input"
fi

# ---- Output filename ----
outfile="${output:-${videoid}.srt}"

# ---- Temp dir and file ----
tmpdir="${HOME}/tmp"
mkdir -p "$tmpdir"
rawfile="${tmpdir}/Youtube-${videoid}.ja.srt"

# ---- Fetch subtitles ----
"${YT_DLP}" \
  --write-auto-sub \
  --sub-lang ja \
  --skip-download \
  --convert-subs srt \
  -o "${tmpdir}/Youtube-${videoid}.%(ext)s" \
  "https://www.youtube.com/watch?v=${videoid}"

[[ ! -s "$rawfile" ]] && die "Subtitle file not created: $rawfile"

# ---- Deduplicate ----
if $keep_ts; then
  # Keep timestamps but drop duplicate *blocks*
  awk '
    BEGIN { RS=""; ORS="\n\n" }   # Paragraph mode (SRT blocks)
    {
      sub(/^[ \t\r\n]+/, "", $0); sub(/[ \t\r\n]+$/, "", $0)
      if ($0 != prev) { print; prev=$0 }
    }
  ' "$rawfile" > "$outfile"
else
    # Strip timestamps and dedupe lines
    uconv -f utf-8 -t utf-8 -x 'Any-NFC' "$rawfile" \
  | sed -E '/^[0-9]+$/d; /^[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}$/d; s/^[[:space:]]+//; s/[[:space:]]+$//; s/[()]//g' \
  | awk 'NF && !seen[$0]++' \
  > "$outfile"
fi
