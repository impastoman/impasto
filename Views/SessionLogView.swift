import SwiftUI

struct SessionLogView: View {
    @ObservedObject var vm: SessionViewModel
    let recipe: Recipe
    let bakeTimeSeconds: TimeInterval
    let ovenTempAchieved: Double?
    let crustColor: CrustColor
    let bottomResult: BottomResult
    let topResult: TopResult
    let photoData: Data?

    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    var onEndSession: (() -> Void)? = nil

    @State private var rating = 3
    @State private var showGoHomeAlert = false
    @State private var notes = ""

    init(vm: SessionViewModel, recipe: Recipe,
         bakeTimeSeconds: TimeInterval = 0,
         ovenTempAchieved: Double? = nil,
         crustColor: CrustColor = .even,
         bottomResult: BottomResult = .good,
         topResult: TopResult = .good,
         photoData: Data? = nil,
         onEndSession: (() -> Void)? = nil) {
        self.vm = vm
        self.recipe = recipe
        self.bakeTimeSeconds = bakeTimeSeconds
        self.ovenTempAchieved = ovenTempAchieved
        self.crustColor = crustColor
        self.bottomResult = bottomResult
        self.topResult = topResult
        self.photoData = photoData
        self.onEndSession = onEndSession
    }

    var body: some View {
        NavigationStack {
            List {
                ratingSection
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
        }
        .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
            if isTrue { dismiss() }
        }
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
            photoData: photoData
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
