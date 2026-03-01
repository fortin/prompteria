import Foundation
import GRDB

@MainActor
final class FolderService: ObservableObject {
    private let db = DatabaseManager.shared.dbQueue

    private func folderWithUpdatedTimestamp(_ folder: Folder) -> Folder {
        var copy = folder
        copy.updatedAt = Date()
        return copy
    }

    func fetchFolders() async throws -> [Folder] {
        try await db.read { db in
            try Folder
                .order(Column("sort_order"), Column("name"))
                .fetchAll(db)
        }
    }

    func getFolder(id: String) async throws -> Folder? {
        try await db.read { db in
            try Folder.fetchOne(db, key: id)
        }
    }

    func create(_ folder: Folder) async throws {
        _ = try await db.write { db in
            let maxOrder = try Int.fetchOne(db, sql: "SELECT COALESCE(MAX(sort_order), -1) FROM folders") ?? -1
            var newFolder = folder
            newFolder.sortOrder = maxOrder + 1
            try newFolder.insert(db)
        }
    }

    func update(_ folder: Folder) async throws {
        let folderToUpdate = folderWithUpdatedTimestamp(folder)
        _ = try await db.write { db in
            try folderToUpdate.update(db)
        }
    }

    func delete(_ folder: Folder) async throws {
        _ = try await db.write { db in
            try folder.delete(db)
        }
    }

    func reorderFolders(_ folders: [Folder]) async throws {
        let foldersToUpdate = folders.enumerated().map { index, folder in
            var copy = folder
            copy.sortOrder = index
            copy.updatedAt = Date()
            return copy
        }
        _ = try await db.write { db in
            for folder in foldersToUpdate {
                try folder.update(db)
            }
        }
    }
}
