import SwiftUI

struct SessionLogView: View {
    @ObservedObject var vm: SessionViewModel
    let recipe: Recipe
    let bakeTimeSeconds: TimeInterval
    let ovenTempAchieved: Double?
    let crustColor: CrustColor
    let bottomResult: BottomResult
    let topResult: TopResult

    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    var onEndSession: (() -> Void)? = nil

    @State private var rating = 3
    @State private var showGoHomeAlert = false
    @State private var notes = ""

    // Aggregated session gallery: starts with every photo across every
    // logged bake plus whatever the user already added in PostBakeView,
    // then the user can reorder, delete, or add more here. The first
    // photo becomes the session's cover thumbnail.
    @State private var aggregatedPhotos: [Data]
    @State private var pendingPhoto: Data? = nil
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
    @State private var viewerItem: PhotoViewerItem? = nil

    init(vm: SessionViewModel, recipe: Recipe,
         bakeTimeSeconds: TimeInterval = 0,
         ovenTempAchieved: Double? = nil,
         crustColor: CrustColor = .even,
         bottomResult: BottomResult = .good,
         topResult: TopResult = .good,
         photos: [Data] = [],
         onEndSession: (() -> Void)? = nil) {
        self.vm = vm
        self.recipe = recipe
        self.bakeTimeSeconds = bakeTimeSeconds
        self.ovenTempAchieved = ovenTempAchieved
        self.crustColor = crustColor
        self.bottomResult = bottomResult
        self.topResult = topResult
        self.onEndSession = onEndSession

        // Merge: every per-bake photo (in pizza order) followed by the
        // session-level photos already added in PostBakeView. Deduplicate
        // by Data equality so a photo added once doesn't appear twice.
        var seen: [Data] = []
        for entry in vm.pizzaEntries {
            for d in entry.displayPhotos where !seen.contains(d) { seen.append(d) }
        }
        for d in photos where !seen.contains(d) { seen.append(d) }
        _aggregatedPhotos = State(initialValue: seen)
    }

