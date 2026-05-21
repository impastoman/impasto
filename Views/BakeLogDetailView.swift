import SwiftUI

struct BakeLogDetailView: View {
    @State private var log: BakeLog
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore

    @State private var selectedTab = 0
    @State private var annotatedRating: Int
    @State private var annotatedNotes: String
    @State private var saved = false
    @State private var showForkWizard = false
    @State private var viewerItem: PhotoViewerItem? = nil

    init(log: BakeLog, recipe: Recipe) {
        _log = State(initialValue: log)
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
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Promote legacy single-photo logs into the photos array so the
            // gallery can show + reorder them. Persisted on first reorder.
            if log.photos.isEmpty, let legacy = log.photoData {
                log.photos = [legacy]
            }
        }
        .sheet(isPresented: $showForkWizard) {
            let forked = forkedRecipe()
            WizardContainerView(mode: .fork(forked)) { newRecipe in
                store.add(newRecipe)
                showForkWizard = false
            }
            .environmentObject(store)
        }
        .fullScreenCover(item: $viewerItem) { item in
            FullScreenPhotoViewer(
                photo: item.photo,
                canMakeMain: item.id != 0,
                onMakeMain: {
                    guard log.photos.indices.contains(item.id) else { return }
                    let moved = log.photos.remove(at: item.id)
                    log.photos.insert(moved, at: 0)
                    log.photoData = log.photos.first
                    store.updateBakeLog(log, recipeId: recipe.id)
                }
            )
        }
    }

    // MARK: - As Baked tab

    var asBakedTab: some View {
        List {
            if !log.photos.isEmpty {
                Section {
                    PhotoGalleryView(
                        photos: Binding(
                            get: { log.photos },
                            set: { newValue in
                                log.photos = newValue
                                log.photoData = newValue.first   // keep legacy cover in sync
                                store.updateBakeLog(log, recipeId: recipe.id)
                            }
                        ),
                        isEditable: false,
                        allowsReorder: true,
                        onTap: { idx in
                            viewerItem = PhotoViewerItem(id: idx, photo: log.photos[idx])
                        },
                        thumbnailSize: 140
                    )
                } header: { Text("Photos") }
                  footer: { Text("Tap any photo to view it full-size or set it as the main thumbnail. Drag photos to reorder.").font(.system(size: 11, design: .monospaced)).tipText() }
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
                    .tipText()
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
        // Carry actual stage durations from this bake session into the forked recipe
        // (10 second minimum floor so no card gets set to zero)
        for i in r.processCards.indices {
            let title = r.processCards[i].title
            if let actual = log.actualStageDurations[title], actual > 0 {
                r.processCards[i].customDuration = max(10, actual)
            }
        }
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
