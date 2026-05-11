import SwiftUI

struct FlourBlendStepView: View {
    @Binding var flourBlend: FlourBlend

    var body: some View {
        List {
            Section { WizardProgressView(step: 3, total: 10) }
                .listRowBackground(Color.clear)
                .listRowInsets(.init())

            flourSection
            totalRow
            addFlourRow
            additivesSection
            hintsSection
        }
    }

    var flourSection: some View {
        Section("Flour blend") {
            ForEach($flourBlend.components) { $component in
                FlourComponentRow(component: $component) {
                    flourBlend.components.removeAll { $0.id == component.id }
                }
            }
        }
    }

    var totalRow: some View {
        let total = flourBlend.totalPercentage
        let isValid = flourBlend.isValid
        return HStack {
            Text("Total").foregroundColor(.secondary).font(.system(.body, design: .monospaced))
            Spacer()
            Text(String(format: "%.0f%%", total) + (isValid ? "  ✓" : ""))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(isValid ? Color(hex: "D2B96A") : .red)
        }
        .listRowBackground(Color.clear)
    }

    var addFlourRow: some View {
        Button {
            flourBlend.components.append(FlourComponent())
        } label: {
            Label("Add flour type", systemImage: "plus")
                .foregroundColor(Color(hex: "D2B96A"))
                .font(.system(.body, design: .monospaced))
        }
    }

    var additivesSection: some View {
        Section {
            ForEach($flourBlend.additives) { $additive in
                AdditiveRow(additive: $additive) {
                    flourBlend.additives.removeAll { $0.id == additive.id }
                }
            }
            Button {
                flourBlend.additives.append(Additive())
            } label: {
                Label("Add additive", systemImage: "plus")
                    .foregroundColor(Color(hex: "D2B96A"))
                    .font(.system(.body, design: .monospaced))
            }
        } header: {
            Text("Additives  ·  % of total flour weight")
        }
    }

    var hintsSection: some View {
        Group {
            if flourBlend.containsRye {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text("Rye flour does not autolyse well — consider disabling autolyse if your blend contains rye")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .listRowBackground(Color.orange.opacity(0.06))
            }
            if !flourBlend.isValid {
                Section {
                    Text("Flour percentages must total 100%")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.red)
                }
                .listRowBackground(Color.red.opacity(0.06))
            }
        }
    }
}

private struct FlourComponentRow: View {
    @Binding var component: FlourComponent
    let onRemove: () -> Void
    @State private var showNote = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: $component.type) {
                    ForEach(FlourType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("0", value: $component.percentage, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .font(.system(.body, design: .monospaced))

                Text("%").foregroundColor(.secondary).font(.system(.body, design: .monospaced))

                Button(action: onRemove) {
                    Image(systemName: "minus.circle").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                TextField("gluten %", value: $component.glutenPct, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 72)
                    .font(.system(size: 13, design: .monospaced))
                Text("% gluten").font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                Spacer()
                TextField("brand / note", text: $component.brand)
                    .font(.system(size: 13, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            }

            if !component.type.typicalGlutenRange.isEmpty {
                Text("Typical: \(component.type.typicalGlutenRange)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AdditiveRow: View {
    @Binding var additive: Additive
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Picker("", selection: $additive.type) {
                    ForEach(AdditiveType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField("0", value: $additive.percentage, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)
                    .font(.system(.body, design: .monospaced))

                Text("%").foregroundColor(.secondary).font(.system(.body, design: .monospaced))

                Button(action: onRemove) {
                    Image(systemName: "minus.circle").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack {
                TextField("note", text: $additive.note)
                    .font(.system(size: 13, design: .monospaced))
                if !additive.type.typicalRange.isEmpty {
                    Text("Typical: \(additive.type.typicalRange)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
