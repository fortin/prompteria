import Foundation
import GRDB

@MainActor
enum ExamplesSeeder {
    static func seedIfNeeded() {
        let dbQueue = DatabaseManager.shared.dbQueue

        do {
            let alreadyHasExamples = try dbQueue.read { db in
                try Folder
                    .filter(Column("name") == "Examples")
                    .fetchCount(db) > 0
            }

            if alreadyHasExamples {
                return
            }

            // Run Script puts file in Examples/; Copy Bundle Resources puts it at bundle root
            let url = Bundle.main.url(
                forResource: "examples-prompts",
                withExtension: "json",
                subdirectory: "Examples"
            ) ?? Bundle.main.url(
                forResource: "examples-prompts",
                withExtension: "json"
            )
            guard let url else {
                return
            }

            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let seed = try decoder.decode(ExamplesSeed.self, from: data)

            try dbQueue.write { db in
                let now = Date()

                let folder = Folder(
                    name: seed.folder.name,
                    emoji: seed.folder.emoji,
                    color: seed.folder.color,
                    sortOrder: 0,
                    createdAt: now,
                    updatedAt: now
                )
                try folder.insert(db)

                for (index, promptSeed) in seed.prompts.enumerated() {
                    let promptText = buildPromptText(from: promptSeed)

                    let prompt = Prompt(
                        folderId: folder.id,
                        title: promptSeed.title,
                        prompt: promptText,
                        description: promptSeed.description,
                        notes: nil,
                        emoji: promptSeed.emoji,
                        color: promptSeed.color,
                        isFavorite: false,
                        sortOrder: index,
                        createdAt: now,
                        updatedAt: now
                    )
                    try prompt.insert(db)
                }
            }
        } catch {
            // Intentionally ignore seeding errors to avoid crashing on launch.
            print("Examples seeding failed: \(error)")
        }
    }

    private static func buildPromptText(from seed: ExamplesSeedPrompt) -> String {
        """
        ROLE:
        \(seed.role)

        TASK:
        \(seed.task)

        CONTEXT:
        \(seed.context)

        CONSTRAINTS:
        \(seed.constraints)

        OUTPUT FORMAT:
        \(seed.outputFormat)
        """
    }
}

