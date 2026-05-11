import Foundation
import Combine

class SessionViewModel: ObservableObject {
    @Published var cards: [ProcessCard]
    @Published var currentIndex: Int = 0
    @Published var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var pHReadings: [Double] = []
    @Published var actualDurations: [UUID: TimeInterval] = [:]
    @Published var pauseDurations: [TimeInterval] = []

    let recipe: Recipe
    let preFlight: PreFlightData
    private var timer: AnyCancellable?
    private var pauseStart: Date? = nil

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

    func start() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsed += 1
                if self.sessionMode == .automatic,
                   let card = self.currentCard,
                   card.type.isTimed,
                   self.targetDuration > 0,
                   self.elapsed >= self.targetDuration {
                    self.completeCard()
                }
            }
    }

    func pause() {
        isRunning = false
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
        elapsed = 0
        if sessionMode == .automatic, let next = currentCard, next.type.isTimed {
            // keep running into next timed card
        } else if sessionMode == .automatic, let next = currentCard, next.type.isActionOnly {
            // pause at action cards so user can act
            pause()
        }
    }

    func logPH(_ value: Double) {
        pHReadings.append(value)
    }

    func buildBakeLog(rating: Int, crustTags: [CrustTag], crumbTags: [CrumbTag],
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
            photoData: photoData
        )
    }
}
