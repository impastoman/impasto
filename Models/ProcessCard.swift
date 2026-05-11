import Foundation

enum AutolyseMode: String, Codable, CaseIterable {
    case standard     = "Autolyse"
    case fermentolyse = "Fermentolyse"
    case saltolyse    = "Saltolyse"

    var description: String {
        switch self {
        case .standard:     return "Flour + water only. No salt, no yeast."
        case .fermentolyse: return "Flour + water + preferment. Fermentation starts immediately."
        case .saltolyse:    return "Flour + water + salt. Slower enzymes, can go overnight cold."
        }
    }
}

enum ProcessCardType: String, Codable, CaseIterable {
    case autolyse
    case incorporateYeast
    case incorporateSalt
    case bassinage
    case kneading
    case bulkFermentation
    case dividing
    case preShape
    case benchRest
    case finalProof
    case bake

    var title: String {
        switch self {
        case .autolyse:          return "Autolyse"
        case .incorporateYeast:  return "Add yeast"
        case .incorporateSalt:   return "Add salt"
        case .bassinage:         return "Bassinage"
        case .kneading:          return "Kneading"
        case .bulkFermentation:  return "Bulk fermentation"
        case .dividing:          return "Divide & pre-shape"
        case .preShape:          return "Pre-shape"
        case .benchRest:         return "Bench rest"
        case .finalProof:        return "Final proof"
        case .bake:              return "Bake"
        }
    }

    var subtitle: String {
        switch self {
        case .autolyse:          return "enzymatic hydration"
        case .incorporateYeast:  return "or add preferment"
        case .incorporateSalt:   return "dissolved in reserved water"
        case .bassinage:         return "gradual water addition"
        case .kneading:          return "gluten development"
        case .bulkFermentation:  return "with stretch & fold intervals"
        case .dividing:          return "scale and portion"
        case .preShape:          return "rough ball, surface tension"
        case .benchRest:         return "gluten relaxation"
        case .finalProof:        return "ball proof"
        case .bake:              return "oven"
        }
    }

    var defaultDuration: TimeInterval {
        switch self {
        case .autolyse:          return 30 * 60
        case .incorporateYeast:  return 0
        case .incorporateSalt:   return 0
        case .bassinage:         return 0
        case .kneading:          return 12 * 60
        case .bulkFermentation:  return 4 * 3600
        case .dividing:          return 0
        case .preShape:          return 0
        case .benchRest:         return 20 * 60
        case .finalProof:        return 30 * 60
        case .bake:              return 0
        }
    }

    var isTimed: Bool {
        defaultDuration > 0 || self == .bake
    }

    var isActionOnly: Bool {
        switch self {
        case .incorporateYeast, .incorporateSalt, .bassinage, .dividing, .preShape:
            return true
        default:
            return false
        }
    }

    var warningIfPlacedAfter: [ProcessCardType] {
        switch self {
        case .benchRest:  return [.autolyse, .incorporateYeast, .incorporateSalt, .kneading]
        case .finalProof: return [.autolyse, .kneading, .bulkFermentation]
        case .bake:       return [.autolyse, .kneading, .bulkFermentation, .finalProof]
        default:          return []
        }
    }
}

struct ProcessCard: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ProcessCardType
    var isEnabled: Bool = true
    var sortOrder: Int = 0
    var customDuration: TimeInterval? = nil
    var recipeNote: String = ""

    // Autolyse-specific
    var autolyseMode: AutolyseMode = .standard

    // Bassinage-specific
    var bassinageReservePct: Double = 0.10

    var title: String { type.title }
    var subtitle: String { type.subtitle }
    var duration: TimeInterval { customDuration ?? type.defaultDuration }

    static func defaultCards(autolyse: Bool, bassinage: Bool) -> [ProcessCard] {
        var cards: [ProcessCard] = []
        var order = 0

        if autolyse {
            cards.append(ProcessCard(type: .autolyse, sortOrder: order)); order += 1
        }
        cards.append(ProcessCard(type: .incorporateYeast, sortOrder: order)); order += 1
        cards.append(ProcessCard(type: .incorporateSalt, sortOrder: order)); order += 1
        if bassinage {
            cards.append(ProcessCard(type: .bassinage, sortOrder: order)); order += 1
        }
        cards.append(ProcessCard(type: .kneading, sortOrder: order)); order += 1
        cards.append(ProcessCard(type: .bulkFermentation, sortOrder: order)); order += 1
        cards.append(ProcessCard(type: .dividing, sortOrder: order)); order += 1
        cards.append(ProcessCard(type: .preShape, sortOrder: order)); order += 1
        cards.append(ProcessCard(type: .benchRest, sortOrder: order)); order += 1
        cards.append(ProcessCard(type: .finalProof, sortOrder: order)); order += 1
        cards.append(ProcessCard(type: .bake, sortOrder: order))
        return cards
    }
}
