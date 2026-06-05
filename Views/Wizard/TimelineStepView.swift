import SwiftUI

struct TimelineStepView: View {
    @Binding var selected: Timeline
    let now: Date = Date()

    @State private var showTimingInfo = false

    var body: some View {
        List {
            Section { WizardProgressView(step: 2, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section {
                ForEach(Timeline.allCases, id: \.self) { option in
                    let target = option.targetDate(from: now)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(option.rawValue).font(.headline)
                                Text(option.hours).font(.caption).foregroundColor(.secondary)
                            }
                            Text("Ready by \(target.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(Color(hex: "D2B96A").opacity(0.7))
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
                        Text("Ball & freeze Â· thaw day-of").font(.caption).foregroundColor(.secondary)
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
            } header: {
                HStack {
                    Text("How long do you have?")
                    Spacer()
                    Button {
                        showTimingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color(hex: "D2B96A"))
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showTimingInfo) {
            TimingInfoSheet()
        }
    }
}

private struct TimingInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("How \"Ready by\" is calculated") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The \"Ready by\" time is calculated from the moment you start this wizard â€” not from when you begin your session.")
                            .font(.jakarta(.regular, size: 13))
                            .foregroundColor(.secondary)
                        Text("It gives you a rough window, not a precise alarm. Your actual finish time will depend on room temperature, yeast activity, and how hands-on you are with each step.")
                            .font(.jakarta(.regular, size: 13))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Timeline options") {
                    timingRow("Less than a day", "6â€“8h",   "Add 8 hours from now. Good for same-day baking with a direct or short preferment.")
                    timingRow("Overnight",       "16â€“24h", "Add 20 hours. Most common for biga or overnight cold proofing.")
                    timingRow("Two Days",        "48h",    "Two full days. Allows a long cold bulk and final proof.")
                    timingRow("Long Cold Proof", "48â€“72h", "Extended cold retard for maximum flavour development.")
                }

                Section("Conflict warnings") {
                    Text("If your timeline is too short for your chosen preferment method, a warning appears on the preferment step. You can still proceed â€” it's advisory, not a block.")
                        .font(.jakarta(.regular, size: 13))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            }
            .navigationTitle("Timing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func timingRow(_ name: String, _ range: String, _ description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).font(.jakarta(.regular, size: 17)).fontWeight(.medium)
                Spacer()
                Text(range).font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
            }
            Text(description)
                .font(.jakarta(.regular, size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
