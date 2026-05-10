import SwiftUI

struct PreFlightView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var data = PreFlightData()
    @State private var showConflictAlert = false
    @State private var showSession = false

    private var hasPreferment: Bool { recipe.method != .direct }

    private var timeConflict: Bool {
        guard hasPreferment, !data.prefermentReady else { return false }
        return recipe.method.minimumHours > recipe.timeline.minimumHours
    }

    var body: some View {
        NavigationStack {
            List {
                if hasPreferment {
                    prefermentSection
                }
                kitchenSection
                summarySection
            }
            .navigationTitle("Pre-Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { beginButton }
            .alert("Time Conflict", isPresented: $showConflictAlert) {
                Button("Proceed Anyway") { showSession = true }
                Button("Choose Another Recipe", role: .cancel) { dismiss() }
            } message: {
                Text("\(recipe.method.rawValue) needs at least \(Int(recipe.method.minimumHours))h but your \(recipe.timeline.rawValue) window (\(recipe.timeline.hours)) may not be enough if the preferment hasn't started. Consider starting the preferment now or picking a longer timeline.")
            }
        }
        .fullScreenCover(isPresented: $showSession) {
            LiveSessionView(recipe: recipe, preFlight: data)
                .environmentObject(store)
        }
    }

    var prefermentSection: some View {
        Section {
            Toggle("Preferment is ready", isOn: $data.prefermentReady)
                .tint(Color(hex: "D2B96A"))

            if data.prefermentReady {
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("hours", value: $data.prefermentAgeHours, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("h").foregroundColor(.secondary)
                }

                if data.hasPHMeter {
                    HStack {
                        Text("pH reading")
                        Spacer()
                        TextField("5.3", text: $data.prefermentPH)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Preferment not started — timeline may shift")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        } header: {
            Text("\(recipe.method.rawValue) status")
        }
    }

    var kitchenSection: some View {
        Section("Kitchen") {
            HStack {
                Text("Room temp")
                Spacer()
                TextField("20", value: $data.roomTempC, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                Text("°C").foregroundColor(.secondary)
            }

            Toggle("pH meter available", isOn: $data.hasPHMeter)
                .tint(Color(hex: "D2B96A"))

            Toggle("Dough thermometer", isOn: $data.hasDoughThermometer)
                .tint(Color(hex: "D2B96A"))
        }
    }

    var summarySection: some View {
        Section {
            LabeledContent("Recipe",   value: recipe.name)
            LabeledContent("Method",   value: recipe.method.rawValue)
            LabeledContent("Timeline", value: "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
            LabeledContent("Target",   value: "\(recipe.ballCount) × \(Int(recipe.ballWeight))g")
        } header: {
            Text("Session overview")
        }
        .font(.system(.body, design: .monospaced))
        .foregroundColor(.secondary)
    }

    var beginButton: some View {
        Button("Begin Session →") {
            if timeConflict {
                showConflictAlert = true
            } else {
                showSession = true
            }
        }
        .buttonStyle(ImpastoButtonStyle(filled: true))
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
