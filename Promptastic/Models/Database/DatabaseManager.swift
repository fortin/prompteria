import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    let dbQueue: DatabaseQueue

    private init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("Promptastic", isDirectory: true)

        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }

        let dbPath = appDirectory.appendingPathComponent("prompts.db").path

        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode=WAL")
        }

        do {
            dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
            try migrate(dbQueue)
        } catch {
            fatalError("Could not initialize database: \(error)")
        }
    }

    private func migrate(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try Schema.createTables(db)
        }
        try migrator.migrate(dbQueue)
    }
}
