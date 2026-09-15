import XCTest
@testable import DevinCore

final class ProfessionalTests: XCTestCase {
    func testLegacySequenceKeepsItsOrder() {
        let a = MediaClip(url: URL(fileURLWithPath: "/tmp/a.mov"), duration: 4)
        let b = MediaClip(url: URL(fileURLWithPath: "/tmp/b.mov"), duration: 3)
        let entries = SequenceLayout.entries([a, b])
        XCTAssertEqual(entries.map(\.position), [0, 4])
        XCTAssertEqual(SequenceLayout.duration([a, b]), 7)
    }
    func testMultitrackDurationIncludesGapsAndOverlaps() {
        var a = MediaClip(url: URL(fileURLWithPath: "/tmp/a.mov"), duration: 4)
        var b = MediaClip(url: URL(fileURLWithPath: "/tmp/b.mov"), duration: 3)
        a.timelineStart = 2; b.timelineStart = 3; b.trackIndex = 1
        XCTAssertEqual(SequenceLayout.duration([a, b]), 6)
        XCTAssertEqual(SequenceLayout.entries([a, b])[1].track, 1)
    }
    func testTimelineSplitPreservesSourceAndSequenceRanges() throws {
        var clip = MediaClip(url: URL(fileURLWithPath: "/tmp/a.mov"), duration: 10)
        clip.start = 2; clip.end = 8; clip.timelineStart = 5; clip.trackIndex = 2
        let pieces = try SequenceLayout.split(clip, at: 7, position: 5)
        XCTAssertEqual(pieces.0.start, 2); XCTAssertEqual(pieces.0.end, 4)
        XCTAssertEqual(pieces.1.start, 4); XCTAssertEqual(pieces.1.end, 8)
        XCTAssertEqual(pieces.1.timelineStart, 7); XCTAssertEqual(pieces.1.trackIndex, 2)
        XCTAssertNotEqual(pieces.0.id, pieces.1.id)
        XCTAssertThrowsError(try SequenceLayout.split(clip, at: 4, position: 5))
    }
    func testBezierSVGPreservesCurvesAndClosedFill() {
        var document = CreativeDocument(title: "Bezier", tool: .form)
        var layer = CanvasElement(kind: .path, name: "Curve", x: 0, y: 0, width: 100, height: 100)
        layer.vectorPath = [VectorCommand(.move, Point2D(0, 0)), VectorCommand(.curve, Point2D(100, 100), control1: Point2D(20, 0), control2: Point2D(80, 100)), VectorCommand(.close, Point2D(0, 0))]
        document.elements = [layer]
        let svg = SVGExporter.render(document)
        XCTAssertTrue(svg.contains("C 20.0 0.0 80.0 100.0 100.0 100.0"))
        XCTAssertTrue(svg.contains(" Z"))
        XCTAssertFalse(svg.contains("polyline"))
    }
    func testNewPropertiesRoundTripAndOldDocumentsStillLoad() throws {
        var document = CreativeDocument(title: "Compatible", tool: .pixel)
        var layer = CanvasElement(kind: .rectangle, name: "Layer", x: 0, y: 0, width: 100, height: 100)
        document.elements = [layer]
        let oldData = try document.encoded()
        XCTAssertEqual(try CreativeDocument.load(from: oldData), document)
        layer.blendMode = .multiply; layer.inPoint = 1; layer.outPoint = 4
        layer.typography = Typography(alignment: .center, leading: 1.5, tracking: 2)
        document.elements = [layer]; document.pageSettings = PageSettings()
        XCTAssertEqual(try CreativeDocument.load(from: document.encoded()), document)
    }
    func testVersionOneProjectsUpgradeWithoutLosingLayers() throws {
        var legacy = CreativeDocument(title: "Legacy", tool: .pixel)
        legacy.version = 1
        legacy.elements = [CanvasElement(kind: .rectangle, name: "Layer", x: 0, y: 0, width: 100, height: 100)]
        let data = try JSONEncoder().encode(legacy)
        let upgraded = try CreativeDocument.load(from: data)
        XCTAssertEqual(upgraded.version, 3)
        XCTAssertEqual(upgraded.elements, legacy.elements)
        let saved = try JSONSerialization.jsonObject(with: upgraded.encoded()) as! [String: Any]
        XCTAssertEqual(saved["version"] as? Int, 3)
    }
    func testPoseEditsKeepInterpolation() {
        var layer = CanvasElement(kind: .ellipse, name: "Ball", x: 0, y: 0, width: 100, height: 100)
        var frame = Keyframe(time: 0, x: 0, y: 0)
        frame.interpolation = .easeInOut
        layer.keyframes = [frame]
        layer.setPose(at: 0, x: 50, y: 50, rotation: 0, opacity: 1)
        XCTAssertEqual(layer.keyframes[0].interpolation, .easeInOut)
        XCTAssertEqual(layer.keyframes[0].id, frame.id)
    }
    func testHoldAndEaseInterpolation() {
        var layer = CanvasElement(kind: .ellipse, name: "Ball", x: 0, y: 0, width: 100, height: 100)
        var start = Keyframe(time: 0, x: 0, y: 0)
        start.interpolation = .hold
        layer.keyframes = [start, Keyframe(time: 2, x: 100, y: 100)]
        XCTAssertEqual(layer.evaluated(at: 1).x, 0)
        layer.keyframes[0].interpolation = .easeInOut
        XCTAssertEqual(layer.evaluated(at: 0.5).x, 15.625, accuracy: 0.001)
        XCTAssertEqual(layer.evaluated(at: 2).x, 100)
    }
    func testInvalidNewPropertiesAreRejected() {
        var document = CreativeDocument(title: "Invalid", tool: .cut)
        var clip = MediaClip(url: URL(fileURLWithPath: "/tmp/a.mov"), duration: 4)
        clip.timelineStart = -1; document.clips = [clip]
        XCTAssertThrowsError(try document.encoded())
        clip.timelineStart = 0; clip.trackIndex = 100; document.clips = [clip]
        XCTAssertThrowsError(try document.encoded())
        document.clips = []
        var layer = CanvasElement(kind: .rectangle, name: "Layer", x: 0, y: 0, width: 100, height: 100)
        layer.inPoint = 4; layer.outPoint = 1; document.elements = [layer]
        XCTAssertThrowsError(try document.encoded())
    }
    func testTextFrameCyclesAreRejected() {
        var document = CreativeDocument(title: "Text", tool: .press)
        var a = CanvasElement(kind: .text, name: "A", x: 0, y: 0, width: 100, height: 100)
        var b = CanvasElement(kind: .text, name: "B", x: 200, y: 0, width: 100, height: 100)
        a.nextTextFrame = b.id; b.nextTextFrame = a.id; document.elements = [a, b]
        XCTAssertThrowsError(try document.encoded())
    }
}
