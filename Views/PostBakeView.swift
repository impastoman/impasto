import SwiftUI
import PhotosUI

struct PostBakeView: View {
    @ObservedObject var vm: SessionViewModel
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var showSessionLog = false
    @State private var selectedPizza: PizzaEntry? = nil

    var body: some View {
        NavigationStack {
            List {
                if !vm.pizzaEntries.isEmpty {
                    pizzaEntriesSection
                }
                photoSection
                bakeTimeSection
            }
            .navigationTitle("Bake results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { showSessionLog = true }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next →") { showSessionLog = true }
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
            .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
                if isTrue { dismiss() }
            }
        }
        .sheet(isPresented: $showSessionLog) {
            SessionLogView(
                vm: vm,
                recipe: recipe,
                bakeTimeSeconds: totalBakeTime,
                ovenTempAchieved: nil,
                photoData: photoData,
                onEndSession: {
                    sessionManager.end(vm)
                }
            )
            .environmentObject(store)
            .environmentObject(sessionManager)
        }
        .sheet(item: $selectedPizza) { pizza in
            PizzaDetailView(entry: pizza)
        }
    }

    var pizzaEntriesSection: some View {
        Section("Logged pizzas") {
            ForEach(vm.pizzaEntries) { entry in
                Button {
                    selectedPizza = entry
                } label: {
                    HStack(spacing: 12) {
                        if let data = entry.photoData, let img = UIImage(data: data) {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 52, height: 52)
                                .clipped().cornerRadius(6)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "ECEAE3"))
                                .frame(width: 52, height: 52)
                                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pizza #\(entry.pizzaNumber)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.primary)
                            Text(shortTime(entry.bakeTimeSeconds))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("\(entry.crustColor.rawValue)  ·  B: \(entry.bottomResult.rawValue)  ·  T: \(entry.topResult.rawValue)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    var photoSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                if let photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 180)
                        .clipped().cornerRadius(6)
                } else {
                    HStack {
                        Image(systemName: "camera").foregroundColor(Color(hex: "D2B96A"))
                        Text(vm.pizzaEntries.isEmpty ? "Add a session photo" : "Add overall session photo")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    photoData = try? await item?.loadTransferable(type: Data.self)
                }
            }
        } header: { Text("Photo") }
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    var totalBakeTime: TimeInterval {
        vm.pizzaEntries.isEmpty
            ? vm.bakeElapsed
            : vm.pizzaEntries.reduce(0) { $0 + $1.bakeTimeSeconds }
    }

    var bakeTimeSection: some View {
        Section("Bake info") {
            LabeledContent("Total bake time", value: timeString(totalBakeTime))
                .font(.system(.body, design: .monospaced))
        }
    }

    func timeString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60; let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    func shortTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, Int(t) % 60)
    }
}

struct PizzaDetailView: View {
    let entry: PizzaEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let data = entry.photoData, let img = UIImage(data: data) {
                    Section {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8)
                    }
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Bake") {
                    LabeledContent("Bake time", value: shortTime(entry.bakeTimeSeconds))
                    if let temp = entry.ovenTempAchieved {
                        LabeledContent("Oven temp", value: "\(Int(temp))°")
                    }
                    LabeledContent("Crust color", value: entry.crustColor.rawValue)
                    LabeledContent("Bottom", value: entry.bottomResult.rawValue)
                    LabeledContent("Top", value: entry.topResult.rawValue)
                }
                .font(.system(.body, design: .monospaced))

                if !entry.crustTags.isEmpty || !entry.crumbTags.isEmpty {
                    Section("Tags") {
                        if !entry.crustTags.isEmpty {
                            LabeledContent("Crust", value: entry.crustTags.map(\.rawValue).joined(separator: ", "))
                        }
                        if !entry.crumbTags.isEmpty {
                            LabeledContent("Crumb", value: entry.crumbTags.map(\.rawValue).joined(separator: ", "))
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                }

                if !entry.notes.isEmpty {
                    Section("Notes") {
                        Text(entry.notes)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Pizza #\(entry.pizzaNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    func shortTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, Int(t) % 60)
    }
}
