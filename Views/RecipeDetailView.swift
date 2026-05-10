import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject var store: RecipeStore
    @State var recipe: Recipe
    @State private var showPreFlight = false

    var body: some View {
        List {
            Section("Style & Method") {
                row("Style",    recipe.style.rawValue)
                row("Method",   recipe.method.rawValue)
                row("Mixer",    recipe.mixerType.rawValue)
                row("Autolyse", recipe.autolyse ? "\(recipe.autolyseMinutes) min" : "None")
                row("Timeline", "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
            }

            Section("Formula") {
                row("Biga hydration",  "\(Int(recipe.bigaHydration * 100))%")
                row("Final hydration", "\(Int(recipe.finalHydration * 100))%")
                row("Biga ratio",      "\(Int(recipe.bigaRatio * 100))%")
                row("Salt",            String(format: "%.1f%%", recipe.saltPct * 100))
                row("Yeast",           String(format: "%.2f%%", recipe.yeastPct * 100))
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

            Section("② Final dough add-ins") {
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
