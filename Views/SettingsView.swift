import SwiftUI

/// App-wide settings stored in UserDefaults via @AppStorage.
/// Read these in any view to gate behavior:
///   @AppStorage("showTips") var showTips: Bool = true
///   @AppStorage("prepDefaultUnits") var prepUnits: String = "metric"
///   @AppStorage("prepDefaultTempUnit") var prepTempUnit: String = "celsius"
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("showTips")             private var showTips: Bool = true
    @AppStorage("prepDefaultUnits")     private var prepUnits: String = "metric"
    @AppStorage("prepDefaultTempUnit")  private var prepTempUnit: String = "celsius"

    var body: some View {
        NavigationStack {
            List {
                Section("Display") {
                    Toggle("Show tips", isOn: $showTips)
                        .tint(Color(hex: "D2B96A"))
                        .font(.jakarta(.regular, size: 17))
                }
                .listRowBackground(Color.clear)

                if showTips {
                    Section {
                        Text("Turning off Show Tips hides the grey explainer captions throughout the app, leaving only field labels. For users who already know what each box does.")
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Prep session defaults") {
                    Picker("Units", selection: $prepUnits) {
                        Text("Metric").tag("metric")
                        Text("Imperial").tag("imperial")
                    }
                    .font(.jakarta(.regular, size: 17))

                    Picker("Temperature", selection: $prepTempUnit) {
                        Text("Celsius").tag("celsius")
                        Text("Fahrenheit").tag("fahrenheit")
                    }
                    .font(.jakarta(.regular, size: 17))
                }
                .listRowBackground(Color.clear)

                if showTips {
                    Section {
                        Text("Prep defaults only pre-select fields when you open a Prep Session. The live session still uses whatever you actually picked in Prep.")
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "D2B96A"))
                        .font(.jakarta(.regular, size: 17))
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
