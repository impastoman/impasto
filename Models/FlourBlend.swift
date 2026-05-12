import Foundation

enum FlourType: String, Codable, CaseIterable {
    case tipo00       = "00 (Tipo 00)"
    case tipo0        = "0 (Tipo 0)"
    case allPurpose   = "All-Purpose"
    case bread        = "Bread"
    case highGluten   = "High-Gluten"
    case wholeWheat   = "Whole Wheat"
    case semolina     = "Semolina"
    case durum        = "Durum"
    case lightRye     = "Light Rye"
    case darkRye      = "Dark Rye"
    case spelt        = "Spelt"
    case einkorn      = "Einkorn"
    case kamut        = "Kamut"
    case other        = "Other"

    var typicalGlutenRange: String {
        switch self {
        case .tipo00:      return "9–12%"
        case .tipo0:       return "11–12%"
        case .allPurpose:  return "10–12%"
        case .bread:       return "11.5–13.5%"
        case .highGluten:  return "13.5–15.5%"
        case .wholeWheat:  return "13–13.2%"
        case .semolina:    return "12–14%"
        case .durum:       return "12–14%"
        case .lightRye:    return "~8%"
        case .darkRye:     return "~8%"
        case .spelt:       return "14–15%"
        case .einkorn:     return "~14%"
        case .kamut:       return "~14%"
        case .other:       return ""
        }
    }

    var ryeWarning: Bool {
        self == .lightRye || self == .darkRye
    }
}

struct FlourComponent: Identifiable, Codable {
    var id: UUID = UUID()
    var type: FlourType = .bread
    var percentage: Double = 100
    var glutenPct: Double? = nil
    var brand: String = ""
}

enum AdditiveType: String, Codable, CaseIterable {
    case diastaticMalt    = "Diastatic Malt"
    case nonDiastaticMalt = "Non-Diastatic Malt"
    case vitalWheatGluten = "Vital Wheat Gluten"
    case ascorbicAcid     = "Ascorbic Acid"
    case oliveOil         = "Olive Oil"
    case milk             = "Milk"
    case butter           = "Butter"
    case sugar            = "Sugar"
    case honey            = "Honey"
    case other            = "Other"

    var typicalRange: String {
        switch self {
        case .diastaticMalt:    return "0.5–2%"
        case .nonDiastaticMalt: return "up to 2%"
        case .vitalWheatGluten: return "1–3%"
        case .ascorbicAcid:     return "0.01–0.05%"
        case .oliveOil:         return "1–5%"
        case .milk:             return "2–5%"
        case .butter:           return "1–4%"
        case .sugar:            return "~2%"
        case .honey:            return "2–6%"
        case .other:            return ""
        }
    }

    var isLiquid: Bool {
        switch self {
        case .oliveOil, .milk, .honey: return true
        default: return false
        }
    }
}

struct Additive: Identifiable, Codable {
    var id: UUID = UUID()
    var type: AdditiveType = .diastaticMalt
    var percentage: Double = 1.0
    var note: String = ""
}

struct FlourBlend: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String = ""
    var components: [FlourComponent] = [FlourComponent()]
    var additives: [Additive] = []

    var totalPercentage: Double {
        components.reduce(0) { $0 + $1.percentage }
    }

    var isValid: Bool { abs(totalPercentage - 100) < 0.01 }

    var containsRye: Bool {
        components.contains { $0.type.ryeWarning }
    }
}
