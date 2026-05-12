import SwiftUI

struct WizardContainerView: View {
    let onComplete: (Recipe) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var reviewMode = false
    @State private var showProcessWarningAlert = false

    @State private var style: PizzaStyle = .neapolitan
    @State private var customStyleName: String = ""
    @State private var usePreferment: Bool = true
    @State private var prefermentHydration: Double = 0.50
    @State private var method: PrefermentMethod = .biga
    @State private var flourBlend: FlourBlend = FlourBlend()
    @State private var finalHydration: Double = PizzaStyle.neapolitan.defaultFinalHydration
    @State private var saltPct: Double = 0.028
    @State private var yeastPct: Double = 0.001
    @State private var yeastType: YeastType = .instantDry
    @State private var timeline: Timeline = .overnight
    @State private var mixerType: MixerType = .hand
    @State private var autolyse: Bool = false
    @State private var bassinage: Bool = false
    @State private var autolyseMinutes: Int = 30
    @State private var customMixerName: String = ""
    @State private var mixingNotes: String = ""
    @State private var ballCount = 6
    @State private var ballWeight: Double = 250
    @State private var buffer: Double = 0.025
    @State private var processCards: [ProcessCard] = ProcessCard.defaultCards(autolyse: false, bassinage: false)
    @State private var bakeSetups: [BakeSetup] = []
    @State private var name = ""

    let totalSteps = 10

    var processWarnings: [String] {
        let enabled = processCards.sorted { $0.sortOrder < $1.sortOrder }
        var warnings: [String] = []
        for (i, card) in enabled.enumerated() {
            let preceding = Set(enabled.prefix(i).map { $0.type })
            for needed in card.type.warningIfPlacedAfter {
                if !preceding.contains(needed) && enabled.contains(where: { $0.type == needed }) {
                    warnings.append("\"\(card.title)\" should come after \"\(needed.title)\"")
                }
            }
        }
        return warnings
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: StyleStepView(selected: $style, customStyleName: $customStyleName)
                case 1: TargetStepView(ballCount: $ballCount, ballWeight: $ballWeight,
                                       buffer: $buffer, style: style)
                case 2: TimelineStepView(selected: $timeline)
                case 3: FlourBlendStepView(flourBlend: $flourBlend)
                case 4: WaterSaltYeastStepView(
                            finalHydration: $finalHydration,
                            saltPct: $saltPct,
                            yeastPct: $yeastPct,
                            yeastType: $yeastType,
                            styleDefault: style.defaultFinalHydration)
                case 5: MethodStepView(usePreferment: $usePreferment,
                                       prefermentHydration: $prefermentHydration,
                                       method: $method)
                case 6: TechniqueStepView(
                            mixerType: $mixerType,
                            autolyse: $autolyse,
                            bassinage: $bassinage,
                            autolyseMinutes: $autolyseMinutes,
                            customMixerName: $customMixerName,
                            mixingNotes: $mixingNotes,
                            style: style,
                            finalHydration: finalHydration)
                case 7: ProcessScriptStepView(processCards: $processCards)
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
            .onChange(of: autolyse)  { _, val in regenerateCards(autolyse: val, bassinage: bassinage) }
            .onChange(of: bassinage) { _, val in regenerateCards(autolyse: autolyse, bassinage: val) }
            .onChange(of: style)     { _, val in finalHydration = val.defaultFinalHydration }
            .onChange(of: autolyseMinutes) { _, mins in
                if let idx = processCards.firstIndex(where: { $0.type == .autolyse }) {
                    processCards[idx].customDuration = Double(mins) * 60
                }
            }
        }
        .interactiveDismissDisabled(step > 0)
        .alert("Process Order Issues", isPresented: $showProcessWarningAlert) {
            Button("Fix manually", role: .cancel) { }
            Button("Proceed anyway") { step += 1 }
        } message: {
            Text(processWarnings.joined(separator: "\n"))
        }
    }

    var navBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("← Back") { step -= 1 }
                    .buttonStyle(ImpastoButtonStyle(filled: false))
            }
            if reviewMode && step != totalSteps - 1 {
                Button("Return to Review →") { step = totalSteps - 1 }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            } else if step < totalSteps - 1 {
                Button("Next →") {
                    if step == 7 && !processWarnings.isEmpty {
                        showProcessWarningAlert = true
                    } else {
                        step += 1
                    }
                }
                .buttonStyle(ImpastoButtonStyle(filled: true))
                .disabled(step == 3 && !flourBlend.isValid)
            } else {
                Button("Save Recipe →") { save() }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
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

    func save() {
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
        recipe.bigaHydration       = prefermentHydration
        recipe.flourBlend          = flourBlend
        recipe.processCards        = processCards
        recipe.bakeSetups          = bakeSetups
        onComplete(recipe)
    }
}
