import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject var store: RecipeStore
    @State var recipe: Recipe
    @State private var showPreFlight = false

    var styleLabel: String {
        recipe.style == .custom && !recipe.customStyleName.isEmpty
            ? recipe.customStyleName
            : recipe.style.rawValue
    }

    var body: some View {
        List {
            Section("Style & Method") {
                row("Style",    styleLabel)
                row("Method",   recipe.method.rawValue)
                row("Mixer",    recipe.mixerType.rawValue)
                row("Autolyse", recipe.autolyse ? "\(recipe.autolyseMinutes) min" : "None")
                row("Timeline", "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
            }

            Section("Formula") {
                row("Final hydration", "\(Int(recipe.finalHydration * 100))%")
                if recipe.bigaRatio > 0 {
                    row("Biga hydration",  "\(Int(recipe.bigaHydration * 100))%")
                    row("Biga percentage", "\(Int(recipe.bigaRatio * 100))%")
                }
                row("Salt",  String(format: "%.1f%%", recipe.saltPct * 100))
                row("Yeast", "\(recipe.yeastType.rawValue)  ·  \(String(format: "%.2f%%", recipe.yeastPct * 100))")
            }

            if !recipe.flourBlend.components.isEmpty {
                Section("Flour blend") {
                    ForEach(recipe.flourBlend.components) { c in
                        row(c.type.rawValue, "\(Int(c.percentage))%")
                    }
                    ForEach(recipe.flourBlend.additives) { a in
                        row(a.type.rawValue, "\(a.percentage)%")
                            .foregroundColor(.secondary)
                    }
                }
                .font(.system(.body, design: .monospaced))
            }

            Section("Target") {
                row("Balls",       "\(recipe.ballCount) × \(Int(recipe.ballWeight))g")
                row("Total dough", "\(Int(recipe.totalDoughWeight))g")
            }

            if recipe.method != .direct {
                Section("① \(recipe.method.rawValue)") {
                    row("Flour", "\(Int(recipe.bigaFlour))g")
                    row("Water", "\(Int(recipe.bigaWater))g")
                    row("Yeast", String(format: "%.1fg", recipe.bigaYeast))
                }
            }

            Section(recipe.method != .direct ? "② Final dough" : "Dough") {
                row("Flour", "\(Int(recipe.additionalFlour))g")
                row("Water", "\(Int(recipe.additionalWater))g")
                row("Salt",  "\(Int(recipe.totalSalt))g")
            }

            Section {
                Button("▶  Start Session") { showPreFlight = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(hex: "D2B96A"))
            }
        }
        .navigationTitle(recipe.name)
        .fullScreenCover(isPresented: $showPreFlight) {
            PreFlightView(recipe: recipe)
                .environmentObject(store)
        }
    }

    func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
            .font(.system(.body, design: .monospaced))
    }
}
