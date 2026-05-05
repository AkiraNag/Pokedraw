import Foundation
import UIKit
import Observation

@Observable
final class DrawingStore {
    var entries: [String: DrawingEntry] = [:]
    var shinyEntries: [String: DrawingEntry] = [:]

    var pendingDraw: PendingDraw? = nil

    private let storageURL: URL
    private let shinyStorageURL: URL
    private let pendingURL: URL
    private let imagesDir: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageURL    = docs.appendingPathComponent("drawings.json")
        shinyStorageURL = docs.appendingPathComponent("drawings_shiny.json")
        pendingURL    = docs.appendingPathComponent("pending_draw.json")
        imagesDir     = docs.appendingPathComponent("drawings_images")
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Queries

    func hasImage(pokemonId: String, isShiny: Bool) -> Bool {
        let dict = isShiny ? shinyEntries : entries
        return dict[pokemonId]?.hasImage == true
    }

    func image(for pokemonId: String, isShiny: Bool) -> UIImage? {
        guard hasImage(pokemonId: pokemonId, isShiny: isShiny) else { return nil }
        guard let data = try? Data(contentsOf: imageURL(for: pokemonId, isShiny: isShiny)) else { return nil }
        return UIImage(data: data)
    }

    // Counts only entries WITH a photo
    var completedNormalCount: Int { entries.values.filter { $0.hasImage }.count }
    var completedShinyCount:  Int { shinyEntries.values.filter { $0.hasImage }.count }

    // MARK: - Mutations

    func save(pokemonId: String, isShiny: Bool, imageData: Data?) {
        let entry = DrawingEntry(pokemonId: pokemonId, isShiny: isShiny,
                                 hasImage: imageData != nil, dateDrawn: Date())
        if isShiny { shinyEntries[pokemonId] = entry }
        else        { entries[pokemonId]      = entry }
        if let data = imageData {
            try? data.write(to: imageURL(for: pokemonId, isShiny: isShiny))
        }
        persist()
    }

    func savePending(_ draw: PendingDraw) {
        pendingDraw = draw
        if let d = try? JSONEncoder().encode(draw) { try? d.write(to: pendingURL) }
    }

    func clearPending() {
        pendingDraw = nil
        try? FileManager.default.removeItem(at: pendingURL)
    }

    func deleteEntry(pokemonId: String, isShiny: Bool) {
        if isShiny { shinyEntries.removeValue(forKey: pokemonId) }
        else        { entries.removeValue(forKey: pokemonId) }
        try? FileManager.default.removeItem(at: imageURL(for: pokemonId, isShiny: isShiny))
        persist()
    }

    // MARK: - Private

    private func imageURL(for pokemonId: String, isShiny: Bool) -> URL {
        imagesDir.appendingPathComponent(isShiny ? "\(pokemonId)_shiny.jpg" : "\(pokemonId).jpg")
    }

    private func load() {
        if let data = try? Data(contentsOf: storageURL),
           let dec  = try? JSONDecoder().decode([String: DrawingEntry].self, from: data) {
            entries = dec
        }
        if let data = try? Data(contentsOf: shinyStorageURL),
           let dec  = try? JSONDecoder().decode([String: DrawingEntry].self, from: data) {
            shinyEntries = dec
        }
        if let data = try? Data(contentsOf: pendingURL),
           let dec  = try? JSONDecoder().decode(PendingDraw.self, from: data) {
            pendingDraw = dec
        }
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(entries)       { try? d.write(to: storageURL) }
        if let d = try? JSONEncoder().encode(shinyEntries)  { try? d.write(to: shinyStorageURL) }
    }
}
