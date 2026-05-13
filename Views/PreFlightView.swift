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

    var body: some View {
        NavigationStack {
            List {
                sessionModeSection
                if hasPreferment { prefermentSection }
                kitchenSection
                if !recipe.bakeSetups.isEmpty { bakeMethodSection }
                modificationsSection
                summarySection
            }
            .navigationTitle("Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { beginButton }
            .sheet(isPresented: $showChecklist) {
                IngredientsChecklistView(recipe: resolvedRecipe, weightUnit: weightUnit)
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
                    Image(systemName: "info.circle").foregroundColor(.secondary).font(.caption)
                    Text("Timers advance automatically. A pause button is always available — pause times are logged.")
                        .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle").foregroundColor(.secondary).font(.caption)
                    Text("Timers run for reference only. Tap 'Next Step' when you're ready to advance.")
                        .font(.system(size: 12, design: .monospaced)).foregroundColor(.secondary)
                }
            }
        } header: { Text("Session mode") }
    }

    var prefermentSection: some View {
        Section {
            Toggle("Preferment is ready", isOn: $data.prefermentReady)
                .tint(Color(hex: "D2B96A"))

            if data.prefermentReady {
                HStack {
                    Text("Age")
                    Spacer()
                    TextField("hours", value: $data.prefermentAgeHours, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                        .font(.system(.body, design: .monospaced))
                    Text("h").foregroundColor(.secondary)
                }
                if data.hasPHMeter {
                    HStack {
                        Text("pH reading")
                        Spacer()
                        TextField("5.3", text: $data.prefermentPH)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Preferment not started — timeline may shift")
                        .font(.caption).foregroundColor(.orange)
                }
            }
        } header: { Text("\(recipe.method.rawValue) status") }
    }

    var kitchenSection: some View {
        Section("Kitchen") {
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
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 60)
                    .font(.system(.body, design: .monospaced))
                Text(useCelsius ? "°C" : "°F").foregroundColor(.secondary)
            }
            Toggle("pH meter available", isOn: $data.hasPHMeter).tint(Color(hex: "D2B96A"))
            Toggle("Dough thermometer", isOn: $data.hasDoughThermometer).tint(Color(hex: "D2B96A"))
        }
    }

    var bakeMethodSection: some View {
        Section {
            ForEach(recipe.bakeSetups) { setup in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(setup.method.rawValue).font(.system(.body, design: .monospaced))
                        if !setup.subMethod.isEmpty {
                            Text(setup.subMethod).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: data.selectedBakeSetupId == setup.id ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(data.selectedBakeSetupId == setup.id ? Color(hex: "D2B96A") : .secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture { data.selectedBakeSetupId = setup.id }
            }
        } header: { Text("Bake method today") }
    }

    var modificationsSection: some View {
        Section {
            HStack {
                Text("Balls")
                Spacer()
                TextField("\(recipe.ballCount)", value: $data.overrideBallCount, format: .number)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 60)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(data.overrideBallCount != nil ? Color(hex: "D2B96A") : .primary)
            }
            HStack {
                Text("Ball weight")
                Spacer()
                TextField("\(Int(ceil(weightUnit.toDisplay(recipe.ballWeight))))", value: Binding(
                    get: { ceil(weightUnit.toDisplay(data.overrideBallWeight ?? recipe.ballWeight)) },
                    set: { data.overrideBallWeight = weightUnit.toGrams(Double($0)) }
                ), format: .number)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 60)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(data.overrideBallWeight != nil ? Color(hex: "D2B96A") : .primary)
                Text(weightUnit.rawValue).foregroundColor(.secondary)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dough loss factor")
                    Text("stuck to bowl, hands, scraper")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                TextField("\(Int(ceil(weightUnit.toDisplay(totalDough * 0.025))))", value: Binding(
                    get: { ceil(weightUnit.toDisplay(data.overrideBuffer.map { $0 * totalDough } ?? totalDough * 0.025)) },
                    set: { data.overrideBuffer = weightUnit.toGrams(Double($0)) / totalDough }
                ), format: .number)
                .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 60)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(data.overrideBuffer != nil ? Color(hex: "D2B96A") : .primary)
                Text(weightUnit.rawValue).foregroundColor(.secondary)
            }
        } header: {
            Text("Last-minute adjustments")
        } footer: {
            Text("Gold values override the recipe for this session only.")
                .font(.system(size: 11, design: .monospaced))
        }
    }

    var summarySection: some View {
        Section {
            LabeledContent("Recipe",   value: recipe.name)
            LabeledContent("Rise method", value: recipe.method.rawValue)
            LabeledContent("Timeline", value: "\(recipe.timeline.rawValue)  ·  \(recipe.timeline.hours)")
            LabeledContent("Target", value: "\(data.overrideBallCount ?? recipe.ballCount) × \(Int(ceil(weightUnit.toDisplay(data.overrideBallWeight ?? recipe.ballWeight)))) \(weightUnit.rawValue)")
            Button {
                showChecklist = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .foregroundColor(Color(hex: "D2B96A"))
                    Text("Prep Ingredients")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(Color(hex: "D2B96A"))
                }
            }
        } header: { Text("Session overview") }
        .font(.system(.body, design: .monospaced))
        .foregroundColor(.secondary)
    }

    var beginButton: some View {
        Button("Begin Session →") {
            if timeConflict { showConflictAlert = true }
            else {
                activeVM = sessionManager.start(recipe: resolvedRecipe, preFlight: data)
                showSession = true
            }
        }
        .buttonStyle(ImpastoButtonStyle(filled: true))
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    var resolvedRecipe: Recipe {
        var r = recipe
        if let bc = data.overrideBallCount   { r.ballCount   = bc }
        if let bw = data.overrideBallWeight  { r.ballWeight  = bw }
        if let h  = data.overrideHydration   { r.finalHydration = h }
        if let b  = data.overrideBuffer      { r.buffer     = b }
        return r
    }
}
