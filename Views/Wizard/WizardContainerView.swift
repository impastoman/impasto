import SwiftUI

struct WizardContainerView: View {
    let onComplete: (Recipe) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var style: PizzaStyle = .neapolitan
    @State private var timeline: Timeline = .overnight
    @State private var ballCount = 6
    @State private var ballWeight: Double = 250
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 0: StyleStepView(selected: $style)
                case 1: FlourStepView()
                case 2: TimelineStepView(selected: $timeline)
                case 3: TargetStepView(ballCount: $ballCount, ballWeight: $ballWeight)
                case 4: ConfirmStepView(name: $name, style: style, timeline: timeline, ballCount: ballCount, ballWeight: ballWeight)
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
            .safeAreaInset(edge: .bottom) {
                navBar
            }
        }
    }

    var navBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("← Back") { step -= 1 }
                    .buttonStyle(ImpastoButtonStyle(filled: false))
            }
            if step < 4 {
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

    func save() {
        let recipe = Recipe(
            name: name.isEmpty ? "\(style.rawValue) — \(timeline.rawValue)" : name,
            style: style,
            timeline: timeline,
            ballCount: ballCount,
            ballWeight: ballWeight
        )
        onComplete(recipe)
    }
}
