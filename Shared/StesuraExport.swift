import Foundation

/// Versioned envelope for sharing Stesura content between users.
///
/// Every export is wrapped in a small header so the receiving app can
/// (1) confirm the file actually came from Stesura, (2) know what TYPE
/// of content it holds, and (3) migrate older payloads as the schema
/// evolves. The `data` payload is always treated as inert — decoded
/// into a known model, never executed.
///
/// Shape on disk:
/// {
///   "stesura_version": "1.0",
///   "schema": "recipe_v1",
///   "exported_at": "2026-06-05T18:30:00Z",
///   "data": { ... }
/// }
enum StesuraExport {
    /// Bump when the envelope format itself changes (not the payload).
    static let formatVersion = "1.0"

    /// Type discriminator for the payload. Each content type round-trips
    /// only as itself — a flourBlend file never imports as a recipe.
    enum Schema: String {
        case recipe     = "recipe_v1"
        case flourBlend = "flourBlend_v1"
        case process    = "process_v1"
        case preferment = "preferment_v1"
    }

    /// Generic envelope. `T` is the concrete payload model.
    struct Envelope<T: Codable>: Codable {
        var stesura_version: String
        var schema: String
        var exported_at: String
        var data: T
    }

    /// Lightweight header decoded first, before we commit to a payload
    /// type, so we can validate version + route on schema.
    private struct Header: Codable {
        var stesura_version: String
        var schema: String
    }

    enum ImportError: LocalizedError {
        case notStesuraFile
        case unsupportedSchema(String)
        case unsupportedVersion(String)
        case corrupt

        var errorDescription: String? {
            switch self {
            case .notStesuraFile:
                return "This file isn't a Stesura export."
            case .unsupportedSchema(let s):
                return "This Stesura file is a \(s.replacingOccurrences(of: "_v1", with: "")) — not a recipe."
            case .unsupportedVersion(let v):
                return "This file was made with a newer version of Stesura (\(v)). Update the app to import it."
            case .corrupt:
                return "Couldn't read this file — it may be damaged or incomplete."
            }
        }
    }

    // MARK: - Encode

    /// Wraps a payload in the versioned envelope and returns pretty JSON.
    static func encode<T: Codable>(_ payload: T, schema: Schema, at date: Date = Date()) -> Data? {
        let env = Envelope(
            stesura_version: formatVersion,
            schema: schema.rawValue,
            exported_at: iso8601.string(from: date),
            data: payload
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(env)
    }

    /// Writes an encoded payload to a temp .stesura.json file and returns
    /// its URL, suitable for ShareLink / the share sheet. `baseName` is
    /// sanitized for the filename.
    static func tempFileURL(for data: Data, baseName: String) -> URL? {
        let safe = baseName
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
        let name = (safe.isEmpty ? "Stesura Recipe" : safe) + ".stesura.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Decode

    /// Validates the envelope and decodes a recipe payload. Falls back to
    /// decoding a bare Recipe (no envelope) so files exported by older
    /// builds of Stesura still import.
    static func decodeRecipe(from data: Data) throws -> Recipe {
        // No header? Could be a legacy bare-recipe export — try that.
        guard let header = try? JSONDecoder().decode(Header.self, from: data) else {
            if let bare = try? JSONDecoder().decode(Recipe.self, from: data) { return bare }
            throw ImportError.notStesuraFile
        }
        guard header.schema == Schema.recipe.rawValue else {
            throw ImportError.unsupportedSchema(header.schema)
        }
        guard isVersionSupported(header.stesura_version) else {
            throw ImportError.unsupportedVersion(header.stesura_version)
        }
        guard let env = try? JSONDecoder().decode(Envelope<Recipe>.self, from: data) else {
            throw ImportError.corrupt
        }
        return env.data
    }

    // MARK: - Helpers

    /// We accept any 1.x payload. A 2.x file is refused with a clear
    /// "update the app" message rather than decoded blindly.
    private static func isVersionSupported(_ version: String) -> Bool {
        version.split(separator: ".").first == "1"
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
