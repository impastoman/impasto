import SwiftUI

struct ConfirmStepView: View {
    @Binding var name: String
    let style: PizzaStyle
    let method: PrefermentMethod
    let mixerType: MixerType
    let autolyse: Bool
    let timeline: Timeline
    let ballCount: Int
    let ballWeight: Double

    var kneadingMinutes: Int {
        switch mixerType {
        case .hand:       return style.defaultFinalHydration > 0.70 ? 15 : 10
        case .standMixer: return style.defaultFinalHydration > 0.70 ? 10 : 8
        case .spiral:     return style.defaultFinalHydration > 0.70 ? 6 : 5
        case .other:      return 10
        }
    }

    var body: some View {
        List {
            Section { WizardProgressView(step: 6, total: 7) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("Name your recipe") {
                TextField("e.g. My Neapolitan", text: $name)
                    .font(.system(.body, design: .monospaced))
            }

            Section("Summary") {
                LabeledContent("Style",    value: style.rawValue)
                LabeledContent("Method",   value: method.rawValue)
                LabeledContent("Mixer",    value: mixerType.rawValue)
                LabeledContent("Autolyse", value: autolyse ? "Yes — \(style == .neapolitan ? 20 : 30) min" : "No")
                LabeledContent("Flour",    value: "Wheat")
                LabeledContent("Timeline", value: "\(timeline.rawValue)  ·  \(timeline.hours)")
                LabeledContent("Balls",    value: "\(ballCount) × \(Int(ballWeight))g")
            }

            Section {
                LabeledContent("Hydration",      value: "\(Int(style.defaultFinalHydration * 100))%")
                    .foregroundColor(.secondary)
                LabeledContent("Biga ratio",     value: method == .direct ? "N/A" : "\(Int(style.defaultBigaRatio * 100))%")
                    .foregroundColor(.secondary)
                LabeledContent("Est. kneading",  value: "~\(kneadingMinutes) min")
                    .foregroundColor(.secondary)
            } header: {
                Text("Auto-set from style + method")
            } footer: {
                Text("All values adjustable in Recipe Detail after saving.")
            }
        }
    }
}
