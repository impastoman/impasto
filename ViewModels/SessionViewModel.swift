import Foundation
import Combine

// MARK: - Session Snapshot (persistence)

struct SessionSnapshot: Codable {
    var id: UUID
    var recipe: Recipe
    var preFlight: PreFlightData
    var cards: [ProcessCard]
    var currentIndex: Int
    var accumulatedSeconds: TimeInterval
    var pHReadings: [Double]
    var actualDurations: [String: TimeInterval]   // UUID.uuidString keys
    var pauseDurations: [TimeInterval]
    var isInBakeStep: Bool
    var bakingStarted: Bool
    var accumulatedBakeSeconds: TimeInterval
    var pizzaEntries: [PizzaEntry]
    var isHidden: Bool
    var sessionNote: String
    var savedAt: Date
    // Step timestamps
    var sessionStartDate: Date?
    var stepCompletionDates: [String: Date]       // UUID.uuidString keys
    // Persisted run/pause state. Defaulted to true so any snapshot decoded
    // from before this field existed is treated as a running session
    // (matching the invariant: only a manual pause should leave a session
    // paused across app launches).
    var isRunning: Bool = true
}

// MARK: - View Model

class SessionViewModel: ObservableObject, Identifiable {
    let id: UUID

    @Published var cards: [ProcessCard]
    @Published var currentIndex: Int = 0
    @Published var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var pHReadings: [Double] = []
    @Published var actualDurations: [UUID: TimeInterval] = [:]
    @Published var pauseDurations: [TimeInterval] = []

    // Bake step state
    @Published var isInBakeStep: Bool = false
    @Published var bakingStarted: Bool = false
    @Published var bakeElapsed: TimeInterval = 0
    @Published var pizzaEntries: [PizzaEntry] = []

    var isHidden: Bool = false
    @Published var sessionNote: String = ""

    // Step timestamps (wall-clock)
    @Published var stepCompletionDates: [UUID: Date] = [:]
    var sessionStartDate: Date? = nil

    let recipe: Recipe
    let preFlight: PreFlightData
    private var timer: AnyCancellable?
    private var bakeTimer: AnyCancellable?
    private var pauseStart: Date? = nil

    // Clock-anchored timing — survives backgrounding
    private var stepStartDate: Date? = nil
    private var accumulatedSeconds: TimeInterval = 0
    private var bakeStartDate: Date? = nil
    private var accumulatedBakeSeconds: TimeInterval = 0

    // Persistence hook — called on every meaningful state change
    var persistenceHook: (() -> Void)? = nil

    // MARK: - Normal init

