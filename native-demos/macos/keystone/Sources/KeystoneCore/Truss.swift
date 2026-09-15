import Foundation

public enum Support: String, Codable, CaseIterable, Sendable {
  case free = "Free"
  case pin = "Pin · X + Y"
  case roller = "Roller · Y"
}

public struct Node: Codable, Identifiable, Equatable, Sendable {
  public var id: Int
  public var x: Double
  public var y: Double
  public var support: Support
  public var loadKN: Double
  public var loadXKN: Double = 0

  public init(id: Int, x: Double, y: Double, support: Support = .free, loadKN: Double = 0) {
    self.id = id
    self.x = x
    self.y = y
    self.support = support
    self.loadKN = loadKN
  }

  private enum CodingKeys: String, CodingKey { case id, x, y, support, loadKN, loadXKN }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(Int.self, forKey: .id)
    x = try c.decode(Double.self, forKey: .x)
    y = try c.decode(Double.self, forKey: .y)
    support = try c.decode(Support.self, forKey: .support)
    loadKN = try c.decode(Double.self, forKey: .loadKN)
    loadXKN = try c.decodeIfPresent(Double.self, forKey: .loadXKN) ?? 0
  }
}

public struct Member: Codable, Identifiable, Equatable, Sendable {
  public var id: Int
  public var a: Int
  public var b: Int
  public var areaCM2: Double
  public var inertiaCM4: Double?
  public var effectiveLengthFactor: Double = 1
  public var sectionName: String?

  public init(id: Int, a: Int, b: Int, areaCM2: Double = 20) {
    self.id = id
    self.a = a
    self.b = b
    self.areaCM2 = areaCM2
  }

  private enum CodingKeys: String, CodingKey {
    case id, a, b, areaCM2, inertiaCM4, effectiveLengthFactor, sectionName
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(Int.self, forKey: .id)
    a = try c.decode(Int.self, forKey: .a)
    b = try c.decode(Int.self, forKey: .b)
    areaCM2 = try c.decode(Double.self, forKey: .areaCM2)
    inertiaCM4 = try c.decodeIfPresent(Double.self, forKey: .inertiaCM4)
    effectiveLengthFactor = try c.decodeIfPresent(Double.self, forKey: .effectiveLengthFactor) ?? 1
    sectionName = try c.decodeIfPresent(String.self, forKey: .sectionName)
  }

  public mutating func apply(_ section: SectionPreset) {
    areaCM2 = section.areaCM2
    inertiaCM4 = section.inertiaCM4
    sectionName = section.name
  }
}

public struct Material: Codable, Equatable, Sendable {
  public var name: String
  public var modulusGPa: Double
  public var yieldMPa: Double
  public var density: Double
  public var costPerKg: Double

  public static let steel = Material(
    name: "Structural steel", modulusGPa: 200, yieldMPa: 250, density: 7850, costPerKg: 2.4)
  public static let aluminum = Material(
    name: "Aluminum 6061", modulusGPa: 69, yieldMPa: 240, density: 2700, costPerKg: 5.2)
}

public struct Design: Codable, Equatable, Sendable {
  public var version = 2
  public var name: String
  public var nodes: [Node]
  public var members: [Member]
  public var material: Material
  public var budget: Double
  public var projectNote = ""
  public var loadCases = [LoadCase.service]
  public var activeCaseID = "service"
  public var resistanceFactor: Double = 1.5
  public var deflectionRatio: Double = 360

  public init(
    name: String, nodes: [Node], members: [Member], material: Material = .steel,
    budget: Double = 2500
  ) {
    self.name = name
    self.nodes = nodes
    self.members = members
    self.material = material
    self.budget = budget
  }

