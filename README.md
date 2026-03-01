# Promptastic

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

1. Go to the [Releases](https://github.com/fortin/promptastic/releases) page
2. Download the latest `Promptastic-*.dmg`
3. Open the DMG and drag Promptastic to Applications
4. **First launch:** Right-click the app → **Open** (required for unsigned builds)

### Option 2: Build from Source

```bash
git clone https://github.com/fortin/promptastic.git
cd promptastic
brew install xcodegen
xcodegen generate
open Promptastic.xcodeproj
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
~/Library/Application Support/Promptastic/prompts.db
```

## Alfred Integration

To search prompts from Alfred:

1. Create a new Alfred workflow.
2. Add a **Script Filter** input:
   - Keyword: `prompts` (or your choice)
   - Script: `/path/to/promptastic/Alfred/search_prompts.sh`
   - Argument: `{query}`
   - Language: `/bin/bash`
3. Add a **Run Script** action connected to the Script Filter:
   - Script: `echo "{query}" | pbcopy`
   - Or use `{arg}` to copy the selected prompt text (the `arg` from Alfred contains the full prompt text).
4. For "Open in Promptastic", add an action that runs: `open "promptastic://prompt/{uid}"`

The `search_prompts.sh` script outputs Alfred JSON. The `arg` field contains the full prompt text for copying.

## URL Scheme

- `promptastic://prompt/{id}` – Opens the app and selects the prompt with the given ID.

## MCP Server

The Promptastic MCP Server (separate repository) enables AI assistants to read and write your prompt library. See [SCHEMA.md](SCHEMA.md) for the database schema used by the MCP server.

## License

CC0 1.0 Universal
