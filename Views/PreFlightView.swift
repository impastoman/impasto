import SwiftUI

enum WeightUnit: String, CaseIterable {
    case grams = "g"; case ounces = "oz"; case pounds = "lb"

    /// Bulk ingredients (flour, water, salt) — ceiling to nearest whole unit.
    func display(_ grams: Double) -> String {
        switch self {
        case .grams:  return String(format: "%.0f g",  ceil(grams))
        case .ounces: return String(format: "%.1f oz", ceil(grams / 28.3495 * 10) / 10)
        case .pounds: return String(format: "%.2f lb", ceil(grams / 453.592  * 100) / 100)
        }
    }

    /// Precise ingredients (yeast, additives) — ceiling to nearest hundredth.
    func displayPrecise(_ grams: Double) -> String {
        switch self {
        case .grams:  return String(format: "%.2f g",  ceil(grams * 100)   / 100)
        case .ounces: return String(format: "%.3f oz", ceil(grams / 28.3495  * 1000)  / 1000)
        case .pounds: return String(format: "%.4f lb", ceil(grams / 453.592  * 10000) / 10000)
        }
    }

    func displayShort(_ grams: Double) -> String {
        switch self {
        case .grams:  return String(format: "%.0f", grams)
        case .ounces: return String(format: "%.1f", grams / 28.3495)
        case .pounds: return String(format: "%.2f", grams / 453.592)
        }
    }

    func toGrams(_ v: Double) -> Double {
        switch self {
        case .grams:  return v
        case .ounces: return v * 28.3495
        case .pounds: return v * 453.592
        }
    }

    func toDisplay(_ grams: Double) -> Double {
        switch self {
        case .grams:  return grams
        case .ounces: return grams / 28.3495
        case .pounds: return grams / 453.592
        }
    }
}

struct PreFlightView: View {
    let recipe: Recipe
    @EnvironmentObject var store: RecipeStore
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var sessionManager: SessionManager
    @State private var data = PreFlightData()
    @State private var showConflictAlert = false
    @State private var showSession = false
    @State private var showChecklist = false
    @State private var showProcessEditor = false
    @State private var activeVM: SessionViewModel? = nil
    @State private var useCelsius = true
    @State private var weightUnit: WeightUnit = .grams

    func toDisplayTemp(_ c: Double) -> Double { useCelsius ? c : c * 9/5 + 32 }
    func fromDisplayTemp(_ t: Double) -> Double { useCelsius ? t : (t - 32) * 5/9 }
    func displayWeight(_ g: Double) -> String { weightUnit.displayShort(g) }
    func gramsFromDisplay(_ v: Double) -> Double { weightUnit.toGrams(v) }

    private var hasPreferment: Bool { recipe.method != .direct }

    private var totalDough: Double {
        let count = Double(data.overrideBallCount ?? recipe.ballCount)
        let weight = data.overrideBallWeight ?? recipe.ballWeight
        return count * weight
    }

    private var timeConflict: Bool {
        guard hasPreferment, !data.prefermentReady else { return false }
        return recipe.method.minimumHours > recipe.timeline.minimumHours
    }

