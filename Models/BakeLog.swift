import Foundation

struct PizzaEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var pizzaNumber: Int
    var bakeTimeSeconds: TimeInterval
    var ovenTempAchieved: Double?
    var crustColor: CrustColor
    var bottomResult: BottomResult
    var topResult: TopResult
    var crustTags: [CrustTag] = []
    var crumbTags: [CrumbTag] = []
    var customCrustTags: [String] = []
    var customCrumbTags: [String] = []
    var notes: String = ""

    // — Photo storage —
    // photoIDs is the source of truth (each UUID resolves to a JPEG file
    // on disk via PhotoStore). photos / photoData are legacy fields kept
    // for backward-compat decoding; emptied during the v2 migration.
    var photoData: Data?            // legacy (pre-multi-photo)
    var photos: [Data] = []         // legacy (in-JSON multi-photo)
    var photoIDs: [UUID] = []       // new — references to PhotoStore files
    var loggedAt: Date = Date()

    /// Default memberwise init — Swift would synthesize this for free if
    /// we didn't have a custom init(from:), but writing the custom
    /// decoder removes the synthesized memberwise init, so we restore it
    /// explicitly here.
    init(id: UUID = UUID(),
         pizzaNumber: Int,
         bakeTimeSeconds: TimeInterval,
         ovenTempAchieved: Double? = nil,
         crustColor: CrustColor,
         bottomResult: BottomResult,
         topResult: TopResult,
         crustTags: [CrustTag] = [],
         crumbTags: [CrumbTag] = [],
         customCrustTags: [String] = [],
         customCrumbTags: [String] = [],
         notes: String = "",
         photoData: Data? = nil,
         photos: [Data] = [],
         photoIDs: [UUID] = [],
         loggedAt: Date = Date()) {
        self.id = id
        self.pizzaNumber = pizzaNumber
        self.bakeTimeSeconds = bakeTimeSeconds
        self.ovenTempAchieved = ovenTempAchieved
        self.crustColor = crustColor
        self.bottomResult = bottomResult
        self.topResult = topResult
        self.crustTags = crustTags
        self.crumbTags = crumbTags
        self.customCrustTags = customCrustTags
        self.customCrumbTags = customCrumbTags
        self.notes = notes
        self.photoData = photoData
        self.photos = photos
        self.photoIDs = photoIDs
        self.loggedAt = loggedAt
    }

    /// Custom decoder — every field with a default uses decodeIfPresent
    /// so old saved data (encoded before the photoIDs field existed)
    /// still decodes successfully.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        pizzaNumber      = try c.decode(Int.self, forKey: .pizzaNumber)
        bakeTimeSeconds  = try c.decode(TimeInterval.self, forKey: .bakeTimeSeconds)
        ovenTempAchieved = try c.decodeIfPresent(Double.self, forKey: .ovenTempAchieved)
        crustColor       = try c.decode(CrustColor.self, forKey: .crustColor)
        bottomResult     = try c.decode(BottomResult.self, forKey: .bottomResult)
        topResult        = try c.decode(TopResult.self, forKey: .topResult)
        crustTags        = (try? c.decode([CrustTag].self, forKey: .crustTags)) ?? []
        crumbTags        = (try? c.decode([CrumbTag].self, forKey: .crumbTags)) ?? []
        customCrustTags  = (try? c.decode([String].self, forKey: .customCrustTags)) ?? []
        customCrumbTags  = (try? c.decode([String].self, forKey: .customCrumbTags)) ?? []
        notes            = (try? c.decode(String.self, forKey: .notes)) ?? ""
        photoData        = try c.decodeIfPresent(Data.self, forKey: .photoData)
        photos           = (try? c.decode([Data].self, forKey: .photos)) ?? []
        photoIDs         = (try? c.decode([UUID].self, forKey: .photoIDs)) ?? []
        loggedAt         = (try? c.decode(Date.self, forKey: .loggedAt)) ?? Date()
    }

    /// Photos to render. Prefers photoIDs (resolved from disk),
    /// then the legacy in-JSON `photos`, then the very-legacy single
    /// `photoData`. Migration runs once and writes legacy data to
    /// PhotoStore, after which only photoIDs is populated.
    var displayPhotos: [Data] {
        if !photoIDs.isEmpty {
            return photoIDs.compactMap { PhotoStore.shared.load($0) }
        }
        if !photos.isEmpty { return photos }
        return [photoData].compactMap { $0 }
    }
}

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

    // — Photo storage —
    // photoIDs is the source of truth (each UUID → JPEG file on disk via
    // PhotoStore). photos / photoData are legacy fields kept for
    // backward-compat decoding; emptied during the v2 migration.
    var photoData: Data? = nil      // legacy (pre-multi-photo)
    var photos: [Data] = []         // legacy (in-JSON multi-photo)
    var photoIDs: [UUID] = []       // new — references to PhotoStore files
    var pizzaEntries: [PizzaEntry] = []

    // Annotated (post-session reflection)
    var annotatedNotes: String = ""
    var annotatedRating: Int? = nil

    /// Memberwise init — explicit because the custom init(from:) below
    /// suppresses Swift's auto-synthesized memberwise init.
    init(id: UUID = UUID(),
         recipeId: UUID,
         date: Date = Date(),
         rating: Int = 0,
         crustTags: [CrustTag] = [],
         crumbTags: [CrumbTag] = [],
         customCrustTags: [String] = [],
         customCrumbTags: [String] = [],
         notes: String = "",
         ballCount: Int,
         ballWeight: Double,
         finalHydration: Double,
         plannedStageDurations: [String: TimeInterval] = [:],
         actualStageDurations: [String: TimeInterval] = [:],
         pauseDurations: [TimeInterval] = [],
         roomTempC: Double = 20,
         prefermentPH: String = "",
         sessionMode: SessionMode = .manual,
         bakeTimeSeconds: TimeInterval = 0,
         ovenTempAchieved: Double? = nil,
         crustColor: CrustColor = .even,
         bottomResult: BottomResult = .good,
         topResult: TopResult = .good,
         photoData: Data? = nil,
         photos: [Data] = [],
         photoIDs: [UUID] = [],
         pizzaEntries: [PizzaEntry] = [],
         annotatedNotes: String = "",
         annotatedRating: Int? = nil) {
        self.id = id
        self.recipeId = recipeId
        self.date = date
        self.rating = rating
        self.crustTags = crustTags
        self.crumbTags = crumbTags
        self.customCrustTags = customCrustTags
        self.customCrumbTags = customCrumbTags
        self.notes = notes
        self.ballCount = ballCount
        self.ballWeight = ballWeight
        self.finalHydration = finalHydration
        self.plannedStageDurations = plannedStageDurations
        self.actualStageDurations = actualStageDurations
        self.pauseDurations = pauseDurations
        self.roomTempC = roomTempC
        self.prefermentPH = prefermentPH
        self.sessionMode = sessionMode
        self.bakeTimeSeconds = bakeTimeSeconds
        self.ovenTempAchieved = ovenTempAchieved
        self.crustColor = crustColor
        self.bottomResult = bottomResult
        self.topResult = topResult
        self.photoData = photoData
        self.photos = photos
        self.photoIDs = photoIDs
        self.pizzaEntries = pizzaEntries
        self.annotatedNotes = annotatedNotes
        self.annotatedRating = annotatedRating
    }

    /// Custom decoder — every field with a default uses decodeIfPresent
    /// so old saved data (encoded before the photoIDs field existed)
    /// still decodes. Same pattern used in Recipe.swift.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                    = (try? c.decode(UUID.self, forKey: .id)) ?? UUID()
        recipeId              = try c.decode(UUID.self, forKey: .recipeId)
        date                  = (try? c.decode(Date.self, forKey: .date)) ?? Date()
        rating                = (try? c.decode(Int.self, forKey: .rating)) ?? 0
        crustTags             = (try? c.decode([CrustTag].self, forKey: .crustTags)) ?? []
        crumbTags             = (try? c.decode([CrumbTag].self, forKey: .crumbTags)) ?? []
        customCrustTags       = (try? c.decode([String].self, forKey: .customCrustTags)) ?? []
        customCrumbTags       = (try? c.decode([String].self, forKey: .customCrumbTags)) ?? []
        notes                 = (try? c.decode(String.self, forKey: .notes)) ?? ""
        ballCount             = try c.decode(Int.self, forKey: .ballCount)
        ballWeight            = try c.decode(Double.self, forKey: .ballWeight)
        finalHydration        = try c.decode(Double.self, forKey: .finalHydration)
        plannedStageDurations = (try? c.decode([String: TimeInterval].self, forKey: .plannedStageDurations)) ?? [:]
        actualStageDurations  = (try? c.decode([String: TimeInterval].self, forKey: .actualStageDurations)) ?? [:]
        pauseDurations        = (try? c.decode([TimeInterval].self, forKey: .pauseDurations)) ?? []
        roomTempC             = (try? c.decode(Double.self, forKey: .roomTempC)) ?? 20
        prefermentPH          = (try? c.decode(String.self, forKey: .prefermentPH)) ?? ""
        sessionMode           = (try? c.decode(SessionMode.self, forKey: .sessionMode)) ?? .manual
        bakeTimeSeconds       = (try? c.decode(TimeInterval.self, forKey: .bakeTimeSeconds)) ?? 0
        ovenTempAchieved      = try c.decodeIfPresent(Double.self, forKey: .ovenTempAchieved)
        crustColor            = (try? c.decode(CrustColor.self, forKey: .crustColor)) ?? .even
        bottomResult          = (try? c.decode(BottomResult.self, forKey: .bottomResult)) ?? .good
        topResult             = (try? c.decode(TopResult.self, forKey: .topResult)) ?? .good
        photoData             = try c.decodeIfPresent(Data.self, forKey: .photoData)
        photos                = (try? c.decode([Data].self, forKey: .photos)) ?? []
        photoIDs              = (try? c.decode([UUID].self, forKey: .photoIDs)) ?? []
        pizzaEntries          = (try? c.decode([PizzaEntry].self, forKey: .pizzaEntries)) ?? []
        annotatedNotes        = (try? c.decode(String.self, forKey: .annotatedNotes)) ?? ""
        annotatedRating       = try c.decodeIfPresent(Int.self, forKey: .annotatedRating)
    }

    /// Session-level photos to render. Prefers photoIDs (resolved from
    /// disk via PhotoStore), then legacy `photos`, then legacy
    /// `photoData`. First photo is the session's cover thumbnail.
    var displayPhotos: [Data] {
        if !photoIDs.isEmpty {
            return photoIDs.compactMap { PhotoStore.shared.load($0) }
        }
        if !photos.isEmpty { return photos }
        return [photoData].compactMap { $0 }
    }
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
