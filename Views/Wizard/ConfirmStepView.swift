import SwiftUI

struct ConfirmStepView: View {
    @Binding var name: String
    let style: PizzaStyle
    let method: PrefermentMethod
    let mixerType: MixerType
    let autolyse: Bool
    let bassinage: Bool
    let timeline: Timeline
    let ballCount: Int
    let ballWeight: Double
    let buffer: Double
    let flourBlend: FlourBlend
    let bakeSetups: [BakeSetup]
    let processCards: [ProcessCard]

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
            Section { WizardProgressView(step: 8, total: 9) }
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
                LabeledContent("Bassinage",value: bassinage ? "Yes" : "No")
                LabeledContent("Timeline", value: "\(timeline.rawValue)  ·  \(timeline.hours)")
                LabeledContent("Balls",    value: "\(ballCount) × \(Int(ballWeight))g")
                LabeledContent("Buffer",   value: "\(Int(buffer * 100))%")
            }

            if !flourBlend.components.isEmpty {
                Section("Flour blend") {
                    ForEach(flourBlend.components) { c in
                        LabeledContent(c.type.rawValue, value: "\(Int(c.percentage))%")
                    }
                    if !flourBlend.additives.isEmpty {
                        ForEach(flourBlend.additives) { a in
                            LabeledContent(a.type.rawValue, value: "\(a.percentage)%")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .font(.system(.body, design: .monospaced))
            }

            Section("Process script") {
                ForEach(processCards.filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }) { card in
                    HStack {
                        Text(card.title)
                            .font(.system(size: 13, design: .monospaced))
                        Spacer()
                        if card.type.isTimed {
                            Text(shortDuration(card.duration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        } else {
                            Text("action")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if !bakeSetups.isEmpty {
                Section("Bake setups") {
                    ForEach(bakeSetups) { setup in
                        HStack {
                            Text(setup.method.rawValue)
                            Spacer()
                            if !setup.subMethod.isEmpty {
                                Text(setup.subMethod).foregroundColor(.secondary)
                            }
                        }
                        .font(.system(size: 13, design: .monospaced))
                    }
                }
            }

            Section {
                LabeledContent("Hydration",      value: "\(Int(style.defaultFinalHydration * 100))%")
                    .foregroundColor(.secondary)
                LabeledContent("Biga percentage", value: method == .direct ? "N/A" : "\(Int(style.defaultBigaRatio * 100))%")
                    .foregroundColor(.secondary)
                LabeledContent("Est. kneading",   value: "~\(kneadingMinutes) min")
                    .foregroundColor(.secondary)
            } header: {
                Text("Auto-set from style + method")
            } footer: {
                Text("All values adjustable in Recipe Detail after saving.")
            }
        }
    }

    func shortDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
