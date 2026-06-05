import UIKit

/// NSCache-backed UIImage cache keyed by photo UUID. Avoids the
/// "decode UIImage(data:) on every SwiftUI body re-evaluation" storm
/// that hits photo galleries / viewers / share editor when state
/// changes nearby.
///
/// NSCache evicts under memory pressure automatically — no manual
/// lifecycle management needed.
///
/// Used together with PhotoStore: `image(for: id)` consults the
/// cache, falls back to PhotoStore.load if missing, decodes, caches,
/// and returns the UIImage.
final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSUUID, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024   // 50 MB ceiling
    }

    /// Get the UIImage for a photo UUID. Resolves from cache first,
    /// then falls back to PhotoStore.load + decode. nil if the file
    /// is missing or the data isn't a valid image.
    func image(for id: UUID) -> UIImage? {
        let key = id as NSUUID
        if let cached = cache.object(forKey: key) { return cached }
        guard let data = PhotoStore.shared.load(id),
              let img  = UIImage(data: data) else { return nil }
        cache.setObject(img, forKey: key, cost: data.count)
        return img
    }

    /// Convenience for legacy code paths that still hold raw Data
    /// (un-migrated entries). Uses a per-Data identity not a UUID;
    /// not cached — direct decode every time.
    func image(from data: Data) -> UIImage? {
        UIImage(data: data)
    }

    /// Drop a specific cached image. Call when the underlying file
    /// changes or is deleted.
    func invalidate(_ id: UUID) {
        cache.removeObject(forKey: id as NSUUID)
    }

    /// Nuke everything. Useful for tests or memory-warning handlers.
    func purge() {
        cache.removeAllObjects()
    }
}
