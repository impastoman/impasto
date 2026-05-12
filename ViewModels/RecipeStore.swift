import SwiftUI
import Combine

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var prefermentRecipes: [PrefermentRecipe] = []
    @Published var savedBlends: [FlourBlend] = []
    @Published var savedProcesses: [SavedProcess] = []
    @Published var savedPreferments: [SavedPreferment] = []
    @Published var activeRecipeId: UUID?

    private let recipeKey     = "impasto_recipes_v3"
    private let prefermentKey = "impasto_preferments_v1"
    private let blendsKey     = "impasto_blends_v1"
    private let processesKey  = "impasto_processes_v1"
    private let sprefsKey     = "impasto_saved_preferments_v1"

    init() { load() }

    var activeRecipe: Recipe? {
        guard let id = activeRecipeId else { return nil }
        return recipes.first { $0.id == id }
    }

    // MARK: - Dough Recipes

    func add(_ recipe: Recipe) { recipes.append(recipe); saveRecipes() }

    func update(_ recipe: Recipe) {
        guard let i = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[i] = recipe; saveRecipes()
    }

    func delete(_ recipe: Recipe) { recipes.removeAll { $0.id == recipe.id }; saveRecipes() }

    func delete(at offsets: IndexSet) { recipes.remove(atOffsets: offsets); saveRecipes() }

    func addBakeLog(_ log: BakeLog, to recipeId: UUID) {
        guard let i = recipes.firstIndex(where: { $0.id == recipeId }) else { return }
        recipes[i].bakeLogs.append(log); saveRecipes()
    }

    // MARK: - Preferment Recipes (legacy full model)

    func addPreferment(_ p: PrefermentRecipe) { prefermentRecipes.append(p); savePreferments() }

    func updatePreferment(_ p: PrefermentRecipe) {
        guard let i = prefermentRecipes.firstIndex(where: { $0.id == p.id }) else { return }
        prefermentRecipes[i] = p; savePreferments()
    }

    func deletePreferment(at offsets: IndexSet) { prefermentRecipes.remove(atOffsets: offsets); savePreferments() }

    // MARK: - Saved Flour Blends

    func addBlend(_ blend: FlourBlend) { savedBlends.append(blend); saveBlends() }

    func updateBlend(_ blend: FlourBlend) {
        guard let i = savedBlends.firstIndex(where: { $0.id == blend.id }) else { return }
        savedBlends[i] = blend; saveBlends()
    }

    func deleteBlend(_ blend: FlourBlend) { savedBlends.removeAll { $0.id == blend.id }; saveBlends() }

    func deleteBlend(at offsets: IndexSet) { savedBlends.remove(atOffsets: offsets); saveBlends() }

    // MARK: - Saved Processes

    func addProcess(_ process: SavedProcess) { savedProcesses.append(process); saveProcesses() }

    func updateProcess(_ process: SavedProcess) {
        guard let i = savedProcesses.firstIndex(where: { $0.id == process.id }) else { return }
        savedProcesses[i] = process; saveProcesses()
    }

    func deleteProcess(_ process: SavedProcess) { savedProcesses.removeAll { $0.id == process.id }; saveProcesses() }

    func deleteProcess(at offsets: IndexSet) { savedProcesses.remove(atOffsets: offsets); saveProcesses() }

    // MARK: - Saved Preferments

    func addSavedPreferment(_ p: SavedPreferment) { savedPreferments.append(p); saveSavedPreferments() }

    func updateSavedPreferment(_ p: SavedPreferment) {
        guard let i = savedPreferments.firstIndex(where: { $0.id == p.id }) else { return }
        savedPreferments[i] = p; saveSavedPreferments()
    }

    func deleteSavedPreferment(_ p: SavedPreferment) { savedPreferments.removeAll { $0.id == p.id }; saveSavedPreferments() }

    func deleteSavedPreferment(at offsets: IndexSet) { savedPreferments.remove(atOffsets: offsets); saveSavedPreferments() }

    // MARK: - Persistence

    private func saveRecipes() {
        if let d = try? JSONEncoder().encode(recipes) { UserDefaults.standard.set(d, forKey: recipeKey) }
    }
    private func savePreferments() {
        if let d = try? JSONEncoder().encode(prefermentRecipes) { UserDefaults.standard.set(d, forKey: prefermentKey) }
    }
    private func saveBlends() {
        if let d = try? JSONEncoder().encode(savedBlends) { UserDefaults.standard.set(d, forKey: blendsKey) }
    }
    private func saveProcesses() {
        if let d = try? JSONEncoder().encode(savedProcesses) { UserDefaults.standard.set(d, forKey: processesKey) }
    }
    private func saveSavedPreferments() {
        if let d = try? JSONEncoder().encode(savedPreferments) { UserDefaults.standard.set(d, forKey: sprefsKey) }
    }

    private func load() {
        if let d = UserDefaults.standard.data(forKey: recipeKey),
           let v = try? JSONDecoder().decode([Recipe].self, from: d) { recipes = v }
        if let d = UserDefaults.standard.data(forKey: prefermentKey),
           let v = try? JSONDecoder().decode([PrefermentRecipe].self, from: d) { prefermentRecipes = v }
        if let d = UserDefaults.standard.data(forKey: blendsKey),
           let v = try? JSONDecoder().decode([FlourBlend].self, from: d) { savedBlends = v }
        if let d = UserDefaults.standard.data(forKey: processesKey),
           let v = try? JSONDecoder().decode([SavedProcess].self, from: d) { savedProcesses = v }
        if let d = UserDefaults.standard.data(forKey: sprefsKey),
           let v = try? JSONDecoder().decode([SavedPreferment].self, from: d) { savedPreferments = v }
    }
}
