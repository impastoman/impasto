import SwiftUI

struct WizardContainerView: View {
    let onComplete: (Recipe) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
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
    @State private var ballCount = 6
    @State private var ballWeight: Double = 250
    @State private var buffer: Double = 0.02
    @State private var processCards: [ProcessCard] = ProcessCard.defaultCards(autolyse: false, bassinage: false)
    @State private var bakeSetups: [BakeSetup] = []
    @State private var name = ""

    let totalSteps = 10

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: StyleStepView(selected: $style, customStyleName: $customStyleName)
                case 1: TargetStepView(ballCount: $ballCount, ballWeight: $ballWeight, buffer: $buffer)
                case 2: TimelineStepView(selected: $timeline, method: method)
                case 3: FlourBlendStepView(flourBlend: $flourBlend)
                case 4: WaterSaltYeastStepView(
                            finalHydration: $finalHydration,
                            saltPct: $saltPct,
                            yeastPct: $yeastPct,
                            yeastType: $yeastType,
                            styleDefault: style.defaultFinalHydration)
                case 5: MethodStepView(usePreferment: $usePreferment, prefermentHydration: $prefermentHydration, method: $method)
                case 6: TechniqueStepView(mixerType: $mixerType, autolyse: $autolyse, bassinage: $bassinage, style: style, finalHydration: finalHydration)
                case 7: ProcessScriptStepView(processCards: $processCards)
                case 8: BakeMethodStepView(bakeSetups: $bakeSetups)
                case 9: ConfirmStepView(
                            name: $name,
                            style: style,
                            customStyleName: customStyleName,
                            method: method,
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
        }
        .interactiveDismissDisabled(step > 0)
    }

    var navBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("← Back") { step -= 1 }
                    .buttonStyle(ImpastoButtonStyle(filled: false))
            }
            if step < totalSteps - 1 {
                Button("Next →") { step += 1 }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
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
        recipe.customStyleName      = customStyleName
        recipe.finalHydration       = finalHydration
        recipe.saltPct              = saltPct
        recipe.yeastPct             = yeastPct
        recipe.yeastType            = yeastType
        recipe.prefermentHydration  = prefermentHydration
        recipe.bigaHydration        = prefermentHydration
        recipe.flourBlend           = flourBlend
        recipe.processCards         = processCards
        recipe.bakeSetups           = bakeSetups
        onComplete(recipe)
    }
}
