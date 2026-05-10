import SwiftUI

struct SessionLogView: View {
    @ObservedObject var vm: SessionViewModel
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

                stageReportSection

                Section("Crust") {
                    FlowTagRow(tags: CrustTag.allCases, selected: $crustTags)
                        .padding(.vertical, 4)
                }

                Section("Crumb") {
                    FlowTagRow(tags: CrumbTag.allCases, selected: $crumbTags)
                        .padding(.vertical, 4)
                }

                if !vm.preFlight.prefermentPH.isEmpty || vm.pHReadings.count > 0 {
                    fermentSection
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    var stageReportSection: some View {
        Section {
            ForEach(SessionStage.allCases, id: \.self) { stage in
                let planned = stage.defaultDuration
                let actual  = vm.actualStageDurations[stage]
                HStack {
                    Text(stage.title)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(width: 100, alignment: .leading)
                    Spacer()
                    if let actual {
                        let delta = actual - planned
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(shortTime(actual))
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.primary)
                            Text(deltaString(delta))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(deltaColor(delta))
                        }
                    } else {
                        Text("—")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Stage times  ·  planned vs. actual")
        }
    }

    var fermentSection: some View {
        Section("Fermentation") {
            if !vm.preFlight.prefermentPH.isEmpty {
                LabeledContent("Pre-flight pH", value: vm.preFlight.prefermentPH)
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

    func save() {
        let log = vm.buildBakeLog(
            rating: rating,
            crustTags: Array(crustTags),
            crumbTags: Array(crumbTags),
            notes: notes
        )
        store.addBakeLog(log, to: recipe.id)
        dismiss()
    }

    func shortTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm", m)
    }

    func deltaString(_ delta: TimeInterval) -> String {
        let abs = Int(abs(delta))
        let h = abs / 3600
        let m = (abs % 3600) / 60
        let sign = delta >= 0 ? "+" : "-"
        if h > 0 { return "\(sign)\(h)h \(m)m" }
        return "\(sign)\(m)m"
    }

    func deltaColor(_ delta: TimeInterval) -> Color {
        if abs(delta) < 300 { return .secondary }
        return delta > 0 ? .orange : Color(hex: "D2B96A")
    }
}

struct FlowTagRow<T: RawRepresentable & Hashable & CaseIterable>: View where T.RawValue == String {
    let tags: [T]
    @Binding var selected: Set<T>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(tags), id: \.self) { tag in
                TagChip(label: tag.rawValue, selected: selected.contains(tag)) {
                    if selected.contains(tag) { selected.remove(tag) } else { selected.insert(tag) }
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
            .background(selected ? Color(hex: "D2B96A").opacity(0.18) : Color(hex: "1A1B18"))
            .foregroundColor(selected ? Color(hex: "D2B96A") : .secondary)
            .cornerRadius(5)
            .onTapGesture(perform: onTap)
    }
}