  private enum CodingKeys: String, CodingKey {
    case version, name, nodes, members, material, budget, projectNote, loadCases, activeCaseID
    case resistanceFactor, deflectionRatio
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let storedVersion = try c.decode(Int.self, forKey: .version)
    guard (1...2).contains(storedVersion) else {
      throw AnalysisError.invalid("Unsupported design version.")
    }
    name = try c.decode(String.self, forKey: .name)
    nodes = try c.decode([Node].self, forKey: .nodes)
    members = try c.decode([Member].self, forKey: .members)
    material = try c.decode(Material.self, forKey: .material)
    budget = try c.decode(Double.self, forKey: .budget)
    projectNote = try c.decodeIfPresent(String.self, forKey: .projectNote) ?? ""
    loadCases = try c.decodeIfPresent([LoadCase].self, forKey: .loadCases) ?? [.service]
    activeCaseID = try c.decodeIfPresent(String.self, forKey: .activeCaseID) ?? "service"
    resistanceFactor = try c.decodeIfPresent(Double.self, forKey: .resistanceFactor) ?? 1.5
    deflectionRatio = try c.decodeIfPresent(Double.self, forKey: .deflectionRatio) ?? 360
  }

  public static func example(height: Double = 3, name: String = "Warren / River crossing") -> Design
  {
    var nodes = (0..<5).map { Node(id: $0, x: Double($0) * 3, y: 0) }
    nodes[0].support = .pin
    nodes[4].support = .roller
    nodes[2].loadKN = 100
    nodes += (0..<4).map { Node(id: $0 + 5, x: Double($0) * 3 + 1.5, y: height) }
    var links = (0..<4).map { ($0, $0 + 1) }
    links += (5..<8).map { ($0, $0 + 1) }
    for i in 0..<4 { links += [(i, i + 5), (i + 5, i + 1)] }
    return Design(
      name: name, nodes: nodes,
      members: links.enumerated().map { Member(id: $0.offset, a: $0.element.0, b: $0.element.1) })
  }

  public func node(_ id: Int) -> Node? { nodes.first { $0.id == id } }

  public func length(_ member: Member) -> Double {
    guard let a = node(member.a), let b = node(member.b) else { return 0 }
    return hypot(b.x - a.x, b.y - a.y)
  }

  public var massKg: Double {
    members.reduce(0) { $0 + length($1) * $1.areaCM2 * 0.0001 * material.density }
  }
  public var cost: Double { massKg * material.costPerKg }

  public func validated(allowDraft: Bool = false) throws -> Design {
    guard version == 2 else { throw AnalysisError.invalid("Unsupported design version.") }
    guard ((allowDraft ? 0 : 2)...100).contains(nodes.count),
      ((allowDraft ? 0 : 1)...300).contains(members.count)
    else {
      throw AnalysisError.invalid("Use 2–100 nodes and 1–300 members.")
    }
    guard Set(nodes.map(\.id)).count == nodes.count,
      Set(members.map(\.id)).count == members.count
    else { throw AnalysisError.invalid("Node and member IDs must be unique.") }
    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, name.count <= 120,
      material.name.count <= 120, projectNote.count <= 2000,
      resistanceFactor.isFinite, (1...5).contains(resistanceFactor),
      deflectionRatio.isFinite, (50...2000).contains(deflectionRatio),
      [material.modulusGPa, material.yieldMPa, material.density, material.costPerKg, budget]
        .allSatisfy({ $0.isFinite && $0 > 0 && $0 <= 1e9 })
    else {
      throw AnalysisError.invalid("Material properties and budget must be positive and finite.")
    }
    guard
      nodes.allSatisfy({
        $0.x.isFinite && $0.y.isFinite && abs($0.x) <= 100 && abs($0.y) <= 100
          && $0.loadKN.isFinite && abs($0.loadKN) <= 10000
          && $0.loadXKN.isFinite && abs($0.loadXKN) <= 10000
          && (0...1_000_000).contains($0.id)
      })
    else { throw AnalysisError.invalid("Invalid node coordinates or loads.") }
    var pairs = Set<String>()
    for member in members {
      guard (0...1_000_000).contains(member.id),
        node(member.a) != nil, node(member.b) != nil, member.a != member.b,
        length(member) >= 0.1, member.areaCM2.isFinite,
        (0.1...1000).contains(member.areaCM2),
        member.inertiaCM4.map({ $0.isFinite && (0.01...1_000_000).contains($0) }) ?? true,
        member.effectiveLengthFactor.isFinite, (0.5...3).contains(member.effectiveLengthFactor),
        (member.sectionName?.count ?? 0) <= 120
      else { throw AnalysisError.invalid("Members need distinct nodes and a valid cross-section.") }
      let key = "\(min(member.a, member.b)):\(max(member.a, member.b))"
      guard pairs.insert(key).inserted else {
        throw AnalysisError.invalid("Duplicate members are not allowed.")
      }
    }
    try validateLoadCases()
    return self
  }
}

