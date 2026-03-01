import Foundation
import GRDB

struct Prompt: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var id: String
    var folderId: String
    var title: String
    var prompt: String
    var description: String?
    var notes: String?
    var emoji: String?
    var color: String?
    var isFavorite: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case folderId = "folder_id"
        case title
        case prompt
        case description
        case notes
        case emoji
        case color
        case isFavorite = "is_favorite"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static let databaseTableName = "prompts"

    static let databaseSelection: [SQLSelectable] = [
        Column(CodingKeys.id),
        Column(CodingKeys.folderId),
        Column(CodingKeys.title),
        Column(CodingKeys.prompt),
        Column(CodingKeys.description),
        Column(CodingKeys.notes),
        Column(CodingKeys.emoji),
        Column(CodingKeys.color),
        Column(CodingKeys.isFavorite),
        Column(CodingKeys.sortOrder),
        Column(CodingKeys.createdAt),
        Column(CodingKeys.updatedAt),
    ]

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["folder_id"] = folderId
        container["title"] = title
        container["prompt"] = prompt
        container["description"] = description
        container["notes"] = notes
        container["emoji"] = emoji
        container["color"] = color
        container["is_favorite"] = isFavorite
        container["sort_order"] = sortOrder
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }

    init(
        id: String = UUID().uuidString,
        folderId: String,
        title: String,
        prompt: String,
        description: String? = nil,
        notes: String? = nil,
        emoji: String? = nil,
        color: String? = nil,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.folderId = folderId
        self.title = title
        self.prompt = prompt
        self.description = description
        self.notes = notes
        self.emoji = emoji
        self.color = color
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(row: Row) throws {
        id = row["id"]
        folderId = row["folder_id"]
        title = row["title"]
        prompt = row["prompt"]
        description = row["description"]
        notes = row["notes"]
        emoji = row["emoji"]
        color = row["color"]
        isFavorite = row["is_favorite"]
        sortOrder = row["sort_order"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }
}
