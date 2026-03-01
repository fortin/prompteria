#!/bin/bash
# Receives path to JSON file (title + prompt) or plain prompt text from Alfred.
# Opens prompteria://fill-template?file=PATH.
# Outputs prompt for Copy to Clipboard fallback.
#
# To use Xcode build instead of /Applications: create prompteria_app_path.txt in this
# workflow folder with the path to Prompteria.app (e.g. ~/Library/Developer/.../Build/Products/Debug/Prompteria.app)
#
# To use installed app in /Applications: remove prompteria_app_path.txt (or leave it absent)
input="$1"
[[ -z "$input" ]] && exit 1

# If input is a path to existing file, use it; else treat as prompt text and write to temp file
if [[ -f "$input" ]]; then
    file_path="$input"
    prompt=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('prompt',''))" "$file_path" 2>/dev/null || cat "$file_path")
else
    tmp="/tmp/prompteria-alfred-prompt.txt"
    printf '%s' "$input" > "$tmp"
    file_path="$tmp"
    prompt="$input"
fi

file_path_encoded=$(printf '%s' "$file_path" | python3 -c "import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))")
url="prompteria://fill-template?file=$file_path_encoded"

# Use custom app path if set (for Xcode build); otherwise use installed app by bundle ID
workflow_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$workflow_dir/prompteria_app_path.txt" ]]; then
    app_path=$(cat "$workflow_dir/prompteria_app_path.txt" | sed 's|^~|'"$HOME"'|' | tr -d '\n')
    if [[ -d "$app_path" ]]; then
        open -a "$app_path" "$url"
    else
        open -b com.prompteria.app "$url" 2>/dev/null || open "$url"
    fi
else
    open -b com.prompteria.app "$url" 2>/dev/null || open "$url"
fi
printf '%s' "$prompt"
