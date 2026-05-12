import SwiftUI
import PhotosUI

struct PostBakeView: View {
    @ObservedObject var vm: SessionViewModel
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @State private var bakeTimeOverride: String = ""
    @State private var ovenTempInput: String = ""
    @State private var crustColor: CrustColor = .even
    @State private var bottomResult: BottomResult = .good
    @State private var topResult: TopResult = .good
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var showSessionLog = false

    var bakeSeconds: TimeInterval {
        if let s = TimeInterval(bakeTimeOverride), s > 0 { return s }
        return vm.actualDurations.values.reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            List {
                photoSection
                bakeTimeSection
                visualSection
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
        }
        .sheet(isPresented: $showSessionLog) {
            SessionLogView(
                vm: vm,
                recipe: recipe,
                bakeTimeSeconds: bakeSeconds,
                ovenTempAchieved: Double(ovenTempInput),
                crustColor: crustColor,
                bottomResult: bottomResult,
                topResult: topResult,
                photoData: photoData,
                onEndSession: { dismiss() }
            )
            .environmentObject(store)
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
                Task {
                    photoData = try? await item?.loadTransferable(type: Data.self)
                }
            }
        } header: { Text("Photo") }
        .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    var bakeTimeSection: some View {
        Section {
            HStack {
                Text("Bake time")
                Spacer()
                TextField(timeDisplay(vm.elapsed), text: $bakeTimeOverride)
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 72)
                    .font(.system(.body, design: .monospaced))
                Text("sec").foregroundColor(.secondary)
            }

            HStack {
                Text("Oven temp achieved")
                Spacer()
                TextField("optional", text: $ovenTempInput)
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 64)
                    .font(.system(.body, design: .monospaced))
                Text("°").foregroundColor(.secondary)
            }
        } header: { Text("Bake info") }
    }

    var visualSection: some View {
        Section("How did it look?") {
            HStack {
                Text("Crust color")
                Spacer()
                Picker("", selection: $crustColor) {
                    ForEach(CrustColor.allCases, id: \.self) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .labelsHidden()
            }

            HStack {
                Text("Bottom")
                Spacer()
                Picker("", selection: $bottomResult) {
                    ForEach(BottomResult.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .labelsHidden()
            }

            HStack {
                Text("Top")
                Spacer()
                Picker("", selection: $topResult) {
                    ForEach(TopResult.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .labelsHidden()
            }
        }
    }

    func timeDisplay(_ t: TimeInterval) -> String {
        String(format: "%.0f", t)
    }
}
