# Prompteria Alfred Workflow

Search and copy prompts from your Prompteria library directly from Alfred.

## Installation

1. Double-click `Prompteria.alfredworkflow` (a zip package) to import it into Alfred
2. Ensure [Prompteria](https://github.com/fortin/prompteria) is installed and you have created some prompts

## Usage

**Search prompts:** Type `prompts` to search, then ↩ to copy the selected prompt to clipboard.

**Add prompt:** Type `add-prompt` to add clipboard content as a new prompt. You'll be prompted for:
- Title (required)
- Description (optional)
- Folder (optional; leave empty for Inbox)

## Requirements

- Alfred 5 with Powerpack
- Prompteria app with prompts created
- macOS (sqlite3 and Python 3 are built-in)

## Development

**Rebuilding the workflow:** After editing files in `workflow/`, run `./build.sh` to regenerate `Prompteria.alfredworkflow`.

The workflow uses `search_prompts.sh` which queries the Prompteria SQLite database at:

- `~/Library/Application Support/Prompteria/prompts.db` (standard)
- `~/Library/Containers/com.prompteria.app/Data/Library/Application Support/Prompteria/prompts.db` (App Store/sandboxed)

You can run the script standalone for testing:

```bash
./search_prompts.sh "search term"
# or
./workflow/search_prompts.sh "search term"
```
