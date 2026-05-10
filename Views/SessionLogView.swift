import SwiftUI

struct SessionLogView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 3
    @State private var crustTags: Set<CrustTag> = []
    @State private var crumbTags: Set<CrumbTag> = []
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Overall") {
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .foregroundColor(Color(hex: "D2B96A"))
                                .font(.title3)
                                .onTapGesture { rating = i }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Crust") {
                    HStack(spacing: 8) {
                        ForEach(CrustTag.allCases, id: \.self) { tag in
                            TagChip(label: tag.rawValue, selected: crustTags.contains(tag)) {
                                if crustTags.contains(tag) { crustTags.remove(tag) } else { crustTags.insert(tag) }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Crumb") {
                    HStack(spacing: 8) {
                        ForEach(CrumbTag.allCases, id: \.self) { tag in
                            TagChip(label: tag.rawValue, selected: crumbTags.contains(tag)) {
                                if crumbTags.contains(tag) { crumbTags.remove(tag) } else { crumbTags.insert(tag) }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Notes") {
                    TextField("Observations...", text: $notes, axis: .vertical)
                        .lineLimit(4...)
                }

                Section {
                    Button("Save to History") { save() }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
            .navigationTitle("How'd it go?")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    func save() {
        let log = BakeLog(
            recipeId: recipe.id,
            rating: rating,
            crustTags: Array(crustTags),
            crumbTags: Array(crumbTags),
            notes: notes,
            ballCount: recipe.ballCount,
            ballWeight: recipe.ballWeight,
            finalHydration: recipe.finalHydration
        )
        store.addBakeLog(log, to: recipe.id)
        dismiss()
    }
}

struct TagChip: View {
    let label: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(label)
            .font(.system(size: 12, design: .monospaced))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(selected ? Color(hex: "D2B96A").opacity(0.18) : Color(hex: "1A1B18"))
            .foregroundColor(selected ? Color(hex: "D2B96A") : .secondary)
            .cornerRadius(5)
            .onTapGesture(perform: onTap)
    }
}
