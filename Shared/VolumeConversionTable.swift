import Foundation

// MARK: - SaltKind

enum SaltKind: String, CaseIterable {
    case table        = "Table Salt"
    case kosherCoarse = "Kosher (Coarse)"
    case kosherFine   = "Kosher (Fine)"
    case seaCoarse    = "Sea Salt (Coarse)"
    case seaFine      = "Sea Salt (Fine)"
}

// MARK: - VolumeUnit

enum VolumeUnit: String, CaseIterable {
    case cups        = "cups"
    case tablespoons = "tbsp"
    case teaspoons   = "tsp"
    case grams       = "g"
    case ounces      = "oz"
    case milliliters = "mL"
}

// MARK: - VolumeConversion

enum VolumeConversion {

    /// Grams per cup for each flour type (spooned & leveled assumption).
    static func gramsPerCup(_ type: FlourType) -> Double {
        switch type {
        case .tipo00:     return 130
        case .tipo0:      return 125
        case .allPurpose: return 120
        case .bread:      return 127
        case .highGluten: return 130
        case .wholeWheat: return 130
        case .semolina:   return 170
        case .durum:      return 160
        case .lightRye:   return 102
        case .darkRye:    return 102
        case .spelt:      return 100
        case .einkorn:    return 120
        case .kamut:      return 120
        case .other:      return 120
        }
    }

    /// Grams per teaspoon for each salt kind.
    static func gramsPerTsp(_ kind: SaltKind) -> Double {
        switch kind {
        case .table:        return 6.0   // fine-ground iodised table salt
        case .kosherCoarse: return 3.0   // e.g. Diamond Crystal — large hollow flakes
        case .kosherFine:   return 4.8   // e.g. Morton — denser compressed flakes
        case .seaCoarse:    return 4.0   // coarse sea salt crystals
        case .seaFine:      return 5.5   // fine-ground sea salt
        }
    }

    /// Grams per teaspoon for each yeast type.
    static func gramsPerTsp(_ type: YeastType) -> Double {
        switch type {
        case .instantDry: return 3.0
        case .activeDry:  return 3.0
        case .fresh:      return 4.0
        case .noYeast:    return 0
        case .other:      return 3.0
        }
    }

    /// Convert amount + unit → grams using a grams-per-cup density.
    /// Weight units (g, oz) bypass the density entirely.
    static func toGrams(_ amount: Double, _ unit: VolumeUnit, densityPerCup: Double) -> Double {
        switch unit {
        case .grams:       return amount
        case .ounces:      return amount * 28.3495
        case .cups:        return amount * densityPerCup
        case .tablespoons: return amount * densityPerCup / 16
        case .teaspoons:   return amount * densityPerCup / 48
        case .milliliters: return amount * densityPerCup / 240
        }
    }

    static func flourToGrams(_ amount: Double, _ unit: VolumeUnit, _ type: FlourType) -> Double {
        toGrams(amount, unit, densityPerCup: gramsPerCup(type))
    }

    static func waterToGrams(_ amount: Double, _ unit: VolumeUnit) -> Double {
        toGrams(amount, unit, densityPerCup: 240) // water: 240 g/cup
    }

    static func saltToGrams(_ amount: Double, _ unit: VolumeUnit, _ kind: SaltKind) -> Double {
        toGrams(amount, unit, densityPerCup: gramsPerTsp(kind) * 48) // 48 tsp per cup
    }

    static func yeastToGrams(_ amount: Double, _ unit: VolumeUnit, _ type: YeastType) -> Double {
        toGrams(amount, unit, densityPerCup: gramsPerTsp(type) * 48)
    }
}
