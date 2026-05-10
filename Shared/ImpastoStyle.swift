import SwiftUI

struct ImpastoButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, design: .monospaced))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(filled ? Color(hex: "D2B96A") : Color.clear)
            .foregroundColor(filled ? Color(hex: "111210") : Color(hex: "9A9688"))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(filled ? Color.clear : Color(hex: "4A4840"), lineWidth: 1)
            )
            .cornerRadius(6)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
