import Foundation

struct PrefermentRecipe: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var flourBlend: FlourBlend = FlourBlend()
    var hydration: Double = 0.50
    var fermentationTempC: Double = 20
    var fermentationHours: Double = 18
    var notes: String = ""
    var createdAt: Date = Date()

    var prefermentLabel: String {
        switch hydration {
        case ..<0.50:           return "Dry Biga"
        case 0.50..<0.51:       return "Biga"
        case 0.51..<0.61:       return "Wet Biga"
        case 0.61..<1.00:       return "High-Hydration Preferment"
        case 1.00..<1.01:       return "Poolish"
        default:                return "Wet Poolish"
        }
    }

    var prefermentNote: String {
        switch hydration {
        case ..<0.51:   return "Slower ferment · more acidity · tight crumb"
        case 0.51..<0.80: return "Balanced ferment · mild complexity"
        case 0.80..<1.01: return "Faster ferment · open crumb · mild sourness"
        default:          return "Very active · aromatic · easy to work"
        }
    }
}
