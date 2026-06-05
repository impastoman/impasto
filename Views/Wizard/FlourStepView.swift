import SwiftUI

struct FlourStepView: View {
    var body: some View {
        List {
            Section { WizardProgressView(step: 2, total: 7) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section(header: Text("What flour?").font(.jakarta(.semibold, size: 13))) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("🌾  Wheat").font(.jakarta(.semibold, size: 17))
                        Text("00, bread flour, all-purpose").font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "D2B96A"))
                }
                .padding(.vertical, 2)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Non-wheat").font(.jakarta(.semibold, size: 17))
                        Text("GF blends, almond, oat").font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Coming soon")
                        .font(.jakarta(.regular, size: 11))
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
