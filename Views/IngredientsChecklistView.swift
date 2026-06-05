import SwiftUI

struct IngredientsChecklistView: View {
    let recipe: Recipe
    var weightUnit: WeightUnit = .grams
    @Environment(\.dismiss) private var dismiss

    @State private var checked: Set<String> = []

    struct CheckItem: Identifiable {
        let id: String
        let label: String
        let amount: String
        var isSubItem: Bool = false
        var note: String = ""
    }

    var prefermentItems: [CheckItem] {
        guard recipe.method != .direct else { return [] }
        var items: [CheckItem] = []
        let label = recipe.method.rawValue

        // Use preferment-specific blend if set, otherwise fall back to main blend
        let prefBlend = recipe.prefermentFlourBlend.components.isEmpty
            ? recipe.flourBlend
            : recipe.prefermentFlourBlend
        let flourComponents = prefBlend.components

        if flourComponents.count > 1 {
            items.append(CheckItem(id: "pref_flour_header", label: "\(label) flour blend", amount: weightUnit.display(recipe.bigaFlour)))
            for c in flourComponents {
                let weight = recipe.bigaFlour * (c.percentage / 100)
                items.append(CheckItem(id: "pref_flour_\(c.id)", label: c.type.rawValue, amount: weightUnit.display(weight), isSubItem: true, note: c.brand))
            }
        } else {
            let flourLabel = flourComponents.first.map { $0.type.rawValue } ?? "\(label) flour"
            let flourNote  = flourComponents.first?.brand ?? ""
            items.append(CheckItem(id: "pref_flour", label: flourLabel, amount: weightUnit.display(recipe.bigaFlour), note: flourNote))
        }

        items.append(CheckItem(id: "pref_water", label: "\(label) water", amount: weightUnit.display(recipe.bigaWater)))
        items.append(CheckItem(id: "pref_yeast", label: "\(recipe.yeastType.rawValue) yeast", amount: weightUnit.displayPrecise(recipe.bigaYeast)))

        for additive in prefBlend.additives {
            let weight = recipe.bigaFlour * (additive.percentage / 100)
            items.append(CheckItem(id: "pref_add_\(additive.id)", label: additive.type.rawValue, amount: weightUnit.displayPrecise(weight), isSubItem: true, note: additive.note))
        }

        return items
    }

    var mainDoughItems: [CheckItem] {
        var items: [CheckItem] = []
        let flourTotal = recipe.method == .direct ? recipe.totalFlour : recipe.additionalFlour

        let flourComponents = recipe.flourBlend.components
        if flourComponents.count > 1 {
            items.append(CheckItem(id: "flour_header", label: "Flour blend", amount: weightUnit.display(flourTotal)))
            for c in flourComponents {
                let weight = flourTotal * (c.percentage / 100)
                items.append(CheckItem(id: "flour_\(c.id)", label: c.type.rawValue, amount: weightUnit.display(weight), isSubItem: true, note: c.brand))
            }
        } else {
            let flourLabel = flourComponents.first.map { $0.type.rawValue } ?? "Flour"
            let flourNote  = flourComponents.first?.brand ?? ""
            items.append(CheckItem(id: "flour", label: flourLabel, amount: weightUnit.display(flourTotal), note: flourNote))
        }

        for additive in recipe.flourBlend.additives {
            let weight = flourTotal * (additive.percentage / 100)
            items.append(CheckItem(id: "add_\(additive.id)", label: additive.type.rawValue, amount: weightUnit.displayPrecise(weight), isSubItem: true, note: additive.note))
        }

        let waterTotal = recipe.method == .direct ? recipe.totalWater : recipe.additionalWater
        if recipe.bassinage {
            let mainWater = waterTotal - recipe.bassinageReserveGrams
            items.append(CheckItem(id: "water_main", label: "Water (main)", amount: weightUnit.display(mainWater)))
            items.append(CheckItem(id: "water_reserve", label: "Water (bassinage reserve)", amount: weightUnit.display(recipe.bassinageReserveGrams)))
        } else {
            items.append(CheckItem(id: "water", label: "Water", amount: weightUnit.display(waterTotal)))
        }

        items.append(CheckItem(id: "salt", label: "Salt", amount: weightUnit.display(recipe.totalSalt)))

        if recipe.method == .direct {
            items.append(CheckItem(id: "yeast", label: "\(recipe.yeastType.rawValue) yeast", amount: weightUnit.displayPrecise(recipe.bigaYeast)))
        }

        return items
    }

    var allItems: [CheckItem] { prefermentItems + mainDoughItems }
    var checkedCount: Int { checked.intersection(Set(allItems.map { $0.id })).count }

    var body: some View {
        NavigationStack {
            List {
                if !prefermentItems.isEmpty {
                    Section {
                        ForEach(prefermentItems) { item in
                            checkRow(item)
                        }
                    } header: {
                        Text(recipe.method.rawValue)
                    }
                }

                Section {
                    ForEach(mainDoughItems) { item in
                        checkRow(item)
                    }
                } header: {
                    Text(recipe.method == .direct ? "Dough" : "Final dough")
                }

                Section {
                    let total = allItems.count
                    HStack {
                        Text("\(checkedCount) of \(total) measured")
                            .font(.jakarta(.regular, size: 13))
                            .foregroundColor(checkedCount == total ? Color(hex: "D2B96A") : .secondary)
                        Spacer()
                        if checkedCount == total {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                    }
                    Button("Clear all") {
                        checked.removeAll()
                    }
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Ingredients Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    func checkRow(_ item: CheckItem) -> some View {
        HStack(spacing: 10) {
            if item.isSubItem {
                Spacer().frame(width: 12)
            }
            Button {
                if checked.contains(item.id) {
                    checked.remove(item.id)
                } else {
                    checked.insert(item.id)
                }
            } label: {
                Image(systemName: checked.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(checked.contains(item.id) ? Color(hex: "D2B96A") : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.label)
                    .font(.system(item.isSubItem ? .subheadline : .body, design: .monospaced))
                    .foregroundColor(checked.contains(item.id) ? .secondary : .primary)
                    .strikethrough(checked.contains(item.id), color: .secondary)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.jakarta(.regular, size: 11))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(item.amount)
                .font(.jakarta(.regular, size: 15))
                .foregroundColor(checked.contains(item.id) ? .secondary : Color(hex: "D2B96A"))
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
        .animation(.easeInOut(duration: 0.15), value: checked.contains(item.id))
    }
}
