import Foundation
import GRDB

enum Schema {
    static func createTables(_ db: Database) throws {
        try db.create(table: "folders") { t in
            t.primaryKey("id", .text)
            t.column("parent_id", .text)
            t.column("name", .text).notNull()
            t.column("emoji", .text)
            t.column("color", .text)
            t.column("sort_order", .integer).notNull().defaults(to: 0)
            t.column("created_at", .datetime).notNull()
            t.column("updated_at", .datetime).notNull()
        }

        try db.create(table: "prompts") { t in
            t.primaryKey("id", .text)
            t.column("folder_id", .text).notNull().references("folders", column: "id", onDelete: .cascade)
            t.column("title", .text).notNull()
            t.column("prompt", .text).notNull()
            t.column("description", .text)
            t.column("notes", .text)
            t.column("emoji", .text)
            t.column("color", .text)
            t.column("is_favorite", .integer).notNull().defaults(to: 0)
            t.column("sort_order", .integer).notNull().defaults(to: 0)
            t.column("created_at", .datetime).notNull()
            t.column("updated_at", .datetime).notNull()
        }

        try db.create(index: "idx_prompts_folder_id", on: "prompts", columns: ["folder_id"])
        try db.create(index: "idx_prompts_is_favorite", on: "prompts", columns: ["is_favorite"])

        // FTS5 for full-text search (external content table)
        try db.execute(sql: """
            CREATE VIRTUAL TABLE prompts_fts USING fts5(
                title, prompt, description, notes,
                content='prompts',
                content_rowid='rowid'
            );
            CREATE TRIGGER prompts_fts_ai AFTER INSERT ON prompts BEGIN
                INSERT INTO prompts_fts(rowid, title, prompt, description, notes)
                VALUES (new.rowid, new.title, new.prompt, coalesce(new.description,''), coalesce(new.notes,''));
            END;
            CREATE TRIGGER prompts_fts_ad AFTER DELETE ON prompts BEGIN
                INSERT INTO prompts_fts(prompts_fts, rowid, title, prompt, description, notes)
                VALUES ('delete', old.rowid, old.title, old.prompt, coalesce(old.description,''), coalesce(old.notes,''));
            END;
            CREATE TRIGGER prompts_fts_au AFTER UPDATE ON prompts BEGIN
                INSERT INTO prompts_fts(prompts_fts, rowid, title, prompt, description, notes)
                VALUES ('delete', old.rowid, old.title, old.prompt, coalesce(old.description,''), coalesce(old.notes,''));
                INSERT INTO prompts_fts(rowid, title, prompt, description, notes)
                VALUES (new.rowid, new.title, new.prompt, coalesce(new.description,''), coalesce(new.notes,''));
            END;
            """)
    }
}
