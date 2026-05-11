import SwiftUI

struct ProcessScriptStepView: View {
    @Binding var processCards: [ProcessCard]

    var body: some View {
        List {
            Section { WizardProgressView(step: 6, total: 9) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            Section {
                ForEach($processCards) { $card in
                    ProcessCardRow(card: $card)
                }
                .onMove { from, to in
                    processCards.move(fromOffsets: from, toOffset: to)
                    for i in processCards.indices { processCards[i].sortOrder = i }
                }
            } header: {
                HStack {
                    Text("Process script")
                    Spacer()
                    EditButton()
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            } footer: {
                Text("Hold and drag to reorder · toggle to enable/disable steps · tap to add a note")
                    .font(.system(size: 11, design: .monospaced))
            }

            warningSection
        }
    }

    @ViewBuilder
    var warningSection: some View {
        let warnings = orderWarnings()
        if !warnings.isEmpty {
            Section {
                ForEach(warnings, id: \.self) { w in
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(w)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
            } header: {
                Text("Order warnings")
            } footer: {
                Text("You can still proceed — warnings are advisory only. Tap 'Auto-order' to reset.")
                    .font(.system(size: 11, design: .monospaced))
            }
            .listRowBackground(Color.orange.opacity(0.06))

            Section {
                Button("Reset to default order") {
                    let auto = processCards.contains { $0.type == .autolyse && $0.isEnabled }
                    let bass = processCards.contains { $0.type == .bassinage && $0.isEnabled }
                    processCards = ProcessCard.defaultCards(autolyse: auto, bassinage: bass)
                }
                .foregroundColor(Color(hex: "D2B96A"))
                .font(.system(.body, design: .monospaced))
            }
        }
    }

    func orderWarnings() -> [String] {
        let enabled = processCards.filter { $0.isEnabled }
        var warnings: [String] = []
        for (i, card) in enabled.enumerated() {
            let preceding = Set(enabled.prefix(i).map { $0.type })
            for problematic in card.type.warningIfPlacedAfter {
                if !preceding.contains(problematic) && enabled.contains(where: { $0.type == problematic }) {
                    warnings.append("\"\(card.title)\" should come after \"\(problematic.title)\"")
                }
            }
        }
        return warnings
    }
}

private struct ProcessCardRow: View {
    @Binding var card: ProcessCard
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Toggle("", isOn: $card.isEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "D2B96A"))
                    .scaleEffect(0.8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(card.isEnabled ? .primary : .secondary)
                    Text(card.subtitle)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if card.type.isTimed && card.isEnabled {
                    Text(shortDuration(card.duration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Button {
                    withAnimation { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)

            if expanded && card.isEnabled {
                VStack(spacing: 10) {
                    Divider()

                    if card.type.isTimed {
                        HStack {
                            Text("Duration")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("min", value: Binding(
                                get: { Int(card.duration / 60) },
                                set: { card.customDuration = Double($0) * 60 }
                            ), format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 52)
                            .font(.system(size: 13, design: .monospaced))
                            .multilineTextAlignment(.trailing)
                            Text("min").font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                        }
                    }

                    if card.type == .bassinage {
                        HStack {
                            Text("Reserve water")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(card.bassinageReservePct * 100))%")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                        Slider(value: $card.bassinageReservePct, in: 0.05...0.20, step: 0.01)
                            .tint(Color(hex: "D2B96A"))
                    }

                    if card.type == .autolyse {
                        Picker("Mode", selection: $card.autolyseMode) {
                            ForEach(AutolyseMode.allCases, id: \.self) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .font(.system(size: 13, design: .monospaced))
                        Text(card.autolyseMode.description)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("Add a note for this step...", text: $card.recipeNote, axis: .vertical)
                            .font(.system(size: 13, design: .monospaced))
                            .lineLimit(2...)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    func shortDuration(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
