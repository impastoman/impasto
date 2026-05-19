import SwiftUI
import PhotosUI

struct PostBakeView: View {
    @ObservedObject var vm: SessionViewModel
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var photos: [Data] = []
    @State private var pendingPhoto: Data? = nil   // bridge to single-image pickers
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
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
            .scrollContentBackground(.hidden)
            .navigationTitle("Bake Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") { showSessionLog = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next →") { showSessionLog = true }
                }
            }
            .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
                if isTrue { dismiss() }
            }
        }
        .onChange(of: pendingPhoto) { _, data in
            if let d = data { photos.append(d); pendingPhoto = nil }
        }
        .sheet(isPresented: $showSessionLog) {
            SessionLogView(
                vm: vm,
                recipe: recipe,
                bakeTimeSeconds: totalBakeTime,
                ovenTempAchieved: nil,
                photos: photos,
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
        .sheet(isPresented: $showCamera) {
            CameraPickerView(imageData: $pendingPhoto)
        }
        .sheet(isPresented: $showLibraryPicker) {
            LibraryPickerView(imageData: $pendingPhoto)
        }
    }

    var pizzaEntriesSection: some View {
        Section("Logged bakes") {
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
                            Text("Bake #\(entry.pizzaNumber)")
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
        .listRowBackground(Color.clear)
    }

    var photoSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { idx, data in
                        if let uiImage = UIImage(data: data) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipped().cornerRadius(8)
                                Button {
                                    photos.remove(at: idx)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.white, Color.black.opacity(0.55))
                                }
                                .padding(4)
                            }
                        }
                    }
                    // Add photo tile
                    Button { showPhotoOptions = true } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "D2B96A"))
                            Text("Add")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(hex: "D2B96A"))
                        }
                        .frame(width: 100, height: 100)
                        .background(Color(hex: "D2B96A").opacity(0.08))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "D2B96A").opacity(0.3), lineWidth: 1))
                    }
                    .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                        Button("Take Photo") { showCamera = true }
                        Button("Choose from Library") { showLibraryPicker = true }
                    }
                }
                .padding(.vertical, 4)
            }
        } header: { Text("Photos") }
        .listRowBackground(Color.clear)
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
        .listRowBackground(Color.clear)
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

// MARK: - Individual bake detail

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
                    .listRowBackground(Color.clear)
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
                .listRowBackground(Color.clear)
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
                    .listRowBackground(Color.clear)
                    .font(.system(.body, design: .monospaced))
                }

                if !entry.notes.isEmpty {
                    Section("Notes") {
                        Text(entry.notes)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Bake #\(entry.pizzaNumber)")
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
