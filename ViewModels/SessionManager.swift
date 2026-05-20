import Foundation
import Combine
import UIKit

class SessionManager: ObservableObject {
    @Published var sessions: [SessionViewModel] = []
    @Published var shouldReturnHome: Bool = false

    private let saveKey = "impasto_sessions_v1"     // fallback UserDefaults key
    private var cancellables = Set<AnyCancellable>()

    init() {
        restoreAll()
        // Save when app moves to background or is about to be killed
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.saveAll() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in self?.saveAll() }
            .store(in: &cancellables)
    }

    // MARK: - Session lifecycle

    func start(recipe: Recipe, preFlight: PreFlightData) -> SessionViewModel {
        let vm = SessionViewModel(recipe: recipe, preFlight: preFlight)
        vm.persistenceHook = { [weak self] in self?.saveAll() }
        // A session starts running from the moment it is created. The user
        // pauses manually with the Pause button if they need to stop the
        // clock; nothing else (mode, navigation, app close) should pause it.
        vm.start()
        sessions.append(vm)
        saveAll()
        return vm
    }

    func end(_ vm: SessionViewModel) {
        sessions.removeAll { $0 === vm }
        saveAll()
    }

    // MARK: - Persistence

    func saveAll() {
        let snapshots = sessions.map { $0.snapshot() }
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        do {
            try data.write(to: Self.snapshotsURL, options: .atomic)
        } catch {
            // Fallback: UserDefaults (smaller payloads only)
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func restoreAll() {
        var data: Data?
        if let fileData = try? Data(contentsOf: Self.snapshotsURL) {
            data = fileData
        } else if let udData = UserDefaults.standard.data(forKey: saveKey) {
            data = udData
        }
        guard let data,
              let snapshots = try? JSONDecoder().decode([SessionSnapshot].self, from: data)
        else { return }
        sessions = snapshots.map { SessionViewModel(restoringFrom: $0) }
        for vm in sessions {
            vm.persistenceHook = { [weak self] in self?.saveAll() }
        }
    }

    private static var snapshotsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("impasto_sessions.json")
    }
}
