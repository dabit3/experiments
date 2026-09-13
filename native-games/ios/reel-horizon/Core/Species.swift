import Foundation

/// What is tied to the end of the line. Baits sit still under a float; lures are retrieved.
public enum TackleKind: String, Codable, CaseIterable, Hashable {
  case redWorm, doughBall, cricket, corn, minnow, cutBait
  case spoon, spinner, crankbait, softGrub, popper, jig

  public var isBait: Bool {
    switch self {
    case .redWorm, .doughBall, .cricket, .corn, .minnow, .cutBait: return true
    default: return false
    }
  }

  public var displayName: String {
    switch self {
    case .redWorm: return "Red Worms"
    case .doughBall: return "Dough Balls"
    case .cricket: return "Crickets"
    case .corn: return "Corn"
    case .minnow: return "Minnows"
    case .cutBait: return "Cut Bait"
    case .spoon: return "Casting Spoon"
    case .spinner: return "Spinner"
    case .crankbait: return "Crankbait"
    case .softGrub: return "Soft Grub"
    case .popper: return "Popper"
    case .jig: return "Jig Head"
    }
  }
}

public enum FishColoring: String, Codable, Hashable {
  case sunfish, bass, shiner, crappie, catfish, carp, walleye, gar, trout, pike, perch, drum
}

public struct Species: Identifiable, Codable, Hashable {
  public let id: String
  public let name: String
  public let latinName: String
  public let minWeightLb: Double
  public let maxWeightLb: Double
  public let trophyWeightLb: Double
  public let uniqueWeightLb: Double
  public let minLengthIn: Double
  public let maxLengthIn: Double
  /// Credits per pound when sold.
  public let pricePerLb: Double
  public let xpPerLb: Double
  public let baseXP: Double
  /// Relative abundance in a waterway (higher means more common).
  public let abundance: Double
  /// Pulling strength per pound; 1.0 is a typical panfish, bass fight much harder.
  public let fightStrength: Double
  public let preferredTackle: Set<TackleKind>
  /// Hours (0-23) where bite activity is highest.
  public let peakHours: Set<Int>
  public let coloring: FishColoring

  public func lengthFor(weightLb: Double) -> Double {
    let span = max(0.0001, maxWeightLb - minWeightLb)
    let t = ((weightLb - minWeightLb) / span).clamped(0, 1)
    return minLengthIn + (maxLengthIn - minLengthIn) * pow(t, 0.42)
  }

  public func activity(atHour hour: Int) -> Double {
    if peakHours.contains(hour) { return 1.0 }
    let dist = peakHours.map { min(abs($0 - hour), 24 - abs($0 - hour)) }.min() ?? 12
    return max(0.25, 1.0 - Double(dist) * 0.18)
  }

  public func lureAffinity(_ kind: TackleKind) -> Double {
    preferredTackle.contains(kind) ? 1.0 : 0.22
  }

  public func grade(weightLb: Double) -> CatchGrade {
    if weightLb >= uniqueWeightLb { return .unique }
    if weightLb >= trophyWeightLb { return .trophy }
    if weightLb < minWeightLb + (trophyWeightLb - minWeightLb) * 0.12 { return .young }
    return .common
  }
}

public enum CatchGrade: String, Codable, Hashable {
  case young, common, trophy, unique

  public var label: String {
    switch self {
    case .young: return "YOUNG"
    case .common: return "COMMON"
    case .trophy: return "TROPHY"
    case .unique: return "UNIQUE"
    }
  }

  public var xpMultiplier: Double {
    switch self {
    case .young: return 0.6
    case .common: return 1
    case .trophy: return 3
    case .unique: return 8
    }
  }
}

extension Comparable {
  public func clamped(_ lo: Self, _ hi: Self) -> Self {
    min(max(self, lo), hi)
  }
}

