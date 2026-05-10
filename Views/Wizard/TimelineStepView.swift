import SwiftUI

struct TimelineStepView: View {
    @Binding var selected: Timeline

    var body: some View {
        List {
            Section { WizardProgressView(step: 2, total: 5) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("How long do you have?") {
                ForEach(Timeline.allCases, id: \.self) { option in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(option.rawValue).font(.headline)
                            Text(option.hours).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if selected == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                    .onTapGesture { selected = option }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Freeze").font(.headline)
                        Text("Ball & freeze · thaw day-of").font(.caption).foregroundColor(.secondary)
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