    init(recipe: Recipe, preFlight: PreFlightData = PreFlightData()) {
        self.id = UUID()
        self.recipe = recipe
        self.preFlight = preFlight
        var enabled = recipe.processCards.filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }
        if preFlight.prefermentReady && recipe.method != .direct {
            enabled = enabled.filter { $0.type != .autolyse && $0.type != .incorporateYeast }
        }
        self.cards = enabled
        // Apply session-only step duration overrides from PreFlight
        for i in self.cards.indices {
            let key = self.cards[i].id.uuidString
            if let override = preFlight.sessionStepDurationOverrides[key] {
                self.cards[i].customDuration = override
            }
        }
    }

    // MARK: - Restore init

    init(restoringFrom snapshot: SessionSnapshot) {
        self.id = snapshot.id
        self.recipe = snapshot.recipe
        self.preFlight = snapshot.preFlight
        self.cards = snapshot.cards
        self.currentIndex = snapshot.currentIndex
        self.accumulatedSeconds = snapshot.accumulatedSeconds
        self.elapsed = snapshot.accumulatedSeconds
        // isRunning is finalized below after we decide whether to resume timers
        self.isRunning = false
        self.pHReadings = snapshot.pHReadings
        var durations: [UUID: TimeInterval] = [:]
        for (key, value) in snapshot.actualDurations {
            if let uuid = UUID(uuidString: key) { durations[uuid] = value }
        }
        self.actualDurations = durations
        self.pauseDurations = snapshot.pauseDurations
        self.isInBakeStep = snapshot.isInBakeStep
        self.bakingStarted = snapshot.bakingStarted
        self.accumulatedBakeSeconds = snapshot.accumulatedBakeSeconds
        self.bakeElapsed = snapshot.accumulatedBakeSeconds
        self.pizzaEntries = snapshot.pizzaEntries
        self.isHidden = snapshot.isHidden
        self.sessionNote = snapshot.sessionNote
        self.sessionStartDate = snapshot.sessionStartDate
        var completions: [UUID: Date] = [:]
        for (key, value) in snapshot.stepCompletionDates {
            if let uuid = UUID(uuidString: key) { completions[uuid] = value }
        }
        self.stepCompletionDates = completions

        // Bridge the wall-clock gap between snapshot save and now, then resume
        // timers if the session was running. A session is only ever paused by
        // a manual button press, so a snapshot with isRunning == true means
        // the user expected time to keep advancing while the app was closed.
        if snapshot.isRunning {
            let bridge = max(0, Date().timeIntervalSince(snapshot.savedAt))
            self.accumulatedSeconds += bridge
            self.elapsed = self.accumulatedSeconds
            if snapshot.bakingStarted {
                self.accumulatedBakeSeconds += bridge
                self.bakeElapsed = self.accumulatedBakeSeconds
                self.startBaking()
            }
            self.start()
        }
    }

    // MARK: - Snapshot

    func snapshot() -> SessionSnapshot {
        // Capture in-flight elapsed time so nothing is lost mid-step
        let currentAccumulated: TimeInterval
        if isRunning, let start = stepStartDate {
            currentAccumulated = accumulatedSeconds + Date().timeIntervalSince(start)
        } else {
            currentAccumulated = accumulatedSeconds
        }
        let currentBakeAccumulated: TimeInterval
        if bakingStarted, let start = bakeStartDate {
            currentBakeAccumulated = accumulatedBakeSeconds + Date().timeIntervalSince(start)
        } else {
            currentBakeAccumulated = accumulatedBakeSeconds
        }
        // Strip bakeLogs to avoid encoding historic photo data
        var snapshotRecipe = recipe
        snapshotRecipe.bakeLogs = []
        return SessionSnapshot(
            id: id,
            recipe: snapshotRecipe,
            preFlight: preFlight,
            cards: cards,
            currentIndex: currentIndex,
            accumulatedSeconds: currentAccumulated,
            pHReadings: pHReadings,
            actualDurations: Dictionary(uniqueKeysWithValues:
                actualDurations.map { ($0.key.uuidString, $0.value) }),
            pauseDurations: pauseDurations,
            isInBakeStep: isInBakeStep,
            bakingStarted: bakingStarted,
            accumulatedBakeSeconds: currentBakeAccumulated,
            pizzaEntries: pizzaEntries,
            isHidden: isHidden,
            sessionNote: sessionNote,
            savedAt: Date(),
            sessionStartDate: sessionStartDate,
            stepCompletionDates: Dictionary(uniqueKeysWithValues:
                stepCompletionDates.map { ($0.key.uuidString, $0.value) }),
            isRunning: isRunning
        )
    }

    // MARK: - Computed

    var currentCard: ProcessCard? { cards.indices.contains(currentIndex) ? cards[currentIndex] : nil }
    var isLastCard: Bool { currentIndex >= cards.count - 1 }
    var sessionMode: SessionMode { preFlight.sessionMode }

    var targetDuration: TimeInterval { currentCard?.duration ?? 0 }
    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(elapsed / targetDuration, 1.0)
    }

    var isOvertime: Bool {
        targetDuration > 0 && elapsed > targetDuration
    }

    // MARK: - Timer control

    func start() {
        isRunning = true
        if sessionStartDate == nil { sessionStartDate = Date() }
        stepStartDate = Date()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.stepStartDate else { return }
                self.elapsed = self.accumulatedSeconds + Date().timeIntervalSince(start)
            }
    }

    func pause() {
        isRunning = false
        if let start = stepStartDate {
            accumulatedSeconds += Date().timeIntervalSince(start)
            stepStartDate = nil
        }
        timer?.cancel()
        pauseStart = Date()
        persistenceHook?()
    }

    func resume() {
        if let start = pauseStart {
            pauseDurations.append(Date().timeIntervalSince(start))
            pauseStart = nil
        }
        start()
    }

    func completeCard() {
        guard let card = currentCard else { return }
        actualDurations[card.id] = elapsed
        stepCompletionDates[card.id] = Date()
        guard !isLastCard else { return }
        currentIndex += 1
        accumulatedSeconds = 0
        stepStartDate = isRunning ? Date() : nil
        elapsed = 0
        // No auto-pause on action-only steps. The session timer keeps counting
        // up so we can record true total session time. The user pauses
        // manually if they want to stop the clock.
        persistenceHook?()
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        let savedElapsed = actualDurations[cards[currentIndex].id] ?? 0
        accumulatedSeconds = savedElapsed
        stepStartDate = isRunning ? Date() : nil
        elapsed = savedElapsed
    }

    func resetTimer() {
        accumulatedSeconds = 0
        stepStartDate = isRunning ? Date() : nil
        elapsed = 0
    }

    // MARK: - Bake step

    func enterBakeStep() {
        isInBakeStep = true
        persistenceHook?()
    }

    func startBaking() {
        bakingStarted = true
        bakeStartDate = Date()
        bakeTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.bakeStartDate else { return }
                self.bakeElapsed = self.accumulatedBakeSeconds + Date().timeIntervalSince(start)
            }
    }

    func stopBaking() {
        if let start = bakeStartDate {
            accumulatedBakeSeconds += Date().timeIntervalSince(start)
            bakeStartDate = nil
        }
        bakeTimer?.cancel()
        persistenceHook?()
    }

    func resetBakeTimer() {
        accumulatedBakeSeconds = 0
        bakeStartDate = nil
        bakeElapsed = 0
    }

    func logPizza(_ entry: PizzaEntry) {
        pizzaEntries.append(entry)
        persistenceHook?()
    }

    func logPH(_ value: Double) {
        pHReadings.append(value)
    }

    func buildBakeLog(rating: Int, crustTags: [CrustTag], crumbTags: [CrumbTag],
                      customCrustTags: [String] = [], customCrumbTags: [String] = [],
                      notes: String, bakeTimeSeconds: TimeInterval,
                      ovenTempAchieved: Double?, crustColor: CrustColor,
                      bottomResult: BottomResult, topResult: TopResult,
                      photoIDs: [UUID] = []) -> BakeLog {
        var planned: [String: TimeInterval] = [:]
        var actual: [String: TimeInterval] = [:]
        for card in cards {
            planned[card.title] = card.duration
            if let a = actualDurations[card.id] { actual[card.title] = a }
        }
        return BakeLog(
            recipeId: recipe.id,
            rating: rating,
            crustTags: crustTags,
            crumbTags: crumbTags,
            customCrustTags: customCrustTags,
            customCrumbTags: customCrumbTags,
            notes: notes,
            ballCount: preFlight.overrideBallCount ?? recipe.ballCount,
            ballWeight: preFlight.overrideBallWeight ?? recipe.ballWeight,
            finalHydration: preFlight.overrideHydration ?? recipe.finalHydration,
            plannedStageDurations: planned,
            actualStageDurations: actual,
            pauseDurations: pauseDurations,
            roomTempC: preFlight.roomTempC,
            prefermentPH: preFlight.prefermentPH,
            sessionMode: preFlight.sessionMode,
            bakeTimeSeconds: bakeTimeSeconds,
            ovenTempAchieved: ovenTempAchieved,
            crustColor: crustColor,
            bottomResult: bottomResult,
            topResult: topResult,
            photoData: nil,
            photos: [],
            photoIDs: photoIDs,
            pizzaEntries: pizzaEntries
        )
    }
}
