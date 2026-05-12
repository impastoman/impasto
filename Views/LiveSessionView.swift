import SwiftUI

struct LiveSessionView: View {
    @ObservedObject var vm: SessionViewModel
    @EnvironmentObject var store: RecipeStore
    @EnvironmentObject var sessionManager: SessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPostBake = false
    @State private var showRecipeSheet = false
    @State private var showPizzaLog = false
    @State private var showEndBakingAlert = false
    @State private var sessionNotes: [UUID: String] = [:]

    var recipe: Recipe { vm.recipe }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F1E8").ignoresSafeArea()

                if vm.isInBakeStep {
                    bakeStepView
                } else {
                    processView
                }
            }
            .navigationTitle("Live Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.isHidden = true
                        vm.pause()
                        dismiss()
                    } label: {
                        Image(systemName: "house")
                    }
                    .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showRecipeSheet = true
                        } label: {
                            Image(systemName: "doc.text")
                        }
                        .foregroundColor(.secondary)
                        if !vm.isInBakeStep {
                            if vm.isRunning {
                                Button("Pause") { vm.pause() }.foregroundColor(Color(hex: "D2B96A"))
                            } else {
                                Button("Start") { vm.start() }.foregroundColor(Color(hex: "D2B96A"))
                            }
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showPostBake) {
            PostBakeView(vm: vm, recipe: recipe)
                .environmentObject(store)
                .environmentObject(sessionManager)
        }
        .sheet(isPresented: $showPizzaLog) {
            PizzaLogView(vm: vm, recipe: recipe) {
                // "Return to baking" — reset bake timer
                vm.resetBakeTimer()
                showPizzaLog = false
            } onEndBake: {
                vm.stopBaking()
                showPizzaLog = false
                showPostBake = true
            }
            .environmentObject(store)
            .environmentObject(sessionManager)
        }
        .onChange(of: sessionManager.sessions.count) { _, _ in
            if !sessionManager.sessions.contains(where: { $0 === vm }) {
                dismiss()
            }
        }
        .sheet(isPresented: $showRecipeSheet) {
            NavigationStack {
                RecipeDetailView(recipe: recipe)
                    .environmentObject(store)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showRecipeSheet = false }
                        }
                    }
            }
        }
    }

    // MARK: - Process view

    var processView: some View {
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
    }

    // MARK: - Card tabs

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

    // MARK: - Timer

    var isCountdown: Bool {
        vm.preFlight.sessionMode == .automatic &&
        (vm.currentCard?.type.isTimed == true) &&
        vm.targetDuration > 0
    }

    var displayTime: TimeInterval {
        if isCountdown {
            if vm.elapsed > vm.targetDuration {
                return vm.elapsed - vm.targetDuration  // overtime: count up from 0
            }
            return vm.targetDuration - vm.elapsed      // counting down
        }
        return vm.elapsed
    }

    var timerBlock: some View {
        VStack(spacing: 6) {
            if let card = vm.currentCard {
                Text(card.title.uppercased())
                    .font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(.secondary)
                Text(card.subtitle)
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)

                Text(timeString(displayTime))
                    .font(.system(size: 56, design: .serif))
                    .foregroundColor(vm.isOvertime ? Color.orange : Color(hex: "2C2A24"))
                    .onLongPressGesture(minimumDuration: 0.6) {
                        let gen = UIImpactFeedbackGenerator(style: .heavy)
                        gen.impactOccurred()
                        vm.resetTimer()
                    }

                if card.type.isTimed && vm.targetDuration > 0 {
                    ProgressView(value: vm.progress)
                        .tint(vm.isOvertime ? .orange : Color(hex: "D2B96A"))
                        .padding(.horizontal, 40)
                    if vm.isOvertime {
                        Text("+\(timeString(vm.elapsed - vm.targetDuration)) overtime")
                            .font(.system(size: 11, design: .monospaced)).foregroundColor(.orange)
                    } else {
                        Text(isCountdown ? "of \(timeString(vm.targetDuration))" : "Target: \(timeString(vm.targetDuration))")
                            .font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                    }
                }

                if vm.preFlight.sessionMode == .automatic && !vm.isRunning && !vm.isLastCard {
                    Text("PAUSED")
                        .font(.system(size: 10, design: .monospaced)).tracking(2)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - Ingredient reference

    @ViewBuilder
    var ingredientRef: some View {
        if let card = vm.currentCard {
            let rows: [(String, String)] = {
                switch card.type {
                case .autolyse:
                    return [
                        ("Flour", "\(Int(recipe.totalFlour))g"),
                        ("Water (hold back \(Int(recipe.bassinageReserveGrams))g)", "\(Int(recipe.totalWater - recipe.bassinageReserveGrams))g")
                    ]
                case .incorporateYeast:
                    return recipe.method == .direct
                        ? [("Yeast", String(format: "%.1fg", recipe.bigaYeast))]
                        : [("Add preferment", "\(Int(recipe.bigaFlour + recipe.bigaWater))g")]
                case .incorporateSalt:
                    return [("Salt (dissolved in \(Int(recipe.bassinageReserveGrams))g water)", "\(Int(recipe.totalSalt))g")]
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

    // MARK: - Stage prompt

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

    // MARK: - Note field

    @ViewBuilder
    var noteField: some View {
        if let card = vm.currentCard {
            VStack(alignment: .leading, spacing: 6) {
                if !card.recipeNote.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "note.text").font(.caption).foregroundColor(.secondary).padding(.top, 2)
                        Text(card.recipeNote)
                            .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                    }
                }
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "pencil").font(.caption).foregroundColor(.secondary).padding(.top, 2)
                    TextField("Add a session note for this step…",
                              text: Binding(
                                get: { sessionNotes[card.id] ?? "" },
                                set: { sessionNotes[card.id] = $0.isEmpty ? nil : $0 }
                              ),
                              axis: .vertical)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.primary)
                        .lineLimit(1...3)
                }
            }
        }
    }

    // MARK: - Action row

    var actionRow: some View {
        HStack(spacing: 12) {
            // Back button — always available when not on first card
            if vm.currentIndex > 0 {
                Button("← Back") {
                    vm.goBack()
                }
                .buttonStyle(ImpastoButtonStyle(filled: false))
            }

            if vm.isLastCard {
                Button("Proceed to Bake →") {
                    vm.enterBakeStep()
                }
                .buttonStyle(ImpastoButtonStyle(filled: true))
            } else {
                if vm.preFlight.sessionMode == .automatic && !vm.isRunning {
                    Button("Resume") { vm.resume() }
                        .buttonStyle(ImpastoButtonStyle(filled: false))
                }
                let isTimedAuto = vm.preFlight.sessionMode == .automatic && vm.currentCard?.type.isActionOnly == false
                Button(isTimedAuto ? "Proceed →" : "Next Step →") { vm.completeCard() }
                    .buttonStyle(ImpastoButtonStyle(filled: true))
            }
        }
    }

    // MARK: - Bake step view

    var bakeStepView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text("BAKE")
                    .font(.system(size: 10, design: .monospaced)).tracking(2).foregroundColor(.secondary)

                if vm.bakingStarted {
                    Text(timeString(vm.bakeElapsed))
                        .font(.system(size: 56, design: .serif))
                        .foregroundColor(Color(hex: "2C2A24"))
                } else {
                    Text("Ready to launch")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let setupId = vm.preFlight.selectedBakeSetupId,
               let setup = recipe.bakeSetups.first(where: { $0.id == setupId }) {
                VStack(spacing: 8) {
                    HStack {
                        Text(setup.method.rawValue)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.secondary)
                        if !setup.subMethod.isEmpty {
                            Text("· \(setup.subMethod)")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(setup.ovenTempDisplay)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(Color(hex: "D2B96A"))
                    }
                    promptRow(icon: "flame", color: .orange, text: "Preheat ~\(setup.preheatMinutes) min before launching. Use infrared thermometer on stone/steel.")
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            } else {
                promptRow(icon: "flame", color: .orange, text: "Preheat oven fully before launching.")
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            Spacer()

            bakeActionRow
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
    }

    var bakeActionRow: some View {
        VStack(spacing: 12) {
            if vm.bakingStarted {
                Button("Log Pizza") {
                    showPizzaLog = true
                }
                .buttonStyle(ImpastoButtonStyle(filled: false))

                Button("End Baking") {
                    showEndBakingAlert = true
                }
                .buttonStyle(ImpastoButtonStyle(filled: true))
                .confirmationDialog("End baking?", isPresented: $showEndBakingAlert, titleVisibility: .visible) {
                    Button("End Baking", role: .destructive) {
                        let gen = UIImpactFeedbackGenerator(style: .medium)
                        gen.impactOccurred()
                        vm.stopBaking()
                        showPostBake = true
                    }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                Button("Start Baking") {
                    vm.startBaking()
                }
                .buttonStyle(ImpastoButtonStyle(filled: true))
            }
        }
    }

    // MARK: - Helpers

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
