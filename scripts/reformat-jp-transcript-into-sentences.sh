#!/usr/bin/env bash
# 
# Usage: reformat-jp-transcript-into-sentences.sh input.srt [output.txt]
#
# If output.txt is missing then the output goes to stdout.

set -euo pipefail

# --- Arguments ---
input="${1:?Error: Please provide input SRT file}"
output="${2:-}"  # optional; empty means stdout

# --- Prepare output stream ---
if [[ -n "$output" ]]; then
    exec >"$output"
fi

# --- Process SRT ---

# --- AWK processing explanation ---
# 
# BEGIN ... END
#   This part removes all ASCII whitespace, collapses multiple Japanese spaces into one and accumulates everything into a single line.
#
# The rest ...
#  - preserves double ellipsis (to avoid breaking a line here)
#  - treats various punctuation as a place to break a line
#  - makes sure that the puncuation itelf is output and not lost
#
# The intention is to avoid splitting in the middle of something that might be a word so tha tsubsequent vocabulary mining is simpler

awk '
BEGIN { line = "" }
{
    gsub(/[[:space:]]+/, "")                # remove ASCII whitespace
    gsub(/\xE3\x80\x80+/, "\xE3\x80\x80")  # collapse Japanese ideographic spaces
    line = line $0
}
END {
    out = ""
    n = length(line)
    i = 1
    while (i <= n) {
        # Check for double ellipsis
        if (substr(line,i,2) == "……") {
            out = out "……"
            print out
            out = ""
            i += 2
            continue
        }

        # single character
        c = substr(line,i,1)
        out = out c

        if (c ~ /[。！？…]|[?！]|、|[（）「」『』]/) {
            print out
            out = ""
        }
        i++
    }
    if (out != "") print out
}
' "$input"
