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
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    var body: some View {
        NavigationStack {
            List {
                photoSection
                bakeInfoSection
                visualSection
                tagsSection
                notesSection
            }
            .navigationTitle("Log Pizza")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Return to Baking") {
                        onReturnToBaking()
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Bake →") {
                        onEndBake()
                    }
                    .foregroundColor(Color(hex: "D2B96A"))
                }
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
                        Text("Add a photo")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                Task { photoData = try? await item?.loadTransferable(type: Data.self) }
            }
        } header: { Text("Photo") }
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    var bakeInfoSection: some View {
        Section("Bake info") {
            HStack {
                Text("Bake time so far")
                Spacer()
                Text(bakeTimeDisplay)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            HStack {
                Text("Oven temp achieved")
                Spacer()
                TextField("optional", text: $ovenTempInput)
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 64)
                    .font(.system(.body, design: .monospaced))
                Text("°").foregroundColor(.secondary)
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
            TextField("Any notes about this pizza…", text: $notes, axis: .vertical)
                .font(.system(size: 13, design: .monospaced))
                .lineLimit(3...)
        }
    }

    var bakeTimeDisplay: String {
        let h = Int(vm.bakeElapsed) / 3600
        let m = (Int(vm.bakeElapsed) % 3600) / 60
        let s = Int(vm.bakeElapsed) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    func tagChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Color(hex: "D2B96A") : Color(hex: "ECEAE3"))
                .foregroundColor(selected ? .white : .primary)
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}
