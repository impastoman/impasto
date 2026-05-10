import Foundation

enum SessionStage: Int, CaseIterable {
    case biga
    case finalDough
    case bulkProof
    case ballProof
    case bake

    var title: String {
        switch self {
        case .biga:       return "Biga"
        case .finalDough: return "Final Dough"
        case .bulkProof:  return "Bulk Proof"
        case .ballProof:  return "Ball Proof"
        case .bake:       return "Bake"
        }
    }

    var defaultDuration: TimeInterval {
        switch self {
        case .biga:       return 18 * 3600
        case .finalDough: return 30 * 60
        case .bulkProof:  return 4 * 3600
        case .ballProof:  return 30 * 60
        case .bake:       return 90
        }
    }
}
