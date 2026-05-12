import SwiftUI

struct ConfirmStepView: View {
    @Binding var name: String
    let style: PizzaStyle
    let customStyleName: String
    let method: PrefermentMethod
    let onJumpTo: (Int) -> Void
    let mixerType: MixerType
    let autolyse: Bool
    let bassinage: Bool
    let finalHydration: Double
    let saltPct: Double
    let yeastPct: Double
    let yeastType: YeastType
    let timeline: Timeline
    let ballCount: Int
    let ballWeight: Double
    let buffer: Double
    let flourBlend: FlourBlend
    let bakeSetups: [BakeSetup]
    let processCards: [ProcessCard]

    var styleLabel: String {
        style == .custom ? (customStyleName.isEmpty ? "My Style" : customStyleName) : style.rawValue
    }

    var kneadingMinutes: Int {
        switch mixerType {
        case .hand:       return finalHydration > 0.70 ? 15 : 10
        case .standMixer: return finalHydration > 0.70 ? 10 : 8
        case .spiral:     return finalHydration > 0.70 ? 6 : 5
        case .other:      return 10
        }
    }

    var body: some View {
        List {
            Section { WizardProgressView(step: 9, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section("Name your recipe") {
                TextField("e.g. My Neapolitan", text: $name)
                    .font(.system(.body, design: .monospaced))
            }

            Section {
                LabeledContent("Style",           value: styleLabel)
                LabeledContent("Preferment",      value: method == .direct ? "Not used" : method.rawValue)
                if method != .direct && !flourBlend.name.isEmpty {
                    LabeledContent("Preferment blend", value: flourBlend.name)
                        .foregroundColor(Color(hex: "D2B96A"))
                }
                LabeledContent("Flour blend",     value: flourBlend.name.isEmpty ? "Custom" : flourBlend.name)
                    .foregroundColor(flourBlend.name.isEmpty ? .secondary : Color(hex: "D2B96A"))
                LabeledContent("Mixer",           value: mixerType.rawValue)
                LabeledContent("Autolyse",        value: autolyse ? "Yes — \(style == .neapolitan ? 20 : 30) min" : "No")
                LabeledContent("Bassinage",       value: bassinage ? "Yes" : "No")
                LabeledContent("Timeline",        value: "\(timeline.rawValue)  ·  \(timeline.hours)")
                LabeledContent("Balls",           value: "\(ballCount) × \(Int(ballWeight))g")
                LabeledContent("Loss factor",     value: "\(max(1, Int(buffer * Double(ballCount) * ballWeight)))g")
            } header: { sectionHeader("Summary", step: 0) }

            if !flourBlend.components.isEmpty {
                Section {
                    ForEach(flourBlend.components) { c in
                        LabeledContent(c.type.rawValue, value: "\(Int(c.percentage))%")
                    }
                    ForEach(flourBlend.additives) { a in
                        LabeledContent(a.type.rawValue, value: "\(a.percentage)%")
                            .foregroundColor(.secondary)
                    }
                } header: { sectionHeader("Flour blend", step: 3) }
                .font(.system(.body, design: .monospaced))
            }

            Section {
                ForEach(processCards.sorted { $0.sortOrder < $1.sortOrder }) { card in
                    HStack {
                        Text(card.title).font(.system(size: 13, design: .monospaced))
                        Spacer()
                        if card.type.isTimed {
                            Text(shortDuration(card.duration))
                                .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                        } else {
                            Text("action")
                                .font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                        }
                    }
                }
            } header: { sectionHeader("Process", step: 7) }

            if !bakeSetups.isEmpty {
                Section {
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
                } header: { sectionHeader("Bake setups", step: 8) }
            }

            Section {
                LabeledContent("Hydration",       value: "\(Int(finalHydration * 100))%").foregroundColor(.secondary)
                LabeledContent("Salt",            value: String(format: "%.1f%%", saltPct * 100)).foregroundColor(.secondary)
                LabeledContent("Yeast",           value: "\(yeastType.rawValue)  ·  \(String(format: "%.2f%%", yeastPct * 100))").foregroundColor(.secondary)
                LabeledContent("Biga percentage", value: method == .direct ? "N/A" : "\(Int(style.defaultBigaRatio * 100))%").foregroundColor(.secondary)
                LabeledContent("Est. kneading",   value: "~\(kneadingMinutes) min").foregroundColor(.secondary)
            } header: {
                Text(style == .custom ? "Balanced defaults (no style preset)" : "Auto-set from style + method")
            } footer: {
                Text("All values adjustable in Recipe Detail after saving.")
            }
        }
    }

    func sectionHeader(_ title: String, step: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Button("Edit") { onJumpTo(step) }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "D2B96A"))
        }
    }

    func shortDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
