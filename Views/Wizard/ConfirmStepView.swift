import SwiftUI

struct ConfirmStepView: View {
    @Binding var name: String
    let style: PizzaStyle
    let timeline: Timeline
    let ballCount: Int
    let ballWeight: Double

    var body: some View {
        List {
            Section { WizardProgressView(step: 4, total: 5) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("Name your recipe") {
                TextField("e.g. My Neapolitan", text: $name)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Summary") {
                LabeledContent("Style",    value: style.rawValue)
                LabeledContent("Flour",    value: "Wheat")
                LabeledContent("Timeline", value: "\(timeline.rawValue)  ·  \(timeline.hours)")
                LabeledContent("Balls",    value: "\(ballCount) × \(Int(ballWeight))g")
            }

            Section {
                LabeledContent("Hydration",  value: "\(Int(style.defaultFinalHydration * 100))%")
                    .foregroundColor(.secondary)
                LabeledContent("Biga ratio", value: "\(Int(style.defaultBigaRatio * 100))%")
                    .foregroundColor(.secondary)
            } header: {
                Text("Auto-set from style")
            } footer: {
                Text("All values are adjustable in Recipe Detail after saving.")
            }
        }
    }
}
