#!/bin/bash
# Alfred workflow: Copy prompt to clipboard, with template variable substitution
# Receives prompt on stdin. If prompt contains {{ varname }} placeholders,
# prompts for all values (requires Python with tkinter), renders the template,
# then outputs the result for the clipboard.
#
# Runs via AppleScript "do shell script" to get proper GUI context for dialogs.

# Alfred may run with minimal env (HOME unset); derive from alfred_preferences
if [[ -z "$HOME" && -n "$alfred_preferences" ]]; then
    export HOME=$(echo "$alfred_preferences" | cut -d'/' -f1-3)
fi
[[ -z "$HOME" ]] && export HOME=$(eval echo ~$(id -un 2>/dev/null))

WORKFLOW_DIR="$(cd "$(dirname "$0")" && pwd)"
PYTHON_SCRIPT="$WORKFLOW_DIR/copy_prompt.py"

# Find Python with tkinter
ENV_PYTHON=""
for p in \
    "$HOME/micromamba/envs/prompteria/bin/python" \
    "$HOME/mambaforge/envs/prompteria/bin/python" \
    "$HOME/miniconda3/envs/prompteria/bin/python" \
    "$HOME/anaconda3/envs/prompteria/bin/python"
do
    if [[ -x "$p" ]]; then
        ENV_PYTHON="$p"
        break
    fi
done
[[ -z "$ENV_PYTHON" ]] && ENV_PYTHON="python3"

# Write prompt to temp file (handles special chars)
TMPF=$(mktemp)
trap 'rm -f "$TMPF"' EXIT
cat > "$TMPF"

# Run via osascript "do shell script" - gets proper GUI context for tkinter dialogs.
# If that fails (e.g. permission), fall back to direct execution.
if ! output=$(osascript -e "
set promptFile to \"$TMPF\"
set pythonPath to \"$ENV_PYTHON\"
set scriptPath to \"$PYTHON_SCRIPT\"
do shell script \"cat \" & quoted form of promptFile & \" | \" & quoted form of pythonPath & \" \" & quoted form of scriptPath
" 2>/dev/null); then
    # Fallback: run directly (dialogs may not appear)
    cat "$TMPF" | "$ENV_PYTHON" "$PYTHON_SCRIPT"
else
    printf '%s' "$output"
fi
