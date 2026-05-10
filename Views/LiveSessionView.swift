import SwiftUI

struct LiveSessionView: View {
    let recipe: Recipe
    @StateObject private var vm: SessionViewModel
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showLog = false
    @State private var pHInput = ""

    init(recipe: Recipe, preFlight: PreFlightData = PreFlightData()) {
        self.recipe = recipe
        _vm = StateObject(wrappedValue: SessionViewModel(recipe: recipe, preFlight: preFlight))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stageTabs.padding(.top, 8)
                Spacer()
                timerBlock
                Spacer()
                ingredientRef.padding(.horizontal)
                stageInputs.padding(.horizontal).padding(.top, 8)
                Spacer()
                actionRow.padding(.horizontal).padding(.bottom, 24)
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
            SessionLogView(vm: vm, recipe: recipe).environmentObject(store)
        }
    }

    var stageTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(SessionStage.allCases, id: \.self) { stage in
                    let isDone = stage.rawValue < vm.currentStage.rawValue
                    Text(stage.title)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(stage == vm.currentStage
                            ? Color(hex: "D2B96A").opacity(0.12)
                            : Color.clear)
                        .foregroundColor(
                            stage == vm.currentStage ? Color(hex: "D2B96A")
                            : isDone ? Color(hex: "D2B96A").opacity(0.4)
                            : .secondary)
                        .overlay(
                            isDone ? Image(systemName: "checkmark")
                                .font(.system(size: 8))
                                .foregroundColor(Color(hex: "D2B96A").opacity(0.5))
                                .offset(x: 0, y: -14)
                            : nil
                        )
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
            Text("Target: \(timeString(vm.targetDuration))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }

    var ingredientRef: some View {
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
        return Group {
            if !rows.isEmpty {
                VStack(spacing: 8) {
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
        }
    }

    @ViewBuilder
    var stageInputs: some View {
        switch vm.currentStage {
        case .biga:
            if recipe.method != .direct {
                HStack(spacing: 8) {
                    Image(systemName: "thermometer.medium")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Log preferment pH when it peaks")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("5.4", text: $pHInput)
                        .keyboardType(.decimalPad)
                        .frame(width: 52)
                        .font(.system(size: 14, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding(6)
                        .background(Color(hex: "1A1B18"))
                        .cornerRadius(6)
                    Button("Log") {
                        if let v = Double(pHInput) { vm.logPH(v); pHInput = "" }
                    }
                    .font(.caption)
                    .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        case .finalDough:
            if recipe.autolyse {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Autolyse rest: \(recipe.autolyseMinutes) min before mixing")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
        case .bulkProof, .ballProof:
            HStack(spacing: 8) {
                Image(systemName: "thermometer.medium")
                    .foregroundColor(.secondary)
                    .font(.caption)
                Text("Look for 50–80% volume increase")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        default:
            EmptyView()
        }
    }

    var actionRow: some View {
        HStack(spacing: 12) {
            if vm.currentStage == .bake {
                Button("Complete Session") { showLog = true }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            } else {
                Button("Next Stage →") { vm.completeStage() }
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
