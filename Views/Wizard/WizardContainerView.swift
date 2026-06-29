import SwiftUI

enum WizardMode {
    case new
    case edit(Recipe)
    case fork(Recipe)
}

// MARK: - ConvertedFormula

struct ConvertedFormula: Identifiable {
    let id = UUID()
    var finalHydration: Double
    var saltPct: Double
    var yeastPct: Double
    var yeastType: YeastType
    var flourBlend: FlourBlend
}

struct WizardContainerView: View {
    let mode: WizardMode
    let onComplete: (Recipe) -> Void
    let onSaveAsNew: ((Recipe) -> Void)?
    /// When set, hydration/salt/yeast/flourBlend are seeded from the converter and
    /// the style-change observer won't overwrite the pre-filled hydration value.
    let hasConvertedFormula: Bool
    @Environment(\.dismiss) private var dismiss

    init(mode: WizardMode = .new,
         convertedFormula: ConvertedFormula? = nil,
         onComplete: @escaping (Recipe) -> Void,
         onSaveAsNew: ((Recipe) -> Void)? = nil) {
        self.mode = mode
        self.onComplete = onComplete
        self.onSaveAsNew = onSaveAsNew
        self.hasConvertedFormula = convertedFormula != nil

        let r: Recipe? = {
            switch mode {
            case .new: return nil
            case .edit(let r), .fork(let r): return r
            }
        }()

        // Dough-agnostic model: every recipe is now "custom" with a
        // free-text style name. New recipes start blank. When editing a
        // legacy recipe that used a prebuilt style (Neapolitan, etc.),
        // surface that style's name as editable text so it isn't lost,
        // and migrate it to .custom on save — display is unaffected
        // because styleLabel already prefers customStyleName for .custom.
        _style              = State(initialValue: .custom)
        _customStyleName    = State(initialValue: {
            guard let r else { return "" }
            return r.style == .custom ? r.customStyleName : r.style.rawValue
        }())
        _usePreferment      = State(initialValue: r.map { $0.method != .direct } ?? true)
        _prefermentHydration = State(initialValue: r?.prefermentHydration ?? 0.50)
        _method             = State(initialValue: r?.method ?? .biga)
        // Formula takes priority over recipe, recipe over defaults
        _flourBlend         = State(initialValue: convertedFormula?.flourBlend ?? r?.flourBlend ?? FlourBlend())
        _finalHydration     = State(initialValue: convertedFormula?.finalHydration ?? r?.finalHydration ?? PizzaStyle.custom.defaultFinalHydration)
        _saltPct            = State(initialValue: convertedFormula?.saltPct ?? r?.saltPct ?? 0.028)
        _yeastPct           = State(initialValue: convertedFormula?.yeastPct ?? r?.yeastPct ?? 0.001)
        _yeastType          = State(initialValue: convertedFormula?.yeastType ?? r?.yeastType ?? .instantDry)
        _timeline           = State(initialValue: r?.timeline ?? .overnight)
        _mixerType          = State(initialValue: r?.mixerType ?? .hand)
        _autolyse           = State(initialValue: r?.autolyse ?? false)
        _bassinage          = State(initialValue: r?.bassinage ?? false)
        _autolyseMinutes    = State(initialValue: r?.autolyseMinutes ?? 30)
        _customMixerName    = State(initialValue: r?.customMixerName ?? "")
        _mixingNotes        = State(initialValue: r?.mixingNotes ?? "")
        _ballCount          = State(initialValue: r?.ballCount ?? 6)
        _ballWeight         = State(initialValue: r?.ballWeight ?? 250)
        _buffer             = State(initialValue: r?.buffer ?? 0.025)
        _processCards       = State(initialValue: r?.processCards ?? ProcessCard.defaultCards(autolyse: false, bassinage: false))
        _bakeSetups         = State(initialValue: r?.bakeSetups ?? [])

        let defaultName: String = {
            guard let r else { return "" }
            switch mode {
            case .fork:
                let fmt = DateFormatter(); fmt.dateFormat = "MMM d yyyy"
                return "\(r.name) — \(fmt.string(from: Date()))"
            default: return r.name
            }
        }()
        _name = State(initialValue: defaultName)

        // Pre-select entry modes for edit/fork so back-nav shows the editor, not the pick card.
        // Also jump straight to .create when a converted formula pre-fills the blend.
        _flourBlendMode  = State(initialValue: (convertedFormula != nil || r?.flourBlend.components.isEmpty == false) ? .create : .pick)
        _prefEntryMode   = State(initialValue: (r != nil && r!.method != .direct) ? .create : .pick)
        _processMode     = State(initialValue: r?.processCards.isEmpty == false ? .create : .pick)

        let initRatio: Double = {
            if let r = r { return r.bigaRatio > 0 ? r.bigaRatio : r.style.defaultBigaRatio }
            return PizzaStyle.custom.defaultBigaRatio
        }()
        _prefermentRatio       = State(initialValue: initRatio)
        _prefermentFlourBlend  = State(initialValue: r?.prefermentFlourBlend ?? FlourBlend())
    }

