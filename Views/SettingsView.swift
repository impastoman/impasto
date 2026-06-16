import SwiftUI

/// App-wide settings stored in UserDefaults via @AppStorage.
/// Read these in any view to gate behavior:
///   @AppStorage("showTips") var showTips: Bool = true
///   @AppStorage("prepDefaultUnits") var prepUnits: String = "metric"
///   @AppStorage("prepDefaultTempUnit") var prepTempUnit: String = "celsius"
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var premium: PremiumStore

    @AppStorage("showTips")             private var showTips: Bool = true
    @AppStorage("prepDefaultUnits")     private var prepUnits: String = "metric"
    @AppStorage("prepDefaultTempUnit")  private var prepTempUnit: String = "celsius"
    @AppStorage("stesura_author_name")  private var authorName: String = ""

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Stesura Premium").font(.jakarta(.semibold, size: 13))) {
                    if premium.isPremium {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill").foregroundColor(.ruleBlue)
                            Text("Premium unlocked — unlimited library")
                                .font(.jakarta(.regular, size: 15))
                        }
                    } else {
                        Button("Unlock Premium — \(premium.displayPrice)") { showPaywall = true }
                            .font(.jakarta(.semibold, size: 15))
                            .foregroundColor(.ruleBlue)
                        Button("Restore Purchase") { Task { await premium.restore() } }
                            .font(.jakarta(.regular, size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.clear)

                #if DEBUG
                Section(header: Text("Developer").font(.jakarta(.semibold, size: 13))) {
                    Toggle("Force Premium (debug builds only)", isOn: $premium.debugUnlock)
                        .tint(.ruleBlue)
                        .font(.jakarta(.regular, size: 15))
                    Text("On = full app unlocked without buying. Off = exercise the free 2-item caps + paywall. Not present in release builds.")
                        .font(.jakarta(.regular, size: 11))
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)
                #endif

                Section(header: Text("Sharing").font(.jakarta(.semibold, size: 13))) {
                    TextField("Your name", text: $authorName)
                        .font(.jakarta(.regular, size: 17))
                        .textInputAutocapitalization(.words)
                }
                .listRowBackground(Color.clear)

                if showTips {
                    Section {
                        Text("When you share a recipe, this name shows as “Shared by …” in the other person's import preview. Leave blank to share anonymously.")
                            .font(.jakarta(.regular, size: 11))
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                }

                Section(header: Text("Display").font(.jakarta(.semibold, size: 13))) {
                    Toggle("Show tips", isOn: $showTips)
                        .tint(Color(hex: "7FA2BD"))
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

                Section(header: Text("Prep session defaults").font(.jakarta(.semibold, size: 13))) {
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
            .meadList()
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(premium) }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "7FA2BD"))
                        .font(.jakarta(.regular, size: 17))
                }
            }
        }
        .preferredColorScheme(.light)
    }
}
