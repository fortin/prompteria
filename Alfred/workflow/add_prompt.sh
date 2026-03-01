#!/bin/bash
# Alfred workflow: Add clipboard content as a new prompt to Promptastic
# Prompts for title, description, folder. Uses Inbox if no folder specified.

# Alfred may run with minimal env (HOME unset); derive from alfred_preferences
if [[ -z "$HOME" && -n "$alfred_preferences" ]]; then
    export HOME=$(echo "$alfred_preferences" | cut -d'/' -f1-3)
fi
[[ -z "$HOME" ]] && export HOME=$(eval echo ~$(id -un 2>/dev/null))

# Database path
DB_STANDARD="$HOME/Library/Application Support/Promptastic/prompts.db"
DB_SANDBOXED="$HOME/Library/Containers/com.promptastic.app/Data/Library/Application Support/Promptastic/prompts.db"
DB_PATH=""
[[ -f "$DB_STANDARD" ]] && DB_PATH="$DB_STANDARD"
[[ -z "$DB_PATH" && -f "$DB_SANDBOXED" ]] && DB_PATH="$DB_SANDBOXED"

if [[ -z "$DB_PATH" ]]; then
    osascript -e 'display alert "Promptastic" message "Database not found. Install Promptastic and create some prompts first."'
    exit 1
fi

# Get clipboard content
PROMPT_TEXT=$(pbpaste 2>/dev/null)
if [[ -z "$PROMPT_TEXT" ]]; then
    osascript -e 'display alert "Promptastic" message "Clipboard is empty. Copy some text first, then run add-prompt."'
    exit 1
fi

# Prompt for title (required)
TITLE=$(osascript 2>/dev/null <<'APPLESCRIPT'
set d to display dialog "Enter prompt title:" default answer "" with title "Add Prompt to Promptastic" with icon note buttons {"Cancel", "OK"} default button "OK"
if button returned of d is "Cancel" then return "CANCEL"
return text returned of d
APPLESCRIPT
)
[[ "$TITLE" == "CANCEL" ]] && exit 0
[[ -z "$TITLE" ]] && TITLE="Untitled"

# Prompt for description (optional)
DESCRIPTION=$(osascript 2>/dev/null <<'APPLESCRIPT'
set d to display dialog "Enter description (optional):" default answer "" with title "Add Prompt to Promptastic" with icon note buttons {"Skip", "OK"} default button "OK"
if button returned of d is "Skip" then
    return ""
else
    return text returned of d
end if
APPLESCRIPT
)

# Prompt for folder (optional, empty = Inbox)
FOLDER_NAME=$(osascript 2>/dev/null <<'APPLESCRIPT'
set d to display dialog "Enter folder name (leave empty for Inbox):" default answer "" with title "Add Prompt to Promptastic" with icon note buttons {"Cancel", "OK"} default button "OK"
if button returned of d is "Cancel" then return "CANCEL"
set t to text returned of d
if t is "" then return "Inbox"
return t
APPLESCRIPT
)
[[ "$FOLDER_NAME" == "CANCEL" ]] && exit 0
[[ -z "$FOLDER_NAME" ]] && FOLDER_NAME="Inbox"

# Escape for SQL
escape_sql() {
    echo "$1" | sed "s/'/''/g"
}
TITLE_ESC=$(escape_sql "$TITLE")
DESCRIPTION_ESC=$(escape_sql "$DESCRIPTION")
PROMPT_ESC=$(escape_sql "$PROMPT_TEXT")
FOLDER_ESC=$(escape_sql "$FOLDER_NAME")

# Get or create folder
FOLDER_ID=$(sqlite3 "$DB_PATH" "SELECT id FROM folders WHERE name = '$FOLDER_ESC' LIMIT 1" 2>/dev/null)

if [[ -z "$FOLDER_ID" ]]; then
    FOLDER_ID=$(uuidgen 2>/dev/null || echo "folder-$(date +%s)-$$")
    FOLDER_ESC_CREATE=$(escape_sql "$FOLDER_NAME")
    sqlite3 "$DB_PATH" "INSERT INTO folders (id, parent_id, name, emoji, color, sort_order, created_at, updated_at) VALUES ('$FOLDER_ID', NULL, '$FOLDER_ESC_CREATE', NULL, NULL, 0, datetime('now'), datetime('now'))" 2>/dev/null
fi

# Generate prompt ID and insert
PROMPT_ID=$(uuidgen 2>/dev/null || echo "prompt-$(date +%s)-$$")
sqlite3 "$DB_PATH" "INSERT INTO prompts (id, folder_id, title, prompt, description, notes, emoji, color, is_favorite, sort_order, created_at, updated_at) VALUES ('$PROMPT_ID', '$FOLDER_ID', '$TITLE_ESC', '$PROMPT_ESC', '$DESCRIPTION_ESC', NULL, NULL, NULL, 0, 0, datetime('now'), datetime('now'))" 2>/dev/null

if [[ $? -eq 0 ]]; then
    osascript -e "display notification \"Added to $FOLDER_NAME\" with title \"Promptastic\""
else
    osascript -e 'display alert "Promptastic" message "Failed to add prompt to database."'
    exit 1
fi
