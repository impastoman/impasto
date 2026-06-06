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
    @State private var showShare = false

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundColor(Color(hex: "7FA2BD"))
            }
        }
        .fullScreenCover(isPresented: $showShare) {
            PhotoShareView(log: log, recipe: recipe, scope: .wholeSession)
        }
        .onAppear {
            // Legacy backstop: if this log is on a build released before
            // the photos-to-disk migration and has any remaining inline
            // photo data, push it through PhotoStore now and populate
            // photoIDs. Migration usually catches this at app launch,
            // but covers the case of a log decoded from elsewhere.
            if log.photoIDs.isEmpty {
                let legacy: [Data] = log.photos.isEmpty
                    ? [log.photoData].compactMap { $0 }
                    : log.photos
                if !legacy.isEmpty {
                    log.photoIDs = legacy.map { PhotoStore.shared.save($0) }
                    log.photos = []
                    log.photoData = nil
                    store.updateBakeLog(log, recipeId: recipe.id)
                }
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
                photoID: item.photoID,
                canMakeMain: item.id != 0,
                onMakeMain: {
                    guard log.photoIDs.indices.contains(item.id) else { return }
                    let moved = log.photoIDs.remove(at: item.id)
                    log.photoIDs.insert(moved, at: 0)
                    store.updateBakeLog(log, recipeId: recipe.id)
                }
            )
        }
    }

    // MARK: - As Baked tab

    var asBakedTab: some View {
        List {
            if !log.photoIDs.isEmpty {
                Section {
                    PhotoGalleryView(
                        photoIDs: Binding(
                            get: { log.photoIDs },
                            set: { newValue in
                                log.photoIDs = newValue
                                store.updateBakeLog(log, recipeId: recipe.id)
                            }
                        ),
                        isEditable: false,
                        allowsReorder: true,
                        onTap: { idx in
                            guard log.photoIDs.indices.contains(idx) else { return }
                            viewerItem = PhotoViewerItem(id: idx, photoID: log.photoIDs[idx])
                        },
                        thumbnailSize: 140
                    )
                } header: { Text("Photos").font(.jakarta(.semibold, size: 13)) }
                  footer: { Text("Tap any photo to view it full-size or set it as the main thumbnail. Drag photos to reorder.").font(.jakarta(.regular, size: 11)).tipText() }
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section(header: Text("Overall").font(.jakarta(.semibold, size: 13))) {
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= log.rating ? "star.fill" : "star")
                            .foregroundColor(Color(hex: "7FA2BD"))
                    }
                }
            }
            .listRowBackground(Color.clear)

            Section(header: Text("Bake").font(.jakarta(.semibold, size: 13))) {
                LabeledContent("Date", value: log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Crust color", value: log.crustColor.rawValue)
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Bottom", value: log.bottomResult.rawValue)
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Top", value: log.topResult.rawValue)
                    .font(.jakarta(.regular, size: 17))
                if log.bakeTimeSeconds > 0 {
                    LabeledContent("Bake time", value: shortTime(log.bakeTimeSeconds))
                        .font(.jakarta(.regular, size: 17))
                }
                if let temp = log.ovenTempAchieved {
                    LabeledContent("Oven temp", value: "\(Int(temp))°")
                        .font(.jakarta(.regular, size: 17))
                }
            }
            .listRowBackground(Color.clear)

            Section(header: Text("Dough").font(.jakarta(.semibold, size: 13))) {
                LabeledContent("Balls", value: "\(log.ballCount) × \(Int(log.ballWeight))g")
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Hydration", value: "\(Int(log.finalHydration * 100))%")
                    .font(.jakarta(.regular, size: 17))
                LabeledContent("Room temp", value: String(format: "%.0f°C", log.roomTempC))
                    .font(.jakarta(.regular, size: 17))
                if !log.prefermentPH.isEmpty {
                    LabeledContent("pH", value: log.prefermentPH)
                        .font(.jakarta(.regular, size: 17))
                }
            }
            .listRowBackground(Color.clear)

            if !log.actualStageDurations.isEmpty {
                Section(header: Text("Stage times").font(.jakarta(.semibold, size: 13))) {
                    ForEach(log.actualStageDurations.keys.sorted(), id: \.self) { stage in
                        let actual = log.actualStageDurations[stage]!
                        let planned = log.plannedStageDurations[stage] ?? 0
                        HStack {
                            Text(stage)
                                .font(.jakarta(.regular, size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(shortTime(actual))
                                .font(.jakarta(.regular, size: 13))
                            if planned > 0 {
                                let delta = actual - planned
                                Text(deltaString(delta))
                                    .font(.jakarta(.regular, size: 11))
                                    .foregroundColor(deltaColor(delta))
                            }
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }

            if !log.crustTags.isEmpty || !log.crumbTags.isEmpty ||
               !log.customCrustTags.isEmpty || !log.customCrumbTags.isEmpty {
                Section(header: Text("Tags").font(.jakarta(.semibold, size: 13))) {
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
                Section(header: Text("Notes").font(.jakarta(.semibold, size: 13))) {
                    Text(log.notes)
                        .font(.jakarta(.regular, size: 13))
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)
            }

            Section {
                Button("Copy Session into New Recipe →") { showForkWizard = true }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(hex: "7FA2BD"))
                    .font(.jakarta(.regular, size: 14))
            } footer: {
                Text("Opens the recipe wizard pre-filled with bake log settings. Saves as a new recipe variant.")
                    .font(.jakarta(.regular, size: 11))
                    .tipText()
            }
            .listRowBackground(Color.clear)
        }
        .meadList()
    }

    // MARK: - Annotated tab

    var annotatedTab: some View {
        List {
            Section(header: Text("Reflection rating").font(.jakarta(.semibold, size: 13))) {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= annotatedRating ? "star.fill" : "star")
                            .foregroundColor(Color(hex: "7FA2BD")).font(.jakarta(.semibold, size: 20))
                            .onTapGesture { annotatedRating = i }
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            Section(header: Text("Reflection notes").font(.jakarta(.semibold, size: 13))) {
                TextField("What would you change next time?", text: $annotatedNotes, axis: .vertical)
                    .font(.jakarta(.regular, size: 13))
                    .lineLimit(4...)
                    .notesBox()
            }
            .listRowBackground(Color.clear)

            Section {
                Button(saved ? "Saved ✓" : "Save Annotation") { saveAnnotation() }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(hex: "7FA2BD"))
                    .font(.jakarta(.regular, size: 14))
            }
            .listRowBackground(Color.clear)

            if let origRating = log.annotatedRating {
                Section(header: Text("Original reflection").font(.jakarta(.semibold, size: 13))) {
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= origRating ? "star.fill" : "star")
                                .foregroundColor(.secondary).font(.jakarta(.regular, size: 12))
                        }
                    }
                    if !log.annotatedNotes.isEmpty {
                        Text(log.annotatedNotes)
                            .font(.jakarta(.regular, size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .meadList()
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
                .font(.jakarta(.regular, size: 12))
                .foregroundColor(.secondary)
                .frame(width: 44, alignment: .leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.jakarta(.regular, size: 12))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: "7FA2BD").opacity(0.12))
                            .foregroundColor(Color(hex: "7FA2BD"))
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
        return delta > 0 ? .orange : Color(hex: "7FA2BD")
    }
}
