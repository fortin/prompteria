#!/bin/bash
# Sync Prompteria workflow files to Alfred's workflow folder.
# Run this after pulling changes to update an already-imported workflow.
# Usage: ./install_workflow.sh [workflow_uid]
# If workflow_uid is omitted, finds the workflow by bundleid com.fort.prompteria.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_SRC="$SCRIPT_DIR/workflow"
ALFRED_PREFS="${alfred_preferences:-}"
if [[ -z "$ALFRED_PREFS" ]]; then
    for p in "$HOME/Library/Application Support/Alfred/Alfred.alfredpreferences" \
             "$HOME/Dropbox/Alfred/Alfred.alfredpreferences"; do
        if [[ -d "$p/workflows" ]]; then
            ALFRED_PREFS="$p"
            break
        fi
    done
fi
WORKFLOWS_DIR="$ALFRED_PREFS/workflows"

if [[ ! -d "$WORKFLOWS_DIR" ]]; then
    echo "Alfred workflows dir not found: $WORKFLOWS_DIR"
    exit 1
fi

if [[ -n "$1" ]]; then
    DEST="$WORKFLOWS_DIR/user.workflow.$1"
else
    DEST=$(grep -l "com.fort.prompteria" "$WORKFLOWS_DIR"/user.workflow.*/info.plist 2>/dev/null | head -1)
    DEST="${DEST%/info.plist}"
fi

if [[ -z "$DEST" || ! -d "$DEST" ]]; then
    echo "Prompteria workflow not found. Import Prompteria.alfredworkflow first."
    exit 1
fi

echo "Installing to: $DEST"
cp "$WORKFLOW_SRC/info.plist" "$DEST/"
cp "$WORKFLOW_SRC/open_fill_template.sh" "$DEST/"
cp "$WORKFLOW_SRC/search_prompts.sh" "$DEST/"
cp "$WORKFLOW_SRC/add_prompt.sh" "$DEST/"
cp "$WORKFLOW_SRC/icon.png" "$DEST/" 2>/dev/null || true
chmod +x "$DEST/open_fill_template.sh" "$DEST/search_prompts.sh" "$DEST/add_prompt.sh"
# Force category to Productivity (Alfred may reset on import)
/usr/libexec/PlistBuddy -c "Set :category Productivity" "$DEST/info.plist" 2>/dev/null || true
echo "Done."