    var body: some View {
        NavigationStack {
            List {
                ratingSection
                photoSection
                stageReportSection
                pauseSection
                fermentSection
                bakeResultsSection
                notesSection
                saveSection
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("How'd it go?")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showLibraryPicker = true }
            }
            .sheet(isPresented: $showCamera) { CameraPickerView(imageData: $pendingPhoto) }
            .sheet(isPresented: $showLibraryPicker) { LibraryPickerView(imageData: $pendingPhoto) }
            .fullScreenCover(item: $viewerItem) { item in
                FullScreenPhotoViewer(
                    photo: item.photo,
                    canMakeMain: item.id != 0,
                    onMakeMain: {
                        guard aggregatedPhotos.indices.contains(item.id) else { return }
                        let moved = aggregatedPhotos.remove(at: item.id)
                        aggregatedPhotos.insert(moved, at: 0)
                    }
                )
            }
        }
        .onChange(of: pendingPhoto) { _, data in
            if let d = data { aggregatedPhotos.append(d); pendingPhoto = nil }
        }
        .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
            if isTrue { dismiss() }
        }
    }

    var photoSection: some View {
        Section {
            if aggregatedPhotos.isEmpty {
                Button { showPhotoOptions = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus").foregroundColor(Color(hex: "D2B96A"))
                        Text("Add a session photo")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            } else {
                PhotoGalleryView(
                    photos: $aggregatedPhotos,
                    onAdd: { showPhotoOptions = true },
                    onTap: { idx in
                        viewerItem = PhotoViewerItem(id: idx, photo: aggregatedPhotos[idx])
                    }
                )
            }
        } header: { Text("Session photos") }
          footer: { Text("Every photo from every bake is collected here. Tap to view full-size or pick a session thumbnail. Drag to reorder. Add more to capture the whole session.").font(.system(size: 11, design: .monospaced)).tipText() }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    var ratingSection: some View {
        Section("Overall") {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .foregroundColor(Color(hex: "D2B96A")).font(.title3)
                        .onTapGesture { rating = i }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.clear)
    }

    var stageReportSection: some View {
        Section {
            ForEach(Array(vm.cards.enumerated()), id: \.element.id) { index, card in
                let planned   = card.duration
                let actual    = vm.actualDurations[card.id]
                let startTime = stepStartTime(for: index)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(card.title)
                            .font(.system(size: 13, design: .monospaced))
                        Spacer()
                        if let t = startTime {
                            Text(wallClock(t))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    if planned > 0 {
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Planned")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(shortTime(planned))
                                    .font(.system(size: 13, design: .monospaced))
                            }
                            Spacer()
                            VStack(alignment: .center, spacing: 2) {
                                Text("Actual")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                if let actual {
                                    Text(shortTime(actual))
                                        .font(.system(size: 13, design: .monospaced))
                                } else {
                                    Text("—")
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if let actual, Swift.abs(actual - planned) >= 60 {
                                let delta = actual - planned
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(delta >= 0 ? "Over" : "Under")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Text(deltaString(delta))
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundColor(deltaColor(delta))
                                }
                            }
                        }
                    } else {
                        if let actual {
                            Text(shortTime(actual))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        } else {
                            Text("action step")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        } header: { Text("Stage times") }
        .listRowBackground(Color.clear)
    }

    /// Wall-clock start time for step at index:
    /// step 0 → sessionStartDate; step N → completion date of step N-1
    func stepStartTime(for index: Int) -> Date? {
        if index == 0 { return vm.sessionStartDate }
        let prevCard = vm.cards[index - 1]
        return vm.stepCompletionDates[prevCard.id]
    }

    func wallClock(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    @ViewBuilder
    var pauseSection: some View {
        if !vm.pauseDurations.isEmpty {
            Section {
                ForEach(Array(vm.pauseDurations.enumerated()), id: \.offset) { i, dur in
                    LabeledContent("Pause \(i + 1)", value: shortTime(dur))
                        .font(.system(size: 13, design: .monospaced))
                }
                LabeledContent("Total paused", value: shortTime(vm.pauseDurations.reduce(0, +)))
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            } header: { Text("Pause log") }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    var fermentSection: some View {
        if !vm.preFlight.prefermentPH.isEmpty || !vm.pHReadings.isEmpty {
            Section("Fermentation") {
                if !vm.preFlight.prefermentPH.isEmpty {
                    LabeledContent("Prep pH", value: vm.preFlight.prefermentPH)
                        .font(.system(.body, design: .monospaced))
                }
                if !vm.pHReadings.isEmpty {
                    LabeledContent("Logged pH", value: vm.pHReadings.map { String(format: "%.1f", $0) }.joined(separator: "  "))
                        .font(.system(.body, design: .monospaced))
                }
                LabeledContent("Room temp", value: String(format: "%.0f°C", vm.preFlight.roomTempC))
                    .font(.system(.body, design: .monospaced))
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    var bakeResultsSection: some View {
        Section("Bake") {
            if bakeTimeSeconds > 0 {
                LabeledContent("Bake time", value: shortTime(bakeTimeSeconds))
                    .font(.system(.body, design: .monospaced))
            }
            if let temp = ovenTempAchieved {
                LabeledContent("Oven temp", value: "\(Int(temp))°")
                    .font(.system(.body, design: .monospaced))
            }
            if !vm.pizzaEntries.isEmpty {
                LabeledContent("Bakes logged", value: "\(vm.pizzaEntries.count)")
                    .font(.system(.body, design: .monospaced))
            }
        }
        .listRowBackground(Color.clear)
    }

    var notesSection: some View {
        Section("Notes") {
            TextField("Observations...", text: $notes, axis: .vertical)
                .lineLimit(4...)
                .notesBox()
        }
        .listRowBackground(Color.clear)
    }

    var saveSection: some View {
        Section {
            Button("Save to History") { save() }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(Color(hex: "D2B96A"))

            Button("↩ Exit Session") { showGoHomeAlert = true }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
                .font(.system(size: 13, design: .monospaced))
        }
        .listRowBackground(Color.clear)
        .confirmationDialog("Save before leaving?", isPresented: $showGoHomeAlert, titleVisibility: .visible) {
            Button("Save to history") { save() }
            Button("Leave without saving", role: .destructive) { goHome() }
            Button("Cancel", role: .cancel) { }
        }
    }

    func goHome() {
        sessionManager.shouldReturnHome = true
        onEndSession?()
    }

    func save() {
        let log = vm.buildBakeLog(
            rating: rating,
            crustTags: [],
            crumbTags: [],
            customCrustTags: [],
            customCrumbTags: [],
            notes: notes,
            bakeTimeSeconds: bakeTimeSeconds,
            ovenTempAchieved: ovenTempAchieved,
            crustColor: crustColor,
            bottomResult: bottomResult,
            topResult: topResult,
            photos: aggregatedPhotos
        )
        store.addBakeLog(log, to: recipe.id)
        goHome()
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

// MARK: - Shared tag components

struct FlowTagRow<T: RawRepresentable & Hashable & CaseIterable>: View where T.RawValue == String {
    let tags: [T]
    @Binding var selected: Set<T>

    init(tags: T.AllCases, selected: Binding<Set<T>>) {
        self.tags = Array(tags)
        self._selected = selected
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagChip(label: tag.rawValue, selected: selected.contains(tag)) {
                        if selected.contains(tag) { selected.remove(tag) } else { selected.insert(tag) }
                    }
                }
            }
        }
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
            .background(selected ? Color(hex: "D2B96A").opacity(0.18) : Color(hex: "ECEAE3"))
            .foregroundColor(selected ? Color(hex: "D2B96A") : .secondary)
            .cornerRadius(5)
            .onTapGesture(perform: onTap)
    }
}
