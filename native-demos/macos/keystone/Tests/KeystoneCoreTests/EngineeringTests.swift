import Foundation
import XCTest

@testable import KeystoneCore

final class EngineeringTests: XCTestCase {
  func testHorizontalLoadAndSelfWeightBalance() throws {
    var design = Design.example()
    design.nodes[2].loadXKN = 40
    design.loadCases[0].includesSelfWeight = true
    let result = try Solver.solve(design)
    let reactions = result.reactionsKN.values.reduce(SIMD2<Double>.zero, +)
    let loads = result.appliedLoadsKN.values.reduce(SIMD2<Double>.zero, +)
    XCTAssertEqual(reactions.x, -40, accuracy: 1e-8)
    XCTAssertEqual(reactions.y, 100 + design.massKg * 9.80665 / 1000, accuracy: 1e-8)
    XCTAssertEqual(loads.x + reactions.x, 0, accuracy: 1e-8)
    XCTAssertEqual(loads.y + reactions.y, 0, accuracy: 1e-8)
  }

  func testIndependentCasesAndFactoring() throws {
    var design = Design.example()
    let baseline = try Solver.solve(design)
    let wind = LoadCase(
      name: "Wind", factor: 1.5,
      loads: [
        NodalLoad(nodeID: 7, xKN: -30, downKN: -25)
      ])
    design.loadCases.append(wind)
    design.activeCaseID = wind.id
    let result = try Solver.solve(design)
    XCTAssertEqual(result.appliedLoadsKN[2], .zero)
    XCTAssertEqual(result.appliedLoadsKN[7], SIMD2(-45, 37.5))
    XCTAssertEqual(result.reactionsKN.values.reduce(0) { $0 + $1.x }, 45, accuracy: 1e-8)
    XCTAssertEqual(result.reactionsKN.values.reduce(0) { $0 + $1.y }, -37.5, accuracy: 1e-8)
    design.activeCaseID = "service"
    XCTAssertEqual(
      try Solver.solve(design).maxDisplacementMM, baseline.maxDisplacementMM, accuracy: 1e-10)
    design.loadCases[0].factor = 2
    XCTAssertEqual(
      try Solver.solve(design).maxDisplacementMM, baseline.maxDisplacementMM * 2, accuracy: 1e-10)
  }

  func testSectionGeometryAndEulerEffectiveLengthScaling() throws {
    let section = SectionPreset.catalog[1]
    XCTAssertEqual(section.areaCM2, 19, accuracy: 1e-12)
    XCTAssertEqual(section.inertiaCM4, (pow(100.0, 4) - pow(90.0, 4)) / 120000, accuracy: 1e-10)
    var design = Design.example()
    for i in design.members.indices { design.members[i].apply(section) }
    let result = try Solver.solve(design)
    let member = try XCTUnwrap(design.members.first { (result.members[$0.id]?.forceKN ?? 0) < -1 })
    let first = try XCTUnwrap(result.members[member.id])
    let expected =
      Double.pi * Double.pi * 200e9 * section.inertiaCM4 * 1e-8
      / pow(design.length(member), 2) / 1000
    XCTAssertEqual(try XCTUnwrap(first.eulerCriticalKN), expected, accuracy: 1e-9)
    XCTAssertEqual(result.missingBucklingChecks, 0)
    let index = try XCTUnwrap(design.members.firstIndex { $0.id == member.id })
    design.members[index].effectiveLengthFactor = 2
    let second = try XCTUnwrap(Solver.solve(design).members[member.id])
    XCTAssertEqual(try XCTUnwrap(second.eulerCriticalKN), expected / 4, accuracy: 1e-9)
    XCTAssertEqual(second.forceKN, first.forceKN, accuracy: 1e-9)
    XCTAssertEqual(second.governingMode, "Euler buckling")
    XCTAssertEqual(
      second.capacityUtilization, abs(first.forceKN) * design.resistanceFactor / (expected / 4),
      accuracy: 1e-9)
  }

  func testMissingInertiaIsNotReportedAsCompleteCheck() throws {
    let design = Design.example()
    let result = try Solver.solve(design)
    XCTAssertGreaterThan(result.missingBucklingChecks, 0)
    XCTAssertEqual(design.allowedVerticalMM, 12_000.0 / 360, accuracy: 1e-10)
    XCTAssertTrue(DesignExport.report(design, analysis: result).contains("buckling unchecked"))
  }

  func testVersionOneMigrationAndVersionTwoRoundTrip() throws {
    let legacy = """
      {"version":1,"name":"Legacy","nodes":[{"id":0,"x":0,"y":0,"support":"Pin · X + Y","loadKN":0},{"id":1,"x":2,"y":0,"support":"Roller · Y","loadKN":15}],"members":[{"id":0,"a":0,"b":1,"areaCM2":20}],"material":{"name":"Steel","modulusGPa":200,"yieldMPa":250,"density":7850,"costPerKg":2.4},"budget":2500}
      """
    let migrated = try DesignExport.decode(Data(legacy.utf8))
    XCTAssertEqual(migrated.version, 2)
    XCTAssertEqual(migrated.nodes[1].loadXKN, 0)
    XCTAssertEqual(migrated.nodalLoad(1).downKN, 15)
    XCTAssertNil(migrated.members[0].inertiaCM4)
    var design = Design.example()
    design.projectNote = "Concept review"
    design.members[0].apply(SectionPreset.catalog[2])
    let loadCase = LoadCase(
      name: "Uplift", includesSelfWeight: true, loads: [NodalLoad(nodeID: 2, downKN: -75)])
    design.loadCases.append(loadCase)
    design.activeCaseID = loadCase.id
    XCTAssertEqual(try DesignExport.decode(DesignExport.json(design)), design)
    var draft = design
    draft.nodes = []
    draft.members = []
    draft.loadCases = [.service]
    draft.activeCaseID = "service"
    XCTAssertEqual(try DesignExport.decode(DesignExport.json(draft)), draft)
    XCTAssertThrowsError(try Solver.solve(draft))
  }

  func testInvalidCaseAndSectionDataAreRejected() {
    var design = Design.example()
    design.loadCases[0].factor = .nan
    XCTAssertThrowsError(try design.validated())
    design = .example()
    design.activeCaseID = "missing"
    XCTAssertThrowsError(try design.validated())
    design = .example()
    design.loadCases.append(LoadCase(name: "Bad", loads: [NodalLoad(nodeID: 999, downKN: 1)]))
    XCTAssertThrowsError(try design.validated())
    design = .example()
    design.members[0].inertiaCM4 = -1
    XCTAssertThrowsError(try design.validated())
    design = .example()
    design.nodes[0].id = Int.max
    XCTAssertThrowsError(try design.validated())
  }

  func testExportSignsAndNumericSchedules() throws {
    var design = Design.example()
    design.setLoad(NodalLoad(nodeID: 2, xKN: -20, downKN: -30))
    let result = try Solver.solve(design)
    let svg = DesignExport.svg(design, analysis: result)
    XCTAssertTrue(svg.contains("30.0 kN ↑"))
    XCTAssertTrue(svg.contains("20.0 kN ←"))
    let csv = DesignExport.csv(design, analysis: result)
    XCTAssertTrue(csv.contains("N3,-20.0,30.0,"))
    XCTAssertTrue(csv.contains("Demand capacity ratio"))
    XCTAssertTrue(DesignExport.report(design, analysis: result).contains("Service load"))
  }
}
