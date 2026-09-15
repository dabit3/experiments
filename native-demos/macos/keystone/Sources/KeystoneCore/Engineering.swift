import Foundation

public struct NodalLoad: Codable, Equatable, Sendable {
  public var nodeID: Int
  public var xKN: Double
  public var downKN: Double

  public init(nodeID: Int, xKN: Double = 0, downKN: Double = 0) {
    self.nodeID = nodeID
    self.xKN = xKN
    self.downKN = downKN
  }
}

public struct LoadCase: Codable, Equatable, Identifiable, Sendable {
  public var id: String
  public var name: String
  public var factor: Double
  public var includesSelfWeight: Bool
  public var loads: [NodalLoad]?

  public init(
    id: String = UUID().uuidString, name: String, factor: Double = 1,
    includesSelfWeight: Bool = false, loads: [NodalLoad]? = []
  ) {
    self.id = id
    self.name = name
    self.factor = factor
    self.includesSelfWeight = includesSelfWeight
    self.loads = loads
  }

  public static let service = LoadCase(id: "service", name: "Service load", loads: nil)
}

public struct SectionPreset: Identifiable, Sendable {
  public var name: String
  public var outerMM: Double
  public var wallMM: Double
  public var id: String { name }
  public var areaCM2: Double { (pow(outerMM, 2) - pow(outerMM - 2 * wallMM, 2)) / 100 }
  public var inertiaCM4: Double {
    (pow(outerMM, 4) - pow(outerMM - 2 * wallMM, 4)) / 12 / 10000
  }
  public static let catalog = [
    SectionPreset(name: "SHS 80 × 80 × 4", outerMM: 80, wallMM: 4),
    SectionPreset(name: "SHS 100 × 100 × 5", outerMM: 100, wallMM: 5),
    SectionPreset(name: "SHS 120 × 120 × 6", outerMM: 120, wallMM: 6),
    SectionPreset(name: "SHS 150 × 150 × 8", outerMM: 150, wallMM: 8),
    SectionPreset(name: "SHS 200 × 200 × 10", outerMM: 200, wallMM: 10),
  ]
}

extension Design {
  public var activeCase: LoadCase {
    loadCases.first { $0.id == activeCaseID } ?? .service
  }
  public var spanM: Double { (nodes.map(\.x).max() ?? 0) - (nodes.map(\.x).min() ?? 0) }
  public var allowedVerticalMM: Double { spanM * 1000 / deflectionRatio }

  public func nodalLoad(_ id: Int) -> NodalLoad {
    if let loads = activeCase.loads {
      return loads.first { $0.nodeID == id } ?? NodalLoad(nodeID: id)
    }
    return NodalLoad(nodeID: id, xKN: node(id)?.loadXKN ?? 0, downKN: node(id)?.loadKN ?? 0)
  }

  public mutating func setLoad(_ load: NodalLoad) {
    guard let index = loadCases.firstIndex(where: { $0.id == activeCaseID }),
      let nodeIndex = nodes.firstIndex(where: { $0.id == load.nodeID })
    else { return }
    if loadCases[index].loads == nil {
      nodes[nodeIndex].loadXKN = load.xKN
      nodes[nodeIndex].loadKN = load.downKN
    } else {
      loadCases[index].loads?.removeAll { $0.nodeID == load.nodeID }
      if load.xKN != 0 || load.downKN != 0 { loadCases[index].loads?.append(load) }
    }
  }

  public func effectiveLoads() -> [Int: SIMD2<Double>] {
    var loads: [Int: SIMD2<Double>] = [:]
    for node in nodes {
      let load = nodalLoad(node.id)
      loads[node.id] = SIMD2(load.xKN, -load.downKN)
    }
    if activeCase.includesSelfWeight {
      for member in members {
        let halfWeightKN =
          length(member) * member.areaCM2 * 1e-4 * material.density * 9.80665 / 2000
        loads[member.a, default: .zero].y -= halfWeightKN
        loads[member.b, default: .zero].y -= halfWeightKN
      }
    }
    return loads.mapValues { $0 * activeCase.factor }
  }

  func validateLoadCases() throws {
    guard (1...12).contains(loadCases.count),
      Set(loadCases.map(\.id)).count == loadCases.count,
      loadCases.contains(where: { $0.id == activeCaseID }),
      loadCases.filter({ $0.id == "service" && $0.loads == nil }).count == 1
    else {
      throw AnalysisError.invalid("A project needs its service case and a valid active load case.")
    }
    for loadCase in loadCases {
      guard !loadCase.id.isEmpty, loadCase.id.count <= 100,
        !loadCase.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
        loadCase.name.count <= 60, loadCase.factor.isFinite, (0.01...10).contains(loadCase.factor),
        loadCase.id == "service" || loadCase.loads != nil
      else {
        throw AnalysisError.invalid("Case names and load factors (0.01–10) must be valid.")
      }
      if let loads = loadCase.loads {
        guard loads.count <= nodes.count, Set(loads.map(\.nodeID)).count == loads.count,
          loads.allSatisfy({
            node($0.nodeID) != nil && $0.xKN.isFinite && $0.downKN.isFinite
              && abs($0.xKN) <= 10000 && abs($0.downKN) <= 10000
          })
        else {
          throw AnalysisError.invalid("Case loads need unique existing nodes and finite forces.")
        }
      }
    }
  }
}
