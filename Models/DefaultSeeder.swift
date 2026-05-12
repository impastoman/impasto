import Foundation

extension RecipeStore {

    private static let seedKey = "impasto_seeded_v1"

    func seedDefaultsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.seedKey) else { return }

        let blend = makeDefaultBlend()
        addBlend(blend)

        let process = makeDefaultProcess()
        addProcess(process)

        var recipe = makeDefaultRecipe(blend: blend, processCards: process.cards)
        recipes.append(recipe)
        saveRecipes()

        UserDefaults.standard.set(true, forKey: Self.seedKey)
    }

    // MARK: - Flour blend

    private func makeDefaultBlend() -> FlourBlend {
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

    // MARK: - Process

    private func makeDefaultProcess() -> SavedProcess {
        var cards: [ProcessCard] = []
        var order = 0

        func add(_ type: ProcessCardType,
                 duration: TimeInterval? = nil,
                 note: String = "",
                 title: String? = nil,
                 bassinagePct: Double? = nil) {
            var c = ProcessCard(type: type)
            c.sortOrder      = order; order += 1
            if let d = duration  { c.customDuration       = d }
            if !note.isEmpty     { c.recipeNote            = note }
            if let t = title     { c.customTitle           = t }
            if let b = bassinagePct { c.bassinageReservePct = b }
            cards.append(c)
        }

        add(.combine)

        add(.autolyse,
            duration: 30 * 60,
            note: "keep covered")

        add(.incorporateYeast,
            note: "dissolve in bassinage")

        add(.bassinage,
            note: "add all gradually during kneading in the next step to avoid splashing",
            bassinagePct: 0.10)

        add(.kneading,
            duration: 10 * 60,
            note: "this step ends 1 minute before kneading is actually done — proceed to next step to add salt")

        add(.incorporateSalt,
            note: "allow mixer to continue mixing while adding salt")

        add(.kneading,
            duration: 1 * 60,
            note: "after all salt has been incorporated, finish the knead until you see the dough start climbing the hook, is tacky without being sticky. Turn off mixer before touching dough. Ideally this step will take less than a minute — if dough is not yet done, continue kneading until it is")

        add(.rest,
            duration: 5 * 60)

        add(.stretchAndFold,
            duration: 60 * 60,
            note: "stretch and fold then rest for 20 minutes. this will total 4 rounds of stretch & fold within 60 minutes")

        add(.bulkFermentation,
            duration: 12 * 3600,
            note: "cover at room temperature or 68–70°F. drizzle olive oil on bottom of bowl/dough and on top")

        add(.divide,
            note: "shape into balls and save in covered pint containers or similar. drizzle olive oil atop each ball")

        add(.coldFerment,
            duration: 36 * 3600,
            note: "store refrigerated")

        add(.preShape,
            note: "move from containers to a dough box or baking tray, fixing shape during transfer. give each dough at least 3\" all around to allow dough space to rise without contacting another")

        add(.finalProof,
            duration: 4 * 3600,
            note: "dough will be ready when it is no longer cold to touch and has expanded. keep doughs covered until time for use")

        return SavedProcess(name: "Perfectly good process", cards: cards)
    }

    // MARK: - Recipe

    private func makeDefaultRecipe(blend: FlourBlend, processCards: [ProcessCard]) -> Recipe {
        var r = Recipe(
            name:       "Classic Neapolitan",
            style:      .neapolitan,
            method:     .direct,
            mixerType:  .standMixer,
            autolyse:   true,
            bassinage:  true,
            timeline:   .longColdProof,
            ballCount:  8,
            ballWeight: 250,
            buffer:     0.0125
        )
        r.finalHydration      = 0.66
        r.saltPct             = 0.03
        r.yeastPct            = 0.001
        r.yeastType           = .instantDry
        r.bassinageReservePct = 0.10
        r.flourBlend          = blend
        r.processCards        = processCards

        var setup             = BakeSetup()
        setup.method          = .portableOven
        setup.subMethod       = ""
        setup.preheatMinutes  = 30
        setup.ovenTempMin     = 800
        setup.ovenTempMax     = 850
        setup.surfaceTemp     = 700
        setup.useCelsius      = false
        r.bakeSetups          = [setup]

        return r
    }
}
