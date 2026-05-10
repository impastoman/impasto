import SwiftUI

struct MethodStepView: View {
    @Binding var selected: PrefermentMethod

    var body: some View {
        List {
            Section { WizardProgressView(step: 1, total: 7) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("What pre-ferment?") {
                ForEach(PrefermentMethod.allCases, id: \.self) { method in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(method.rawValue).font(.headline)
                            Text(method.description).font(.caption).foregroundColor(.secondary)
                            Text(method.flavorNote)
                                .font(.caption)
                                .foregroundColor(Color(hex: "D2B96A").opacity(0.8))
                        }
                        Spacer()
                        if selected == method {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "D2B96A"))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture { selected = method }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Levain").font(.headline)
                        Text("Sourdough starter · wild fermentation")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Coming soon")
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                .padding(.vertical, 4)
                .opacity(0.45)
            }
        }
    }
}
