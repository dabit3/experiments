import Foundation

public enum WeatherKind: String, Codable, CaseIterable, Hashable {
  case sunny, partlyCloudy, overcast, rain, fog

  public var label: String {
    switch self {
    case .sunny: return "Sunny"
    case .partlyCloudy: return "Partly Cloudy"
    case .overcast: return "Overcast"
    case .rain: return "Light Rain"
    case .fog: return "Morning Fog"
    }
  }

  /// Multiplier on bite frequency.
  public var biteFactor: Double {
    switch self {
    case .sunny: return 0.9
    case .partlyCloudy: return 1.05
    case .overcast: return 1.15
    case .rain: return 1.2
    case .fog: return 1.0
    }
  }
}

public struct WeatherForecast: Codable, Hashable {
  public let kind: WeatherKind
  public let airTempF: Int
  public let waterTempF: Int
  public let windMph: Double
  public let windDirection: String
  public let pressureInHg: Double

  public init(
    kind: WeatherKind, airTempF: Int, waterTempF: Int, windMph: Double, windDirection: String,
    pressureInHg: Double
  ) {
    self.kind = kind
    self.airTempF = airTempF
    self.waterTempF = waterTempF
    self.windMph = windMph
    self.windDirection = windDirection
    self.pressureInHg = pressureInHg
  }
}

public struct LicenseOption: Codable, Hashable, Identifiable {
  public var id: String { "\(days)-\(advanced)" }
  public let days: Int
  public let price: Int
  public let advanced: Bool

  public var durationLabel: String {
    switch days {
    case 1: return "1 Day"
    case 3: return "3 Days"
    case 7: return "Week"
    case 30: return "Month"
    default: return "\(days) Days"
    }
  }
}

public struct Waterway: Identifiable, Codable, Hashable {
  public let id: String
  public let name: String
  public let region: String
  public let country: String
  public let requiredLevel: Int
  public let travelFee: Int
  public let dailyFishingFee: Int
  public let speciesIDs: [String]
  /// Globe position in degrees.
  public let latitude: Double
  public let longitude: Double
  public let description: String
  public let forecast: WeatherForecast
  public let waterTint: WaterTint
  public let basicLicensePerDay: Int
  public let advancedLicensePerDay: Int
  /// Species that a basic license forces the angler to release.
  public let mustReleaseBasic: [String]

  public var species: [Species] { speciesIDs.map(SpeciesCatalog.find) }

  public var displayTitle: String { "\(name.uppercased()) - \(region.uppercased())" }

  public var licenses: [LicenseOption] {
    [
      LicenseOption(days: 1, price: basicLicensePerDay, advanced: false),
      LicenseOption(days: 3, price: Int(Double(basicLicensePerDay) * 2.8), advanced: false),
      LicenseOption(days: 7, price: Int(Double(basicLicensePerDay) * 6.3), advanced: false),
      LicenseOption(days: 1, price: advancedLicensePerDay, advanced: true),
      LicenseOption(days: 3, price: Int(Double(advancedLicensePerDay) * 2.85), advanced: true),
      LicenseOption(days: 7, price: Int(Double(advancedLicensePerDay) * 6.3), advanced: true),
    ]
  }
}

public enum WaterTint: String, Codable, Hashable {
  case warmGreen, muddyBrown, coldBlue, deepTeal, blackwater
}

