# Prompteria

A native macOS app for organizing, searching, and managing your AI prompt library.

## Features

- **Folder Organization** – Create folders to organize prompts. Drag and drop to reorganize.
- **Instant Search** – Full-text search across titles, prompts, descriptions, and notes.
- **Visual Customization** – 300+ emoji icons and custom colors for prompts and folders.
- **Multi-Format Preview** – Toggle between editor and preview for Markdown, HTML, JSON, and XML.
- **One-Click Copy** – Copy prompt text to clipboard. Optional auto-copy on select.
- **Backup & Restore** – Export and import your library as JSON.
- **Light & Dark Mode** – System sync or manual override.
- **Per-Prompt Description & Notes** – Track what each prompt does and results.
- **Bulk Operations** – Multi-select with checkboxes, shift-click for ranges, bulk move/export/delete.
- **Favourites** – Star prompts and access via the Favourites smart folder.

## Requirements

- macOS 14.0+
- Xcode 16+ (for building from source)

## Installation

### Option 1: Download Release (Recommended)

1. Go to the [Releases](https://github.com/fortin/prompteria/releases) page
2. Download the latest `Prompteria-*.dmg`
3. Open the DMG and drag Prompteria to Applications
4. **First launch:** Right-click the app → **Open** (required for unsigned builds)

### Option 2: Build from Source

```bash
git clone https://github.com/fortin/prompteria.git
cd prompteria
brew install xcodegen
xcodegen generate
open Prompteria.xcodeproj
# Build and run (⌘R)
```

To create a release DMG:

```bash
./scripts/build-release.sh 1.0.0
```

See [docs/README.md](docs/README.md) for full documentation.

## Data Location

Prompts are stored in:

```
~/Library/Application Support/Prompteria/prompts.db
```

## Built-in Examples

On first launch, Prompteria seeds an `Examples` folder with a small set of structured sample prompts.

- **Source of truth**: All built-in examples are defined in `Prompteria/Resources/Examples/examples-prompts.json`.
- **Editing examples**: Modify that JSON file and rebuild the app to change the default examples for new installs.
- **Seeding behavior**: The app only creates the `Examples` folder if it does not already exist, so user edits to examples are preserved across launches.

## Alfred Integration

To search prompts from Alfred:

1. Create a new Alfred workflow.
2. Add a **Script Filter** input:
   - Keyword: `prompts` (or your choice)
   - Script: `/path/to/prompteria/Alfred/search_prompts.sh`
   - Argument: `{query}`
   - Language: `/bin/bash`
3. Add a **Run Script** action connected to the Script Filter:
   - Script: `echo "{query}" | pbcopy`
   - Or use `{arg}` to copy the selected prompt text (the `arg` from Alfred contains the full prompt text).
4. For "Open in Prompteria", add an action that runs: `open "prompteria://prompt/{uid}"`

The `search_prompts.sh` script outputs Alfred JSON. The `arg` field contains the full prompt text for copying. The pre-built `Prompteria.alfredworkflow` includes template variable support: prompts with `{{ varname }}` placeholders will prompt for values in a single dialog before copying.

## Linking to Prompts

You can link to any prompt for use in other apps, notes, or Hookmark.

### Context Menu

Right-click a prompt and choose **Link to prompt** to copy its URL (`prompteria://prompt/{id}`) to the clipboard. Paste it anywhere to create a link that opens that prompt in Prompteria.

### URL Scheme

- `prompteria://prompt/{id}` – Opens the app and selects the prompt with the given ID.

### Hookmark Integration

Prompteria supports [Hookmark](https://hookproductivity.com/) for linking prompts to other apps. To add Prompteria to Hookmark:

1. Open Hookmark → **Preferences** → **Scripts**
2. Add a new app entry for Prompteria
3. In **Get Address**, paste:

```applescript
tell application "Prompteria" to fetch link
```

4. Leave **Open Item** blank—`prompteria://prompt/{id}` opens directly via the system.

## MCP Server

The Prompteria MCP Server (separate repository) enables AI assistants to read and write your prompt library. See [SCHEMA.md](SCHEMA.md) for the database schema used by the MCP server.

## License

CC0 1.0 Universal
