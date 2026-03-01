import SwiftUI

struct EmptyContentView: View {
    let message: String

    var body: some View {
        ContentUnavailableView(
            message,
            systemImage: "tray"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