    @State private var step = 0
    @State private var reviewMode = false
    @State private var flourBlendMode: FlourBlendStepView.EntryMode
    @State private var prefEntryMode: MethodStepView.PrefEntryMode
    @State private var processMode: ProcessScriptStepView.EntryMode
    @State private var style: PizzaStyle
    @State private var customStyleName: String
    @State private var usePreferment: Bool
    @State private var prefermentHydration: Double
    @State private var method: PrefermentMethod
    @State private var flourBlend: FlourBlend
    @State private var finalHydration: Double
    @State private var saltPct: Double
    @State private var yeastPct: Double
    @State private var yeastType: YeastType
    @State private var timeline: Timeline
    @State private var mixerType: MixerType
    @State private var autolyse: Bool
    @State private var bassinage: Bool
    @State private var autolyseMinutes: Int
    @State private var customMixerName: String
    @State private var mixingNotes: String
    @State private var ballCount: Int
    @State private var ballWeight: Double
    @State private var buffer: Double
    @State private var processCards: [ProcessCard]
    @State private var bakeSetups: [BakeSetup]
    @State private var name: String
    @State private var prefermentRatio: Double
    @State private var prefermentFlourBlend: FlourBlend

    var isEditMode: Bool { if case .edit = mode { return true }; return false }
    var isForkMode: Bool { if case .fork = mode { return true }; return false }

