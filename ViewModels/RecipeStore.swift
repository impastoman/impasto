import SwiftUI
import Combine

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var prefermentRecipes: [PrefermentRecipe] = []
    @Published var activeRecipeId: UUID?

    private let recipeKey     = "impasto_recipes_v3"
    private let prefermentKey = "impasto_preferments_v1"

    init() { load() }

    var activeRecipe: Recipe? {
        guard let id = activeRecipeId else { return nil }
        return recipes.first { $0.id == id }
    }

    // MARK: - Dough Recipes

    func add(_ recipe: Recipe) {
        recipes.append(recipe)
        saveRecipes()
    }

    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index] = recipe
        saveRecipes()
    }

    func delete(at offsets: IndexSet) {
        recipes.remove(atOffsets: offsets)
        saveRecipes()
    }

    func addBakeLog(_ log: BakeLog, to recipeId: UUID) {
        guard let index = recipes.firstIndex(where: { $0.id == recipeId }) else { return }
        recipes[index].bakeLogs.append(log)
        saveRecipes()
    }

    // MARK: - Preferment Recipes

    func addPreferment(_ p: PrefermentRecipe) {
        prefermentRecipes.append(p)
        savePreferments()
    }

    func updatePreferment(_ p: PrefermentRecipe) {
        guard let index = prefermentRecipes.firstIndex(where: { $0.id == p.id }) else { return }
        prefermentRecipes[index] = p
        savePreferments()
    }

    func deletePreferment(at offsets: IndexSet) {
        prefermentRecipes.remove(atOffsets: offsets)
        savePreferments()
    }

    // MARK: - Persistence

    private func saveRecipes() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: recipeKey)
        }
    }

    private func savePreferments() {
        if let encoded = try? JSONEncoder().encode(prefermentRecipes) {
            UserDefaults.standard.set(encoded, forKey: prefermentKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: recipeKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decoded
        }
        if let data = UserDefaults.standard.data(forKey: prefermentKey),
           let decoded = try? JSONDecoder().decode([PrefermentRecipe].self, from: data) {
            prefermentRecipes = decoded
        }
    }
}
