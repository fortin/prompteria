# Promptastic Database Schema

This document describes the SQLite database schema used by Promptastic. The MCP server and other integrations connect to the same database at:

```
~/Library/Application Support/Promptastic/prompts.db
```

**Note:** If the app is sandboxed (App Store build), the path is:
```
~/Library/Containers/com.promptastic.app/Data/Library/Application Support/Promptastic/prompts.db
```

## Configuration

- **Journal mode:** WAL (Write-Ahead Logging) for safe concurrent access
- **IDs:** UUID strings (TEXT)

## Tables

### folders

| Column     | Type    | Constraints |
|------------|---------|--------------|
| id         | TEXT    | PRIMARY KEY  |
| parent_id  | TEXT    | nullable     |
| name       | TEXT    | NOT NULL     |
| emoji      | TEXT    | nullable     |
| color      | TEXT    | nullable (hex) |
| sort_order | INTEGER | NOT NULL, default 0 |
| created_at | REAL    | NOT NULL (Unix timestamp) |
| updated_at | REAL    | NOT NULL (Unix timestamp) |

### prompts

| Column     | Type    | Constraints |
|------------|---------|--------------|
| id         | TEXT    | PRIMARY KEY  |
| folder_id  | TEXT    | NOT NULL, FK → folders.id ON DELETE CASCADE |
| title      | TEXT    | NOT NULL     |
| prompt     | TEXT    | NOT NULL     |
| description| TEXT    | nullable     |
| notes      | TEXT    | nullable     |
| emoji      | TEXT    | nullable     |
| color      | TEXT    | nullable (hex) |
| is_favorite| INTEGER | NOT NULL, 0 or 1 |
| sort_order | INTEGER | NOT NULL, default 0 |
| created_at | REAL    | NOT NULL (Unix timestamp) |
| updated_at | REAL    | NOT NULL (Unix timestamp) |

### prompts_fts (FTS5 virtual table)

Full-text search index on prompts. Columns: `title`, `prompt`, `description`, `notes`.

- **content:** prompts (external content table)
- **content_rowid:** rowid
- Kept in sync via triggers: `prompts_fts_ai`, `prompts_fts_ad`, `prompts_fts_au`

## Indexes

- `idx_prompts_folder_id` on prompts(folder_id)
- `idx_prompts_is_favorite` on prompts(is_favorite)

## MCP Server Tools Reference

| Tool           | Type  | Description                    |
|----------------|-------|--------------------------------|
| list_folders   | Read  | Get all folders with metadata |
| list_prompts   | Read  | Get prompts from folder       |
| get_prompt     | Read  | Get single prompt by ID       |
| search_prompts | Read  | Full-text search              |
| create_prompt  | Write | Create new prompt            |
| update_prompt  | Write | Modify existing prompt        |
| delete_prompt  | Write | Delete prompt                 |
| create_folder  | Write | Create new folder             |
| update_folder  | Write | Modify folder                 |
| delete_folder  | Write | Delete folder                 |
| move_prompt    | Write | Move prompt to folder         |
