import XCTest
@testable import DevinCore

final class VectorPathTests: XCTestCase {
    let start = Point2D(0, 0)
    let end = Point2D(1200, 0)
    var cubic: [VectorCommand] {
        [.init(.move, start), .init(.curve, end, control1: Point2D(0, 900), control2: Point2D(1200, 900))]
    }
    func evaluate(_ start: Point2D, _ command: VectorCommand, _ t: Double) -> Point2D {
        let a = command.control1 ?? command.point, b = command.control2 ?? command.point, u = 1 - t
        return Point2D(u * u * u * start.x + 3 * u * u * t * a.x + 3 * u * t * t * b.x + t * t * t * command.point.x,
                       u * u * u * start.y + 3 * u * u * t * a.y + 3 * u * t * t * b.y + t * t * t * command.point.y)
    }
    func assertPoint(_ a: Point2D, _ b: Point2D, accuracy: Double = 0.000001, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.x, b.x, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(a.y, b.y, accuracy: accuracy, file: file, line: line)
    }
    func testInsertionPreservesCubicBetweenCoarseSamples() throws {
        for t in [0.123, 0.37, 0.5, 0.877] {
            var path = cubic
            let target = evaluate(start, path[1], t)
            XCTAssertTrue(VectorPathEditor.addAnchor(to: &path, at: target, tolerance: 0.01))
            guard path.count == 3 else { XCTFail("Insertion must split the cubic"); continue }
            assertPoint(path[1].point, target)
            for step in 0...100 {
                let s = Double(step) / 100
                let actual = s <= t ? evaluate(start, path[1], s / t) : evaluate(path[1].point, path[2], (s - t) / (1 - t))
                assertPoint(actual, evaluate(start, cubic[1], s))
            }
        }
    }
    func testInsertionProjectsLinesAndSplitsClosingEdge() {
        var path: [VectorCommand] = [.init(.move, start), .init(.line, Point2D(100, 0)), .init(.line, Point2D(100, 100)), .init(.close, start)]
        XCTAssertTrue(VectorPathEditor.addAnchor(to: &path, at: Point2D(40, 2), tolerance: 3))
        XCTAssertEqual(path[1], VectorCommand(.line, Point2D(40, 0)))
        XCTAssertTrue(VectorPathEditor.addAnchor(to: &path, at: Point2D(50, 50), tolerance: 1))
        XCTAssertEqual(path[path.count - 2], VectorCommand(.line, Point2D(50, 50)))
        XCTAssertEqual(path.last?.verb, .close)
    }
    func testInsertionRejectsEndpointsDegeneracyAndInvalidGeometry() {
        for target in [start, end, Point2D(5000, 5000)] {
            var path = cubic
            XCTAssertFalse(VectorPathEditor.addAnchor(to: &path, at: target, tolerance: 1))
            XCTAssertEqual(path, cubic)
        }
        var zero: [VectorCommand] = [.init(.move, start), .init(.line, start)]
        let original = zero
        XCTAssertFalse(VectorPathEditor.addAnchor(to: &zero, at: start))
        XCTAssertEqual(zero, original)
        var malformed: [VectorCommand] = [.init(.line, start), .init(.line, end)]
        XCTAssertFalse(VectorPathEditor.addAnchor(to: &malformed, at: Point2D(600, 0)))
        var path = cubic
        XCTAssertFalse(VectorPathEditor.addAnchor(to: &path, at: Point2D(.nan, 0)))
        XCTAssertFalse(VectorPathEditor.addAnchor(to: &path, at: start, tolerance: .infinity))
        XCTAssertFalse(VectorPathEditor.deleteAnchor(from: &path, at: start, tolerance: -1))
    }
    func testMissingControlsMatchRendererAndSVGDefaults() {
        var path: [VectorCommand] = [.init(.move, start), .init(.curve, end)]
        let original = path
        let target = evaluate(start, path[1], 0.37)
        XCTAssertTrue(VectorPathEditor.addAnchor(to: &path, at: target, tolerance: 0.01))
        guard path.count == 3 else { return XCTFail("Expected cubic split") }
        assertPoint(evaluate(start, path[1], 0.5), evaluate(start, original[1], 0.185))
    }
    func testDeleteEndpointsAndNeverMergeAcrossSubpaths() {
        let second: [VectorCommand] = [.init(.move, Point2D(200, 200)), .init(.curve, Point2D(300, 200), control1: Point2D(220, 180), control2: Point2D(280, 180))]
        var path: [VectorCommand] = [.init(.move, start), .init(.line, Point2D(100, 0))] + second
        XCTAssertTrue(VectorPathEditor.deleteAnchor(from: &path, at: Point2D(100, 0)))
        XCTAssertEqual(path, [.init(.move, start)] + second)
        XCTAssertTrue(VectorPathEditor.deleteAnchor(from: &path, at: start))
        XCTAssertEqual(path, second)
        XCTAssertTrue(VectorPathEditor.deleteAnchor(from: &path, at: second[0].point))
        XCTAssertEqual(path, [.init(.move, second[1].point)])
    }
    func testDeleteReconnectsNeighborsWithoutRemovingSubpath() {
        var path: [VectorCommand] = [.init(.move, start), .init(.curve, Point2D(50, 50), control1: Point2D(10, 20), control2: Point2D(40, 40)), .init(.curve, Point2D(100, 0), control1: Point2D(60, 40), control2: Point2D(90, 20))]
        XCTAssertTrue(VectorPathEditor.deleteAnchor(from: &path, at: Point2D(50, 50)))
        XCTAssertEqual(path, [.init(.move, start), .init(.curve, Point2D(100, 0), control1: Point2D(10, 20), control2: Point2D(90, 20))])
    }
    func testDeleteClosedStartAndExplicitSeam() {
        for explicit in [false, true] {
            var path: [VectorCommand] = [.init(.move, start), .init(.line, Point2D(100, 0)), .init(.line, Point2D(100, 100))]
            if explicit { path.append(.init(.curve, start, control1: Point2D(50, 100), control2: Point2D(0, 50))) }
            path.append(.init(.close, start))
            XCTAssertTrue(VectorPathEditor.deleteAnchor(from: &path, at: start))
            XCTAssertEqual(path.first, .init(.move, Point2D(100, 0)))
            XCTAssertEqual(path.last?.verb, .close)
            XCTAssertFalse(path.dropFirst().dropLast().contains { $0.point == start })
        }
    }
    func testConvertClickCollapsesOnlyHandlesOwnedByAnchor() {
        var path: [VectorCommand] = [.init(.move, start), .init(.curve, Point2D(100, 100), control1: Point2D(10, 20), control2: Point2D(80, 90)), .init(.curve, Point2D(200, 0), control1: Point2D(120, 110), control2: Point2D(180, 10))]
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: Point2D(100, 100)))
        XCTAssertEqual(path[1].control1, Point2D(10, 20))
        XCTAssertEqual(path[1].control2, Point2D(100, 100))
        XCTAssertEqual(path[2].control1, Point2D(100, 100))
        XCTAssertEqual(path[2].control2, Point2D(180, 10))
        let corner = path
        XCTAssertFalse(VectorPathEditor.convertAnchor(in: &path, at: Point2D(100, 100)))
        XCTAssertEqual(path, corner)
    }
    func testConvertDragCreatesSymmetricHandlesAndKeepsNeighborControls() {
        var path: [VectorCommand] = [.init(.move, start), .init(.line, Point2D(100, 100)), .init(.curve, Point2D(200, 0), control1: Point2D(120, 110), control2: Point2D(180, 10))]
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: Point2D(100, 100), outgoing: Point2D(130, 80)))
        XCTAssertEqual(path[1], .init(.curve, Point2D(100, 100), control1: start, control2: Point2D(70, 120)))
        XCTAssertEqual(path[2].control1, Point2D(130, 80))
        XCTAssertEqual(path[2].control2, Point2D(180, 10))
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: start, outgoing: Point2D(20, 0)))
        XCTAssertEqual(path[1].control1, Point2D(20, 0))
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: Point2D(200, 0), outgoing: Point2D(230, 20)))
        XCTAssertEqual(path[2].control2, Point2D(170, -20))
    }
    func testConvertClosedSeamAndLastAnchorPreservesOtherSubpath() {
        let other: [VectorCommand] = [.init(.move, Point2D(500, 500)), .init(.line, Point2D(600, 500))]
        var path: [VectorCommand] = [.init(.move, start), .init(.line, Point2D(100, 0)), .init(.line, Point2D(100, 100)), .init(.close, start)] + other
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: start, outgoing: Point2D(30, -20)))
        XCTAssertEqual(path[1].control1, Point2D(30, -20))
        XCTAssertEqual(path[3], .init(.curve, start, control1: Point2D(100, 100), control2: Point2D(-30, 20)))
        XCTAssertEqual(Array(path.suffix(2)), other)
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: start))
        XCTAssertEqual(path[1].control1, start)
        XCTAssertEqual(path[3].control2, start)
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: Point2D(100, 100), outgoing: Point2D(120, 90)))
        XCTAssertEqual(path[2].control2, Point2D(80, 110))
        XCTAssertEqual(path[3].control1, Point2D(120, 90))
        XCTAssertEqual(Array(path.suffix(2)), other)
    }
    func testEditsRejectInvalidControlsAndCoordinateOverflowAtomically() {
        var path = cubic
        XCTAssertFalse(VectorPathEditor.convertAnchor(in: &path, at: start, outgoing: Point2D(.infinity, 0)))
        XCTAssertEqual(path, cubic)
        var boundary: [VectorCommand] = [.init(.move, Point2D(999999, 0)), .init(.line, Point2D(999999, 100))]
        let original = boundary
        XCTAssertFalse(VectorPathEditor.convertAnchor(in: &boundary, at: Point2D(999999, 100), outgoing: Point2D(-999999, 100)))
        XCTAssertEqual(boundary, original)
        var invalid: [VectorCommand] = [.init(.move, start), .init(.curve, end, control1: Point2D(1000001, 0))]
        let invalidBefore = invalid
        XCTAssertFalse(VectorPathEditor.deleteAnchor(from: &invalid, at: start))
        XCTAssertFalse(VectorPathEditor.convertAnchor(in: &invalid, at: start))
        XCTAssertEqual(invalid, invalidBefore)
    }
    func testMovingAnAnchorCarriesOnlyItsAttachedHandles() {
        var path: [VectorCommand] = [.init(.move, start), .init(.curve, Point2D(100, 100), control1: Point2D(10, 20), control2: Point2D(80, 90)), .init(.curve, Point2D(200, 0), control1: Point2D(120, 110), control2: Point2D(180, 10))]
        XCTAssertTrue(VectorPathEditor.moveNode(in: &path, at: 1, to: Point2D(110, 120)))
        XCTAssertEqual(path[1].point, Point2D(110, 120))
        XCTAssertEqual(path[1].control2, Point2D(90, 110))
        XCTAssertEqual(path[2].control1, Point2D(130, 130))
        XCTAssertEqual(path[1].control1, Point2D(10, 20))
        XCTAssertEqual(path[2].control2, Point2D(180, 10))
    }
    func testMovingClosedSeamKeepsItClosedAndPreservesOtherSubpaths() {
        let other: [VectorCommand] = [.init(.move, Point2D(500, 500)), .init(.line, Point2D(600, 500))]
        var path: [VectorCommand] = [.init(.move, start), .init(.curve, Point2D(100, 0), control1: Point2D(20, 10), control2: Point2D(80, 10)), .init(.curve, start, control1: Point2D(80, 90), control2: Point2D(0, 30)), .init(.close, start)] + other
        XCTAssertTrue(VectorPathEditor.moveNode(in: &path, at: 2, to: Point2D(10, 15)))
        XCTAssertEqual(path[0].point, Point2D(10, 15))
        XCTAssertEqual(path[2].point, Point2D(10, 15))
        XCTAssertEqual(path[3].point, Point2D(10, 15))
        XCTAssertEqual(path[1].control1, Point2D(30, 25))
        XCTAssertEqual(path[2].control2, Point2D(10, 45))
        XCTAssertEqual(Array(path.suffix(2)), other)
    }
    func testMovingAControlDoesNotMoveAnchorsOrOtherControls() {
        var path = cubic
        XCTAssertTrue(VectorPathEditor.moveNode(in: &path, at: 1, to: Point2D(50, 50), control: 1))
        XCTAssertEqual(path[1].control1, Point2D(50, 50))
        XCTAssertEqual(path[1].control2, cubic[1].control2)
        XCTAssertEqual(path[1].point, end)
        XCTAssertEqual(path[0].point, start)
    }
    func testMovingNodesRejectsInvalidTargetsAndNoOps() {
        var path = cubic
        for index in [-1, 2] { XCTAssertFalse(VectorPathEditor.moveNode(in: &path, at: index, to: start)) }
        XCTAssertFalse(VectorPathEditor.moveNode(in: &path, at: 0, to: start))
        XCTAssertFalse(VectorPathEditor.moveNode(in: &path, at: 1, to: Point2D(.nan, 0)))
        XCTAssertFalse(VectorPathEditor.moveNode(in: &path, at: 1, to: start, control: 3))
        XCTAssertFalse(VectorPathEditor.moveNode(in: &path, at: 0, to: Point2D(10, 10), control: 1))
        XCTAssertEqual(path, cubic)
    }
    func testEditedGeometryRoundTripsAndExportsEditableCubics() throws {
        var path = cubic
        XCTAssertTrue(VectorPathEditor.addAnchor(to: &path, at: Point2D(600, 675), tolerance: 0.01))
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: path[1].point, outgoing: Point2D(650, 700)))
        var document = CreativeDocument(title: "Edited anchors", tool: .pixel)
        var layer = CanvasElement(kind: .path, name: "Editable", x: 10, y: 20, width: 1200, height: 900)
        layer.rotation = 25; layer.vectorPath = path; document.elements = [layer]
        let reopened = try CreativeDocument.load(from: document.encoded())
        XCTAssertEqual(reopened, document)
        let svg = SVGExporter.render(document)
        XCTAssertTrue(svg.contains(path[1].svg))
        XCTAssertTrue(svg.contains(path[2].svg))
        XCTAssertFalse(svg.contains("<image"))
        document.version = 2
        XCTAssertEqual(try CreativeDocument.load(from: JSONEncoder().encode(document)).elements, document.elements)
    }
}

