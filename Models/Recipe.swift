import Foundation

struct Recipe: Identifiable, Codable {
    var id: UUID
    var name: String
    var style: PizzaStyle
    var method: PrefermentMethod
    var mixerType: MixerType
    var autolyse: Bool
    var timeline: Timeline
    var bigaHydration: Double
    var finalHydration: Double
    var bigaRatio: Double
    var saltPct: Double
    var yeastPct: Double
    var ballCount: Int
    var ballWeight: Double
    var notes: String
    var bakeLogs: [BakeLog]

    init(
        name: String,
        style: PizzaStyle = .neapolitan,
        method: PrefermentMethod = .biga,
        mixerType: MixerType = .hand,
        autolyse: Bool = false,
        timeline: Timeline = .overnight,
        ballCount: Int = 6,
        ballWeight: Double = 250
    ) {
        self.id = UUID()
        self.name = name
        self.style = style
        self.method = method
        self.mixerType = mixerType
        self.autolyse = autolyse
        self.timeline = timeline
        self.ballCount = ballCount
        self.ballWeight = ballWeight
        self.bigaHydration = method == .poolish ? 1.0 : 0.50
        self.finalHydration = style.defaultFinalHydration
        self.bigaRatio = method == .direct ? 0 : style.defaultBigaRatio
        self.saltPct = 0.03
        self.yeastPct = 0.001
        self.notes = ""
        self.bakeLogs = []
    }

    // Handles decoding older saved recipes that lack new fields
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self, forKey: .id)
        name          = try c.decode(String.self, forKey: .name)
        style         = try c.decode(PizzaStyle.self, forKey: .style)
        method        = (try? c.decode(PrefermentMethod.self, forKey: .method)) ?? .biga
        mixerType     = (try? c.decode(MixerType.self, forKey: .mixerType)) ?? .hand
        autolyse      = (try? c.decode(Bool.self, forKey: .autolyse)) ?? false
        timeline      = try c.decode(Timeline.self, forKey: .timeline)
        bigaHydration = try c.decode(Double.self, forKey: .bigaHydration)
        finalHydration = try c.decode(Double.self, forKey: .finalHydration)
        bigaRatio     = try c.decode(Double.self, forKey: .bigaRatio)
        saltPct       = try c.decode(Double.self, forKey: .saltPct)
        yeastPct      = try c.decode(Double.self, forKey: .yeastPct)
        ballCount     = try c.decode(Int.self, forKey: .ballCount)
        ballWeight    = try c.decode(Double.self, forKey: .ballWeight)
        notes         = try c.decode(String.self, forKey: .notes)
        bakeLogs      = (try? c.decode([BakeLog].self, forKey: .bakeLogs)) ?? []
    }

    var totalDoughWeight: Double  { Double(ballCount) * ballWeight }
    var totalFlour: Double        { totalDoughWeight / (1 + finalHydration + saltPct) }
    var totalWater: Double        { totalFlour * finalHydration }
    var totalSalt: Double         { totalFlour * saltPct }
    var bigaFlour: Double         { totalFlour * bigaRatio }
    var bigaWater: Double         { bigaFlour * bigaHydration }
    var bigaYeast: Double         { bigaFlour * yeastPct }
    var additionalFlour: Double   { totalFlour - bigaFlour }
    var additionalWater: Double   { totalWater - bigaWater }

    var estimatedKneadingMinutes: Int {
        switch mixerType {
        case .hand:        return finalHydration > 0.70 ? 15 : 10
        case .standMixer:  return finalHydration > 0.70 ? 10 : 8
        case .spiral:      return finalHydration > 0.70 ? 6 : 5
        case .other:       return 10
        }
    }

    var autolyseMinutes: Int {
        autolyse ? (style == .neapolitan ? 20 : 30) : 0
    }
}

enum PrefermentMethod: String, Codable, CaseIterable {
    case biga    = "Biga"
    case poolish = "Poolish"
    case direct  = "Direct"

    var description: String {
        switch self {
        case .biga:    return "Stiff pre-ferment · 45–50% hydration"
        case .poolish: return "Liquid pre-ferment · 100% hydration"
        case .direct:  return "No pre-ferment · all flour at once"
        }
    }

    var flavorNote: String {
        switch self {
        case .biga:    return "More acidity, chew, and complexity"
        case .poolish: return "Mild sourness, open crumb, easier to work"
        case .direct:  return "Neutral flavor, fastest path to the oven"
        }
    }

    var minimumHours: Double {
        switch self {
        case .biga:    return 16
        case .poolish: return 8
        case .direct:  return 0
        }
    }
}

enum MixerType: String, Codable, CaseIterable {
    case hand        = "Hand mix"
    case standMixer  = "Stand mixer"
    case spiral      = "Spiral mixer"
    case other       = "Other"

    var note: String {
        switch self {
        case .hand:       return "Slap & fold works well above 68%"
        case .standMixer: return "Dough hook, medium speed"
        case .spiral:     return "Bowl rotates, fastest gluten development"
        case .other:      return ""
        }
    }
}

enum PizzaStyle: String, Codable, CaseIterable {
    case neapolitan = "Neapolitan"
    case newYork    = "New York"
    case detroit    = "Detroit"
    case sicilian   = "Sicilian"

    var description: String {
        switch self {
        case .neapolitan: return "High heat · charred · airy"
        case .newYork:    return "Foldable · chew · crisp edge"
        case .detroit:    return "Thick · caramelised crust"
        case .sicilian:   return "Square · light · focaccia-like"
        }
    }

    var defaultFinalHydration: Double {
        switch self {
        case .neapolitan: return 0.66
        case .newYork:    return 0.62
        case .detroit:    return 0.72
        case .sicilian:   return 0.70
        }
    }

    var defaultBigaRatio: Double {
        switch self {
        case .neapolitan: return 0.33
        case .newYork:    return 0.30
        case .detroit:    return 0.40
        case .sicilian:   return 0.35
        }
    }
}

enum Timeline: String, Codable, CaseIterable {
    case tonight       = "Tonight"
    case overnight     = "Overnight"
    case twoDays       = "Two Days"
    case longColdProof = "Long Cold Proof"

    var hours: String {
        switch self {
        case .tonight:       return "6–8h"
        case .overnight:     return "16–24h"
        case .twoDays:       return "48h"
        case .longColdProof: return "48–72h"
        }
    }

    var minimumHours: Double {
        switch self {
        case .tonight:       return 6
        case .overnight:     return 16
        case .twoDays:       return 48
        case .longColdProof: return 48
        }
    }

    func targetDate(from now: Date = Date()) -> Date {
        switch self {
        case .tonight:
            var c = Calendar.current.dateComponents([.year, .month, .day], from: now)
            c.hour = 23; c.minute = 0
            return Calendar.current.date(from: c) ?? now.addingTimeInterval(7 * 3600)
        case .overnight:     return now.addingTimeInterval(20 * 3600)
        case .twoDays:       return now.addingTimeInterval(48 * 3600)
        case .longColdProof: return now.addingTimeInterval(60 * 3600)
        }
    }

    func warning(for method: PrefermentMethod, from now: Date = Date()) -> String? {
        guard method.minimumHours > 0 else { return nil }
        let available = targetDate(from: now).timeIntervalSince(now) / 3600
        guard available < method.minimumHours else { return nil }
        return "\(method.rawValue) needs at least \(Int(method.minimumHours))h — only \(Int(available))h available"
    }
}
