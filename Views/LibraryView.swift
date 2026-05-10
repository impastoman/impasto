import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: RecipeStore
    @State private var showWizard = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.recipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeRowView(recipe: recipe)
                    }
                }
                .onDelete { store.delete(at: $0) }
            }
            .navigationTitle("Library")
            .toolbar {
                Button { showWizard = true } label: { Image(systemName: "plus") }
            }
            .overlay {
                if store.recipes.isEmpty {
                    ContentUnavailableView("No recipes yet", systemImage: "fork.knife", description: Text("Tap + to create your first recipe."))
                }
            }
        }
        .sheet(isPresented: $showWizard) {
            WizardContainerView { recipe in
                store.add(recipe)
                showWizard = false
            }
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(recipe.name).font(.headline)
                Spacer()
                Text(recipe.style.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color(hex: "1A1B18"))
                    .cornerRadius(4)
            }
            Text("\(Int(recipe.finalHydration * 100))% · \(recipe.ballCount) × \(Int(recipe.ballWeight))g · \(recipe.timeline.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(recipe.bakeLogs.isEmpty ? "Untested" : "Tested ×\(recipe.bakeLogs.count)")
                .font(.caption2)
                .foregroundColor(recipe.bakeLogs.isEmpty ? .orange : .green)
        }
        .padding(.vertical, 4)
    }
}
