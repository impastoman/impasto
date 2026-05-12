import Foundation

struct BakeLog: Identifiable, Codable {
    var id: UUID = UUID()
    var recipeId: UUID
    var date: Date = Date()
    var rating: Int = 0
    var crustTags: [CrustTag] = []
    var crumbTags: [CrumbTag] = []
    var customCrustTags: [String] = []
    var customCrumbTags: [String] = []
    var notes: String = ""
    var ballCount: Int
    var ballWeight: Double
    var finalHydration: Double
    var plannedStageDurations: [String: TimeInterval] = [:]
    var actualStageDurations: [String: TimeInterval] = [:]
    var pauseDurations: [TimeInterval] = []
    var roomTempC: Double = 20
    var prefermentPH: String = ""
    var sessionMode: SessionMode = .manual

    // Bake results
    var bakeTimeSeconds: TimeInterval = 0
    var ovenTempAchieved: Double? = nil
    var crustColor: CrustColor = .even
    var bottomResult: BottomResult = .good
    var topResult: TopResult = .good
    var photoData: Data? = nil
}

enum SessionMode: String, Codable {
    case automatic = "Automatic"
    case manual    = "Manual"
}

enum CrustColor: String, Codable, CaseIterable {
    case pale    = "Pale"
    case even    = "Even"
    case leopard = "Leopard"
    case charred = "Charred"
}

enum BottomResult: String, Codable, CaseIterable {
    case undercooked = "Undercooked"
    case good        = "Good"
    case crispy      = "Crispy"
}

enum TopResult: String, Codable, CaseIterable {
    case undercooked   = "Undercooked"
    case good          = "Good"
    case slightlyCharred = "Slightly Charred"
}

enum CrustTag: String, Codable, CaseIterable {
    case crispy   = "Crispy"
    case evenChar = "Even char"
    case pale     = "Pale"
    case chewy    = "Chewy"
    case crackly  = "Crackly"
}

enum CrumbTag: String, Codable, CaseIterable {
    case open    = "Open"
    case airy    = "Airy"
    case dense   = "Dense"
    case tender  = "Tender"
    case gummy   = "Gummy"
}
