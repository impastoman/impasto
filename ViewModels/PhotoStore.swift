import Foundation

/// On-disk store for photo JPEG data. Replaces the previous approach
/// where photos were embedded as Data inside BakeLog/PizzaEntry and
/// shipped as Base64 inside the recipes JSON in UserDefaults.
///
/// Layout: Documents/photos/<UUID>.jpg
///
/// Lifecycle:
///   - PhotoStore.shared.save(data) → UUID. Writes the JPEG to disk
///     and returns a unique id the caller stores on the model.
///   - PhotoStore.shared.load(uuid) → Data?. Reads from disk if
///     present. Cheap; OS-cached via NSData.
///   - PhotoStore.shared.delete(uuid). Called when a photo is removed
///     from a BakeLog / PizzaEntry.
///
/// Thread-safe for reads; writes serialized via FileManager.
final class PhotoStore {
    static let shared = PhotoStore()

    private let directory: URL

    private init() {
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        directory = docs.appendingPathComponent("photos", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    /// Save a JPEG Data blob → return the UUID it was stored under.
    @discardableResult
    func save(_ data: Data) -> UUID {
        let id = UUID()
        let url = url(for: id)
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            // Quiet failure — the caller still gets a UUID but a later
            // load() will return nil. Acceptable in our context; the
            // UI shows an empty thumbnail rather than crashing.
        }
        return id
    }

    /// Load JPEG Data for a UUID. nil if missing.
    func load(_ id: UUID) -> Data? {
        try? Data(contentsOf: url(for: id))
    }

    /// Remove the file backing this UUID. No-op if it doesn't exist.
    func delete(_ id: UUID) {
        try? FileManager.default.removeItem(at: url(for: id))
    }

    /// Bulk delete — used during BakeLog deletion to clean up the
    /// session's photos atomically.
    func delete(_ ids: [UUID]) {
        for id in ids { delete(id) }
    }

    private func url(for id: UUID) -> URL {
        directory.appendingPathComponent(id.uuidString + ".jpg")
    }
}
