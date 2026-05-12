import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published var sessions: [SessionViewModel] = []
    @Published var shouldReturnHome: Bool = false

    func start(recipe: Recipe, preFlight: PreFlightData) -> SessionViewModel {
        let vm = SessionViewModel(recipe: recipe, preFlight: preFlight)
        sessions.append(vm)
        return vm
    }

    func end(_ vm: SessionViewModel) {
        sessions.removeAll { $0 === vm }
    }
}
