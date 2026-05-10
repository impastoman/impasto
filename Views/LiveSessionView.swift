import SwiftUI

struct LiveSessionView: View {
    let recipe: Recipe
    @StateObject private var vm: SessionViewModel
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showLog = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _vm = StateObject(wrappedValue: SessionViewModel(recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stageTabs
                    .padding(.top, 8)

                Spacer()

                timerBlock

                Spacer()

                ingredientRef
                    .padding(.horizontal)

                Spacer()

                actionRow
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
            .navigationTitle("Live Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("✕") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(vm.isRunning ? "Pause" : "Start") {
                        vm.isRunning ? vm.pause() : vm.start()
                    }
                    .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        }
        .sheet(isPresented: $showLog) {
            SessionLogView(recipe: recipe).environmentObject(store)
        }
    }

    var stageTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(SessionStage.allCases, id: \.self) { stage in
                    Text(stage.title)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(stage == vm.currentStage ? Color(hex: "D2B96A").opacity(0.12) : Color.clear)
                        .foregroundColor(stage == vm.currentStage ? Color(hex: "D2B96A") : .secondary)
                }
            }
        }
    }

    var timerBlock: some View {
        VStack(spacing: 6) {
            Text(vm.currentStage.title.uppercased())
                .font(.system(size: 10, design: .monospaced))
                .tracking(2)
                .foregroundColor(.secondary)
            Text(timeString(vm.elapsed))
                .font(.system(size: 56, design: .serif))
                .foregroundColor(Color(hex: "E8D49A"))
            ProgressView(value: vm.progress)
                .tint(Color(hex: "D2B96A"))
                .padding(.horizontal, 40)
            if vm.currentStage == .biga {
                Text("Target pH 5.3–5.5")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }

    var ingredientRef: some View {
        VStack(spacing: 8) {
            let rows: [(String, String)] = {
                switch vm.currentStage {
                case .biga:
                    return [
                        ("Biga flour", "\(Int(recipe.bigaFlour))g"),
                        ("Biga water", "\(Int(recipe.bigaWater))g"),
                        ("Yeast",      String(format: "%.1fg", recipe.bigaYeast))
                    ]
                case .finalDough:
                    return [
                        ("Add flour", "\(Int(recipe.additionalFlour))g"),
                        ("Add water", "\(Int(recipe.additionalWater))g"),
                        ("Salt",      "\(Int(recipe.totalSalt))g")
                    ]
                default:
                    return []
                }
            }()
            ForEach(rows, id: \.0) { label, value in
                HStack {
                    Text(label).foregroundColor(.secondary)
                    Spacer()
                    Text(value).fontWeight(.medium)
                }
                .font(.system(size: 14, design: .monospaced))
            }
        }
        .padding(16)
        .background(Color(hex: "1A1B18"))
        .cornerRadius(8)
    }

    var actionRow: some View {
        HStack(spacing: 12) {
            if vm.currentStage == .biga {
                Button("Log pH") { vm.logPH(5.4) }
                    .buttonStyle(ImpastoButtonStyle(filled: false))
            }
            if vm.currentStage == .bake {
                Button("Complete Session") { showLog = true }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            } else {
                Button("Next Stage →") { vm.nextStage() }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            }
        }
    }

    func timeString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
