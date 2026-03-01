import Foundation

// MARK: - Snippet JSON Format (e.g. from snippet managers, Raycast, etc.)

struct SnippetImportData: Codable {
    let categories: [SnippetCategory]?
    let snippets: [SnippetItem]
    let version: String?
    let updatedAt: String?
}

struct SnippetCategory: Codable {
    let id: String
    let name: String
    let order: Int?
    let isHiddenInMenuBar: Bool?
    let isHiddenInManager: Bool?
}

struct SnippetItem: Codable {
    let id: String
    let title: String
    let content: String
    let categoryId: String?
    let order: Int?
    let variables: [SnippetVariable]?
    let variableDisplayMode: String?
    let pasteAction: String?

    enum CodingKeys: String, CodingKey {
        case id, title, content, order, variables, variableDisplayMode, pasteAction
        case categoryId = "categoryId"
    }
}

struct SnippetVariable: Codable {
    let placeholder: String?
    let id: String?
    let name: String?
    let startIndex: Int?
    let endIndex: Int?
}

// MARK: - Prompteria Backup Format

struct BackupData: Codable {
    let version: Int
    let exportedAt: Date
    let folders: [FolderBackup]
    let prompts: [PromptBackup]
}

struct FolderBackup: Codable {
    let id: String
    let parentId: String?
    let name: String
    let emoji: String?
    let color: String?
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
}

struct PromptBackup: Codable {
    let id: String
    let folderId: String
    let title: String
    let prompt: String
    let description: String?
    let notes: String?
    let emoji: String?
    let color: String?
    let isFavorite: Bool
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
}

@MainActor
final class BackupService: ObservableObject {
    private let db = DatabaseManager.shared.dbQueue

    func exportToJSON() throws -> Data {
        let folders: [Folder] = try db.read { try Folder.fetchAll($0) }
        let prompts: [Prompt] = try db.read { try Prompt.fetchAll($0) }

        let backup = BackupData(
            version: 1,
            exportedAt: Date(),
            folders: folders.map { folder in
                FolderBackup(
                    id: folder.id,
                    parentId: folder.parentId,
                    name: folder.name,
                    emoji: folder.emoji,
                    color: folder.color,
                    sortOrder: folder.sortOrder,
                    createdAt: folder.createdAt,
                    updatedAt: folder.updatedAt
                )
            },
            prompts: prompts.map { prompt in
                PromptBackup(
                    id: prompt.id,
                    folderId: prompt.folderId,
                    title: prompt.title,
                    prompt: prompt.prompt,
                    description: prompt.description,
                    notes: prompt.notes,
                    emoji: prompt.emoji,
                    color: prompt.color,
                    isFavorite: prompt.isFavorite,
                    sortOrder: prompt.sortOrder,
                    createdAt: prompt.createdAt,
                    updatedAt: prompt.updatedAt
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    func importFromJSON(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        try db.write { db in
            for folderBackup in backup.folders {
                let folder = Folder(
                    id: folderBackup.id,
                    parentId: folderBackup.parentId,
                    name: folderBackup.name,
                    emoji: folderBackup.emoji,
                    color: folderBackup.color,
                    sortOrder: folderBackup.sortOrder,
                    createdAt: folderBackup.createdAt,
                    updatedAt: folderBackup.updatedAt
                )
                try folder.insert(db, onConflict: .replace)
            }
            for promptBackup in backup.prompts {
                let prompt = Prompt(
                    id: promptBackup.id,
                    folderId: promptBackup.folderId,
                    title: promptBackup.title,
                    prompt: promptBackup.prompt,
                    description: promptBackup.description,
                    notes: promptBackup.notes,
                    emoji: promptBackup.emoji,
                    color: promptBackup.color,
                    isFavorite: promptBackup.isFavorite,
                    sortOrder: promptBackup.sortOrder,
                    createdAt: promptBackup.createdAt,
                    updatedAt: promptBackup.updatedAt
                )
                try prompt.insert(db, onConflict: .replace)
            }
        }
    }

    /// Imports prompts from snippet-style JSON exports (e.g. Raycast snippets, Alfred, etc.)
    /// Format: `{ "categories": [...], "snippets": [...] }` where categories map to folders
    /// and snippets map to prompts.
    func importSnippetJSON(_ data: Data) throws {
        let decoder = JSONDecoder()
        let snippetData = try decoder.decode(SnippetImportData.self, from: data)

        let categories = snippetData.categories ?? []
        let snippets = snippetData.snippets

        // Build categoryId -> new folder mapping (use new UUIDs to avoid conflicts)
        var categoryToFolderId: [String: String] = [:]
        let now = Date()

        try db.write { db in
            // Import categories as folders
            for (index, cat) in categories.enumerated() {
                let newId = UUID().uuidString
                categoryToFolderId[cat.id] = newId
                let folder = Folder(
                    id: newId,
                    parentId: nil,
                    name: cat.name,
                    emoji: nil,
                    color: nil,
                    sortOrder: cat.order ?? index,
                    createdAt: now,
                    updatedAt: now
                )
                try folder.insert(db)
            }

            // Create "Imported" folder for snippets with unknown/missing category
            let uncategorizedFolderId: String
            let uncategorizedId = UUID().uuidString
            let uncategorizedFolder = Folder(
                id: uncategorizedId,
                parentId: nil,
                name: "Imported",
                emoji: nil,
                color: nil,
                sortOrder: categories.count,
                createdAt: now,
                updatedAt: now
            )
            try uncategorizedFolder.insert(db)
            uncategorizedFolderId = uncategorizedId

            // Import snippets as prompts
            for (index, snippet) in snippets.enumerated() {
                let folderId = snippet.categoryId.flatMap { categoryToFolderId[$0] } ?? uncategorizedFolderId
                let prompt = Prompt(
                    id: UUID().uuidString,
                    folderId: folderId,
                    title: snippet.title,
                    prompt: snippet.content,
                    description: nil,
                    notes: nil,
                    emoji: nil,
                    color: nil,
                    isFavorite: false,
                    sortOrder: snippet.order ?? index,
                    createdAt: now,
                    updatedAt: now
                )
                try prompt.insert(db)
            }
        }
    }
}
