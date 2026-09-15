import XCTest
@testable import DevinCore

final class RasterAlgorithmTests: XCTestCase {
    func testContiguousSelectionDoesNotCrossDifferentColors() throws {
        let grid = try RasterGrid(width: 3, height: 1, rgba: [255,0,0,255, 0,0,255,255, 255,0,0,255])
        XCTAssertEqual(grid.region(x: 0, y: 0, tolerance: 0, contiguous: true), [255, 0, 0])
        XCTAssertEqual(grid.region(x: 0, y: 0, tolerance: 0, contiguous: false), [255, 0, 255])
    }
    func testToleranceAndAlphaArePartOfRegionMatching() throws {
        let grid = try RasterGrid(width: 3, height: 1, rgba: [100,100,100,255, 108,100,100,255, 108,100,100,0])
        XCTAssertEqual(grid.region(x: 0, y: 0, tolerance: 10, contiguous: true), [255,255,0])
        XCTAssertEqual(grid.region(x: -1, y: 0, tolerance: 10, contiguous: true), [0,0,0])
    }
    func testGradientEndpointsAndDegenerateDrag() {
        XCTAssertEqual(RasterGrid.gradientFraction(at: Point2D(0, 0), from: Point2D(0, 0), to: Point2D(10, 0), radial: false), 0)
        XCTAssertEqual(RasterGrid.gradientFraction(at: Point2D(5, 0), from: Point2D(0, 0), to: Point2D(10, 0), radial: false), 0.5)
        XCTAssertEqual(RasterGrid.gradientFraction(at: Point2D(10, 0), from: Point2D(0, 0), to: Point2D(10, 0), radial: true), 1)
        XCTAssertEqual(RasterGrid.gradientFraction(at: Point2D(0, 0), from: Point2D(0, 0), to: Point2D(0, 0), radial: false), 0)
    }
    func testRasterDimensionsAreValidated() {
        XCTAssertThrowsError(try RasterGrid(width: 2, height: 2, rgba: [0]))
        XCTAssertThrowsError(try RasterGrid(width: Int.max, height: 2, rgba: []))
    }
    func testLedgerHasUniqueFeatureIDsAndNoUnsupportedParityClaims() {
        let all = ParityLedger.all
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertEqual(Set(all.map(\.tool)).count, StudioTool.allCases.count)
        XCTAssertTrue(all.allSatisfy { $0.acceptance.count >= 5 && URL(string: $0.reference)?.host == "helpx.adobe.com" })
        XCTAssertTrue(all.filter { $0.status == .verified }.allSatisfy { !$0.comparisonEvidence.isEmpty })
        XCTAssertGreaterThan(ParityLedger.features(.pixel).count, 100)
        XCTAssertGreaterThan(ParityLedger.features(.motion).count, 70)
    }
}