    let totalSteps = 10


    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: StyleStepView(name: $name, customStyleName: $customStyleName)
                case 1: TargetStepView(ballCount: $ballCount, ballWeight: $ballWeight,
                                       buffer: $buffer, style: style)
                case 2: TimelineStepView(selected: $timeline)
                case 3: FlourBlendStepView(flourBlend: $flourBlend, mode: $flourBlendMode)
                case 4: WaterSaltYeastStepView(
                            finalHydration: $finalHydration,
                            saltPct: $saltPct,
                            yeastPct: $yeastPct,
                            yeastType: $yeastType,
                            styleDefault: style.defaultFinalHydration,
                            isFromConversion: hasConvertedFormula)
                case 5: MethodStepView(usePreferment: $usePreferment,
                                       prefermentHydration: $prefermentHydration,
                                       method: $method,
                                       prefEntryMode: $prefEntryMode,
                                       timeline: $timeline,
                                       prefermentRatio: $prefermentRatio,
                                       prefermentFlourBlend: $prefermentFlourBlend)
                case 6: TechniqueStepView(
                            mixerType: $mixerType,
                            autolyse: $autolyse,
                            bassinage: $bassinage,
                            autolyseMinutes: $autolyseMinutes,
                            customMixerName: $customMixerName,
                            mixingNotes: $mixingNotes,
                            style: style,
                            finalHydration: finalHydration)
                case 7: ProcessScriptStepView(processCards: $processCards, mode: $processMode)
                case 8: BakeMethodStepView(bakeSetups: $bakeSetups)
                case 9: ConfirmStepView(
                            name: $name,
                            style: style,
                            customStyleName: customStyleName,
                            method: method,
                            onJumpTo: { target in
                                reviewMode = true
                                step = target
                            },
                            mixerType: mixerType,
                            autolyse: autolyse,
                            bassinage: bassinage,
                            finalHydration: finalHydration,
                            saltPct: saltPct,
                            yeastPct: yeastPct,
                            yeastType: yeastType,
                            timeline: timeline,
                            ballCount: ballCount,
                            ballWeight: ballWeight,
                            buffer: buffer,
                            flourBlend: flourBlend,
                            prefermentFlourBlend: prefermentFlourBlend,
                            prefermentRatio: prefermentRatio,
                            bakeSetups: bakeSetups,
                            processCards: processCards)
                default: EmptyView()
                }
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { navBar }
            .keyboardDoneButton()
            .onChange(of: autolyse)  { _, val in regenerateCards(autolyse: val, bassinage: bassinage) }
            .onChange(of: bassinage) { _, val in regenerateCards(autolyse: autolyse, bassinage: val) }
            .onChange(of: style)     { _, val in
                // Don't override hydration when it was seeded from a volume conversion
                if !hasConvertedFormula { finalHydration = val.defaultFinalHydration }
            }
            .onChange(of: autolyseMinutes) { _, mins in
                if let idx = processCards.firstIndex(where: { $0.type == .autolyse }) {
                    processCards[idx].customDuration = Double(mins) * 60
                }
            }
        }
        .interactiveDismissDisabled(step > 0)
        .presentationBackground(Color.white)
        .preferredColorScheme(.light)
    }

    var navBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("← Back") { step -= 1 }
                    .buttonStyle(StesuraButtonStyle(filled: false))
            }
            if reviewMode && step != totalSteps - 1 {
                Button("Return to Review →") { step = totalSteps - 1 }
                    .buttonStyle(StesuraButtonStyle(filled: true))
            } else if step < totalSteps - 1 {
                Button("Next →") {
                    step += 1
                }
                .buttonStyle(StesuraButtonStyle(filled: true))
                .disabled((step == 3 && !flourBlend.isValid)
                          || (step == 0 && name.trimmingCharacters(in: .whitespaces).isEmpty))
            } else if isEditMode {
                Button("Save as New →") { saveAsNew() }
                    .buttonStyle(StesuraButtonStyle(filled: false))
                Button("Save Changes →") { save() }
                    .buttonStyle(StesuraButtonStyle(filled: true))
            } else if isForkMode {
                Button("Save as New →") { saveAsNew() }
                    .buttonStyle(StesuraButtonStyle(filled: true))
            } else {
                Button("Save Recipe →") { save() }
                    .buttonStyle(StesuraButtonStyle(filled: true))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    func regenerateCards(autolyse: Bool, bassinage: Bool) {
        processCards = ProcessCard.defaultCards(autolyse: autolyse, bassinage: bassinage)
        if autolyse, let idx = processCards.firstIndex(where: { $0.type == .autolyse }) {
            processCards[idx].customDuration = Double(autolyseMinutes) * 60
        }
    }

    func buildRecipe() -> Recipe {
        let styleName = style == .custom ? (customStyleName.isEmpty ? "My Style" : customStyleName) : style.rawValue
        var recipe = Recipe(
            name: name.isEmpty ? "\(styleName) — \(method.rawValue)" : name,
            style: style,
            method: method,
            mixerType: mixerType,
            autolyse: autolyse,
            bassinage: bassinage,
            timeline: timeline,
            ballCount: ballCount,
            ballWeight: ballWeight,
            buffer: buffer
        )
        recipe.customStyleName     = customStyleName
        recipe.customMixerName     = customMixerName
        recipe.mixingNotes         = mixingNotes
        recipe.finalHydration      = finalHydration
        recipe.saltPct             = saltPct
        recipe.yeastPct            = yeastPct
        recipe.yeastType           = yeastType
        recipe.prefermentHydration = prefermentHydration
        recipe.bigaHydration         = prefermentHydration
        recipe.bigaRatio             = usePreferment ? prefermentRatio : 0
        recipe.flourBlend            = flourBlend
        recipe.prefermentFlourBlend  = usePreferment ? prefermentFlourBlend : FlourBlend()
        recipe.processCards          = processCards
        recipe.bakeSetups            = bakeSetups
        return recipe
    }

    func save() {
        var recipe = buildRecipe()
        if case .edit(let existing) = mode {
            recipe.id = existing.id
            recipe.bakeLogs = existing.bakeLogs
        }
        onComplete(recipe)
    }

    func saveAsNew() {
        var recipe = buildRecipe()
        recipe.id = UUID()
        if let handler = onSaveAsNew { handler(recipe) }
        else { onComplete(recipe) }
    }
}
