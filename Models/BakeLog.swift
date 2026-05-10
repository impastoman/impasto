import Foundation

struct BakeLog: Identifiable, Codable {
    var id: UUID = UUID()
    var recipeId: UUID
    var date: Date = Date()
    var rating: Int = 0
    var crustTags: [CrustTag] = []
    var crumbTags: [CrumbTag] = []
    var notes: String = ""
    var ballCount: Int
    var ballWeight: Double
    var finalHydration: Double
    var plannedStageDurations: [String: TimeInterval] = [:]
    var actualStageDurations: [String: TimeInterval] = [:]
    var roomTempC: Double = 20
    var prefermentPH: String = ""
}

enum CrustTag: String, Codable, CaseIterable {
    case crispy   = "Crispy"
    case evenChar = "Even char"
    case pale     = "Pale"
}

enum CrumbTag: String, Codable, CaseIterable {
    case open  = "Open"
    case airy  = "Airy"
    case dense = "Dense"
}
