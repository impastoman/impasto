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
    // logged bake plus the session-level photos collected in PostBakeView,
    // dedup'd. User can reorder, delete, add more. First photo becomes
    // the session's cover thumbnail. Stored as UUIDs — each resolves to
    // a JPEG on disk via PhotoStore.
    @State private var aggregatedPhotoIDs: [UUID]
    @State private var pendingPhoto: Data? = nil
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
    @State private var durationEdits: [UUID: String] = [:]
    @State private var viewerItem: PhotoViewerItem? = nil
    @State private var showShare = false

    init(vm: SessionViewModel, recipe: Recipe,
         bakeTimeSeconds: TimeInterval = 0,
         ovenTempAchieved: Double? = nil,
         crustColor: CrustColor = .even,
         bottomResult: BottomResult = .good,
         topResult: TopResult = .good,
         photoIDs: [UUID] = [],
         onEndSession: (() -> Void)? = nil) {
        self.vm = vm
        self.recipe = recipe
        self.bakeTimeSeconds = bakeTimeSeconds
        self.ovenTempAchieved = ovenTempAchieved
        self.crustColor = crustColor
        self.bottomResult = bottomResult
        self.topResult = topResult
        self.onEndSession = onEndSession

        // Per-bake photos (in pizza order) followed by the session-level
        // photos already collected in PostBakeView. Dedup by UUID.
        var seen: [UUID] = []
        for entry in vm.pizzaEntries {
            for id in entry.photoIDs where !seen.contains(id) { seen.append(id) }
        }
        for id in photoIDs where !seen.contains(id) { seen.append(id) }
        _aggregatedPhotoIDs = State(initialValue: seen)
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
            .meadList()
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
                    photoID: item.photoID,
                    canMakeMain: item.id != 0,
                    onMakeMain: {
                        guard aggregatedPhotoIDs.indices.contains(item.id) else { return }
                        let moved = aggregatedPhotoIDs.remove(at: item.id)
                        aggregatedPhotoIDs.insert(moved, at: 0)
                    }
                )
            }
            // "Share this session" sheet lives here at the body level — NOT
            // on saveSection. A presentation modifier attached to a List
            // Section is torn down when that row re-renders, which made the
            // editor flash open then collapse and drop back to Bake Results.
            .sheet(isPresented: $showShare) {
                // Preview BakeLog from current in-session state — never saved.
                let previewLog = vm.buildBakeLog(
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
                    photoIDs: aggregatedPhotoIDs
                )
                PhotoShareView(log: previewLog, recipe: recipe, scope: .wholeSession)
            }
        }
        .onChange(of: pendingPhoto) { _, data in
            if let d = data {
                aggregatedPhotoIDs.append(PhotoStore.shared.save(d))
                pendingPhoto = nil
            }
        }
        .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
            if isTrue { dismiss() }
        }
    }

    var photoSection: some View {
        Section {
            if aggregatedPhotoIDs.isEmpty {
                Button { showPhotoOptions = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus").foregroundColor(Color.ruleBlue)
                        Text("Add a session photo")
                            .font(.jakarta(.regular, size: 17))
                            .foregroundColor(Color.ruleBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            } else {
                PhotoGalleryView(
                    photoIDs: $aggregatedPhotoIDs,
                    onAdd: { showPhotoOptions = true },
                    onTap: { idx in
                        guard aggregatedPhotoIDs.indices.contains(idx) else { return }
                        viewerItem = PhotoViewerItem(id: idx, photoID: aggregatedPhotoIDs[idx])
                    }
                )
            }
        } header: { Text("Session photos").font(.jakarta(.semibold, size: 13)) }
          footer: { Text("Every photo from every bake is collected here. Tap to view full-size or pick a session thumbnail. Drag to reorder. Add more to capture the whole session.").font(.jakarta(.regular, size: 11)).tipText() }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    var ratingSection: some View {
        Section(header: Text("Overall").font(.jakarta(.semibold, size: 13))) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .foregroundColor(Color(hex: "7FA2BD")).font(.jakarta(.semibold, size: 20))
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
                            .font(.jakarta(.regular, size: 13))
                        Spacer()
                        if let t = startTime {
                            Text(wallClock(t))
                                .font(.jakarta(.regular, size: 10))
                                .foregroundColor(.secondary)
                        }
                    }

                    if planned > 0 {
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Planned")
                                    .font(.jakarta(.regular, size: 10))
                                    .foregroundColor(.secondary)
                                Text(shortTime(planned))
                                    .font(.jakarta(.regular, size: 13))
                            }
                            Spacer()
                            VStack(alignment: .center, spacing: 2) {
                                Text("Actual")
                                    .font(.jakarta(.regular, size: 10))
                                    .foregroundColor(.secondary)
                                if let actual {
                                    TextField(editableTime(actual), text: Binding(
                                        get: { durationEdits[card.id] ?? editableTime(actual) },
                                        set: { durationEdits[card.id] = $0 }
                                    ))
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.jakarta(.regular, size: 13))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                                    .onSubmit {
                                        if let str = durationEdits[card.id], let t = parseTime(str) {
                                            vm.actualDurations[card.id] = t
                                        }
                                        durationEdits.removeValue(forKey: card.id)
                                    }
                                } else {
                                    Text("—")
                                        .font(.jakarta(.regular, size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if let actual, Swift.abs(actual - planned) >= 60 {
                                let delta = actual - planned
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(delta >= 0 ? "Over" : "Under")
                                        .font(.jakarta(.regular, size: 10))
                                        .foregroundColor(.secondary)
                                    Text(deltaString(delta))
                                        .font(.jakarta(.regular, size: 13))
                                        .foregroundColor(deltaColor(delta))
                                }
                            }
                        }
                    } else {
                        if let actual {
                            TextField(editableTime(actual), text: Binding(
                                get: { durationEdits[card.id] ?? editableTime(actual) },
                                set: { durationEdits[card.id] = $0 }
                            ))
                            .keyboardType(.numbersAndPunctuation)
                            .font(.jakarta(.regular, size: 12))
                            .foregroundColor(.secondary)
                            .onSubmit {
                                if let str = durationEdits[card.id], let t = parseTime(str) {
                                    vm.actualDurations[card.id] = t
                                }
                                durationEdits.removeValue(forKey: card.id)
                            }
                        } else {
                            Text("action step")
                                .font(.jakarta(.regular, size: 11))
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
                        .font(.jakarta(.regular, size: 13))
                }
                LabeledContent("Total paused", value: shortTime(vm.pauseDurations.reduce(0, +)))
                    .font(.jakarta(.regular, size: 13))
                    .foregroundColor(.secondary)
            } header: { Text("Pause log") }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    var fermentSection: some View {
        if !vm.preFlight.prefermentPH.isEmpty || !vm.pHReadings.isEmpty {
            Section(header: Text("Fermentation").font(.jakarta(.semibold, size: 13))) {
                if !vm.preFlight.prefermentPH.isEmpty {
                    LabeledContent("Prep pH", value: vm.preFlight.prefermentPH)
                        .font(.jakarta(.regular, size: 17))
                }
                if !vm.pHReadings.isEmpty {
                    LabeledContent("Logged pH", value: vm.pHReadings.map { String(format: "%.1f", $0) }.joined(separator: "  "))
                        .font(.jakarta(.regular, size: 17))
                }
                LabeledContent("Room temp", value: String(format: "%.0f°C", vm.preFlight.roomTempC))
                    .font(.jakarta(.regular, size: 17))
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    var bakeResultsSection: some View {
        Section(header: Text("Bake").font(.jakarta(.semibold, size: 13))) {
            if bakeTimeSeconds > 0 {
                LabeledContent("Bake time", value: shortTime(bakeTimeSeconds))
                    .font(.jakarta(.regular, size: 17))
            }
            if let temp = ovenTempAchieved {
                LabeledContent("Oven temp", value: "\(Int(temp))°")
                    .font(.jakarta(.regular, size: 17))
            }
            if !vm.pizzaEntries.isEmpty {
                LabeledContent("Bakes logged", value: "\(vm.pizzaEntries.count)")
                    .font(.jakarta(.regular, size: 17))
            }
        }
        .listRowBackground(Color.clear)
    }

    var notesSection: some View {
        Section(header: Text("Notes").font(.jakarta(.semibold, size: 13))) {
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
                .foregroundColor(Color(hex: "7FA2BD"))

            Button("Share this session →") { showShare = true }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(Color(hex: "7FA2BD"))
                .font(.jakarta(.regular, size: 13))

            Button("↩ Exit Session") { showGoHomeAlert = true }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
                .font(.jakarta(.regular, size: 13))
        }
        .listRowBackground(Color.clear)
        .confirmationDialog("Save before leaving?", isPresented: $showGoHomeAlert, titleVisibility: .visible) {
            Button("Save to history") { save() }
            Button("Leave without saving", role: .destructive) { goHome() }
            Button("Cancel", role: .cancel) { }
        }
        // NOTE: the "Share this session" sheet is presented at the body
        // level (see `var body`), NOT here. A .sheet/.fullScreenCover
        // attached to a List Section gets torn down when the row
        // re-renders, which flashed the editor open then collapsed it
        // and dragged the parent sheet back to Bake Results.
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
            photoIDs: aggregatedPhotoIDs
        )
        store.addBakeLog(log, to: recipe.id)
        goHome()
    }

    func shortTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, Int(t) % 60)
    }

    func editableTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60; let s = Int(t) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    func parseTime(_ s: String) -> TimeInterval? {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        switch parts.count {
        case 2: return TimeInterval(parts[0] * 60 + parts[1])
        case 3: return TimeInterval(parts[0] * 3600 + parts[1] * 60 + parts[2])
        default: return nil
        }
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
            .font(.jakarta(.regular, size: 12))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(selected ? Color(hex: "7FA2BD").opacity(0.18) : Color(hex: "ECEAE3"))
            .foregroundColor(selected ? Color(hex: "7FA2BD") : .secondary)
            .cornerRadius(5)
            .onTapGesture(perform: onTap)
    }
}
