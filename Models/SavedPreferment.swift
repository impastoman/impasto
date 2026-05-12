import Foundation

struct SavedPreferment: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var method: PrefermentMethod
    var hydration: Double
    var notes: String = ""
    var createdAt: Date = Date()

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
