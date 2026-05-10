import Foundation
import Combine

class SessionViewModel: ObservableObject {
    @Published var currentStage: SessionStage = .biga
    @Published var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var pHReadings: [Double] = []
    @Published var actualStageDurations: [SessionStage: TimeInterval] = [:]

    let recipe: Recipe
    let preFlight: PreFlightData
    private var timer: AnyCancellable?

    init(recipe: Recipe, preFlight: PreFlightData = PreFlightData()) {
        self.recipe = recipe
        self.preFlight = preFlight
        if preFlight.prefermentReady && recipe.method != .direct {
            currentStage = .finalDough
        }
    }

    var targetDuration: TimeInterval { currentStage.defaultDuration }
    var progress: Double { min(elapsed / targetDuration, 1.0) }

    func start() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.elapsed += 1 }
    }

    func pause() {
        isRunning = false
        timer?.cancel()
    }

    func completeStage() {
        actualStageDurations[currentStage] = elapsed
        let stages = SessionStage.allCases
        guard let current = stages.firstIndex(of: currentStage),
              current + 1 < stages.count else { return }
        currentStage = stages[current + 1]
        elapsed = 0
    }

    func logPH(_ value: Double) {
        pHReadings.append(value)
    }

    func buildBakeLog(rating: Int, crustTags: [CrustTag], crumbTags: [CrumbTag], notes: String) -> BakeLog {
        var planned: [String: TimeInterval] = [:]
        var actual: [String: TimeInterval] = [:]
        for stage in SessionStage.allCases {
            planned[stage.title] = stage.defaultDuration
            if let a = actualStageDurations[stage] { actual[stage.title] = a }
        }
        return BakeLog(
            recipeId: recipe.id,
            rating: rating,
            crustTags: crustTags,
            crumbTags: crumbTags,
            notes: notes,
            ballCount: recipe.ballCount,
            ballWeight: recipe.ballWeight,
            finalHydration: recipe.finalHydration,
            plannedStageDurations: planned,
            actualStageDurations: actual,
            roomTempC: preFlight.roomTempC,
            prefermentPH: preFlight.prefermentPH
        )
    }
}
