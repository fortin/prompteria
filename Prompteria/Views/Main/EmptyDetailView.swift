import SwiftUI

struct EmptyDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Prompt",
            systemImage: "doc.text",
            description: Text("Choose a prompt from the list to view and edit it.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
