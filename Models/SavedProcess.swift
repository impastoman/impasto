import Foundation

struct SavedProcess: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var cards: [ProcessCard]
    var createdAt: Date = Date()
    var folderName: String = ""
}
