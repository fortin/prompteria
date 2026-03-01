# Prompteria Alfred Workflow

Search and copy prompts from your Prompteria library directly from Alfred.

## Installation

1. Double-click `Prompteria.alfredworkflow` (a zip package) to import it into Alfred
2. Ensure [Prompteria](https://github.com/fortin/prompteria) is installed and you have created some prompts

**Template variables:** Prompts with `{{ varname }}` placeholders will prompt for values before copying. For reliable dialogs (separate field per variable), run the setup script once:

```bash
cd /path/to/prompteria/Alfred/workflow
./setup_env.sh
```

This creates a `prompteria` env at `~/micromamba/envs/prompteria` with Python + tkinter. Uses micromamba, mamba, or conda (whichever is installed).

**Category:** After importing, right-click the workflow in the sidebar and select "Productivity" (Alfred strips category on export, so it may show as Uncategorised).

**Updating:** If connections appear broken after re-importing, remove the existing Prompteria workflow from Alfred Preferences → Workflows first, then import the new `.alfredworkflow` file.

**Testing template variables:** Run `./test_template_vars.sh` in the workflow folder to verify the dialog appears. If it works manually but not from Alfred, grant Alfred "Automation" permission (System Settings → Privacy & Security → Automation) to run shell scripts.

**Testing with Xcode build:** By default the workflow uses the Prompteria app from Launch Services (typically `/Applications`). To test with the version built and run from Xcode:

1. Find your Xcode build path (exclude Index to get the main build):
   ```bash
   find ~/Library/Developer/Xcode/DerivedData -name "Prompteria.app" -path "*/Build/Products/Debug/*" ! -path "*Index*" 2>/dev/null | head -1
   ```
2. In your Alfred workflow folder (right-click workflow → "Open in Finder"), create `prompteria_app_path.txt` containing that path (one line, no quotes).
3. Run `./install_workflow.sh` to sync the updated script.
4. The workflow will now use your Xcode build when opening prompts.

## Usage

**Search prompts:** Type `prompts` to search, then ↩ to copy the selected prompt to clipboard. If the prompt contains template variables (`{{ varname }}`), you'll be prompted for their values in a single dialog before copying.

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
