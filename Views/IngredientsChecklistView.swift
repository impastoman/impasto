import SwiftUI

struct IngredientsChecklistView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss

    @State private var checked: Set<String> = []

    struct CheckItem: Identifiable {
        let id: String
        let label: String
        let amount: String
        var isSubItem: Bool = false
    }

    var prefermentItems: [CheckItem] {
        guard recipe.method != .direct else { return [] }
        var items: [CheckItem] = []
        let label = recipe.method.rawValue

        let flourComponents = recipe.flourBlend.components
        if flourComponents.count > 1 {
            items.append(CheckItem(id: "pref_flour_header", label: "\(label) flour blend", amount: "\(Int(recipe.bigaFlour))g"))
            for c in flourComponents {
                let weight = recipe.bigaFlour * (c.percentage / 100)
                items.append(CheckItem(id: "pref_flour_\(c.id)", label: c.type.rawValue, amount: "\(Int(weight))g", isSubItem: true))
            }
        } else {
            items.append(CheckItem(id: "pref_flour", label: "\(label) flour", amount: "\(Int(recipe.bigaFlour))g"))
        }

        items.append(CheckItem(id: "pref_water", label: "\(label) water", amount: "\(Int(recipe.bigaWater))g"))
        items.append(CheckItem(id: "pref_yeast", label: "\(recipe.yeastType.rawValue) yeast", amount: String(format: "%.1fg", recipe.bigaYeast)))

        for additive in recipe.flourBlend.additives {
            let weight = recipe.bigaFlour * (additive.percentage / 100)
            items.append(CheckItem(id: "pref_add_\(additive.id)", label: additive.type.rawValue, amount: "\(Int(weight))g", isSubItem: true))
        }

        return items
    }

    var mainDoughItems: [CheckItem] {
        var items: [CheckItem] = []
        let flourTotal = recipe.method == .direct ? recipe.totalFlour : recipe.additionalFlour

        let flourComponents = recipe.flourBlend.components
        if flourComponents.count > 1 {
            items.append(CheckItem(id: "flour_header", label: "Flour blend", amount: "\(Int(flourTotal))g"))
            for c in flourComponents {
                let weight = flourTotal * (c.percentage / 100)
                items.append(CheckItem(id: "flour_\(c.id)", label: c.type.rawValue, amount: "\(Int(weight))g", isSubItem: true))
            }
        } else {
            let flourLabel = flourComponents.first.map { $0.type.rawValue } ?? "Flour"
            items.append(CheckItem(id: "flour", label: flourLabel, amount: "\(Int(flourTotal))g"))
        }

        for additive in recipe.flourBlend.additives {
            let weight = flourTotal * (additive.percentage / 100)
            items.append(CheckItem(id: "add_\(additive.id)", label: additive.type.rawValue, amount: "\(Int(weight))g", isSubItem: true))
        }

        let waterTotal = recipe.method == .direct ? recipe.totalWater : recipe.additionalWater
        if recipe.bassinage {
            let mainWater = waterTotal - recipe.bassinageReserveGrams
            items.append(CheckItem(id: "water_main", label: "Water (main)", amount: "\(Int(mainWater))g"))
            items.append(CheckItem(id: "water_reserve", label: "Water (bassinage reserve)", amount: "\(Int(recipe.bassinageReserveGrams))g"))
        } else {
            items.append(CheckItem(id: "water", label: "Water", amount: "\(Int(waterTotal))g"))
        }

        items.append(CheckItem(id: "salt", label: "Salt", amount: "\(Int(recipe.totalSalt))g"))

        if recipe.method == .direct {
            items.append(CheckItem(id: "yeast", label: "\(recipe.yeastType.rawValue) yeast", amount: String(format: "%.1fg", recipe.bigaYeast)))
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
                            .font(.system(size: 13, design: .monospaced))
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
                    .font(.system(size: 13, design: .monospaced))
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

            Text(item.label)
                .font(.system(item.isSubItem ? .subheadline : .body, design: .monospaced))
                .foregroundColor(checked.contains(item.id) ? .secondary : .primary)
                .strikethrough(checked.contains(item.id), color: .secondary)
            Spacer()
            Text(item.amount)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(checked.contains(item.id) ? .secondary : Color(hex: "D2B96A"))
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
        .animation(.easeInOut(duration: 0.15), value: checked.contains(item.id))
    }
}
