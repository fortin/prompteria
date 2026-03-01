import Foundation
import GRDB

@MainActor
final class PromptService: ObservableObject {
    private let db = DatabaseManager.shared.dbQueue

    private func modifiedPrompt(_ prompt: Prompt, _ block: (inout Prompt) -> Void) -> Prompt {
        var copy = prompt
        block(&copy)
        copy.updatedAt = Date()
        return copy
    }

    func fetchPrompts(in folderId: String?) async throws -> [Prompt] {
        try await db.read { db in
            if let folderId {
                try Prompt
                    .filter(Column("folder_id") == folderId)
                    .order(Column("sort_order"), Column("created_at"))
                    .fetchAll(db)
            } else {
                try Prompt
                    .order(Column("sort_order"), Column("created_at"))
                    .fetchAll(db)
            }
        }
    }

    func fetchFavorites() async throws -> [Prompt] {
        try await db.read { db in
            try Prompt
                .filter(Column("is_favorite") == true)
                .order(Column("updated_at").desc)
                .fetchAll(db)
        }
    }

    func searchPrompts(query: String, folderId: String?) async throws -> [Prompt] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return try await fetchPrompts(in: folderId)
        }

        let searchTerms = query
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { "\"\($0)\"*" }
            .joined(separator: " ")

        return try await db.read { db in
            let ids: [Int64] = try Int64.fetchAll(db, sql: """
                SELECT rowid FROM prompts_fts WHERE prompts_fts MATCH ?
                """, arguments: [searchTerms])

            guard !ids.isEmpty else { return [] }

            var request = Prompt.filter(ids.contains(Column.rowID))
            if let folderId {
                request = request.filter(Column("folder_id") == folderId)
            }
            return try request
                .order(Column("sort_order"), Column("created_at"))
                .fetchAll(db)
        }
    }

    func getPrompt(id: String) async throws -> Prompt? {
        try await db.read { db in
            try Prompt.fetchOne(db, key: id)
        }
    }

    func create(_ prompt: Prompt) async throws {
        _ = try await db.write { db in
            try prompt.insert(db)
        }
    }

    func update(_ prompt: Prompt) async throws {
        let promptToUpdate = modifiedPrompt(prompt) { _ in }
        _ = try await db.write { db in
            try promptToUpdate.update(db)
        }
    }

    func delete(_ prompt: Prompt) async throws {
        _ = try await db.write { db in
            try prompt.delete(db)
        }
    }

    func toggleFavorite(_ prompt: Prompt) async throws {
        let promptToUpdate = modifiedPrompt(prompt) { $0.isFavorite.toggle() }
        _ = try await db.write { db in
            try promptToUpdate.update(db)
        }
    }

    func movePrompt(_ prompt: Prompt, to folderId: String) async throws {
        let promptToUpdate = modifiedPrompt(prompt) { $0.folderId = folderId }
        _ = try await db.write { db in
            try promptToUpdate.update(db)
        }
    }

    func reorderPrompts(_ prompts: [Prompt]) async throws {
        let promptsToUpdate = prompts.enumerated().map { index, prompt in
            var copy = prompt
            copy.sortOrder = index
            copy.updatedAt = Date()
            return copy
        }
        _ = try await db.write { db in
            for prompt in promptsToUpdate {
                try prompt.update(db)
            }
        }
    }
}
