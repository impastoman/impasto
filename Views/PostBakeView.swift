import SwiftUI
import PhotosUI

struct PostBakeView: View {
    @ObservedObject var vm: SessionViewModel
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var photoIDs: [UUID] = []
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
            if let d = data {
                photoIDs.append(PhotoStore.shared.save(d))
                pendingPhoto = nil
            }
        }
        .sheet(isPresented: $showSessionLog) {
            SessionLogView(
                vm: vm,
                recipe: recipe,
                bakeTimeSeconds: totalBakeTime,
                ovenTempAchieved: nil,
                photoIDs: photoIDs,
                onEndSession: {
                    sessionManager.end(vm)
                }
            )
            .environmentObject(store)
            .environmentObject(sessionManager)
        }
        .sheet(item: $selectedPizza) { pizza in
            // Bridge selectedPizza (value snapshot) → a write-back binding
            // into vm.pizzaEntries so Make-main / reorder persists.
            PizzaDetailView(entry: Binding(
                get: { vm.pizzaEntries.first(where: { $0.id == pizza.id }) ?? pizza },
                set: { newValue in
                    if let idx = vm.pizzaEntries.firstIndex(where: { $0.id == pizza.id }) {
                        vm.pizzaEntries[idx] = newValue
                    }
                }
            ))
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(imageData: $pendingPhoto)
        }
        .sheet(isPresented: $showLibraryPicker) {
            LibraryPickerView(imageData: $pendingPhoto)
        }
    }

    var pizzaEntriesSection: some View {
        Section(header: Text("Logged bakes").font(.jakarta(.semibold, size: 13))) {
            ForEach(vm.pizzaEntries) { entry in
                Button {
                    selectedPizza = entry
                } label: {
                    HStack(spacing: 12) {
                        if let coverID = entry.photoIDs.first,
                           let img = ImageCache.shared.image(for: coverID) {
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
                                .font(.jakarta(.regular, size: 14))
                                .foregroundColor(.primary)
                            Text(shortTime(entry.bakeTimeSeconds))
                                .font(.jakarta(.regular, size: 12))
                                .foregroundColor(.secondary)
                            Text("\(entry.crustColor.rawValue)  ·  B: \(entry.bottomResult.rawValue)  ·  T: \(entry.topResult.rawValue)")
                                .font(.jakarta(.regular, size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.jakarta(.regular, size: 12))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .listRowBackground(Color.clear)
    }

    var photoSection: some View {
        Section {
            PhotoGalleryView(
                photoIDs: $photoIDs,
                onAdd: { showPhotoOptions = true }
            )
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showLibraryPicker = true }
            }
        } header: { Text("Photos").font(.jakarta(.semibold, size: 13)) }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    var totalBakeTime: TimeInterval {
        vm.pizzaEntries.isEmpty
            ? vm.bakeElapsed
            : vm.pizzaEntries.reduce(0) { $0 + $1.bakeTimeSeconds }
    }

    var bakeTimeSection: some View {
        Section(header: Text("Bake info").font(.jakarta(.semibold, size: 13))) {
            LabeledContent("Total bake time", value: timeString(totalBakeTime))
                .font(.jakarta(.regular, size: 17))
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
    @Binding var entry: PizzaEntry
    @Environment(\.dismiss) private var dismiss
    @State private var viewerItem: PhotoViewerItem? = nil

    var body: some View {
        NavigationStack {
            List {
                if !entry.photoIDs.isEmpty {
                    Section {
                        PhotoGalleryView(
                            photoIDs: $entry.photoIDs,
                            isEditable: false,
                            allowsReorder: true,
                            onTap: { idx in
                                guard entry.photoIDs.indices.contains(idx) else { return }
                                viewerItem = PhotoViewerItem(id: idx, photoID: entry.photoIDs[idx])
                            }
                        )
                    } header: { Text("Photos").font(.jakarta(.semibold, size: 13)) }
                      footer: { Text("Tap a photo to view it full-size or set it as this bake's main thumbnail. Drag to reorder.").font(.jakarta(.regular, size: 11)).tipText() }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section(header: Text("Bake").font(.jakarta(.semibold, size: 13))) {
                    LabeledContent("Bake time", value: shortTime(entry.bakeTimeSeconds))
                    if let temp = entry.ovenTempAchieved {
                        LabeledContent("Oven temp", value: "\(Int(temp))°")
                    }
                    LabeledContent("Crust color", value: entry.crustColor.rawValue)
                    LabeledContent("Bottom", value: entry.bottomResult.rawValue)
                    LabeledContent("Top", value: entry.topResult.rawValue)
                }
                .listRowBackground(Color.clear)
                .font(.jakarta(.regular, size: 17))

                if !entry.crustTags.isEmpty || !entry.crumbTags.isEmpty {
                    Section(header: Text("Tags").font(.jakarta(.semibold, size: 13))) {
                        if !entry.crustTags.isEmpty {
                            LabeledContent("Crust", value: entry.crustTags.map(\.rawValue).joined(separator: ", "))
                        }
                        if !entry.crumbTags.isEmpty {
                            LabeledContent("Crumb", value: entry.crumbTags.map(\.rawValue).joined(separator: ", "))
                        }
                    }
                    .listRowBackground(Color.clear)
                    .font(.jakarta(.regular, size: 17))
                }

                if !entry.notes.isEmpty {
                    Section(header: Text("Notes").font(.jakarta(.semibold, size: 13))) {
                        Text(entry.notes)
                            .font(.jakarta(.regular, size: 13))
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
        .fullScreenCover(item: $viewerItem) { item in
            FullScreenPhotoViewer(
                photoID: item.photoID,
                canMakeMain: item.id != 0,
                onMakeMain: {
                    guard entry.photoIDs.indices.contains(item.id) else { return }
                    let moved = entry.photoIDs.remove(at: item.id)
                    entry.photoIDs.insert(moved, at: 0)
                }
            )
        }
    }

    func shortTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        return String(format: "%dm %02ds", m, Int(t) % 60)
    }
}
