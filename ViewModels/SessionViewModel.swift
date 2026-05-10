import Foundation
import Combine

class SessionViewModel: ObservableObject {
    @Published var currentStage: SessionStage = .biga
    @Published var elapsed: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var pHReadings: [Double] = []

    let recipe: Recipe
    private var timer: AnyCancellable?

    init(recipe: Recipe) {
        self.recipe = recipe
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

    func nextStage() {
        let stages = SessionStage.allCases
        guard let current = stages.firstIndex(of: currentStage),
              current + 1 < stages.count else { return }
        currentStage = stages[current + 1]
        elapsed = 0
    }

    func logPH(_ value: Double) {
        pHReadings.append(value)
    }
}