public enum WaterwayCatalog {
  public static let all: [Waterway] = [
    Waterway(
      id: "lonePineLake", name: "Lone Pine Lake", region: "Texas", country: "USA",
      requiredLevel: 1, travelFee: 0, dailyFishingFee: 0,
      speciesIDs: [
        "bluegill", "redearSunfish", "goldenShiner", "whiteCrappie", "largemouthBass",
        "spottedBass", "channelCatfish", "commonCarp", "walleye", "freshwaterDrum",
      ],
      latitude: 31.4, longitude: -98.7,
      description:
        "A warm reservoir ringed by pines and boat docks. Panfish crowd the shallows at dawn while bass patrol the weed edges.",
      forecast: WeatherForecast(
        kind: .partlyCloudy, airTempF: 69, waterTempF: 66, windMph: 3.8, windDirection: "NW",
        pressureInHg: 30.02),
      waterTint: .warmGreen, basicLicensePerDay: 100, advancedLicensePerDay: 200,
      mustReleaseBasic: ["spottedBass"]),
    Waterway(
      id: "muddyForkRiver", name: "Muddy Fork River", region: "Missouri", country: "USA",
      requiredLevel: 4, travelFee: 120, dailyFishingFee: 60,
      speciesIDs: [
        "smallmouthBass", "rockBass", "channelCatfish", "flatheadCatfish", "longnoseGar",
        "commonCarp", "freshwaterDrum", "walleye",
      ],
      latitude: 38.4, longitude: -92.4,
      description:
        "Slow chocolate current under sycamores and a rusted railway bridge. Catfish hold in the deep bends after sunset.",
      forecast: WeatherForecast(
        kind: .overcast, airTempF: 61, waterTempF: 58, windMph: 6.2, windDirection: "SW",
        pressureInHg: 29.88),
      waterTint: .muddyBrown, basicLicensePerDay: 160, advancedLicensePerDay: 320,
      mustReleaseBasic: ["flatheadCatfish"]),
    Waterway(
      id: "emeraldTarn", name: "Emerald Tarn", region: "New York", country: "USA",
      requiredLevel: 8, travelFee: 260, dailyFishingFee: 90,
      speciesIDs: [
        "yellowPerch", "brookTrout", "rainbowTrout", "chainPickerel", "rockBass",
        "smallmouthBass", "northernPike",
      ],
      latitude: 43.9, longitude: -74.4,
      description:
        "Glass-clear Adirondack water with granite shelves. Trout rise at first light; pike lurk under the lily pads.",
      forecast: WeatherForecast(
        kind: .fog, airTempF: 52, waterTempF: 49, windMph: 2.1, windDirection: "N",
        pressureInHg: 30.15),
      waterTint: .coldBlue, basicLicensePerDay: 220, advancedLicensePerDay: 440,
      mustReleaseBasic: ["northernPike"]),
    Waterway(
      id: "cypressBayou", name: "Cypress Bayou", region: "Louisiana", country: "USA",
      requiredLevel: 12, travelFee: 340, dailyFishingFee: 110,
      speciesIDs: [
        "largemouthBass", "bluegill", "redearSunfish", "whiteCrappie", "channelCatfish",
        "longnoseGar", "freshwaterDrum", "commonCarp",
      ],
      latitude: 30.6, longitude: -91.6,
      description:
        "Blackwater sloughs beneath Spanish moss. Gar roll at noon; crappie stack against the cypress knees at dusk.",
      forecast: WeatherForecast(
        kind: .rain, airTempF: 77, waterTempF: 74, windMph: 4.4, windDirection: "SE",
        pressureInHg: 29.76),
      waterTint: .blackwater, basicLicensePerDay: 260, advancedLicensePerDay: 520,
      mustReleaseBasic: ["longnoseGar"]),
    Waterway(
      id: "graniteFjord", name: "Granite Fjord", region: "Oregon", country: "USA",
      requiredLevel: 16, travelFee: 480, dailyFishingFee: 140,
      speciesIDs: [
        "rainbowTrout", "brookTrout", "smallmouthBass", "yellowPerch", "walleye", "northernPike",
      ],
      latitude: 44.1, longitude: -121.8,
      description:
        "Cold Cascade water pooled behind a basalt sill. Long casts with spoons reach the trophy trout holding off the drop.",
      forecast: WeatherForecast(
        kind: .sunny, airTempF: 58, waterTempF: 51, windMph: 8.9, windDirection: "W",
        pressureInHg: 30.24),
      waterTint: .deepTeal, basicLicensePerDay: 320, advancedLicensePerDay: 640,
      mustReleaseBasic: ["rainbowTrout"]),
  ]

  public static func find(_ id: String) -> Waterway {
    guard let waterway = all.first(where: { $0.id == id }) else {
      fatalError("Unknown waterway \(id)")
    }
    return waterway
  }
}
