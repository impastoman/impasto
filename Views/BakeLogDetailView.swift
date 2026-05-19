import SwiftUI

struct BakeLogDetailView: View {
    let log: BakeLog
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore

    @State private var selectedTab = 0
    @State private var annotatedRating: Int
    @State private var annotatedNotes: String
    @State private var saved = false
    @State private var showForkWizard = false

    init(log: BakeLog, recipe: Recipe) {
        self.log = log
        self.recipe = recipe
        _annotatedRating = State(initialValue: log.annotatedRating ?? log.rating)
        _annotatedNotes = State(initialValue: log.annotatedNotes)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("As Baked").tag(0)
                Text("Annotated").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal).padding(.top, 10).padding(.bottom, 6)

            if selectedTab == 0 { asBakedTab }
            else { annotatedTab }
        }
        .background { RuledPaperBackground() }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.paperHeader, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            FillerPaperHeaderBand(title: recipe.name)
        }
        .sheet(isPresented: $showForkWizard) {
            let forked = forkedRecipe()
            WizardContainerView(mode: .fork(forked)) { newRecipe in
                store.add(newRecipe)
                showForkWizard = false
            }
            .environmentObject(store)
        }
    }

    // MARK: - As Baked tab

    var asBakedTab: some View {
        List {
            if let photo = log.photoData, let uiImage = UIImage(data: photo) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 200)
                        .clipped().cornerRadius(6)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section("Overall") {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= log.rating ? "star.fill" : "star")
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                }
            }
            .listRowBackground(Color.clear)

            Section("Bake") {
                LabeledContent("Date", value: log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Crust color", value: log.crustColor.rawValue)
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Bottom", value: log.bottomResult.rawValue)
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Top", value: log.topResult.rawValue)
                    .font(.system(.body, design: .monospaced))
                if log.bakeTimeSeconds > 0 {
                    LabeledContent("Bake time", value: shortTime(log.bakeTimeSeconds))
                        .font(.system(.body, design: .monospaced))
                }
                if let temp = log.ovenTempAchieved {
                    LabeledContent("Oven temp", value: "\(Int(temp))°")
                        .font(.system(.body, design: .monospaced))
                }
            }
            .listRowBackground(Color.clear)

            Section("Dough") {
                LabeledContent("Balls", value: "\(log.ballCount) × \(Int(log.ballWeight))g")
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Hydration", value: "\(Int(log.finalHydration * 100))%")
                    .font(.system(.body, design: .monospaced))
                LabeledContent("Room temp", value: String(format: "%.0f°C", log.roomTempC))
                    .font(.system(.body, design: .monospaced))
                if !log.prefermentPH.isEmpty {
                    LabeledContent("pH", value: log.prefermentPH)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .listRowBackground(Color.clear)

            if !log.actualStageDurations.isEmpty {
                Section("Stage times") {
                    ForEach(log.actualStageDurations.keys.sorted(), id: \.self) { stage in
                        let actual = log.actualStageDurations[stage]!
                        let planned = log.plannedStageDurations[stage] ?? 0
                        HStack {
                            Text(stage)
                                .font(.system(size: 13, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(shortTime(actual))
                                .font(.system(size: 13, design: .monospaced))
                            if planned > 0 {
                                let delta = actual - planned
                                Text(deltaString(delta))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(deltaColor(delta))
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }

            if !log.crustTags.isEmpty || !log.crumbTags.isEmpty ||
               !log.customCrustTags.isEmpty || !log.customCrumbTags.isEmpty {
                Section("Tags") {
                    if !log.crustTags.isEmpty || !log.customCrustTags.isEmpty {
                        tagRow(title: "Crust", tags: log.crustTags.map { $0.rawValue } + log.customCrustTags)
                    }
                    if !log.crumbTags.isEmpty || !log.customCrumbTags.isEmpty {
                        tagRow(title: "Crumb", tags: log.crumbTags.map { $0.rawValue } + log.customCrumbTags)
                    }
                }
                .listRowBackground(Color.clear)
            }

            if !log.notes.isEmpty {
                Section("Notes") {
                    Text(log.notes)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                Button("Copy Session into New Recipe →") { showForkWizard = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(hex: "D2B96A"))
                    .font(.system(size: 14, design: .monospaced))
            } footer: {
                Text("Opens the recipe wizard pre-filled with bake log settings. Saves as a new recipe variant.")
                    .font(.system(size: 11, design: .monospaced))
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Annotated tab

    var annotatedTab: some View {
        List {
            Section("Reflection rating") {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= annotatedRating ? "star.fill" : "star")
                            .foregroundColor(Color(hex: "D2B96A")).font(.title3)
                            .onTapGesture { annotatedRating = i }
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            Section("Reflection notes") {
                TextField("What would you change next time?", text: $annotatedNotes, axis: .vertical)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(4...)
                    .notesBox()
            }
            .listRowBackground(Color.clear)

            Section {
                Button(saved ? "Saved ✓" : "Save Annotation") { saveAnnotation() }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(hex: "D2B96A"))
                    .font(.system(size: 14, design: .monospaced))
            }
            .listRowBackground(Color.clear)

            if let origRating = log.annotatedRating {
                Section("Original reflection") {
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= origRating ? "star.fill" : "star")
                                .foregroundColor(.secondary).font(.caption)
                        }
                    }
                    if !log.annotatedNotes.isEmpty {
                        Text(log.annotatedNotes)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Helpers

    func saveAnnotation() {
        var updated = log
        updated.annotatedRating = annotatedRating
        updated.annotatedNotes = annotatedNotes
        store.updateBakeLog(updated, recipeId: recipe.id)
        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
    }

    func forkedRecipe() -> Recipe {
        var r = recipe
        r.finalHydration = log.finalHydration
        r.ballCount = log.ballCount
        r.ballWeight = log.ballWeight
        return r
    }

    func tagRow(title: String, tags: [String]) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: "D2B96A").opacity(0.12))
                            .foregroundColor(Color(hex: "D2B96A"))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    func shortTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, Int(t) % 60)
    }

    func deltaString(_ delta: TimeInterval) -> String {
        let abs = Int(Swift.abs(delta)); let h = abs / 3600; let m = (abs % 3600) / 60
        let sign = delta >= 0 ? "+" : "-"
        if h > 0 { return "\(sign)\(h)h \(m)m" }
        return "\(sign)\(m)m"
    }

    func deltaColor(_ delta: TimeInterval) -> Color {
        if Swift.abs(delta) < 300 { return .secondary }
        return delta > 0 ? .orange : Color(hex: "D2B96A")
    }
}
