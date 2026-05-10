import Foundation

struct Recipe: Identifiable, Codable {
    var id: UUID
    var name: String
    var style: PizzaStyle
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
        timeline: Timeline = .overnight,
        ballCount: Int = 6,
        ballWeight: Double = 250
    ) {
        self.id = UUID()
        self.name = name
        self.style = style
        self.timeline = timeline
        self.ballCount = ballCount
        self.ballWeight = ballWeight
        self.bigaHydration = 0.50
        self.finalHydration = style.defaultFinalHydration
        self.bigaRatio = style.defaultBigaRatio
        self.saltPct = 0.03
        self.yeastPct = 0.001
        self.notes = ""
        self.bakeLogs = []
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
    case tonight      = "Tonight"
    case overnight    = "Overnight"
    case twoDays      = "Two Days"
    case longColdProof = "Long Cold Proof"

    var hours: String {
        switch self {
        case .tonight:       return "6–8h"
        case .overnight:     return "16–24h"
        case .twoDays:       return "48h"
        case .longColdProof: return "48–72h"
        }
    }
}
