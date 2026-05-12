import SwiftUI

struct LiveSessionView: View {
    let recipe: Recipe
    @StateObject private var vm: SessionViewModel
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showPostBake = false
    @State private var pHInput = ""

    init(recipe: Recipe, preFlight: PreFlightData = PreFlightData()) {
        self.recipe = recipe
        _vm = StateObject(wrappedValue: SessionViewModel(recipe: recipe, preFlight: preFlight))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                cardTabs.padding(.top, 8)
                Spacer()
                timerBlock
                Spacer()
                ingredientRef.padding(.horizontal)
                stagePrompt.padding(.horizontal).padding(.top, 8)
                noteField.padding(.horizontal).padding(.top, 4)
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
                    if vm.isRunning {
                        Button("Pause") { vm.pause() }.foregroundColor(Color(hex: "D2B96A"))
                    } else {
                        Button("Start") { vm.start() }.foregroundColor(Color(hex: "D2B96A"))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showPostBake) {
            PostBakeView(vm: vm, recipe: recipe).environmentObject(store)
        }
    }

    var cardTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(vm.cards.enumerated()), id: \.element.id) { index, card in
                    let isCurrent = index == vm.currentIndex
                    let isDone    = index < vm.currentIndex
                    Text(card.title)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(isCurrent ? Color(hex: "D2B96A").opacity(0.12) : Color.clear)
                        .foregroundColor(isCurrent ? Color(hex: "D2B96A") : isDone ? Color(hex: "D2B96A").opacity(0.4) : .secondary)
                }
            }
        }
    }

    var isCountdown: Bool {
        vm.preFlight.sessionMode == .automatic &&
        (vm.currentCard?.type.isTimed == true) &&
        vm.targetDuration > 0
    }

    var displayTime: TimeInterval {
        isCountdown ? max(0, vm.targetDuration - vm.elapsed) : vm.elapsed
    }

    var timerBlock: some View {
        VStack(spacing: 6) {
            if let card = vm.currentCard {
                Text(card.title.uppercased())
                    .font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(.secondary)
                Text(card.subtitle)
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                Text(timeString(displayTime))
                    .font(.system(size: 56, design: .serif)).foregroundColor(Color(hex: "E8D49A"))
                if card.type.isTimed && vm.targetDuration > 0 {
                    ProgressView(value: vm.progress)
                        .tint(Color(hex: "D2B96A")).padding(.horizontal, 40)
                    Text(isCountdown ? "of \(timeString(vm.targetDuration))" : "Target: \(timeString(vm.targetDuration))")
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                }
                if vm.preFlight.sessionMode == .automatic && !vm.isRunning && !vm.isLastCard {
                    Text("PAUSED")
                        .font(.system(size: 10, design: .monospaced)).tracking(2)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    @ViewBuilder
    var ingredientRef: some View {
        if let card = vm.currentCard {
            let rows: [(String, String)] = {
                switch card.type {
                case .autolyse, .incorporateYeast, .incorporateSalt, .kneading:
                    if card.type == .autolyse {
                        return [
                            ("Flour", "\(Int(recipe.totalFlour))g"),
                            ("Water (hold back \(Int(recipe.bassinageReserveGrams))g)", "\(Int(recipe.totalWater - recipe.bassinageReserveGrams))g")
                        ]
                    } else if card.type == .incorporateYeast {
                        return recipe.method == .direct
                            ? [("Yeast", String(format: "%.1fg", recipe.bigaYeast))]
                            : [("Add preferment", "\(Int(recipe.bigaFlour + recipe.bigaWater))g")]
                    } else if card.type == .incorporateSalt {
                        return [("Salt (dissolved in \(Int(recipe.bassinageReserveGrams))g water)", "\(Int(recipe.totalSalt))g")]
                    }
                    return []
                case .bulkFermentation:
                    return [("Volume increase target", "50–80%")]
                default:
                    return []
                }
            }()

            if !rows.isEmpty {
                VStack(spacing: 8) {
                    ForEach(rows, id: \.0) { label, value in
                        HStack {
                            Text(label).foregroundColor(Color(hex: "9A9688"))
                            Spacer()
                            Text(value).foregroundColor(Color(hex: "2C2A24")).fontWeight(.medium)
                        }
                        .font(.system(size: 14, design: .monospaced))
                    }
                }
                .padding(14)
                .background(Color(hex: "F0EDE4"))
                .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    var stagePrompt: some View {
        if let card = vm.currentCard {
            switch card.type {
            case .autolyse:
                promptRow(icon: "drop", color: .blue, text: "Stir until no dry flour remains — do not knead. Cover and rest.")
                if card.autolyseMode != .standard {
                    promptRow(icon: "info.circle", color: .secondary, text: card.autolyseMode.description)
                }
            case .incorporateYeast:
                promptRow(icon: "circle.dotted", color: .secondary, text: "Dissolve yeast in reserved water. Fold into dough on one side.")
            case .incorporateSalt:
                promptRow(icon: "circle.dotted", color: .orange, text: "Dissolve salt in remaining water. Add on the opposite side from yeast.")
            case .bassinage:
                promptRow(icon: "drop.fill", color: .blue, text: "Add reserved water in 2–3 small additions. Allow full absorption between each.")
            case .kneading:
                if recipe.mixerType == .hand && recipe.finalHydration > 0.68 {
                    promptRow(icon: "hand.raised", color: .secondary, text: "Slap & fold technique recommended at this hydration. Wet hands throughout.")
                }
                promptRow(icon: "checkmark.circle", color: Color(hex: "D2B96A"), text: "Windowpane test at target time: stretch thin — should be translucent without tearing.")
            case .bulkFermentation:
                promptRow(icon: "arrow.up.arrow.down", color: .secondary, text: "Perform stretch & fold sets every 30 min for the first 2 hours (4 sets total).")
            case .preShape:
                promptRow(icon: "circle", color: .secondary, text: "Shape into rough balls. Surface tension should feel taut.")
            case .benchRest:
                promptRow(icon: "timer", color: .secondary, text: "Cover and rest. Gluten will relax for final shaping.")
            case .finalProof:
                promptRow(icon: "hand.tap", color: Color(hex: "D2B96A"), text: "Poke test: press gently — dough should spring back slowly when ready.")
            case .bake:
                if let setupId = vm.preFlight.selectedBakeSetupId,
                   let setup = recipe.bakeSetups.first(where: { $0.id == setupId }) {
                    promptRow(icon: "flame", color: .orange, text: "Preheat \(setup.method.rawValue)\(setup.subMethod.isEmpty ? "" : " (\(setup.subMethod))"): \(setup.ovenTempDisplay). Preheat ~\(setup.preheatMinutes) min.")
                } else {
                    promptRow(icon: "flame", color: .orange, text: "Preheat oven fully before launching.")
                }
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    var noteField: some View {
        if let card = vm.currentCard {
            let recipeNote = card.recipeNote
            VStack(alignment: .leading, spacing: 4) {
                if !recipeNote.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text").font(.caption).foregroundColor(.secondary)
                        Text(recipeNote)
                            .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    var actionRow: some View {
        HStack(spacing: 12) {
            if let card = vm.currentCard, card.type == .bake {
                Button("Done Baking") { showPostBake = true }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            } else if vm.isLastCard {
                Button("Done Baking") { showPostBake = true }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            } else {
                if vm.preFlight.sessionMode == .automatic && !vm.isRunning {
                    Button("Resume") { vm.resume() }
                        .buttonStyle(ImpastoButtonStyle(filled: false))
                }
                let isTimedAuto = vm.preFlight.sessionMode == .automatic && vm.currentCard?.type.isActionOnly == false
                Button(isTimedAuto ? "Skip →" : "Next Step →") { vm.completeCard() }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            }
        }
    }

    func promptRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.caption).padding(.top, 2)
            Text(text).font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
        }
    }

    func timeString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600; let m = (Int(t) % 3600) / 60; let s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
