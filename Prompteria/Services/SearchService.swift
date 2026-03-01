import Foundation
import GRDB

@MainActor
final class SearchService: ObservableObject {
    private let promptService = PromptService()

    func search(query: String, folderId: String?) async throws -> [Prompt] {
        try await promptService.searchPrompts(query: query, folderId: folderId)
    }
}
