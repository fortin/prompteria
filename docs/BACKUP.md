# Backup & Restore

Prompteria stores your prompt library in a local SQLite database. This document explains how to back up and restore your data.

## Data Location

```
~/Library/Application Support/Prompteria/prompts.db
```

The database uses SQLite with WAL (Write-Ahead Logging). Related files in the same directory:

- `prompts.db` – main database
- `prompts.db-wal` – write-ahead log (may exist)
- `prompts.db-shm` – shared memory (may exist)

## In-App Backup

1. Open **Settings** (gear icon)
2. Click **Export Library**
3. Choose a location and save the JSON file

The export includes all prompts, folders, and metadata.

## In-App Restore

1. Open **Settings**
2. Click **Import Library**
3. Select a previously exported JSON file

**Warning:** Import merges with existing data. Duplicate prompts may be created if you import the same backup twice. For a clean restore, delete the app data first (see below).

## Manual Backup

To back up the raw database:

```bash
# Create backup
cp ~/Library/Application\ Support/Prompteria/prompts.db ~/Desktop/prompteria-backup.db

# Or copy the entire directory
cp -r ~/Library/Application\ Support/Prompteria ~/Desktop/Prompteria-backup
```

## Clean Restore

To start fresh or restore from a manual backup:

```bash
# Remove existing data
rm -rf ~/Library/Application\ Support/Prompteria

# Restore from backup (if you have one)
mkdir -p ~/Library/Application\ Support/Prompteria
cp ~/Desktop/prompteria-backup.db ~/Library/Application\ Support/Prompteria/prompts.db
```

Then relaunch Prompteria.

## Schema

See [SCHEMA.md](../SCHEMA.md) for the database structure. The MCP server and other integrations use the same schema.
