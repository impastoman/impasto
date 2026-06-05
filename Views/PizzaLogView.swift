import SwiftUI
import PhotosUI

struct PizzaLogView: View {
    @ObservedObject var vm: SessionViewModel
    let recipe: Recipe
    let onReturnToBaking: () -> Void
    let onEndBake: () -> Void

    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var crustColor: CrustColor = .even
    @State private var bottomResult: BottomResult = .good
    @State private var topResult: TopResult = .good
    @State private var crustTags: Set<CrustTag> = []
    @State private var crumbTags: Set<CrumbTag> = []
    @State private var customCrustTags: Set<String> = []
    @State private var customCrumbTags: Set<String> = []
    @State private var showNewCrustTag = false
    @State private var showNewCrumbTag = false
    @State private var newTagText = ""
    @State private var notes = ""
    @State private var ovenTempInput = ""
    @State private var photos: [Data] = []
    @State private var pendingPhoto: Data? = nil   // bridge to single-image pickers
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
    @State private var snapshotBakeTime: TimeInterval = 0

    var body: some View {
        NavigationStack {
            List {
                photoSection
                bakeInfoSection
                visualSection
                tagsSection
                notesSection
                logAndReturnSection
            }
            .navigationTitle("Log Bake #\(vm.pizzaEntries.count + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { snapshotBakeTime = vm.bakeElapsed }
            .keyboardDoneButton()
            .onChange(of: pendingPhoto) { _, data in
                if let d = data { photos.append(d); pendingPhoto = nil }
            }
            .sheet(isPresented: $showCamera) { CameraPickerView(imageData: $pendingPhoto) }
            .sheet(isPresented: $showLibraryPicker) { LibraryPickerView(imageData: $pendingPhoto) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("â† Back") {
                        onReturnToBaking()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Bake â†’") {
                        savePizzaEntry()
                        onEndBake()
                    }
                    .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        }
    }

    var photoSection: some View {
        Section {
            PhotoGalleryView(
                photos: $photos,
                onAdd: { showPhotoOptions = true }
            )
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showLibraryPicker = true }
            }
        } header: { Text("Photos") }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    var bakeInfoSection: some View {
        Section("Bake info") {
            HStack {
                Text("Bake time")
                Spacer()
                Text(bakeTimeDisplay)
                    .font(.jakarta(.regular, size: 17))
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Oven temp achieved")
                Spacer()
                TextField("optional", text: $ovenTempInput)
                    .keyboardType(.decimalPad).multilineTextAlignment(.center).frame(width: 64)
                    .font(.jakarta(.regular, size: 17))
                    .inputBox()
                Text("Â°").foregroundColor(.secondary)
            }
        }
    }

    var visualSection: some View {
        Section("How did this one look?") {
            HStack {
                Text("Crust color")
                Spacer()
                Picker("", selection: $crustColor) {
                    ForEach(CrustColor.allCases, id: \.self) { c in Text(c.rawValue).tag(c) }
                }
                .labelsHidden()
            }
            HStack {
                Text("Bottom")
                Spacer()
                Picker("", selection: $bottomResult) {
                    ForEach(BottomResult.allCases, id: \.self) { r in Text(r.rawValue).tag(r) }
                }
                .labelsHidden()
            }
            HStack {
                Text("Top")
                Spacer()
                Picker("", selection: $topResult) {
                    ForEach(TopResult.allCases, id: \.self) { r in Text(r.rawValue).tag(r) }
                }
                .labelsHidden()
            }
        }
    }

    var tagsSection: some View {
        Group {
            Section("Crust") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(CrustTag.allCases, id: \.self) { tag in
                        tagChip(tag.rawValue, selected: crustTags.contains(tag)) {
                            if crustTags.contains(tag) { crustTags.remove(tag) }
                            else { crustTags.insert(tag) }
                        }
                    }
                    ForEach(store.customCrustTags, id: \.self) { tag in
                        tagChip(tag, selected: customCrustTags.contains(tag)) {
                            if customCrustTags.contains(tag) { customCrustTags.remove(tag) }
                            else { customCrustTags.insert(tag) }
                        }
                    }
                    tagChip("+ New", selected: false) { showNewCrustTag = true }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

            Section("Crumb") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(CrumbTag.allCases, id: \.self) { tag in
                        tagChip(tag.rawValue, selected: crumbTags.contains(tag)) {
                            if crumbTags.contains(tag) { crumbTags.remove(tag) }
                            else { crumbTags.insert(tag) }
                        }
                    }
                    ForEach(store.customCrumbTags, id: \.self) { tag in
                        tagChip(tag, selected: customCrumbTags.contains(tag)) {
                            if customCrumbTags.contains(tag) { customCrumbTags.remove(tag) }
                            else { customCrumbTags.insert(tag) }
                        }
                    }
                    tagChip("+ New", selected: false) { showNewCrumbTag = true }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)
        }
        .alert("New Crust Tag", isPresented: $showNewCrustTag) {
            TextField("e.g. Leoparded", text: $newTagText)
            Button("Add") {
                let t = newTagText.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty && !store.customCrustTags.contains(t) {
                    store.customCrustTags.append(t)
                    store.saveCustomTags()
                    customCrustTags.insert(t)
                }
                newTagText = ""
            }
            Button("Cancel", role: .cancel) { newTagText = "" }
        }
        .alert("New Crumb Tag", isPresented: $showNewCrumbTag) {
            TextField("e.g. Pillowy", text: $newTagText)
            Button("Add") {
                let t = newTagText.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty && !store.customCrumbTags.contains(t) {
                    store.customCrumbTags.append(t)
                    store.saveCustomTags()
                    customCrumbTags.insert(t)
                }
                newTagText = ""
            }
            Button("Cancel", role: .cancel) { newTagText = "" }
        }
    }

    var notesSection: some View {
        Section("Notes") {
            TextField("Any notes about this bakeâ€¦", text: $notes, axis: .vertical)
                .font(.jakarta(.regular, size: 13))
                .lineLimit(3...)
                .notesBox()
        }
    }

    var logAndReturnSection: some View {
        Section {
            Button("Log & Return to Baking") {
                savePizzaEntry()
                onReturnToBaking()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(Color(hex: "D2B96A"))
        }
    }

    func savePizzaEntry() {
        let entry = PizzaEntry(
            pizzaNumber: vm.pizzaEntries.count + 1,
            bakeTimeSeconds: snapshotBakeTime,
            ovenTempAchieved: Double(ovenTempInput),
            crustColor: crustColor,
            bottomResult: bottomResult,
            topResult: topResult,
            crustTags: Array(crustTags),
            crumbTags: Array(crumbTags),
            customCrustTags: Array(customCrustTags),
            customCrumbTags: Array(customCrumbTags),
            notes: notes,
            photoData: photos.first,     // legacy mirror
            photos: photos
        )
        vm.logPizza(entry)
    }

    var bakeTimeDisplay: String {
        let h = Int(snapshotBakeTime) / 3600
        let m = (Int(snapshotBakeTime) % 3600) / 60
        let s = Int(snapshotBakeTime) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    func tagChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.jakarta(.regular, size: 12))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Color(hex: "D2B96A") : Color(hex: "ECEAE3"))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
