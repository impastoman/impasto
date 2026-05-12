import Foundation

struct Recipe: Identifiable, Codable {
    var id: UUID
    var name: String
    var style: PizzaStyle
    var method: PrefermentMethod
    var prefermentHydration: Double
    var mixerType: MixerType
    var autolyse: Bool
    var bassinage: Bool
    var bassinageReservePct: Double
    var timeline: Timeline
    var bigaHydration: Double
    var finalHydration: Double
    var bigaRatio: Double
    var saltPct: Double
    var yeastPct: Double
    var ballCount: Int
    var ballWeight: Double
    var buffer: Double
    var flourBlend: FlourBlend
    var prefermentFlourBlend: FlourBlend
    var processCards: [ProcessCard]
    var bakeSetups: [BakeSetup]
    var yeastType: YeastType
    var customMixerName: String
    var mixingNotes: String
    var customStyleName: String
    var notes: String
    var bakeLogs: [BakeLog]

    init(
        name: String,
        style: PizzaStyle = .neapolitan,
        method: PrefermentMethod = .biga,
        mixerType: MixerType = .hand,
        autolyse: Bool = false,
        bassinage: Bool = false,
        timeline: Timeline = .overnight,
        ballCount: Int = 6,
        ballWeight: Double = 250,
        buffer: Double = 0.02
    ) {
        self.id = UUID()
        self.name = name
        self.style = style
        self.method = method
        self.mixerType = mixerType
        self.autolyse = autolyse
        self.bassinage = bassinage
        self.bassinageReservePct = 0.10
        self.timeline = timeline
        self.ballCount = ballCount
        self.ballWeight = ballWeight
        self.buffer = buffer
        self.prefermentHydration = method == .poolish ? 1.0 : 0.50
        self.bigaHydration = method == .poolish ? 1.0 : 0.50
        self.finalHydration = style.defaultFinalHydration
        self.bigaRatio = method == .direct ? 0 : style.defaultBigaRatio
        self.saltPct = 0.03
        self.yeastPct = 0.001
        self.yeastType = .instantDry
        self.customMixerName = ""
        self.mixingNotes = ""
        self.customStyleName = ""
        self.notes = ""
        self.bakeLogs = []
        self.flourBlend = FlourBlend()
        self.prefermentFlourBlend = FlourBlend()
        self.bakeSetups = []
        self.processCards = ProcessCard.defaultCards(autolyse: autolyse, bassinage: bassinage)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                  = try c.decode(UUID.self, forKey: .id)
        name                = try c.decode(String.self, forKey: .name)
        style               = try c.decode(PizzaStyle.self, forKey: .style)
        method              = (try? c.decode(PrefermentMethod.self, forKey: .method)) ?? .biga
        mixerType           = (try? c.decode(MixerType.self, forKey: .mixerType)) ?? .hand
        autolyse            = (try? c.decode(Bool.self, forKey: .autolyse)) ?? false
        bassinage           = (try? c.decode(Bool.self, forKey: .bassinage)) ?? false
        bassinageReservePct = (try? c.decode(Double.self, forKey: .bassinageReservePct)) ?? 0.10
        timeline            = try c.decode(Timeline.self, forKey: .timeline)
        bigaHydration       = try c.decode(Double.self, forKey: .bigaHydration)
        prefermentHydration = (try? c.decode(Double.self, forKey: .prefermentHydration)) ?? bigaHydration
        finalHydration      = try c.decode(Double.self, forKey: .finalHydration)
        bigaRatio           = try c.decode(Double.self, forKey: .bigaRatio)
        saltPct             = try c.decode(Double.self, forKey: .saltPct)
        yeastPct            = try c.decode(Double.self, forKey: .yeastPct)
        ballCount           = try c.decode(Int.self, forKey: .ballCount)
        ballWeight          = try c.decode(Double.self, forKey: .ballWeight)
        buffer              = (try? c.decode(Double.self, forKey: .buffer)) ?? 0.02
        yeastType           = (try? c.decode(YeastType.self, forKey: .yeastType)) ?? .instantDry
        customMixerName     = (try? c.decode(String.self, forKey: .customMixerName)) ?? ""
        mixingNotes         = (try? c.decode(String.self, forKey: .mixingNotes)) ?? ""
        customStyleName     = (try? c.decode(String.self, forKey: .customStyleName)) ?? ""
        notes               = try c.decode(String.self, forKey: .notes)
        bakeLogs            = (try? c.decode([BakeLog].self, forKey: .bakeLogs)) ?? []
        flourBlend          = (try? c.decode(FlourBlend.self, forKey: .flourBlend)) ?? FlourBlend()
        prefermentFlourBlend = (try? c.decode(FlourBlend.self, forKey: .prefermentFlourBlend)) ?? FlourBlend()
        bakeSetups          = (try? c.decode([BakeSetup].self, forKey: .bakeSetups)) ?? []
        let savedCards      = try? c.decode([ProcessCard].self, forKey: .processCards)
        processCards        = savedCards ?? ProcessCard.defaultCards(autolyse: autolyse, bassinage: bassinage)
    }

    // Total dough weight including buffer
    var totalDoughWeight: Double  { Double(ballCount) * ballWeight * (1 + buffer) }
    var totalFlour: Double        { totalDoughWeight / (1 + finalHydration + saltPct) }
    var totalWater: Double        { totalFlour * finalHydration }
    var totalSalt: Double         { totalFlour * saltPct }
    var bigaFlour: Double         { totalFlour * bigaRatio }
    var bigaWater: Double         { bigaFlour * bigaHydration }
    var bigaYeast: Double         { bigaFlour * yeastPct }
    var additionalFlour: Double   { totalFlour - bigaFlour }
    var additionalWater: Double   { totalWater - bigaWater }
    var bassinageReserveGrams: Double { totalWater * bassinageReservePct }

    var bigaPercentage: Double {
        get { bigaRatio }
        set { bigaRatio = newValue }
    }

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

enum YeastType: String, Codable, CaseIterable {
    case instantDry = "Instant dry"
    case activeDry  = "Active dry"
    case fresh      = "Fresh"
    case other      = "Other"

    var typicalRange: String {
        switch self {
        case .instantDry: return "0.05–0.5% of flour · less for cold ferment"
        case .activeDry:  return "0.1–0.6% of flour · proof in warm water first"
        case .fresh:      return "0.15–1.5% of flour · ~3× the instant dry amount"
        case .other:      return "refer to your yeast's packaging"
        }
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
        case .standMixer: return "Generally set to the lowest possible speed"
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
    case custom     = "Custom"

    var description: String {
        switch self {
        case .neapolitan: return "High heat · charred · airy"
        case .newYork:    return "Foldable · chew · crisp edge"
        case .detroit:    return "Thick · caramelised crust"
        case .sicilian:   return "Square · light · focaccia-like"
        case .custom:     return "Your rules · your ratios"
        }
    }

    var defaultFinalHydration: Double {
        switch self {
        case .neapolitan: return 0.66
        case .newYork:    return 0.62
        case .detroit:    return 0.72
        case .sicilian:   return 0.70
        case .custom:     return 0.65
        }
    }

    var defaultBigaRatio: Double {
        switch self {
        case .neapolitan: return 0.33
        case .newYork:    return 0.30
        case .detroit:    return 0.40
        case .sicilian:   return 0.35
        case .custom:     return 0.30
        }
    }
}

enum Timeline: String, Codable, CaseIterable {
    case tonight       = "Less than a day"
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
        case .tonight:       return now.addingTimeInterval(8 * 3600)
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
