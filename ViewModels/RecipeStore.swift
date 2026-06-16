import SwiftUI
import Combine

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []
    /// Free-tier cap, applied independently to dough recipes, flour
    /// blends, processes, and preferments (each capped at this count,
    /// incl. any seeded item). Premium removes all caps.
    let freeItemLimit = 2
    /// Mirrored from PremiumStore (set in StesuraApp). When true, no cap.
    var isPremium = false
    /// Flipped true (deferred to the next runloop tick) when a save is
    /// blocked by a free cap; drives the global paywall sheet. Deferring
    /// avoids a present-while-dismissing race with the sheet the blocked
    /// action was triggered from (wizard / builder), which otherwise
    /// swallowed the paywall.
    @Published var showPaywall = false
    /// Show the paywall, deferred to the next runloop tick so it never
    /// races a sheet/dialog dismissal. Use from add-method guards AND
    /// from entry-point gates.
    func requestPaywall() {
        DispatchQueue.main.async { self.showPaywall = true }
    }

    // Per-type "can add another?" checks — gate entry points with these.
    var canAddRecipe: Bool     { isPremium || recipes.count          < freeItemLimit }
    var canAddBlend: Bool      { isPremium || savedBlends.count       < freeItemLimit }
    var canAddProcess: Bool    { isPremium || savedProcesses.count    < freeItemLimit }
    var canAddPreferment: Bool { isPremium || savedPreferments.count  < freeItemLimit }
    /// A recipe parsed from a tapped .stesura file / link, awaiting the
    /// import preview. Set by StesuraApp's .onOpenURL handler; presented
    /// as a sheet and cleared on dismiss.
    @Published var pendingImport: Recipe? = nil
    /// Optional sender name carried with pendingImport ("Shared by …").
    @Published var pendingImportAuthor: String? = nil
    @Published var prefermentRecipes: [PrefermentRecipe] = []
    @Published var savedBlends: [FlourBlend] = []
    @Published var savedProcesses: [SavedProcess] = []
    @Published var savedPreferments: [SavedPreferment] = []
    @Published var activeRecipeId: UUID?
    @Published var customCrustTags: [String] = []
    @Published var customCrumbTags: [String] = []
    @Published var librarySectionOrder: [String] = ["Recipes", "Processes", "Flour Blends", "Preferments"]
    @Published var recipeFolders:    [String] = []
    @Published var blendFolders:     [String] = []
    @Published var processFolders:   [String] = []
    @Published var prefermentFolders:[String] = []

    private let recipeKey     = "impasto_recipes_v3"
    private let prefermentKey = "impasto_preferments_v1"
    private let blendsKey     = "impasto_blends_v1"
    private let processesKey  = "impasto_processes_v1"
    private let sprefsKey     = "impasto_saved_preferments_v1"
    private let customTagsKey      = "impasto_custom_tags_v1"
    private let sectionOrderKey    = "impasto_section_order_v1"
    private let folderRegistryKey  = "impasto_folder_registry_v1"

    /// UserDefaults flag set true after the photos-to-disk migration has
    /// completed. Bumped to v3 if we ever need to re-migrate.
    private let photosMigratedKey = "impasto_photos_migrated_v2"

    /// Serial queue for persistence. JSON-encoding the full recipes array
    /// (bake logs, process cards, stage durations, tags) is heavy enough
    /// to hitch the UI when done on the main thread on every add/update/
    /// move/save. We snapshot the value-type collection on the main thread
    /// (cheap, copy-on-write) and encode + write on this background queue.
    /// Serial so writes never land out of order; UserDefaults is
    /// thread-safe.
    private let persistQueue = DispatchQueue(label: "tech.stesura.persist", qos: .utility)

    /// Snapshot-on-main, encode-and-write-off-main persistence helper.
    private func persist<T: Encodable>(_ value: T, key: String) {
        persistQueue.async {
            if let d = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(d, forKey: key)
            }
        }
    }

    init() {
        load()
        migratePhotosToDiskIfNeeded()
        seedDefaultsIfNeeded()
    }

    /// One-time migration: walk every recipe's bakeLogs and pizzaEntries,
    /// write any inline photo Data to disk via PhotoStore, populate the
    /// new photoIDs arrays, and clear the legacy photos/photoData fields
    /// so subsequent saves don't re-serialize the JPEG bytes as Base64.
    ///
    /// Saves only happen if at least one entry was migrated — avoids a
    /// pointless rewrite for users who already have no photos.
    private func migratePhotosToDiskIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: photosMigratedKey) else { return }

        var changed = false
        for ri in recipes.indices {
            for li in recipes[ri].bakeLogs.indices {
                // BakeLog session-level photos
                let log = recipes[ri].bakeLogs[li]
                if log.photoIDs.isEmpty {
                    let legacy: [Data] = log.photos.isEmpty
                        ? [log.photoData].compactMap { $0 }
                        : log.photos
                    if !legacy.isEmpty {
                        let ids = legacy.map { PhotoStore.shared.save($0) }
                        recipes[ri].bakeLogs[li].photoIDs = ids
                        recipes[ri].bakeLogs[li].photos = []
                        recipes[ri].bakeLogs[li].photoData = nil
                        changed = true
                    }
                }

                // Per-PizzaEntry photos
                for ei in recipes[ri].bakeLogs[li].pizzaEntries.indices {
                    let entry = recipes[ri].bakeLogs[li].pizzaEntries[ei]
                    if entry.photoIDs.isEmpty {
                        let legacy: [Data] = entry.photos.isEmpty
                            ? [entry.photoData].compactMap { $0 }
                            : entry.photos
                        if !legacy.isEmpty {
                            let ids = legacy.map { PhotoStore.shared.save($0) }
                            recipes[ri].bakeLogs[li].pizzaEntries[ei].photoIDs = ids
                            recipes[ri].bakeLogs[li].pizzaEntries[ei].photos = []
                            recipes[ri].bakeLogs[li].pizzaEntries[ei].photoData = nil
                            changed = true
                        }
                    }
                }
            }
        }

        if changed { saveRecipes() }
        UserDefaults.standard.set(true, forKey: photosMigratedKey)
    }

    var activeRecipe: Recipe? {
        guard let id = activeRecipeId else { return nil }
        return recipes.first { $0.id == id }
    }

    // MARK: - Dough Recipes

    /// Adds a dough recipe. On the free tier, refuses past freeItemLimit
    /// and flips showPaywall (the global paywall sheet appears). Returns
    /// whether the recipe was actually saved — callers that do follow-up
    /// work (e.g. import fan-out) must check this and bail on false.
    @discardableResult
    func add(_ recipe: Recipe) -> Bool {
        guard canAddRecipe else { requestPaywall(); return false }
        recipes.append(recipe); saveRecipes(); return true
    }

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

    /// Walks recipes → bakeLogs → pizzaEntries to find and replace a
    /// PizzaEntry by its UUID. Used by the history pizza-detail sheet
    /// where the caller doesn't know which recipe/log owns the entry.
    func updatePizzaEntry(_ entry: PizzaEntry) {
        for ri in recipes.indices {
            for li in recipes[ri].bakeLogs.indices {
                if let ei = recipes[ri].bakeLogs[li].pizzaEntries.firstIndex(where: { $0.id == entry.id }) {
                    recipes[ri].bakeLogs[li].pizzaEntries[ei] = entry
                    saveRecipes()
                    return
                }
            }
        }
    }

    // MARK: - Preferment Recipes (legacy full model)

    func addPreferment(_ p: PrefermentRecipe) { prefermentRecipes.append(p); savePreferments() }

    func updatePreferment(_ p: PrefermentRecipe) {
        guard let i = prefermentRecipes.firstIndex(where: { $0.id == p.id }) else { return }
        prefermentRecipes[i] = p; savePreferments()
    }

    func deletePreferment(at offsets: IndexSet) { prefermentRecipes.remove(atOffsets: offsets); savePreferments() }

    // MARK: - Saved Flour Blends

    /// User-initiated add — capped on the free tier (shows paywall when
    /// blocked). Returns whether it saved.
    @discardableResult
    func addBlend(_ blend: FlourBlend) -> Bool {
        guard canAddBlend else { requestPaywall(); return false }
        savedBlends.append(blend); saveBlends(); return true
    }
    /// Uncapped add for seeding + recipe-import fan-out (a recipe's pieces
    /// should always come through, regardless of the free cap).
    func forceAddBlend(_ blend: FlourBlend) { savedBlends.append(blend); saveBlends() }

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

    @discardableResult
    func addProcess(_ process: SavedProcess) -> Bool {
        guard canAddProcess else { requestPaywall(); return false }
        savedProcesses.append(process); saveProcesses(); return true
    }
    func forceAddProcess(_ process: SavedProcess) { savedProcesses.append(process); saveProcesses() }

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

    @discardableResult
    func addSavedPreferment(_ p: SavedPreferment) -> Bool {
        guard canAddPreferment else { requestPaywall(); return false }
        savedPreferments.append(p); saveSavedPreferments(); return true
    }
    func forceAddSavedPreferment(_ p: SavedPreferment) { savedPreferments.append(p); saveSavedPreferments() }

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

    private func saveRecipes()    { persist(recipes,          key: recipeKey) }
    private func savePreferments() { persist(prefermentRecipes, key: prefermentKey) }
    private func saveBlends()     { persist(savedBlends,      key: blendsKey) }
    private func saveProcesses()  { persist(savedProcesses,   key: processesKey) }
    private func saveSavedPreferments() { persist(savedPreferments, key: sprefsKey) }

    func saveCustomTags() {
        persist(["crust": customCrustTags, "crumb": customCrumbTags], key: customTagsKey)
    }

    func saveSectionOrder() {
        persist(librarySectionOrder, key: sectionOrderKey)
    }

    func saveFolderRegistry() {
        let data: [String: [String]] = [
            "recipes": recipeFolders, "blends": blendFolders,
            "processes": processFolders, "preferments": prefermentFolders
        ]
        persist(data, key: folderRegistryKey)
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
        if let d = UserDefaults.standard.data(forKey: sectionOrderKey),
           let v = try? JSONDecoder().decode([String].self, from: d) { librarySectionOrder = v }
        if let d = UserDefaults.standard.data(forKey: folderRegistryKey),
           let v = try? JSONDecoder().decode([String: [String]].self, from: d) {
            recipeFolders     = v["recipes"]     ?? []
            blendFolders      = v["blends"]      ?? []
            processFolders    = v["processes"]   ?? []
            prefermentFolders = v["preferments"] ?? []
        }
    }

    // MARK: - Seed defaults

    private static let seedKey = "impasto_seeded_v6"

    func seedDefaultsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.seedKey) else { return }

        // Remove any prior-version seed data by name before re-seeding
        savedBlends.removeAll    { ["Perfectly good flour", "Perfectly Good Flour Blend"].contains($0.name) };  saveBlends()
        savedProcesses.removeAll { $0.name == "Perfectly good process" };                                       saveProcesses()
        recipes.removeAll        { ["Classic Neapolitan", "Perfectly Good Dough Recipe"].contains($0.name) }
        saveRecipes()
        UserDefaults.standard.removeObject(forKey: "impasto_seeded_v1")
        UserDefaults.standard.removeObject(forKey: "impasto_seeded_v2")
        UserDefaults.standard.removeObject(forKey: "impasto_seeded_v3")
        UserDefaults.standard.removeObject(forKey: "impasto_seeded_v4")
        UserDefaults.standard.removeObject(forKey: "impasto_seeded_v5")

        // Uncapped adds — seeding must never be blocked by the free cap.
        let blend = makeSeedBlend()
        forceAddBlend(blend)

        let process = makeSeedProcess()
        forceAddProcess(process)

        recipes.append(makeSeedRecipe(blend: blend, processCards: process.cards))
        saveRecipes()

        UserDefaults.standard.set(true, forKey: Self.seedKey)
    }

    private func makeSeedBlend() -> FlourBlend {
        var component = FlourComponent()
        component.type       = .tipo00
        component.percentage = 100
        component.glutenPct  = 15
        component.brand      = "TG California Artisan Blend"
        var blend = FlourBlend()
        blend.name       = "Perfectly Good Flour Blend"
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
        card(.autolyse,         duration: 30 * 60,  note: "leave covered")
        card(.incorporateYeast,                     note: "dissolve in reserved water")
        card(.bassinage,                            note: "add gradually to running mixer, to avoid splashing", bassinagePct: 0.10)
        card(.kneading,         duration: 11 * 60,  note: "This is part 1 of kneading; plan to cut kneading short when it is less than 1 min. to completion to add salt")
        card(.incorporateSalt,                      note: "leave mixer running while gradually adding salt to prevent splashing salt")
        card(.kneading,         duration: 1 * 60,   note: "look for dough to show signs of completion. While mixer is off, pressing dough will leave an indent that bounces back somewhat, is soft, and the dough appears to snake up the dough hook as a single unit. If dough does not appear done at this step, continue kneading until it is")
        card(.rest,             duration: 5 * 60,   note: "Dough should be covered during every rest step")
        card(.stretchAndFold,   duration: 0,        note: "imagine 4 corners of the dough, pull on each outwards then fold onto center. Flip dough when four corners are done")
        card(.benchRest,        duration: 20 * 60,  note: "this dough will be stretched and folded 4 total times with rests in between")
        card(.stretchAndFold,   duration: 0,        note: "same method as before and the same again for the next two stretch and folds")
        card(.benchRest,        duration: 20 * 60)
        card(.stretchAndFold,   duration: 0,        note: "one more rest and one more stretch and fold to go!")
        card(.benchRest,        duration: 20 * 60,  note: "good time to get a bowl ready to bulk ferment. Use a few drops of extra virgin olive oil and spread through bowl")
        card(.stretchAndFold,   duration: 0)
        card(.bulkFermentation, duration: 8 * 3600, note: "place dough into bowl for bulk fermentation at room temperature. Pour a few droplets on top and cover")
        card(.divide,                               note: "place dough onto a clean surface and use dough cutter to make number of desired dough balls. Use a scale to remove and add dough portions among each other to get desired size")
        card(.preShape,                             note: "Have as many 16oz deli containers with lids or similar ready with a drop of EVOO on the bottom to store balls in fridge. Shape each portion into a ball, building tension on the top, and place into container. Pour a drop of EVOO atop each dough ball before closing container")
        card(.coldFerment,      duration: 36 * 3600, note: "store refrigerated")
        card(.preShape,                             note: "transfer cool doughs onto a baking sheet or dough box with enough space between them to allow room for dough to expand without touching one another, at least 3\" apart on each side")
        card(.finalProof,       duration: 4 * 3600,  note: "doughs should remain covered and away from direct sun during final proof. Bake begins after doughs have expanded, and have warmed up")

        return SavedProcess(name: "Perfectly good process", cards: cards)
    }

    private func makeSeedRecipe(blend: FlourBlend, processCards: [ProcessCard]) -> Recipe {
        var r = Recipe(name: "Perfectly Good Dough Recipe", style: .custom, method: .direct,
                       mixerType: .standMixer, autolyse: true, bassinage: true,
                       timeline: .longColdProof, ballCount: 8, ballWeight: 250, buffer: 0.0075)
        r.customStyleName = "Perfectly Good Style"
        r.finalHydration      = 0.66
        r.saltPct             = 0.03
        r.yeastPct            = 0.001
        r.yeastType           = .activeDry
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
