import Foundation
import Combine

class SessionViewModel: ObservableObject, Identifiable {
    let id: UUID = UUID()

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

    init(recipe: Recipe, preFlight: PreFlightData = PreFlightData()) {
        self.recipe = recipe
        self.preFlight = preFlight
        var enabled = recipe.processCards.filter { $0.isEnabled }.sorted { $0.sortOrder < $1.sortOrder }
        if preFlight.prefermentReady && recipe.method != .direct {
            enabled = enabled.filter { $0.type != .autolyse && $0.type != .incorporateYeast }
        }
        self.cards = enabled
        if preFlight.sessionMode == .automatic { self.isRunning = false }
    }

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

    func start() {
        isRunning = true
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
        guard !isLastCard else { return }
        currentIndex += 1
        accumulatedSeconds = 0
        stepStartDate = isRunning ? Date() : nil
        elapsed = 0
        if sessionMode == .automatic, let next = currentCard, next.type.isActionOnly {
            pause()
        }
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
    }

    func resetBakeTimer() {
        accumulatedBakeSeconds = 0
        bakeStartDate = nil
        bakeElapsed = 0
    }

    func logPizza(_ entry: PizzaEntry) {
        pizzaEntries.append(entry)
    }

    func logPH(_ value: Double) {
        pHReadings.append(value)
    }

    func buildBakeLog(rating: Int, crustTags: [CrustTag], crumbTags: [CrumbTag],
                      customCrustTags: [String] = [], customCrumbTags: [String] = [],
                      notes: String, bakeTimeSeconds: TimeInterval,
                      ovenTempAchieved: Double?, crustColor: CrustColor,
                      bottomResult: BottomResult, topResult: TopResult,
                      photoData: Data?) -> BakeLog {
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
            photoData: photoData,
            pizzaEntries: pizzaEntries
        )
    }
}