    private var defaultSessionName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: Date())) · \(recipe.name)"
    }

    var body: some View {
        NavigationStack {
            List {
                sessionNameSection
                sessionModeSection
                if hasPreferment { prefermentSection }
                kitchenSection
                if !recipe.bakeSetups.isEmpty { bakeMethodSection }
                modificationsSection
                summarySection
            }
            .meadList()
            .navigationTitle("Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .keyboardDoneButton()
            .safeAreaInset(edge: .bottom) { beginButton }
            .sheet(isPresented: $showChecklist) {
                IngredientsChecklistView(recipe: resolvedRecipe, weightUnit: weightUnit)
            }
            .sheet(isPresented: $showProcessEditor) {
                SessionProcessEditorSheet(
                    recipe: recipe,
                    prefermentReady: data.prefermentReady,
                    overrides: $data.sessionStepDurationOverrides
                )
            }
            .alert("Time Conflict", isPresented: $showConflictAlert) {
                Button("Proceed Anyway") {
                    activeVM = sessionManager.start(recipe: resolvedRecipe, preFlight: data)
                    showSession = true
                }
                Button("Choose Another Recipe", role: .cancel) { dismiss() }
            } message: {
                Text("\(recipe.method.rawValue) needs at least \(Int(recipe.method.minimumHours))h but your \(recipe.timeline.rawValue) window (\(recipe.timeline.hours)) may not be enough if the preferment hasn't started.")
            }
        }
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showSession, onDismiss: {
            // Clean up session only if it wasn't hidden (hidden sessions stay in SessionManager)
            if let vm = activeVM, !vm.isHidden {
                sessionManager.end(vm)
                activeVM = nil
            }
        }) {
            if let vm = activeVM {
                LiveSessionView(vm: vm)
                    .environmentObject(store)
                    .environmentObject(sessionManager)
            }
        }
        .onChange(of: sessionManager.shouldReturnHome) { _, isTrue in
            if isTrue { dismiss() }
        }
    }

    // MARK: - Session name

    var sessionNameSection: some View {
        Section {
            TextField(defaultSessionName, text: $data.sessionName)
                .font(.jakarta(.regular, size: 17))
        } header: { Text("Session name") }
          footer: { Text("Optional — shown in your session history").tipText() }
    }

    // MARK: - Session mode

    var sessionModeSection: some View {
        Section {
            Picker("Session mode", selection: $data.sessionMode) {
                ForEach([SessionMode.automatic, .manual], id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)

            if data.sessionMode == .automatic {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle").foregroundColor(.secondary).font(.jakarta(.regular, size: 12))
                    Text("Timers advance automatically. A pause button is always available — pause times are logged.")
                        .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                }
                .tipText()
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle").foregroundColor(.secondary).font(.jakarta(.regular, size: 12))
                    Text("Timers run for reference only. Tap 'Next Step' when you're ready to advance.")
                        .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                }
                .tipText()
            }
        } header: { Text("Session mode") }
    }

    // MARK: - Preferment

    var prefermentSection: some View {
        Section {
            Toggle("Preferment is ready", isOn: $data.prefermentReady)
                .tint(Color(hex: "7FA2BD"))

            if data.prefermentReady {
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("hours", value: $data.prefermentAgeHours, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.center).frame(width: 80)
                        .font(.jakarta(.regular, size: 17))
                        .inputBox()
                    Text("h").foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Preferment not started — timeline may shift")
                        .font(.jakarta(.regular, size: 12)).foregroundColor(.orange)
                }
            }
        } header: { Text("\(recipe.method.rawValue) status") }
    }

    // MARK: - Kitchen

    var kitchenSection: some View {
        Section(header: Text("Kitchen").font(.jakarta(.semibold, size: 13))) {
            HStack {
                Text("Temperature")
                Spacer()
                Picker("", selection: $useCelsius) {
                    Text("°C").tag(true)
                    Text("°F").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 90)
            }
            HStack {
                Text("Dough weight")
                Spacer()
                Picker("", selection: $weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { u in Text(u.rawValue).tag(u) }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            HStack {
                Text("Room temp")
                Spacer()
                TextField(useCelsius ? "20" : "68", value: Binding(
                    get: { toDisplayTemp(data.roomTempC) },
                    set: { data.roomTempC = fromDisplayTemp($0) }
                ), format: .number)
                    .keyboardType(.decimalPad).multilineTextAlignment(.center).frame(width: 60)
                    .font(.jakarta(.regular, size: 17))
                    .inputBox()
                Text(useCelsius ? "°C" : "°F").foregroundColor(.secondary)
            }
            Toggle("Dough thermometer", isOn: $data.hasDoughThermometer).tint(Color(hex: "7FA2BD"))
        }
    }

    // MARK: - Bake method

    var bakeMethodSection: some View {
        Section {
            ForEach(recipe.bakeSetups) { setup in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(setup.method.displayName).font(.jakarta(.regular, size: 17))
                        if !setup.subMethod.isEmpty {
                            Text(setup.subMethod).font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: data.selectedBakeSetupId == setup.id ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(data.selectedBakeSetupId == setup.id ? Color(hex: "7FA2BD") : .secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { data.selectedBakeSetupId = setup.id }
            }
        } header: { Text("Bake method today") }
    }

    // MARK: - Modifications

    var modificationsSection: some View {
        Section {
            HStack {
                Text("Balls")
                Spacer()
                TextField("\(recipe.ballCount)", value: $data.overrideBallCount, format: .number)
                    .keyboardType(.numberPad).multilineTextAlignment(.center).frame(width: 60)
                    .font(.jakarta(.regular, size: 17))
                    .foregroundColor(data.overrideBallCount != nil ? Color(hex: "7FA2BD") : .primary)
                    .inputBox()
            }
            HStack {
                Text("Ball weight")
                Spacer()
                TextField("\(Int(ceil(weightUnit.toDisplay(recipe.ballWeight))))", value: Binding(
                    get: { ceil(weightUnit.toDisplay(data.overrideBallWeight ?? recipe.ballWeight)) },
                    set: { data.overrideBallWeight = weightUnit.toGrams(Double($0)) }
                ), format: .number)
                    .keyboardType(.numberPad).multilineTextAlignment(.center).frame(width: 60)
                    .font(.jakarta(.regular, size: 17))
                    .foregroundColor(data.overrideBallWeight != nil ? Color(hex: "7FA2BD") : .primary)
                    .inputBox()
                Text(weightUnit.rawValue).foregroundColor(.secondary)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dough loss factor")
                    Text("stuck to bowl, hands, scraper")
                        .font(.jakarta(.regular, size: 11))
                        .foregroundColor(.secondary)
                        .tipText()
                }
                Spacer()
                TextField("\(Int(ceil(weightUnit.toDisplay(totalDough * 0.025))))", value: Binding(
                    get: { ceil(weightUnit.toDisplay(data.overrideBuffer.map { $0 * totalDough } ?? totalDough * 0.025)) },
                    set: { data.overrideBuffer = weightUnit.toGrams(Double($0)) / totalDough }
                ), format: .number)
                .keyboardType(.numberPad).multilineTextAlignment(.center).frame(width: 60)
                .font(.jakarta(.regular, size: 17))
                .foregroundColor(data.overrideBuffer != nil ? Color(hex: "7FA2BD") : .primary)
                .inputBox()
                Text(weightUnit.rawValue).foregroundColor(.secondary)
            }
        } header: {
            Text("Last-minute adjustments")
        } footer: {
            Text("Gold values override the recipe for this session only.")
                .font(.jakarta(.regular, size: 11))
                .tipText()
        }
    }

    // MARK: - Summary

    var summarySection: some View {
        Section {
            LabeledContent("Recipe",      value: recipe.name)
            LabeledContent("Rise method", value: recipe.method.rawValue)
            LabeledContent("Timeline",    value: "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
            LabeledContent("Target",      value: "\(data.overrideBallCount ?? recipe.ballCount) × \(Int(ceil(weightUnit.toDisplay(data.overrideBallWeight ?? recipe.ballWeight)))) \(weightUnit.rawValue)")
            Button {
                showChecklist = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .foregroundColor(Color(hex: "7FA2BD"))
                    Text("Prep Ingredients")
                        .font(.jakarta(.regular, size: 17))
                        .foregroundColor(Color(hex: "7FA2BD"))
                }
            }
            Button {
                showProcessEditor = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(data.sessionStepDurationOverrides.isEmpty ? .secondary : Color(hex: "7FA2BD"))
                    Text("Review & Edit Process")
                        .font(.jakarta(.regular, size: 17))
                        .foregroundColor(data.sessionStepDurationOverrides.isEmpty ? .secondary : Color(hex: "7FA2BD"))
                }
            }
        } header: { Text("Session overview") }
        .font(.jakarta(.regular, size: 17))
        .foregroundColor(.secondary)
    }

    // MARK: - Begin button (long press)

    var beginButton: some View {
        LongPressBeginButton {
            if timeConflict { showConflictAlert = true }
            else {
                activeVM = sessionManager.start(recipe: resolvedRecipe, preFlight: data)
                showSession = true
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Resolved recipe

    var resolvedRecipe: Recipe {
        var r = recipe
        if let bc = data.overrideBallCount   { r.ballCount      = bc }
        if let bw = data.overrideBallWeight  { r.ballWeight     = bw }
        if let h  = data.overrideHydration   { r.finalHydration = h }
        if let b  = data.overrideBuffer      { r.buffer         = b }
        return r
    }
}

// MARK: - Session process editor

struct SessionProcessEditorSheet: View {
    let recipe: Recipe
    let prefermentReady: Bool
    @Binding var overrides: [String: TimeInterval]
    @Environment(\.dismiss) private var dismiss

    var enabledCards: [ProcessCard] {
        var cards = recipe.processCards.filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }
        if prefermentReady && recipe.method != .direct {
            cards = cards.filter { $0.type != .autolyse && $0.type != .incorporateYeast }
        }
        return cards
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Adjust step durations for this session only. Changes don't affect the saved recipe.")
                        .font(.jakarta(.regular, size: 12))
                        .foregroundColor(.secondary)
                }
                .listRowBackground(Color.clear)

                Section(header: Text("Process steps").font(.jakarta(.semibold, size: 13))) {
                    ForEach(enabledCards) { card in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.title)
                                    .font(.jakarta(.regular, size: 17))
                                if !card.subtitle.isEmpty {
                                    Text(card.subtitle)
                                        .font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if card.duration > 0 {
                                DurationField(
                                    seconds: Binding(
                                        get: { overrides[card.id.uuidString] ?? card.duration },
                                        set: { overrides[card.id.uuidString] = $0 }
                                    ),
                                    valueColor: overrides[card.id.uuidString] != nil
                                        ? Color(hex: "7FA2BD") : .primary
                                )
                            } else {
                                Text("action").font(.jakarta(.regular, size: 12)).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if !overrides.isEmpty {
                    Section {
                        Button("Reset all to recipe defaults") {
                            overrides = [:]
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.jakarta(.regular, size: 13))
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .meadList()
            .navigationTitle("Process Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "7FA2BD"))
                }
            }
            .keyboardDoneButton()
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Long-press begin button

private struct LongPressBeginButton: View {
    let action: () -> Void
    @State private var progress: Double = 0

    var body: some View {
        Text("Begin Session →")
            .font(.jakarta(.regular, size: 14))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color(hex: "7FA2BD"))
            .foregroundColor(Color(hex: "111210"))
            .cornerRadius(6)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Color(hex: "FFFFFF")
                        .opacity(0.28)
                        .frame(width: geo.size.width * progress)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onLongPressGesture(minimumDuration: 0.45, pressing: { isPressing in
                withAnimation(isPressing ? .linear(duration: 0.45) : .easeOut(duration: 0.15)) {
                    progress = isPressing ? 1.0 : 0.0
                }
            }, perform: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                withAnimation(.easeOut(duration: 0.15)) { progress = 0.0 }
                action()
            })
    }
}
