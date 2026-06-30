import Foundation

struct SavedPreferment: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var method: PrefermentMethod
    var hydration: Double
    var notes: String = ""
    var createdAt: Date = Date()
    var flourBlend: FlourBlend = FlourBlend()
    var ratioPercent: Double = 0.30
    var folderName: String = ""

    // Hydration accounting + sourdough starter maintenance (1.2)
    var countInHydration: Bool = true
    var isSourdough: Bool = false
    var feedInterval: Double = 0
    var feedUnit: String = "hours"
    var discardGrams: Double = 0
    var feedFlourGrams: Double = 0
    var feedWaterGrams: Double = 0

    var label: String {
        switch hydration {
        case ..<0.50:       return "Dry Biga"
        case 0.50..<0.51:   return "Biga"
        case 0.51..<0.61:   return "Wet Biga"
        case 0.61..<0.99:   return "High-Hydration Preferment"
        case 0.99..<1.01:   return "Poolish"
        default:            return "Wet Poolish"
        }
    }
}

extension SavedPreferment {
    /// Defensive decode: synthesized Codable does not fall back to default values
    /// for missing keys, so older saved preferments (written before these fields
    /// existed) would fail to decode. decodeIfPresent keeps the whole library
    /// loadable and defaults any field the stored JSON doesn't carry.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        name             = (try? c.decode(String.self, forKey: .name)) ?? ""
        method           = (try? c.decode(PrefermentMethod.self, forKey: .method)) ?? .biga
        hydration        = (try? c.decode(Double.self, forKey: .hydration)) ?? 0.50
        notes            = (try? c.decode(String.self, forKey: .notes)) ?? ""
        createdAt        = (try? c.decode(Date.self, forKey: .createdAt)) ?? Date()
        flourBlend       = (try? c.decode(FlourBlend.self, forKey: .flourBlend)) ?? FlourBlend()
        ratioPercent     = (try? c.decode(Double.self, forKey: .ratioPercent)) ?? 0.30
        folderName       = (try? c.decode(String.self, forKey: .folderName)) ?? ""
        countInHydration = (try? c.decode(Bool.self, forKey: .countInHydration)) ?? true
        isSourdough      = (try? c.decode(Bool.self, forKey: .isSourdough)) ?? false
        feedInterval     = (try? c.decode(Double.self, forKey: .feedInterval)) ?? 0
        feedUnit         = (try? c.decode(String.self, forKey: .feedUnit)) ?? "hours"
        discardGrams     = (try? c.decode(Double.self, forKey: .discardGrams)) ?? 0
        feedFlourGrams   = (try? c.decode(Double.self, forKey: .feedFlourGrams)) ?? 0
        feedWaterGrams   = (try? c.decode(Double.self, forKey: .feedWaterGrams)) ?? 0
    }
}
