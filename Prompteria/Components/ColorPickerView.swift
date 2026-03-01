import SwiftUI

private let presetColors: [String] = [
    "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
    "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9",
    "#F8B500", "#00CED1", "#FF69B4", "#32CD32", "#FF4500",
]

struct ColorPickerView: View {
    let onSelect: (String) -> Void
    @State private var customColor: Color = .blue
    @State private var showCustom = false

    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                ForEach(presetColors, id: \.self) { hex in
                    if let color = Color(hex: hex) {
                        Button {
                            onSelect(hex)
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            Button("Custom Color") {
                showCustom = true
            }

            if showCustom {
                ColorPicker("Pick a color", selection: $customColor, supportsOpacity: false)
                    .onChange(of: customColor) { _, newValue in
                        onSelect(newValue.hexString)
                    }
            }
        }
        .padding(20)
        .frame(width: 200)
    }
}