public enum AnalysisError: Error, LocalizedError, Equatable {
  case invalid(String)
  case unstable
  public var errorDescription: String? {
    switch self {
    case .invalid(let reason): return reason
    case .unstable:
      return "A mechanism was detected. Add triangulation or restore a support, then try again."
    }
  }
}

public struct MemberResult: Sendable {
  public var forceKN: Double
  public var stressMPa: Double
  public var utilization: Double
  public var eulerCriticalKN: Double?
  public var capacityUtilization: Double
  public var governingMode: String
}

public struct Analysis: Sendable {
  public var members: [Int: MemberResult]
  public var displacement: [Int: SIMD2<Double>]
  public var reactionsKN: [Int: SIMD2<Double>]
  public var maxDisplacementMM: Double
  public var maxUtilization: Double
  public var residualN: Double
  public var appliedLoadsKN: [Int: SIMD2<Double>]
  public var maxCapacityUtilization: Double
  public var maxVerticalMM: Double
  public var missingBucklingChecks: Int
}

public enum Solver {
  public static func solve(_ design: Design) throws -> Analysis {
    let design = try design.validated()
    let count = design.nodes.count * 2
    let indices = Dictionary(
      uniqueKeysWithValues: design.nodes.enumerated().map { ($0.element.id, $0.offset) })
    var stiffness = Array(repeating: Array(repeating: 0.0, count: count), count: count)
    var loads = Array(repeating: 0.0, count: count)
    var fixed = Set<Int>()
    let applied = design.effectiveLoads()
    for (i, node) in design.nodes.enumerated() {
      loads[2 * i] = (applied[node.id]?.x ?? 0) * 1000
      loads[2 * i + 1] = (applied[node.id]?.y ?? 0) * 1000
      if node.support == .pin { fixed.insert(2 * i) }
      if node.support != .free { fixed.insert(2 * i + 1) }
    }
    for member in design.members {
      guard let ai = indices[member.a], let bi = indices[member.b] else {
        throw AnalysisError.invalid("Missing member node.")
      }
      let a = design.nodes[ai]
      let b = design.nodes[bi]
      let length = design.length(member)
      let c = (b.x - a.x) / length
      let s = (b.y - a.y) / length
      let vector = [-c, -s, c, s]
      let dofs = [2 * ai, 2 * ai + 1, 2 * bi, 2 * bi + 1]
      let axial = design.material.modulusGPa * 1e9 * member.areaCM2 * 1e-4 / length
      for i in 0..<4 {
        for j in 0..<4 { stiffness[dofs[i]][dofs[j]] += axial * vector[i] * vector[j] }
      }
    }
    let free = (0..<count).filter { !fixed.contains($0) }
    var displacement = Array(repeating: 0.0, count: count)
    if !free.isEmpty {
      let size = free.count
      var lower = Array(repeating: Array(repeating: 0.0, count: size), count: size)
      let scale = free.map { stiffness[$0][$0] }.max() ?? 0
      guard scale > 0 else { throw AnalysisError.unstable }
      for i in 0..<size {
        for j in 0...i {
          var sum = stiffness[free[i]][free[j]]
          for k in 0..<j { sum -= lower[i][k] * lower[j][k] }
          if i == j {
            guard sum.isFinite, sum > scale * 1e-10 else { throw AnalysisError.unstable }
            lower[i][j] = sqrt(sum)
          } else {
            lower[i][j] = sum / lower[j][j]
          }
        }
      }
      var y = Array(repeating: 0.0, count: size)
      for i in 0..<size {
        var value = loads[free[i]]
        for j in 0..<i { value -= lower[i][j] * y[j] }
        y[i] = value / lower[i][i]
      }
      for i in (0..<size).reversed() {
        var value = y[i]
        for j in (i + 1)..<size { value -= lower[j][i] * displacement[free[j]] }
        displacement[free[i]] = value / lower[i][i]
      }
    }
    var memberResults: [Int: MemberResult] = [:]
    for member in design.members {
      guard let ai = indices[member.a], let bi = indices[member.b] else { continue }
      let a = design.nodes[ai]
      let b = design.nodes[bi]
      let length = design.length(member)
      let extensionM =
        (displacement[2 * bi] - displacement[2 * ai]) * (b.x - a.x) / length
        + (displacement[2 * bi + 1] - displacement[2 * ai + 1]) * (b.y - a.y) / length
      let stress = design.material.modulusGPa * 1000 * extensionM / length
      let force = stress * member.areaCM2 * 0.1
      let yieldKN = design.material.yieldMPa * member.areaCM2 * 0.1
      let euler = member.inertiaCM4.map {
        Double.pi * Double.pi * design.material.modulusGPa * 1e9 * $0 * 1e-8
          / pow(member.effectiveLengthFactor * length, 2) / 1000
      }
      let capacity = force < -0.001 ? min(yieldKN, euler ?? yieldKN) : yieldKN
      memberResults[member.id] = MemberResult(
        forceKN: force, stressMPa: stress,
        utilization: abs(stress) / design.material.yieldMPa,
        eulerCriticalKN: euler,
        capacityUtilization: abs(force) * design.resistanceFactor / capacity,
        governingMode: force < -0.001 && (euler ?? .infinity) < yieldKN
          ? "Euler buckling" : "Axial yield")
    }
    var displacements: [Int: SIMD2<Double>] = [:]
    var reactions: [Int: SIMD2<Double>] = [:]
    var residual = 0.0
    for (i, node) in design.nodes.enumerated() {
      displacements[node.id] = SIMD2(displacement[2 * i], displacement[2 * i + 1])
      var reaction = SIMD2<Double>.zero
      for axis in 0..<2 {
        let row = 2 * i + axis
        let value = zip(stiffness[row], displacement).reduce(0) { $0 + $1.0 * $1.1 } - loads[row]
        if fixed.contains(row) {
          reaction[axis] = value / 1000
        } else {
          residual = max(residual, abs(value))
        }
      }
      reactions[node.id] = reaction
    }
    return Analysis(
      members: memberResults, displacement: displacements, reactionsKN: reactions,
      maxDisplacementMM: displacements.values.map { hypot($0.x, $0.y) * 1000 }.max() ?? 0,
      maxUtilization: memberResults.values.map(\.utilization).max() ?? 0, residualN: residual,
      appliedLoadsKN: applied,
      maxCapacityUtilization: memberResults.values.map(\.capacityUtilization).max() ?? 0,
      maxVerticalMM: displacements.values.map { abs($0.y) * 1000 }.max() ?? 0,
      missingBucklingChecks: design.members.filter {
        $0.inertiaCM4 == nil && (memberResults[$0.id]?.forceKN ?? 0) < -0.001
      }.count)
  }
}

public struct DesignHistory {
  public private(set) var undoStack: [Design] = []
  public private(set) var redoStack: [Design] = []
  public init() {}
  public mutating func record(_ design: Design) {
    undoStack.append(design)
    if undoStack.count > 100 { undoStack.removeFirst() }
    redoStack.removeAll()
  }
  public mutating func undo(_ current: Design) -> Design? {
    guard let previous = undoStack.popLast() else { return nil }
    redoStack.append(current)
    return previous
  }
  public mutating func redo(_ current: Design) -> Design? {
    guard let next = redoStack.popLast() else { return nil }
    undoStack.append(current)
    return next
  }
}
