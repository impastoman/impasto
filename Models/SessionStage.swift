import Foundation

enum SessionStage: Int, CaseIterable {
    case biga
    case finalDough
    case bulkFermentation
    case ballProof
    case bake

    var title: String {
        switch self {
        case .biga:             return "Preferment"
        case .finalDough:       return "Final Dough"
        case .bulkFermentation: return "Bulk Fermentation"
        case .ballProof:        return "Final Proof"
        case .bake:             return "Bake"
        }
    }

    var defaultDuration: TimeInterval {
        switch self {
        case .biga:             return 18 * 3600
        case .finalDough:       return 30 * 60
        case .bulkFermentation: return 4 * 3600
        case .ballProof:        return 30 * 60
        case .bake:             return 0
        }
    }
}
