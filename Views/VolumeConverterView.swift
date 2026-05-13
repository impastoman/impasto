import SwiftUI

// MARK: - Amount Parsing (file-scope)

private func parseAmount(_ text: String) -> Double {
    let trimmed = text.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return 0 }

    // Mixed number: "1 1/4"
    let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
    if parts.count == 2, let whole = Double(parts[0]) {
        if let frac = parseFraction(String(parts[1])) { return whole + frac }
    }
    // Plain fraction: "3/4"
    if let frac = parseFraction(trimmed) { return frac }
    // Decimal / integer
    return Double(trimmed) ?? 0
}

private func parseFraction(_ text: String) -> Double? {
    let parts = text.split(separator: "/")
    guard parts.count == 2,
          let num = Double(parts[0]),
          let den = Double(parts[1]),
          den > 0 else { return nil }
    return num / den
}

// MARK: - Data Models

struct FlourEntry: Identifiable {
    var id = UUID()
    var amountText: String
    var unit: VolumeUnit
    var flourType: FlourType

    init(amountText: String = "", unit: VolumeUnit = .cups, flourType: FlourType = .allPurpose) {
        self.amountText = amountText
        self.unit = unit
        self.flourType = flourType
    }

    var amount: Double { parseAmount(amountText) }
    var grams: Double  { VolumeConversion.flourToGrams(amount, unit, flourType) }
}

struct IngredientEntry {
    var amountText: String
    var unit: VolumeUnit

    init(amountText: String = "", unit: VolumeUnit = .teaspoons) {
        self.amountText = amountText
        self.unit = unit
    }

    var amount: Double { parseAmount(amountText) }
}

// MARK: - VolumeConverterView

struct VolumeConverterView: View {
    let onConvert: (ConvertedFormula) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var flourEntries: [FlourEntry] = [FlourEntry(unit: .cups, flourType: .allPurpose)]
    @State private var waterEntry  = IngredientEntry(unit: .cups)
    @State private var saltEntry   = IngredientEntry(unit: .teaspoons)
    @State private var saltKind: SaltKind  = .table
    @State private var yeastEntry  = IngredientEntry(unit: .teaspoons)
    @State private var yeastType: YeastType = .instantDry

