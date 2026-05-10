import Foundation
import Combine

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var activeRecipeId: UUID?

    private let saveKey = "impasto_recipes"

    init() { load() }

    var activeRecipe: Recipe? {
        guard let id = activeRecipeId else { return nil }
        return recipes.first { $0.id == id }
    }

    func add(_ recipe: Recipe) {
        recipes.append(recipe)
        save()
    }

    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index] = recipe
        save()
    }

    func delete(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        save()
    }

    func addBakeLog(_ log: BakeLog, to recipeId: UUID) {
        guard let index = recipes.firstIndex(where: { $0.id == recipeId }) else { return }
        recipes[index].bakeLogs.append(log)
        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Recipe].self, from: data)
        else { return }
        recipes = decoded
    }
}