final class FreeformPathTests: XCTestCase {
    func stroke(_ points: [Point2D], fit: Double = 2) -> FreeformPathStroke {
        var stroke = FreeformPathStroke(curveFit: fit)
        for point in points { XCTAssertTrue(stroke.append(point)) }
        return stroke
    }
    var wave: [Point2D] {
        (0...240).map { Point2D(Double($0), 60 + 30 * sin(Double($0) / 30) + 0.8 * sin(Double($0) * 1.7)) }
    }
    func testCurveFitRangeAndDefault() {
        XCTAssertEqual(FreeformPathStroke.defaultCurveFit, 2)
        XCTAssertEqual(FreeformPathStroke.curveFitRange, 0.5...10)
        for (input, expected) in [(-1.0, 0.5), (0.5, 0.5), (2, 2), (10, 10), (100, 10), (.nan, 2), (.infinity, 2)] {
            XCTAssertEqual(FreeformPathStroke(curveFit: input).curveFit, expected)
        }
    }
    func testSamplingFiltersJitterButPreservesMouseUpEndpoint() throws {
        var value = stroke([Point2D(10, 10), Point2D(10.1, 10.1), Point2D(10, 10), Point2D(30, 20)])
        XCTAssertEqual(value.samples.count, 2)
        let endpoint = Point2D(30.1, 20.1)
        XCTAssertTrue(value.append(endpoint, isFinal: true))
        let path = try XCTUnwrap(value.path(closingDistance: 0))
        XCTAssertEqual(path.first?.point, Point2D(10, 10))
        XCTAssertEqual(path.last?.point, endpoint)
        XCTAssertFalse(path.contains { $0.verb == .close })
    }
    func testSampleLimitCancelsInsteadOfTruncatingThePath() {
        var value = FreeformPathStroke()
        for i in 0..<FreeformPathStroke.maximumSamples { XCTAssertTrue(value.append(Point2D(Double(i), 0))) }
        XCTAssertEqual(value.samples.count, FreeformPathStroke.maximumSamples)
        XCTAssertNotNil(value.path(closingDistance: 0))
        XCTAssertFalse(value.append(Point2D(Double(FreeformPathStroke.maximumSamples), 0), isFinal: true))
        XCTAssertLessThanOrEqual(value.samples.count, FreeformPathStroke.maximumSamples)
        XCTAssertNil(value.path())
        XCTAssertFalse(value.append(Point2D(0, 0)))
    }
    func testCurveFitReducesAnchorsAndCreatesSmoothEditableCubics() throws {
        let fine = try XCTUnwrap(stroke(wave, fit: 0.5).path())
        let coarse = try XCTUnwrap(stroke(wave, fit: 10).path())
        XCTAssertLessThan(coarse.count, fine.count)
        XCTAssertLessThan(fine.count, wave.count)
        for path in [fine, coarse] {
            XCTAssertEqual(path.first?.verb, .move)
            XCTAssertEqual(path.first?.point, wave.first)
            XCTAssertEqual(path.last?.point, wave.last)
            XCTAssertTrue(path.dropFirst().allSatisfy { $0.verb == .curve && $0.control1 != nil && $0.control2 != nil })
            XCTAssertTrue(path.dropFirst().contains { $0.control2 != $0.point })
            for i in 1..<(path.count - 1) {
                let anchor = path[i].point, incoming = try XCTUnwrap(path[i].control2), outgoing = try XCTUnwrap(path[i + 1].control1)
                XCTAssertEqual(anchor.x - incoming.x, outgoing.x - anchor.x, accuracy: 0.000001)
                XCTAssertEqual(anchor.y - incoming.y, outgoing.y - anchor.y, accuracy: 0.000001)
            }
        }
    }
    func testReturningNearStartClosesWithASmoothSeam() throws {
        let circle = (0...60).map { i in
            let angle = Double(i) / 60 * .pi * 2
            return Point2D(80 + 50 * cos(angle), 80 + 50 * sin(angle))
        }
        var value = stroke(Array(circle.dropLast()))
        XCTAssertTrue(value.append(Point2D(132, 81), isFinal: true))
        let path = try XCTUnwrap(value.path(closingDistance: 5))
        XCTAssertEqual(path.last?.verb, .close)
        XCTAssertEqual(path.last?.point, path.first?.point)
        XCTAssertEqual(path[path.count - 2].point, path[0].point)
        let incoming = try XCTUnwrap(path[path.count - 2].control2), outgoing = try XCTUnwrap(path[1].control1), start = path[0].point
        XCTAssertEqual(start.x - incoming.x, outgoing.x - start.x, accuracy: 0.000001)
        XCTAssertEqual(start.y - incoming.y, outgoing.y - start.y, accuracy: 0.000001)
        XCTAssertFalse(try XCTUnwrap(value.path(closingDistance: 1)).contains { $0.verb == .close })
        XCTAssertFalse(try XCTUnwrap(stroke([Point2D(0, 0), Point2D(1, 0)]).path()).contains { $0.verb == .close })
    }
    func testDegenerateAndInvalidInputCannotCreateGeometry() {
        XCTAssertNil(FreeformPathStroke().path())
        XCTAssertNil(stroke(Array(repeating: Point2D(10, 10), count: 20)).path())
        for point in [Point2D(.nan, 0), Point2D(0, .infinity), Point2D(1000001, 0)] {
            var value = stroke([Point2D(0, 0), Point2D(100, 100)])
            XCTAssertFalse(value.append(point))
            XCTAssertNil(value.path())
        }
        let value = stroke(wave)
        XCTAssertNil(value.path(closingDistance: -1))
        XCTAssertNil(value.path(closingDistance: .infinity))
    }
    func testFreeformGeometrySupportsAnchorEditsHistoryAndProjectRoundTrip() throws {
        var path = try XCTUnwrap(stroke(wave).path())
        let anchor = path[1].point
        XCTAssertTrue(VectorPathEditor.convertAnchor(in: &path, at: anchor, tolerance: 0))
        XCTAssertTrue(VectorPathEditor.deleteAnchor(from: &path, at: anchor, tolerance: 0))
        var document = CreativeDocument(title: "Freeform vector", tool: .pixel)
        let original = document
        var element = CanvasElement(kind: .path, name: "Freeform Pen", x: 0, y: 0, width: 240, height: 100)
        element.vectorPath = path; document.elements = [element]
        var history = History<CreativeDocument>()
        history.record(original, replacing: document)
        XCTAssertEqual(history.undo(document), original)
        XCTAssertEqual(history.redo(original), document)
        XCTAssertEqual(try CreativeDocument.load(from: document.encoded()), document)
        let svg = SVGExporter.render(document)
        XCTAssertTrue(svg.contains(path[1].svg))
        XCTAssertFalse(svg.contains("<image"))
        document.version = 2
        XCTAssertEqual(try CreativeDocument.load(from: JSONEncoder().encode(document)).elements, document.elements)
    }
}

