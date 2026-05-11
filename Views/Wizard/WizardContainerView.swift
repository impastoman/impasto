import SwiftUI

struct WizardContainerView: View {
    let onComplete: (Recipe) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var style: PizzaStyle = .neapolitan
    @State private var usePreferment: Bool = true
    @State private var prefermentHydration: Double = 0.50
    @State private var method: PrefermentMethod = .biga
    @State private var flourBlend: FlourBlend = FlourBlend()
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

    let totalSteps = 9

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: StyleStepView(selected: $style)
                case 1: MethodStepView(usePreferment: $usePreferment, prefermentHydration: $prefermentHydration, method: $method)
                case 2: FlourBlendStepView(flourBlend: $flourBlend)
                case 3: TimelineStepView(selected: $timeline, method: method)
                case 4: TechniqueStepView(mixerType: $mixerType, autolyse: $autolyse, bassinage: $bassinage, style: style, finalHydration: style.defaultFinalHydration)
                case 5: TargetStepView(ballCount: $ballCount, ballWeight: $ballWeight, buffer: $buffer)
                case 6: ProcessScriptStepView(processCards: $processCards)
                case 7: BakeMethodStepView(bakeSetups: $bakeSetups)
                case 8: ConfirmStepView(name: $name, style: style, method: method, mixerType: mixerType, autolyse: autolyse, bassinage: bassinage, timeline: timeline, ballCount: ballCount, ballWeight: ballWeight, buffer: buffer, flourBlend: flourBlend, bakeSetups: bakeSetups, processCards: processCards)
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
            .onChange(of: autolyse) { _, val in regenerateCards(autolyse: val, bassinage: bassinage) }
            .onChange(of: bassinage) { _, val in regenerateCards(autolyse: autolyse, bassinage: val) }
        }
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
        var recipe = Recipe(
            name: name.isEmpty ? "\(style.rawValue) — \(method.rawValue)" : name,
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
        recipe.prefermentHydration = prefermentHydration
        recipe.bigaHydration = prefermentHydration
        recipe.flourBlend = flourBlend
        recipe.processCards = processCards
        recipe.bakeSetups = bakeSetups
        onComplete(recipe)
    }
}
