import SwiftUI

struct FlourStepView: View {
    var body: some View {
        List {
            Section { WizardProgressView(step: 1, total: 5) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("What flour?") {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("🌾  Wheat").font(.headline)
                        Text("00, bread flour, all-purpose").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "D2B96A"))
                }
                .padding(.vertical, 2)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Non-wheat").font(.headline)
                        Text("GF blends, almond, oat").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Coming soon")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                .padding(.vertical, 2)
                .opacity(0.45)
            }
        }
    }
}
