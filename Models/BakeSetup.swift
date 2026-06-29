import Foundation

enum BakeMethod: String, Codable, CaseIterable {
    case homeOven      = "Home Oven"
    case pizzaOven     = "Dedicated Pizza Oven"   // rawValue kept for Codable compatibility
    case portableOven  = "Portable Pizza Oven"    // rawValue kept for Codable compatibility
    case grill         = "Grill"
    case other         = "Other"

    var displayName: String {
        switch self {
        case .pizzaOven:    return "Dedicated Oven"
        case .portableOven: return "Portable Oven"
        default:            return rawValue
        }
    }

    var subMethods: [String] {
        switch self {
        case .homeOven:     return ["Baking Steel", "Baking Stone", "Baking Pan", "Cast Iron", "Dutch Oven", "Broiler Method"]
        case .pizzaOven:    return ["Wood-Fired", "Gas-Fired", "Electric", "Multi-Fuel"]
        case .portableOven: return []
        case .grill:        return ["Gas", "Charcoal"]
        case .other:        return []
        }
    }

    var hasSurfaceTemp: Bool {
        switch self {
        case .homeOven:  return true
        case .pizzaOven: return true
        case .portableOven: return true
        default: return false
        }
    }

    var icon: String {
        switch self {
        case .homeOven:     return "oven"
        case .pizzaOven:    return "flame"
        case .portableOven: return "flame.fill"
        case .grill:        return "smoke"
        case .other:        return "questionmark.circle"
        }
    }
}

struct BakeSetup: Identifiable, Codable {
    var id: UUID = UUID()
    var method: BakeMethod = .homeOven
    var subMethod: String = ""
    var ovenTempMin: Double = 260
    var ovenTempMax: Double = 290
    var surfaceTemp: Double? = nil
    var preheatMinutes: Int = 45
    var useCelsius: Bool = false
    var notes: String = ""

    var tempUnit: String { useCelsius ? "°C" : "°F" }

    var ovenTempDisplay: String {
        "\(Int(ovenTempMin))–\(Int(ovenTempMax))\(tempUnit)"
    }
}
