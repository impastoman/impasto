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
    }

    var stageReportSection: some View {
        Section {
            ForEach(vm.cards, id: \.id) { card in
                let planned = card.duration
                let actual  = vm.actualDurations[card.id]
                if planned > 0 {
                    // Timed step — show labeled planned / actual / delta
                    VStack(alignment: .leading, spacing: 5) {
                        Text(card.title)
                            .font(.system(size: 13, design: .monospaced))
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
                    }
                    .padding(.vertical, 2)
                } else {
                    // Action step — just title + actual time
                    HStack {
                        Text(card.title)
                            .font(.system(size: 13, design: .monospaced))
                        Spacer()
                        if let actual {
                            Text(shortTime(actual))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                        } else {
                            Text("—")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        } header: { Text("Stage times") }
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
        }
    }

    @ViewBuilder
    var bakeResultsSection: some View {
        Section("Bake") {
            if bakeTimeSeconds > 0 {
                LabeledContent("Bake time", value: shortTime(bakeTimeSeconds)).font(.system(.body, design: .monospaced))
            }
            if let temp = ovenTempAchieved {
                LabeledContent("Oven temp", value: "\(Int(temp))°").font(.system(.body, design: .monospaced))
            }
            if !vm.pizzaEntries.isEmpty {
                LabeledContent("Pizzas logged", value: "\(vm.pizzaEntries.count)").font(.system(.body, design: .monospaced))
            }
        }
    }

    var notesSection: some View {
        Section("Notes") {
            TextField("Observations...", text: $notes, axis: .vertical).lineLimit(4...)
        }
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
        .confirmationDialog("Save before leaving?", isPresented: $showGoHomeAlert, titleVisibility: .visible) {
            Button("Save to history") { save() }
            Button("Leave without saving", role: .destructive) { goHome() }
            Button("Cancel", role: .cancel) { }
        }
    }

    func goHome() {
        // Set the flag BEFORE ending the session so LiveSessionView's
        // sessions.count observer sees shouldReturnHome = true and skips
        // its own dismiss(), letting the shouldReturnHome cascade handle
        // the orderly inside-out unwinding instead.
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
