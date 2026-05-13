import SwiftUI
import Combine

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var prefermentRecipes: [PrefermentRecipe] = []
    @Published var savedBlends: [FlourBlend] = []
    @Published var savedProcesses: [SavedProcess] = []
    @Published var savedPreferments: [SavedPreferment] = []
    @Published var activeRecipeId: UUID?
    @Published var customCrustTags: [String] = []
    @Published var customCrumbTags: [String] = []

    private let recipeKey     = "impasto_recipes_v3"
    private let prefermentKey = "impasto_preferments_v1"
    private let blendsKey     = "impasto_blends_v1"
    private let processesKey  = "impasto_processes_v1"
    private let sprefsKey     = "impasto_saved_preferments_v1"
    private let customTagsKey = "impasto_custom_tags_v1"

    init() { load(); seedDefaultsIfNeeded() }

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

    func moveRecipes(inFolder folder: String, from source: IndexSet, to destination: Int) {
        let indices = recipes.indices.filter { recipes[$0].folderName == folder }
        var items = indices.map { recipes[$0] }
        items.move(fromOffsets: source, toOffset: destination)
        for (i, item) in zip(indices, items) { recipes[i] = item }
        saveRecipes()
    }

    func moveRecipeToFolder(_ recipe: Recipe, folder: String) {
        guard let i = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[i].folderName = folder; saveRecipes()
    }

    func addBakeLog(_ log: BakeLog, to recipeId: UUID) {
        guard let i = recipes.firstIndex(where: { $0.id == recipeId }) else { return }
        recipes[i].bakeLogs.append(log); saveRecipes()
    }

    func updateBakeLog(_ log: BakeLog, recipeId: UUID) {
        guard let ri = recipes.firstIndex(where: { $0.id == recipeId }),
              let li = recipes[ri].bakeLogs.firstIndex(where: { $0.id == log.id }) else { return }
        recipes[ri].bakeLogs[li] = log; saveRecipes()
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

    func moveBlends(inFolder folder: String, from source: IndexSet, to destination: Int) {
        let indices = savedBlends.indices.filter { savedBlends[$0].folderName == folder }
        var items = indices.map { savedBlends[$0] }
        items.move(fromOffsets: source, toOffset: destination)
        for (i, item) in zip(indices, items) { savedBlends[i] = item }
        saveBlends()
    }

    func moveBlendToFolder(_ blend: FlourBlend, folder: String) {
        guard let i = savedBlends.firstIndex(where: { $0.id == blend.id }) else { return }
        savedBlends[i].folderName = folder; saveBlends()
    }

    // MARK: - Saved Processes

    func addProcess(_ process: SavedProcess) { savedProcesses.append(process); saveProcesses() }

    func updateProcess(_ process: SavedProcess) {
        guard let i = savedProcesses.firstIndex(where: { $0.id == process.id }) else { return }
        savedProcesses[i] = process; saveProcesses()
    }

    func deleteProcess(_ process: SavedProcess) { savedProcesses.removeAll { $0.id == process.id }; saveProcesses() }

    func deleteProcess(at offsets: IndexSet) { savedProcesses.remove(atOffsets: offsets); saveProcesses() }

    func moveProcesses(inFolder folder: String, from source: IndexSet, to destination: Int) {
        let indices = savedProcesses.indices.filter { savedProcesses[$0].folderName == folder }
        var items = indices.map { savedProcesses[$0] }
        items.move(fromOffsets: source, toOffset: destination)
        for (i, item) in zip(indices, items) { savedProcesses[i] = item }
        saveProcesses()
    }

    func moveProcessToFolder(_ process: SavedProcess, folder: String) {
        guard let i = savedProcesses.firstIndex(where: { $0.id == process.id }) else { return }
        savedProcesses[i].folderName = folder; saveProcesses()
    }

    // MARK: - Saved Preferments

    func addSavedPreferment(_ p: SavedPreferment) { savedPreferments.append(p); saveSavedPreferments() }

    func updateSavedPreferment(_ p: SavedPreferment) {
        guard let i = savedPreferments.firstIndex(where: { $0.id == p.id }) else { return }
        savedPreferments[i] = p; saveSavedPreferments()
    }

    func deleteSavedPreferment(_ p: SavedPreferment) { savedPreferments.removeAll { $0.id == p.id }; saveSavedPreferments() }

    func deleteSavedPreferment(at offsets: IndexSet) { savedPreferments.remove(atOffsets: offsets); saveSavedPreferments() }

    func movePreferments(inFolder folder: String, from source: IndexSet, to destination: Int) {
        let indices = savedPreferments.indices.filter { savedPreferments[$0].folderName == folder }
        var items = indices.map { savedPreferments[$0] }
        items.move(fromOffsets: source, toOffset: destination)
        for (i, item) in zip(indices, items) { savedPreferments[i] = item }
        saveSavedPreferments()
    }

    func movePrefermentToFolder(_ pref: SavedPreferment, folder: String) {
        guard let i = savedPreferments.firstIndex(where: { $0.id == pref.id }) else { return }
        savedPreferments[i].folderName = folder; saveSavedPreferments()
    }

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
    func saveCustomTags() {
        let data = ["crust": customCrustTags, "crumb": customCrumbTags]
        if let d = try? JSONEncoder().encode(data) { UserDefaults.standard.set(d, forKey: customTagsKey) }
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
        if let d = UserDefaults.standard.data(forKey: customTagsKey),
           let v = try? JSONDecoder().decode([String: [String]].self, from: d) {
            customCrustTags = v["crust"] ?? []
            customCrumbTags = v["crumb"] ?? []
        }
    }

    // MARK: - Seed defaults

    private static let seedKey = "impasto_seeded_v3"

    func seedDefaultsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.seedKey) else { return }

        // Remove any prior-version seed data by name before re-seeding
        savedBlends.removeAll    { $0.name == "Perfectly good flour" };               saveBlends()
        savedProcesses.removeAll { $0.name == "Perfectly good process" };             saveProcesses()
        recipes.removeAll        { ["Classic Neapolitan", "Perfectly Good Dough Recipe"].contains($0.name) }
        saveRecipes()
        UserDefaults.standard.removeObject(forKey: "impasto_seeded_v1")
        UserDefaults.standard.removeObject(forKey: "impasto_seeded_v2")

        let blend = makeSeedBlend()
        addBlend(blend)

        let process = makeSeedProcess()
        addProcess(process)

        recipes.append(makeSeedRecipe(blend: blend, processCards: process.cards))
        saveRecipes()

        UserDefaults.standard.set(true, forKey: Self.seedKey)
    }

    private func makeSeedBlend() -> FlourBlend {
        var component = FlourComponent()
        component.type       = .tipo00
        component.percentage = 100
        component.glutenPct  = 15
        component.brand      = "TG \"California Artisan\" Type 00 Pizza Flour"
        var blend = FlourBlend()
        blend.name       = "Perfectly good flour"
        blend.components = [component]
        return blend
    }

    private func makeSeedProcess() -> SavedProcess {
        var cards: [ProcessCard] = []
        var order = 0

        func card(_ type: ProcessCardType,
                  duration: TimeInterval? = nil,
                  note: String = "",
                  bassinagePct: Double? = nil) {
            var c = ProcessCard(type: type)
            c.sortOrder = order; order += 1
            if let d = duration      { c.customDuration      = d }
            if !note.isEmpty         { c.recipeNote           = note }
            if let b = bassinagePct  { c.bassinageReservePct = b }
            cards.append(c)
        }

        card(.combine)
        card(.autolyse,          duration: 30 * 60,   note: "keep covered")
        card(.incorporateYeast,                        note: "dissolve in bassinage")
        card(.bassinage,                               note: "add all gradually during kneading in the next step to avoid splashing", bassinagePct: 0.10)
        card(.kneading,          duration: 10 * 60,   note: "this step ends 1 minute before kneading is actually done — proceed to next step to add salt")
        card(.incorporateSalt,                         note: "allow mixer to continue mixing while adding salt")
        card(.kneading,          duration: 1 * 60,    note: "after all salt has been incorporated, finish the knead until you see the dough start climbing the hook, is tacky without being sticky. Turn off mixer before touching dough. Ideally this step will take less than a minute — if dough is not yet done, continue kneading until it is")
        card(.rest,              duration: 5 * 60)
        card(.stretchAndFold,    duration: 60 * 60,   note: "stretch and fold then rest for 20 minutes. this will total 4 rounds of stretch & fold within 60 minutes")
        card(.bulkFermentation,  duration: 12 * 3600, note: "cover at room temperature or 68–70°F. drizzle olive oil on bottom of bowl/dough and on top")
        card(.divide,                                  note: "shape into balls and save in covered pint containers or similar. drizzle olive oil atop each ball")
        card(.coldFerment,       duration: 36 * 3600, note: "store refrigerated")
        card(.preShape,                                note: "move from containers to a dough box or baking tray, fixing shape during transfer. give each dough at least 3\" all around to allow dough space to rise without contacting another")
        card(.finalProof,        duration: 4 * 3600,  note: "dough will be ready when it is no longer cold to touch and has expanded. keep doughs covered until time for use")

        return SavedProcess(name: "Perfectly good process", cards: cards)
    }

    private func makeSeedRecipe(blend: FlourBlend, processCards: [ProcessCard]) -> Recipe {
        var r = Recipe(name: "Perfectly Good Dough Recipe", style: .custom, method: .direct,
                       mixerType: .standMixer, autolyse: true, bassinage: true,
                       timeline: .longColdProof, ballCount: 8, ballWeight: 250, buffer: 0.0125)
        r.customStyleName = "Perfectly Good Style"
        r.finalHydration      = 0.66
        r.saltPct             = 0.03
        r.yeastPct            = 0.001
        r.yeastType           = .instantDry
        r.bassinageReservePct = 0.10
        r.flourBlend          = blend
        r.processCards        = processCards

        var setup = BakeSetup()
        setup.method         = .portableOven
        setup.subMethod      = ""
        setup.preheatMinutes = 30
        setup.ovenTempMin    = 800
        setup.ovenTempMax    = 850
        setup.surfaceTemp    = 700
        setup.useCelsius     = false
        r.bakeSetups = [setup]
        return r
    }
}
