import Foundation

struct ExamplesSeed: Codable {
    let version: Int
    let folder: ExamplesSeedFolder
    let prompts: [ExamplesSeedPrompt]
}

struct ExamplesSeedFolder: Codable {
    let name: String
    let emoji: String?
    let color: String?
}

struct ExamplesSeedPrompt: Codable {
    let key: String
    let title: String
    let description: String?
    let emoji: String?
    let color: String?
    let role: String
    let task: String
    let context: String
    let constraints: String
    let outputFormat: String
}

