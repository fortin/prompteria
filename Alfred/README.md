# Promptastic Alfred Workflow

Search and copy prompts from your Promptastic library directly from Alfred.

## Installation

1. Double-click `Promptastic.alfredworkflow` (a zip package) to import it into Alfred
2. Ensure [Promptastic](https://github.com/promptastic) is installed and you have created some prompts

## Usage

**Search prompts:** Type `prompts` to search, then ↩ to copy the selected prompt to clipboard.

**Add prompt:** Type `add-prompt` to add clipboard content as a new prompt. You'll be prompted for:
- Title (required)
- Description (optional)
- Folder (optional; leave empty for Inbox)

## Requirements

- Alfred 5 with Powerpack
- Promptastic app with prompts created
- macOS (sqlite3 and Python 3 are built-in)

## Development

**Rebuilding the workflow:** After editing files in `workflow/`, run `./build.sh` to regenerate `Promptastic.alfredworkflow`.

The workflow uses `search_prompts.sh` which queries the Promptastic SQLite database at:

- `~/Library/Application Support/Promptastic/prompts.db` (standard)
- `~/Library/Containers/com.promptastic.app/Data/Library/Application Support/Promptastic/prompts.db` (App Store/sandboxed)

You can run the script standalone for testing:

```bash
./search_prompts.sh "search term"
# or
./workflow/search_prompts.sh "search term"
```
