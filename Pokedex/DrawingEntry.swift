import Foundation

struct DrawingEntry: Codable {
    var pokemonId: String  // "1", "3.1", "6.2"
    var isShiny: Bool
    var hasImage: Bool
    var dateDrawn: Date
}

struct PendingDraw: Codable {
    var pokemonId: String
    var isShiny: Bool
}
