import Foundation
import GRDB

struct Folder: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var id: String
    var parentId: String?
    var name: String
    var emoji: String?
    var color: String?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case parentId = "parent_id"
        case name
        case emoji
        case color
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    static let databaseTableName = "folders"

    static let databaseSelection: [SQLSelectable] = [
        Column(CodingKeys.id),
        Column(CodingKeys.parentId),
        Column(CodingKeys.name),
        Column(CodingKeys.emoji),
        Column(CodingKeys.color),
        Column(CodingKeys.sortOrder),
        Column(CodingKeys.createdAt),
        Column(CodingKeys.updatedAt),
    ]

    func encode(to container: inout PersistenceContainer) {
        container["id"] = id
        container["parent_id"] = parentId
        container["name"] = name
        container["emoji"] = emoji
        container["color"] = color
        container["sort_order"] = sortOrder
        container["created_at"] = createdAt
        container["updated_at"] = updatedAt
    }

    init(
        id: String = UUID().uuidString,
        parentId: String? = nil,
        name: String,
        emoji: String? = nil,
        color: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.parentId = parentId
        self.name = name
        self.emoji = emoji
        self.color = color
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(row: Row) throws {
        id = row["id"]
        parentId = row["parent_id"]
        name = row["name"]
        emoji = row["emoji"]
        color = row["color"]
        sortOrder = row["sort_order"]
        createdAt = row["created_at"]
        updatedAt = row["updated_at"]
    }
}
