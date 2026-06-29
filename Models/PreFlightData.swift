import Foundation

struct PreFlightData: Codable {
    var prefermentReady: Bool = false
    var prefermentHydration: Double = 0.50
    var prefermentPH: String = ""
    var roomTempC: Double = 20
    var hasPHMeter: Bool = false
    var hasDoughThermometer: Bool = false

    var sessionMode: SessionMode = .manual
    var selectedBakeSetupId: UUID? = nil

    var sessionName: String = ""

    // Last-minute overrides (nil = use recipe value)
    var overrideBallCount: Int? = nil
    var overrideBallWeight: Double? = nil
    var overrideHydration: Double? = nil
    var overrideBuffer: Double? = nil

    // Session-only step duration overrides (UUID.uuidString → seconds)
    var sessionStepDurationOverrides: [String: TimeInterval] = [:]
}
