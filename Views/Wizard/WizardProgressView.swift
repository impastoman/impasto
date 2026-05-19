import SwiftUI

struct WizardProgressView: View {
    @Environment(\.wizardTitle) private var title
    let step: Int
    let total: Int

    var body: some View {
        VStack(spacing: 0) {
            // Title header — scrolls with list content
            if !title.isEmpty {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.paperMargin)
                        .frame(width: 1.2)
                        .padding(.leading, 12)
                    Text(title)
                        .font(.system(size: 24, design: .serif))
                        .foregroundColor(Color.paperWhite)
                        .padding(.leading, 12)
                        .padding(.trailing, 16)
                        .padding(.vertical, 14)
                    Spacer()
                }
                .background(Color.paperHeader)
            }
            // Step dots
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= step ? Color(hex: "D2B96A") : Color(hex: "2A2A28"))
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}
