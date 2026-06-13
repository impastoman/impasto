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

    /// Custom file extension. The app registers ownership of this in
    /// Info.plist (exported UTI + document type) so a tapped .stesura
    /// file opens directly in Stesura rather than being offered to every
    /// JSON-capable app. The payload inside is still JSON.
    static let fileExtension = "stesura"

    /// Custom URL scheme. Recipe shares are a stesura://import?d=<payload>
    /// link — tapping a LINK in Messages opens the app directly, whereas
    /// tapping a file attachment only previews it. Registered in
    /// Info.plist under CFBundleURLTypes.
    static let urlScheme = "stesura"
    static let importHost = "import"

    /// Universal Link host. Recipe shares are now https://<universalHost>/import?d=…
    /// links — these render as a clean tappable card in Messages AND open
    /// the app directly (a custom-scheme link shows the raw URL). Requires
    /// the Associated Domains entitlement (applinks:<universalHost>) and the
    /// AASA file hosted at https://<universalHost>/.well-known/apple-app-site-association.
    static let universalHost = "stesura.perfectlyfinewares.com"
    static let universalImportPath = "/import"

    /// Type discriminator for the payload. Each content type round-trips
    /// only as itself — a flourBlend file never imports as a recipe.
    enum Schema: String {
        case recipe     = "recipe_v1"
        case flourBlend = "flourBlend_v1"
        case process    = "process_v1"
        case preferment = "preferment_v1"
    }

    /// Generic envelope. `T` is the concrete payload model. `author` is
    /// optional transport metadata (the sender's display name) — it never
    /// touches the saved Recipe, only the import preview ("Shared by …").
    struct Envelope<T: Codable>: Codable {
        var stesura_version: String
        var schema: String
        var exported_at: String
        var author: String?
        var data: T
    }

    /// Lightweight header decoded first, before we commit to a payload
    /// type, so we can validate version + route on schema, and surface
    /// the optional author without decoding the whole payload.
    private struct Header: Codable {
        var stesura_version: String
        var schema: String
        var author: String?
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
    /// `author` (the sender's display name) is omitted when nil/blank.
    static func encode<T: Codable>(_ payload: T, schema: Schema, author: String? = nil, at date: Date = Date()) -> Data? {
        let cleanAuthor = author?.trimmingCharacters(in: .whitespacesAndNewlines)
        let env = Envelope(
            stesura_version: formatVersion,
            schema: schema.rawValue,
            exported_at: iso8601.string(from: date),
            author: (cleanAuthor?.isEmpty == false) ? cleanAuthor : nil,
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
        let name = (safe.isEmpty ? "Stesura Recipe" : safe) + ".\(fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    /// Builds a stesura://import?d=<payload> deep link for a recipe.
    /// The envelope JSON is zlib-compressed then base64url-encoded to
    /// keep the link as short as possible. Tapping this link in Messages
    /// (or anywhere) opens Stesura straight into the import preview.
    static func encodeRecipeLink(_ recipe: Recipe, author: String? = nil, at date: Date = Date()) -> URL? {
        var r = recipe
        r.bakeLogs = []
        guard let json = encode(r, schema: .recipe, author: author, at: date),
              let compressed = try? (json as NSData).compressed(using: .zlib) as Data
        else { return nil }
        var comps = URLComponents()
        comps.scheme = urlScheme
        comps.host = importHost
        comps.queryItems = [URLQueryItem(name: "d", value: base64URLEncode(compressed))]
        return comps.url
    }

    /// Builds the https Universal Link for a recipe:
    /// https://stesura.perfectlyfinewares.com/import?d=<payload>&n=<name>
    /// Same compressed payload as the custom-scheme link; `n` is the plain
    /// recipe name for the web fallback page's teaser (the app ignores it
    /// and reads the real data from `d`). This is the preferred share form.
    static func encodeRecipeUniversalLink(_ recipe: Recipe, author: String? = nil, at date: Date = Date()) -> URL? {
        var r = recipe
        r.bakeLogs = []
        guard let json = encode(r, schema: .recipe, author: author, at: date),
              let compressed = try? (json as NSData).compressed(using: .zlib) as Data
        else { return nil }
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = universalHost
        comps.path = universalImportPath
        var items = [URLQueryItem(name: "d", value: base64URLEncode(compressed))]
        let name = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { items.append(URLQueryItem(name: "n", value: name)) }
        comps.queryItems = items
        return comps.url
    }

    // MARK: - Decode

    /// Decodes a recipe from a stesura://import?d=… deep link. Reverses
    /// encodeRecipeLink: base64url-decode → zlib-inflate → envelope decode.
    static func decodeRecipe(fromLink url: URL) throws -> Recipe {
        guard let json = linkPayload(url) else { throw ImportError.corrupt }
        return try decodeRecipe(from: json)
    }

    /// Reads a recipe from a file URL (e.g. one opened via .onOpenURL
    /// from Files / AirDrop / Messages). Handles security-scoped access
    /// for files that live outside the app sandbox.
    static func decodeRecipe(fromFile url: URL) throws -> Recipe {
        guard let data = fileData(url) else { throw ImportError.corrupt }
        return try decodeRecipe(from: data)
    }

    // MARK: - Author (optional "Shared by …" metadata)

    /// Reads the sender's display name from an envelope, if present.
    /// nil for legacy/bare exports or when the sender left it blank.
    static func author(from data: Data) -> String? {
        let name = (try? JSONDecoder().decode(Header.self, from: data))?.author?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false) ? name : nil
    }

    static func author(fromLink url: URL) -> String? {
        guard let json = linkPayload(url) else { return nil }
        return author(from: json)
    }

    static func author(fromFile url: URL) -> String? {
        guard let data = fileData(url) else { return nil }
        return author(from: data)
    }

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

    /// True if a URL is a Stesura recipe link — either the custom scheme
    /// (stesura://import?d=…) or the https Universal Link
    /// (https://stesura.perfectlyfinewares.com/import?d=…).
    static func isRecipeLink(_ url: URL) -> Bool {
        if url.scheme == urlScheme { return true }
        if url.scheme == "https", url.host == universalHost,
           url.path.hasPrefix(universalImportPath) { return true }
        return false
    }

    /// Extracts and inflates the JSON payload from a recipe link (custom
    /// scheme or Universal Link). nil if the URL isn't a valid Stesura link.
    private static func linkPayload(_ url: URL) -> Data? {
        guard isRecipeLink(url),
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let encoded = comps.queryItems?.first(where: { $0.name == "d" })?.value,
              let compressed = base64URLDecode(encoded),
              let json = try? (compressed as NSData).decompressed(using: .zlib) as Data
        else { return nil }
        return json
    }

    /// Reads raw bytes from a file URL with security-scoped access.
    private static func fileData(_ url: URL) -> Data? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        return try? Data(contentsOf: url)
    }

    /// We accept any 1.x payload. A 2.x file is refused with a clear
    /// "update the app" message rather than decoded blindly.
    private static func isVersionSupported(_ version: String) -> Bool {
        version.split(separator: ".").first == "1"
    }

    /// URL-safe base64 (RFC 4648 §5): +/ → -_ and padding stripped, so
    /// the payload survives intact inside a URL query string.
    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }   // restore padding
        return Data(base64Encoded: s)
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
