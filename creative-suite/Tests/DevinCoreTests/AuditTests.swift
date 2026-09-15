import XCTest
@testable import DevinCore

final class AuditTests: XCTestCase {
    func testRotatedResizeKeepsOppositeCornerFixed() {
        var layer = CanvasElement(kind: .rectangle, name: "Rotated", x: 100, y: 80, width: 120, height: 60)
        layer.rotation = 37
        let anchor = layer.worldPoint(Point2D(0, 0))
        let resized = layer.resizedBottomRight(to: layer.worldPoint(Point2D(240, 120)), preserveAspect: true)
        let result = resized.worldPoint(Point2D(0, 0))
        XCTAssertEqual(result.x, anchor.x, accuracy: 0.0001)
        XCTAssertEqual(result.y, anchor.y, accuracy: 0.0001)
        XCTAssertEqual(resized.width, 240, accuracy: 0.0001)
    }
    func testPageReorderingPreservesAllLayerIDs() throws {
        var document = CreativeDocument(title: "Frames", tool: .frame)
        document.pageCount = 3
        document.elements = (0..<3).map { CanvasElement(kind: .rectangle, name: "Page \($0)", x: 0, y: 0, width: 100, height: 100, page: $0) }
        let ids = document.elements.map(\.id)
        try document.movePage(from: 0, to: 2)
        XCTAssertEqual(document.elements.map(\.page), [2, 0, 1])
        XCTAssertEqual(document.elements.map(\.id), ids)
    }
    func testMutedAudioEnvelopeIsSilent() {
        var clip = MediaClip(url: URL(fileURLWithPath: "/tmp/audio.wav"), duration: 2)
        clip.muted = true
        XCTAssertEqual(clip.amplitude(at: 1), 0)
    }
    func testFullHTMLDocumentIsNotNested() {
        var document = CreativeDocument(title: "Web", tool: .code)
        document.html = "<!doctype html><html><head><title>Example</title></head><body><h1>Hello</h1></body></html>"
        document.css = "h1 { color: red; }"
        document.javascript = "document.title = 'Ready';"
        let result = document.webSource()
        XCTAssertEqual(result.components(separatedBy: "<html>").count - 1, 1)
        XCTAssertTrue(result.contains(document.css))
        XCTAssertTrue(result.contains(document.javascript))
    }
    func testSVGRespectsTextAlignment() {
        var document = CreativeDocument(title: "Type", tool: .form)
        var text = CanvasElement(kind: .text, name: "Text", x: 0, y: 0, width: 200, height: 80)
        text.typography = Typography(alignment: .center, leading: 1.5, tracking: 10)
        document.elements = [text]
        XCTAssertTrue(SVGExporter.render(document).contains("text-anchor=\"middle\""))
    }
    func testTextFrameCannotHaveTwoIncomingStories() {
        var document = CreativeDocument(title: "Stories", tool: .press)
        var a = CanvasElement(kind: .text, name: "A", x: 0, y: 0, width: 100, height: 100)
        var b = a; b.id = UUID()
        var c = a; c.id = UUID()
        a.nextTextFrame = c.id; b.nextTextFrame = c.id
        document.elements = [a, b, c]
        XCTAssertThrowsError(try document.encoded())
    }
    func testDuplicateKeyframeIDsAreRejected() {
        var document = CreativeDocument(title: "Animation", tool: .motion)
        var element = CanvasElement(kind: .ellipse, name: "Ball", x: 0, y: 0, width: 100, height: 100)
        let frame = Keyframe(time: 0, x: 0, y: 0)
        element.keyframes = [frame, frame]
        document.elements = [element]
        XCTAssertThrowsError(try document.encoded())
    }
    func testExtremeMediaDurationsAreRejected() {
        var document = CreativeDocument(title: "Media", tool: .cut)
        document.assets = [MediaAsset(url: URL(fileURLWithPath: "/tmp/clip.mov"), duration: 1e100, hasVideo: true)]
        XCTAssertThrowsError(try document.encoded())
    }
}