public enum SpeciesCatalog {
  public static let all: [Species] = [
    Species(
      id: "bluegill", name: "Bluegill", latinName: "Lepomis macrochirus",
      minWeightLb: 0.15, maxWeightLb: 2.9, trophyWeightLb: 1.4, uniqueWeightLb: 2.6,
      minLengthIn: 4.2, maxLengthIn: 14.5, pricePerLb: 38, xpPerLb: 30, baseXP: 9,
      abundance: 1.6, fightStrength: 0.9,
      preferredTackle: [.redWorm, .cricket, .doughBall, .softGrub, .spinner],
      peakHours: [6, 7, 8, 17, 18, 19], coloring: .sunfish),
    Species(
      id: "redearSunfish", name: "Redear Sunfish", latinName: "Lepomis microlophus",
      minWeightLb: 0.2, maxWeightLb: 4.4, trophyWeightLb: 2.2, uniqueWeightLb: 4.0,
      minLengthIn: 4.5, maxLengthIn: 16.2, pricePerLb: 44, xpPerLb: 34, baseXP: 11,
      abundance: 1.1, fightStrength: 1.0,
      preferredTackle: [.redWorm, .cricket, .corn, .softGrub],
      peakHours: [7, 8, 9, 16, 17, 18], coloring: .sunfish),
    Species(
      id: "goldenShiner", name: "Golden Shiner", latinName: "Notemigonus crysoleucas",
      minWeightLb: 0.05, maxWeightLb: 1.3, trophyWeightLb: 0.7, uniqueWeightLb: 1.2,
      minLengthIn: 3.3, maxLengthIn: 12.4, pricePerLb: 24, xpPerLb: 22, baseXP: 6,
      abundance: 1.5, fightStrength: 0.6,
      preferredTackle: [.redWorm, .doughBall, .corn],
      peakHours: [5, 6, 7, 19, 20], coloring: .shiner),
    Species(
      id: "whiteCrappie", name: "White Crappie", latinName: "Pomoxis annularis",
      minWeightLb: 0.3, maxWeightLb: 4.8, trophyWeightLb: 2.4, uniqueWeightLb: 4.4,
      minLengthIn: 6.0, maxLengthIn: 19.5, pricePerLb: 52, xpPerLb: 40, baseXP: 14,
      abundance: 0.9, fightStrength: 1.0,
      preferredTackle: [.minnow, .softGrub, .jig, .spinner],
      peakHours: [5, 6, 19, 20, 21], coloring: .crappie),
    Species(
      id: "largemouthBass", name: "Largemouth Bass", latinName: "Micropterus salmoides",
      minWeightLb: 0.8, maxWeightLb: 22.0, trophyWeightLb: 9.0, uniqueWeightLb: 18.0,
      minLengthIn: 9.5, maxLengthIn: 29.0, pricePerLb: 74, xpPerLb: 60, baseXP: 30,
      abundance: 0.7, fightStrength: 1.5,
      preferredTackle: [.crankbait, .spinner, .popper, .softGrub, .minnow],
      peakHours: [6, 7, 8, 18, 19, 20], coloring: .bass),
    Species(
      id: "spottedBass", name: "Spotted Bass", latinName: "Micropterus punctulatus",
      minWeightLb: 0.6, maxWeightLb: 10.4, trophyWeightLb: 5.0, uniqueWeightLb: 9.4,
      minLengthIn: 8.5, maxLengthIn: 25.0, pricePerLb: 70, xpPerLb: 58, baseXP: 26,
      abundance: 0.5, fightStrength: 1.45,
      preferredTackle: [.crankbait, .spinner, .spoon, .softGrub],
      peakHours: [7, 8, 17, 18, 19], coloring: .bass),
    Species(
      id: "channelCatfish", name: "Channel Catfish", latinName: "Ictalurus punctatus",
      minWeightLb: 1.2, maxWeightLb: 58.0, trophyWeightLb: 20.0, uniqueWeightLb: 48.0,
      minLengthIn: 12.0, maxLengthIn: 52.0, pricePerLb: 48, xpPerLb: 46, baseXP: 34,
      abundance: 0.45, fightStrength: 1.3,
      preferredTackle: [.cutBait, .redWorm, .doughBall, .minnow],
      peakHours: [20, 21, 22, 5, 6], coloring: .catfish),
    Species(
      id: "commonCarp", name: "Common Carp", latinName: "Cyprinus carpio",
      minWeightLb: 2.0, maxWeightLb: 68.0, trophyWeightLb: 30.0, uniqueWeightLb: 60.0,
      minLengthIn: 14.0, maxLengthIn: 48.0, pricePerLb: 40, xpPerLb: 42, baseXP: 36,
      abundance: 0.4, fightStrength: 1.35,
      preferredTackle: [.corn, .doughBall, .redWorm],
      peakHours: [6, 7, 8, 9, 18, 19], coloring: .carp),
    Species(
      id: "walleye", name: "Walleye", latinName: "Sander vitreus",
      minWeightLb: 0.9, maxWeightLb: 24.0, trophyWeightLb: 10.0, uniqueWeightLb: 21.0,
      minLengthIn: 10.0, maxLengthIn: 40.0, pricePerLb: 86, xpPerLb: 66, baseXP: 40,
      abundance: 0.35, fightStrength: 1.4,
      preferredTackle: [.minnow, .jig, .crankbait, .spoon],
      peakHours: [5, 6, 20, 21, 22], coloring: .walleye),
    Species(
      id: "smallmouthBass", name: "Smallmouth Bass", latinName: "Micropterus dolomieu",
      minWeightLb: 0.6, maxWeightLb: 11.8, trophyWeightLb: 5.5, uniqueWeightLb: 10.6,
      minLengthIn: 8.0, maxLengthIn: 26.0, pricePerLb: 80, xpPerLb: 64, baseXP: 30,
      abundance: 0.7, fightStrength: 1.7,
      preferredTackle: [.crankbait, .spinner, .softGrub, .jig],
      peakHours: [6, 7, 8, 17, 18], coloring: .bass),
    Species(
      id: "longnoseGar", name: "Longnose Gar", latinName: "Lepisosteus osseus",
      minWeightLb: 1.5, maxWeightLb: 50.0, trophyWeightLb: 22.0, uniqueWeightLb: 44.0,
      minLengthIn: 20.0, maxLengthIn: 72.0, pricePerLb: 44, xpPerLb: 50, baseXP: 40,
      abundance: 0.3, fightStrength: 1.5,
      preferredTackle: [.minnow, .cutBait, .spoon],
      peakHours: [11, 12, 13, 14, 15], coloring: .gar),
    Species(
      id: "flatheadCatfish", name: "Flathead Catfish", latinName: "Pylodictis olivaris",
      minWeightLb: 2.5, maxWeightLb: 123.0, trophyWeightLb: 45.0, uniqueWeightLb: 100.0,
      minLengthIn: 15.0, maxLengthIn: 61.0, pricePerLb: 56, xpPerLb: 52, baseXP: 60,
      abundance: 0.25, fightStrength: 1.4,
      preferredTackle: [.cutBait, .minnow],
      peakHours: [21, 22, 23, 4, 5], coloring: .catfish),
    Species(
      id: "rockBass", name: "Rock Bass", latinName: "Ambloplites rupestris",
      minWeightLb: 0.2, maxWeightLb: 3.0, trophyWeightLb: 1.5, uniqueWeightLb: 2.7,
      minLengthIn: 4.5, maxLengthIn: 17.0, pricePerLb: 36, xpPerLb: 30, baseXP: 9,
      abundance: 1.2, fightStrength: 0.95,
      preferredTackle: [.redWorm, .cricket, .spinner, .softGrub],
      peakHours: [6, 7, 8, 17, 18], coloring: .sunfish),
    Species(
      id: "yellowPerch", name: "Yellow Perch", latinName: "Perca flavescens",
      minWeightLb: 0.2, maxWeightLb: 4.2, trophyWeightLb: 2.0, uniqueWeightLb: 3.8,
      minLengthIn: 5.0, maxLengthIn: 21.0, pricePerLb: 46, xpPerLb: 36, baseXP: 12,
      abundance: 1.4, fightStrength: 0.9,
      preferredTackle: [.redWorm, .minnow, .jig, .spinner],
      peakHours: [7, 8, 9, 16, 17], coloring: .perch),
    Species(
      id: "brookTrout", name: "Brook Trout", latinName: "Salvelinus fontinalis",
      minWeightLb: 0.3, maxWeightLb: 14.5, trophyWeightLb: 5.0, uniqueWeightLb: 12.0,
      minLengthIn: 7.0, maxLengthIn: 34.0, pricePerLb: 96, xpPerLb: 74, baseXP: 24,
      abundance: 0.8, fightStrength: 1.6,
      preferredTackle: [.spinner, .spoon, .redWorm, .cricket],
      peakHours: [5, 6, 7, 19, 20], coloring: .trout),
    Species(
      id: "rainbowTrout", name: "Rainbow Trout", latinName: "Oncorhynchus mykiss",
      minWeightLb: 0.5, maxWeightLb: 42.0, trophyWeightLb: 12.0, uniqueWeightLb: 36.0,
      minLengthIn: 8.0, maxLengthIn: 45.0, pricePerLb: 92, xpPerLb: 72, baseXP: 30,
      abundance: 0.6, fightStrength: 1.75,
      preferredTackle: [.spinner, .spoon, .crankbait, .corn],
      peakHours: [6, 7, 8, 18, 19], coloring: .trout),
    Species(
      id: "chainPickerel", name: "Chain Pickerel", latinName: "Esox niger",
      minWeightLb: 0.7, maxWeightLb: 9.6, trophyWeightLb: 4.5, uniqueWeightLb: 8.6,
      minLengthIn: 10.0, maxLengthIn: 31.0, pricePerLb: 66, xpPerLb: 58, baseXP: 24,
      abundance: 0.5, fightStrength: 1.55,
      preferredTackle: [.spoon, .spinner, .minnow, .crankbait],
      peakHours: [8, 9, 10, 15, 16, 17], coloring: .pike),
    Species(
      id: "northernPike", name: "Northern Pike", latinName: "Esox lucius",
      minWeightLb: 2.0, maxWeightLb: 55.0, trophyWeightLb: 22.0, uniqueWeightLb: 48.0,
      minLengthIn: 16.0, maxLengthIn: 58.0, pricePerLb: 90, xpPerLb: 70, baseXP: 60,
      abundance: 0.3, fightStrength: 1.9,
      preferredTackle: [.spoon, .crankbait, .minnow, .cutBait],
      peakHours: [7, 8, 9, 17, 18, 19], coloring: .pike),
    Species(
      id: "freshwaterDrum", name: "Freshwater Drum", latinName: "Aplodinotus grunniens",
      minWeightLb: 1.0, maxWeightLb: 54.0, trophyWeightLb: 20.0, uniqueWeightLb: 46.0,
      minLengthIn: 11.0, maxLengthIn: 37.0, pricePerLb: 38, xpPerLb: 40, baseXP: 30,
      abundance: 0.4, fightStrength: 1.25,
      preferredTackle: [.redWorm, .cutBait, .jig, .minnow],
      peakHours: [19, 20, 21, 22], coloring: .drum),
  ]

  public static let byID: [String: Species] = Dictionary(
    uniqueKeysWithValues: all.map { ($0.id, $0) })

  public static func find(_ id: String) -> Species {
    guard let species = byID[id] else { fatalError("Unknown species \(id)") }
    return species
  }
}
