import SwiftUI

struct TimelineStepView: View {
    @Binding var selected: Timeline
    let method: PrefermentMethod
    let now: Date = Date()

    var body: some View {
        List {
            Section { WizardProgressView(step: 3, total: 7) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("How long do you have?") {
                ForEach(Timeline.allCases, id: \.self) { option in
                    let warning = option.warning(for: method, from: now)
                    let target  = option.targetDate(from: now)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(option.rawValue).font(.headline)
                                Text(option.hours).font(.caption).foregroundColor(.secondary)
                            }
                            Text("Ready by \(target.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(warning != nil ? .yellow : Color(hex: "D2B96A").opacity(0.7))
                            if let w = warning {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                                    Text(w).font(.caption2)
                                }
                                .foregroundColor(.yellow)
                            }
                        }
                        Spacer()
                        if selected == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "D2B96A"))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
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
                .padding(.vertical, 4)
                .opacity(0.45)
            }
        }
    }
}
