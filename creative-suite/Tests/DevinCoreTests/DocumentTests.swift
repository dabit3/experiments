import XCTest
@testable import DevinCore

final class DocumentTests: XCTestCase {
    func testRoundTripPreservesEditableLayers() throws {
        var document = CreativeDocument(title: "Test", tool: .pixel)
        var layer = CanvasElement(kind: .text, name: "Title", x: 12, y: 42, width: 200, height: 100)
        layer.text = "A & B < C"
        layer.keyframes = [Keyframe(time: 0, x: 12, y: 42), Keyframe(time: 2, x: 100, y: 100)]
        document.elements = [layer]
        XCTAssertEqual(try CreativeDocument.load(from: document.encoded()), document)
    }
    func testValidationRejectsInvalidCanvasAndLayer() throws {
        var document = CreativeDocument(title: "Test", tool: .form)
        document.width = -1
        XCTAssertThrowsError(try document.encoded())
        document.width = 1200
        document.elements = [CanvasElement(kind: .rectangle, name: "Bad", x: 0, y: 0, width: -3, height: 50)]
        XCTAssertThrowsError(try document.encoded())
        document.elements[0].width = 30
        document.elements[0].page = 10
        XCTAssertThrowsError(try document.encoded())
    }
    func testDuplicateIDsRejected() {
        var document = CreativeDocument(title: "Test", tool: .form)
        let layer = CanvasElement(kind: .rectangle, name: "Shape", x: 0, y: 0, width: 30, height: 50)
        document.elements = [layer, layer]
        XCTAssertThrowsError(try document.encoded())
    }
    func testHistoryUndoRedoAndBranch() {
        var history = History<Int>(limit: 2)
        history.record(0, replacing: 1)
        history.record(1, replacing: 2)
        history.record(2, replacing: 3)
        XCTAssertEqual(history.undo(3), 2)
        XCTAssertEqual(history.undo(2), 1)
        XCTAssertNil(history.undo(1))
        XCTAssertEqual(history.redo(1), 2)
        history.record(2, replacing: 4)
        XCTAssertTrue(history.redoStack.isEmpty)
        history.record(4, replacing: 4)
        XCTAssertEqual(history.undoStack.count, 2)
    }
    func testKeyframeInterpolationAndClamping() {
        var layer = CanvasElement(kind: .ellipse, name: "Ball", x: 0, y: 0, width: 100, height: 80)
        layer.keyframes = [Keyframe(time: 2, x: 100, y: 200, rotation: 90, opacity: 0.5, scale: 2), Keyframe(time: 0, x: 0, y: 0)]
        let middle = layer.evaluated(at: 1)
        XCTAssertEqual(middle.x, 50)
        XCTAssertEqual(middle.y, 100)
        XCTAssertEqual(middle.width, 150)
        XCTAssertEqual(middle.rotation, 45)
        XCTAssertEqual(middle.opacity, 0.75)
        XCTAssertEqual(layer.evaluated(at: -10).x, 0)
        XCTAssertEqual(layer.evaluated(at: 99).x, 100)
    }
    func testAudioEnvelope() {
        var clip = MediaClip(url: URL(fileURLWithPath: "/tmp/test.wav"), duration: 10)
        clip.start = 2; clip.end = 8; clip.gain = 0.8; clip.fadeIn = 2; clip.fadeOut = 1
        XCTAssertEqual(clip.duration, 6)
        XCTAssertEqual(clip.amplitude(at: 0), 0)
        XCTAssertEqual(clip.amplitude(at: 1), 0.4)
        XCTAssertEqual(clip.amplitude(at: 3), 0.8)
        XCTAssertEqual(clip.amplitude(at: 5.5), 0.4)
        XCTAssertEqual(clip.amplitude(at: 7), 0)
    }
    func testSVGIsEscapedAndFiltersPages() {
        var document = CreativeDocument(title: "Test", tool: .form)
        document.pageCount = 2
        var layer = CanvasElement(kind: .text, name: "Text", x: 0, y: 0, width: 100, height: 100)
        layer.text = "<script>&\"'"
        var hidden = layer; hidden.id = UUID(); hidden.text = "DO_NOT_INCLUDE"; hidden.page = 1
        document.elements = [layer, hidden]
        let svg = SVGExporter.render(document)
        XCTAssertTrue(svg.contains("&lt;script&gt;&amp;&quot;&apos;"))
        XCTAssertFalse(svg.contains("DO_NOT_INCLUDE"))
        XCTAssertTrue(svg.hasSuffix("</svg>"))
    }
    func testClipRangeValidation() {
        var document = CreativeDocument(title: "Test", tool: .cut)
        var clip = MediaClip(url: URL(fileURLWithPath: "/tmp/clip.mov"), duration: 10)
        clip.end = 11
        document.clips = [clip]
        XCTAssertThrowsError(try document.encoded())
        clip.end = 8; clip.start = 9; document.clips = [clip]
        XCTAssertThrowsError(try document.encoded())
    }
    func testCropMovesLayersAndKeyframesWithoutDiscardingImageData() throws {
        var document = CreativeDocument(title: "Crop", tool: .pixel)
        var layer = CanvasElement(kind: .image, name: "Photo", x: 100, y: 80, width: 800, height: 600)
        layer.imageData = Data([1, 2, 3])
        layer.keyframes = [Keyframe(time: 0, x: 100, y: 80)]
        document.elements = [layer]
        try document.crop(x: 40, y: 20, width: 600, height: 400)
        XCTAssertEqual(document.width, 600)
        XCTAssertEqual(document.height, 400)
        XCTAssertEqual(document.elements[0].x, 60)
        XCTAssertEqual(document.elements[0].keyframes[0].y, 60)
        XCTAssertEqual(document.elements[0].imageData, layer.imageData)
        XCTAssertThrowsError(try document.crop(x: 0, y: 0, width: 4, height: 10))
    }
    func testKeyframeUpsertKeepsScaleAndReplacesNearbyFrame() {
        var layer = CanvasElement(kind: .ellipse, name: "Ball", x: 0, y: 0, width: 100, height: 100)
        layer.keyframes = [Keyframe(time: 0, x: 0, y: 0, scale: 1), Keyframe(time: 2, x: 100, y: 100, scale: 2)]
        layer.setPose(at: 1, x: 80, y: 90, rotation: 45, opacity: 0.7)
        XCTAssertEqual(layer.keyframes.count, 3)
        XCTAssertEqual(layer.evaluated(at: 1).width, 150)
        layer.setPose(at: 1.001, x: 90, y: 95, rotation: 45, opacity: 0.7, tolerance: 0.01)
        XCTAssertEqual(layer.keyframes.count, 3)
        XCTAssertEqual(layer.evaluated(at: 1.001).x, 90)
    }
    func testValidationRejectsExtremeKeyframesAndDuplicateObjects() {
        var document = CreativeDocument(title: "Invalid", tool: .motion)
        var layer = CanvasElement(kind: .ellipse, name: "Ball", x: 0, y: 0, width: 100, height: 100)
        layer.keyframes = [Keyframe(time: 1, x: 1e100, y: 0)]
        document.elements = [layer]
        XCTAssertThrowsError(try document.encoded())
        document.elements = []
        let object = SpatialObject(name: "Sphere", primitive: "sphere")
        document.objects = [object, object]
        XCTAssertThrowsError(try document.encoded())
    }
    func testEveryToolHasUniqueIdentity() {
        XCTAssertEqual(StudioTool.allCases.count, 12)
        XCTAssertEqual(Set(StudioTool.allCases.map(\.monogram)).count, 12)
        XCTAssertEqual(StudioTool.allCases.filter(\.isCanvas).count, 6)
    }
}