    private var canReview: Bool {
        flourEntries.allSatisfy { !$0.amountText.isEmpty && $0.grams > 0 }
            && !waterEntry.amountText.isEmpty
            && waterEntry.amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                flourSection
                waterSection
                saltSection
                yeastSection
                hintSection
            }
            .navigationTitle("Convert a Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 13, design: .monospaced))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ConversionReviewView(
                            flourEntries: flourEntries,
                            waterEntry: waterEntry,
                            saltEntry: saltEntry,
                            saltKind: saltKind,
                            yeastEntry: yeastEntry,
                            yeastType: yeastType,
                            onConvert: onConvert
                        )
                    } label: {
                        Text("Review →")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(canReview ? Color(hex: "D2B96A") : .secondary)
                    }
                    .disabled(!canReview)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Sections

    private var flourSection: some View {
        Section {
            ForEach($flourEntries) { $entry in
                FlourEntryRow(entry: $entry)
            }
            .onDelete { idx in flourEntries.remove(atOffsets: idx) }

            Button {
                flourEntries.append(FlourEntry(unit: .cups, flourType: .bread))
            } label: {
                Label("Add another flour", systemImage: "plus.circle")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(hex: "D2B96A"))
            }
        } header: {
            sectionHeader("Flour")
        }
    }

    private var waterSection: some View {
        Section {
            AmountUnitRow(
                amountText: $waterEntry.amountText,
                unit: $waterEntry.unit,
                units: [.cups, .milliliters, .tablespoons, .teaspoons, .grams, .ounces],
                placeholder: "e.g. 1 1/4"
            )
        } header: { sectionHeader("Water") }
    }

    private var saltSection: some View {
        Section {
            AmountUnitRow(
                amountText: $saltEntry.amountText,
                unit: $saltEntry.unit,
                units: [.teaspoons, .tablespoons, .grams, .ounces],
                placeholder: "e.g. 1 1/2"
            )
            Picker("Salt type", selection: $saltKind) {
                ForEach(SaltKind.allCases, id: \.self) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .font(.system(size: 13, design: .monospaced))
        } header: { sectionHeader("Salt (optional)") }
    }

    private var yeastSection: some View {
        Section {
            AmountUnitRow(
                amountText: $yeastEntry.amountText,
                unit: $yeastEntry.unit,
                units: [.teaspoons, .tablespoons, .grams],
                placeholder: "e.g. 1/4"
            )
            Picker("Yeast type", selection: $yeastType) {
                ForEach(YeastType.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .font(.system(size: 13, design: .monospaced))
        } header: { sectionHeader("Yeast (optional)") }
    }

    private var hintSection: some View {
        Section {
            Text("Fractions like \"1/4\", mixed numbers like \"1 1/4\", and decimals like \"0.25\" all work for amounts.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, design: .monospaced))
            .tracking(1.5)
    }
}

// MARK: - FlourEntryRow

private struct FlourEntryRow: View {
    @Binding var entry: FlourEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AmountUnitRow(
                amountText: $entry.amountText,
                unit: $entry.unit,
                units: [.cups, .tablespoons, .teaspoons, .grams, .ounces],
                placeholder: "e.g. 2"
            )
            Picker("Flour type", selection: $entry.flourType) {
                ForEach(FlourType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            .font(.system(size: 13, design: .monospaced))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - AmountUnitRow

private struct AmountUnitRow: View {
    @Binding var amountText: String
    @Binding var unit: VolumeUnit
    let units: [VolumeUnit]
    let placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $amountText)
                .keyboardType(.default)
                .font(.system(size: 14, design: .monospaced))
                .frame(maxWidth: .infinity)

            Picker("Unit", selection: $unit) {
                ForEach(units, id: \.self) { u in
                    Text(u.rawValue).tag(u)
                }
            }
            .pickerStyle(.menu)
            .font(.system(size: 13, design: .monospaced))
        }
    }
}

// MARK: - ConversionReviewView

struct ConversionReviewView: View {
    let flourEntries: [FlourEntry]
    let waterEntry: IngredientEntry
    let saltEntry: IngredientEntry
    let saltKind: SaltKind
    let yeastEntry: IngredientEntry
    let yeastType: YeastType
    let onConvert: (ConvertedFormula) -> Void

    // MARK: Computed weights

    private var totalFlourGrams: Double {
        flourEntries.reduce(0) { $0 + $1.grams }
    }

    private var waterGrams: Double {
        VolumeConversion.waterToGrams(waterEntry.amount, waterEntry.unit)
    }

    private var saltGrams: Double {
        guard saltEntry.amount > 0 else { return 0 }
        return VolumeConversion.saltToGrams(saltEntry.amount, saltEntry.unit, saltKind)
    }

    private var yeastGrams: Double {
        guard yeastEntry.amount > 0 else { return 0 }
        return VolumeConversion.yeastToGrams(yeastEntry.amount, yeastEntry.unit, yeastType)
    }

    private var hydration: Double { totalFlourGrams > 0 ? waterGrams  / totalFlourGrams : 0 }
    private var saltPct:   Double { totalFlourGrams > 0 ? saltGrams   / totalFlourGrams : 0 }
    private var yeastPct:  Double { totalFlourGrams > 0 ? yeastGrams  / totalFlourGrams : 0 }

    private var builtFlourBlend: FlourBlend {
        var blend = FlourBlend()
        if flourEntries.count == 1 {
            blend.components = [FlourComponent(type: flourEntries[0].flourType, percentage: 100)]
        } else {
            blend.components = flourEntries.map { entry in
                let pct = totalFlourGrams > 0
                    ? (entry.grams / totalFlourGrams * 1000).rounded() / 10   // 1 decimal place
                    : 0
                return FlourComponent(type: entry.flourType, percentage: pct)
            }
        }
        return blend
    }

    private var formula: ConvertedFormula {
        ConvertedFormula(
            finalHydration: hydration,
            saltPct: saltPct > 0 ? saltPct : 0.028,
            yeastPct: yeastPct > 0 ? yeastPct : 0.001,
            yeastType: yeastType,
            flourBlend: builtFlourBlend
        )
    }

    // MARK: Warnings

    private var warnings: [String] {
        var list: [String] = []
        if hydration < 0.55 || hydration > 0.92 {
            list.append("Hydration of \(Int(hydration * 100))% is outside the typical pizza range (55–92%) — double-check your water amount.")
        }
        if saltPct > 0.04 {
            list.append("Salt at \(String(format: "%.2f", saltPct * 100))% is high — typical is 2–3%.")
        }
        if yeastPct > 0.015 {
            list.append("Yeast at \(String(format: "%.3f", yeastPct * 100))% is quite high — typical is 0.1–0.5%.")
        }
        return list
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ingredientTable
                percentageSummary
                notesBlock
                buildButton
            }
            .padding(16)
        }
        .background(Color(hex: "F5F1E8").ignoresSafeArea())
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Ingredient table

    private var ingredientTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            tableHeader("INGREDIENTS")

            ForEach(Array(flourEntries.enumerated()), id: \.element.id) { idx, entry in
                if idx > 0 { Divider().padding(.leading, 16) }
                tableRow(
                    label: entry.flourType.rawValue,
                    amount: "\(entry.amountText) \(entry.unit.rawValue)",
                    grams: entry.grams,
                    annotation: totalFlourGrams > 0
                        ? String(format: "%.1f%% of flour", entry.grams / totalFlourGrams * 100)
                        : ""
                )
            }

            Divider().padding(.leading, 16)
            tableRow(
                label: "Water",
                amount: "\(waterEntry.amountText) \(waterEntry.unit.rawValue)",
                grams: waterGrams,
                annotation: String(format: "%.1f%% baker's", hydration * 100)
            )

            if saltGrams > 0 {
                Divider().padding(.leading, 16)
                tableRow(
                    label: "Salt (\(saltKind.rawValue))",
                    amount: "\(saltEntry.amountText) \(saltEntry.unit.rawValue)",
                    grams: saltGrams,
                    annotation: String(format: "%.2f%% baker's", saltPct * 100)
                )
            }

            if yeastGrams > 0 {
                Divider().padding(.leading, 16)
                tableRow(
                    label: "Yeast (\(yeastType.rawValue))",
                    amount: "\(yeastEntry.amountText) \(yeastEntry.unit.rawValue)",
                    grams: yeastGrams,
                    annotation: String(format: "%.3f%% baker's", yeastPct * 100)
                )
            }
        }
        .background(Color.white)
        .cornerRadius(10)
    }

    // MARK: - Baker's % summary

    private var percentageSummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            tableHeader("BAKER'S PERCENTAGES")
            summaryRow(label: "Total flour", value: String(format: "%.0f g", totalFlourGrams))
            Divider().padding(.leading, 16)
            summaryRow(label: "Hydration", value: String(format: "%.1f%%", hydration * 100))
            if saltPct > 0 {
                Divider().padding(.leading, 16)
                summaryRow(label: "Salt", value: String(format: "%.2f%%", saltPct * 100))
            }
            if yeastPct > 0 {
                Divider().padding(.leading, 16)
                summaryRow(label: "Yeast", value: String(format: "%.3f%%", yeastPct * 100))
            }
        }
        .background(Color.white)
        .cornerRadius(10)
    }

    // MARK: - Notes & warnings

    private var notesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("These values are estimates — volume measurements vary depending on how flour is scooped. The recipe wizard lets you fine-tune everything before saving.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(warnings, id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Build button

    private var buildButton: some View {
        Button("Build This Recipe →") {
            onConvert(formula)
        }
        .buttonStyle(ImpastoButtonStyle(filled: true))
        .padding(.top, 4)
    }

    // MARK: - Sub-view helpers

    private func tableHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(Color(hex: "9A9688"))
            .tracking(2)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
    }

    private func tableRow(label: String, amount: String, grams: Double, annotation: String) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.primary)
                Text(amount)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f g", grams))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.primary)
                if !annotation.isEmpty {
                    Text(annotation)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "9A9688"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "D2B96A"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
