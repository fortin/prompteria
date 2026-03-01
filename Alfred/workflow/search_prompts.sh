#!/bin/bash
# Alfred Script Filter for Prompteria
# Queries prompts.db and outputs Alfred JSON format
# Usage: ./search_prompts.sh [query]
# Output: Alfred Script Filter JSON with prompt items
# Action: Copy prompt text to clipboard. arg contains the full prompt text.

# Alfred may run with minimal env (HOME unset); derive from alfred_preferences
if [[ -z "$HOME" && -n "$alfred_preferences" ]]; then
    export HOME=$(echo "$alfred_preferences" | cut -d'/' -f1-3)
fi
[[ -z "$HOME" ]] && export HOME=$(eval echo ~$(id -un 2>/dev/null))

# Check both standard and sandboxed (App Store) database paths
DB_STANDARD="$HOME/Library/Application Support/Prompteria/prompts.db"
DB_SANDBOXED="$HOME/Library/Containers/com.prompteria.app/Data/Library/Application Support/Prompteria/prompts.db"

QUERY="${1:-}"

# Prefer standard path; fall back to sandboxed if standard doesn't exist
if [[ -f "$DB_STANDARD" ]]; then
    DB_PATH="$DB_STANDARD"
elif [[ -f "$DB_SANDBOXED" ]]; then
    DB_PATH="$DB_SANDBOXED"
else
    echo '{"items":[{"title":"Prompteria database not found","subtitle":"Install Prompteria and create some prompts first","valid":false}]}'
    exit 0
fi

if [[ -z "$QUERY" ]]; then
    SQL="SELECT p.id, p.title, p.prompt, f.name as folder_name FROM prompts p LEFT JOIN folders f ON p.folder_id = f.id ORDER BY p.updated_at DESC LIMIT 50"
else
    # Use FTS5 for full-text search (title, prompt, description, notes)
    # Escape for FTS5: " -> ""; escape for SQL: ' -> ''
    FTS_TERM=$(echo "$QUERY" | sed 's/"/""/g' | sed "s/'/''/g")
    SQL_FTS="SELECT p.id, p.title, p.prompt, f.name as folder_name FROM prompts_fts JOIN prompts p ON p.rowid = prompts_fts.rowid LEFT JOIN folders f ON p.folder_id = f.id WHERE prompts_fts MATCH '$FTS_TERM' ORDER BY p.updated_at DESC LIMIT 30"
    # Fallback: LIKE search if FTS5 fails (e.g. older DB without FTS5)
    ESCAPED=$(echo "$QUERY" | sed "s/'/''/g")
    SQL_LIKE="SELECT p.id, p.title, p.prompt, f.name as folder_name FROM prompts p LEFT JOIN folders f ON p.folder_id = f.id WHERE p.title LIKE '%$ESCAPED%' OR p.prompt LIKE '%$ESCAPED%' OR COALESCE(p.description,'') LIKE '%$ESCAPED%' OR COALESCE(p.notes,'') LIKE '%$ESCAPED%' ORDER BY p.updated_at DESC LIMIT 30"
fi

# Use sqlite3 -json and pass to Python via stdin for safe handling
run_query() {
    local db="$1"
    if [[ -z "$QUERY" ]]; then
        sqlite3 -json "$db" "$SQL" 2>/dev/null
    else
        local r
        r=$(sqlite3 -json "$db" "$SQL_FTS" 2>/dev/null)
        if [[ -z "$r" || "$r" == "[]" ]]; then
            r=$(sqlite3 -json "$db" "$SQL_LIKE" 2>/dev/null)
        fi
        echo "$r"
    fi
}

RESULTS=$(run_query "$DB_PATH")
# If no results, try the other database path (in case app uses sandboxed/standard)
if [[ -z "$RESULTS" || "$RESULTS" == "[]" ]]; then
    OTHER_DB=""
    [[ "$DB_PATH" == "$DB_STANDARD" ]] && OTHER_DB="$DB_SANDBOXED"
    [[ "$DB_PATH" == "$DB_SANDBOXED" ]] && OTHER_DB="$DB_STANDARD"
    if [[ -n "$OTHER_DB" && -f "$OTHER_DB" ]]; then
        RESULTS=$(run_query "$OTHER_DB")
    fi
fi

if [[ -z "$RESULTS" || "$RESULTS" == "[]" ]]; then
    # Debug: write to workflow folder and stderr (visible in Alfred debugger)
    WORKFLOW_DIR="$(cd "$(dirname "$0")" && pwd)"
    DEBUG_FILE="$WORKFLOW_DIR/prompteria-debug.txt"
    {
        echo "=== $(date) ==="
        echo "Script: $0 | WORKFLOW_DIR=$WORKFLOW_DIR"
        echo "HOME=$HOME"
        echo "alfred_preferences=$alfred_preferences"
        echo "QUERY=$QUERY"
        echo "DB_STANDARD=$DB_STANDARD (exists: $( [[ -f "$DB_STANDARD" ]] && echo yes || echo no ))"
        echo "DB_SANDBOXED=$DB_SANDBOXED (exists: $( [[ -f "$DB_SANDBOXED" ]] && echo yes || echo no ))"
        echo "DB_PATH=$DB_PATH"
        if [[ -n "$QUERY" && -n "$SQL_FTS" ]]; then
            echo "--- FTS result ---"
            sqlite3 -json "$DB_PATH" "$SQL_FTS" 2>&1 | head -c 500
            echo ""
            echo "--- LIKE result ---"
            sqlite3 -json "$DB_PATH" "$SQL_LIKE" 2>&1 | head -c 500
        fi
    } > "$DEBUG_FILE" 2>&1
    echo "Debug: $DEBUG_FILE" >&2
    echo "{\"items\":[{\"title\":\"No prompts found\",\"subtitle\":\"Debug: $DEBUG_FILE\",\"valid\":false}]}"
    exit 0
fi

echo "$RESULTS" | python3 -c "
import json
import sys

try:
    rows = json.load(sys.stdin)
except:
    print('{\"items\":[{\"title\":\"Error parsing results\",\"valid\":false}]}')
    sys.exit(0)

items = []
for row in rows:
    prompt_id = row.get('id', '')
    title = row.get('title', 'Untitled')
    prompt_text = row.get('prompt', '')
    folder = row.get('folder_name', '')
    subtitle = folder if folder else 'No folder'
    if len(prompt_text) > 80:
        subtitle += ' • ' + prompt_text[:77] + '...'
    subtitle += ' • Action to copy prompt to clipboard'
    items.append({
        'title': title,
        'subtitle': subtitle,
        'arg': prompt_text,
        'uid': prompt_id,
        'valid': True
    })

print(json.dumps({'items': items}))
"
