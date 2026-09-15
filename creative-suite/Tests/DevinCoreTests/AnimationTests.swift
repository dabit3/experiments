import XCTest
@testable import DevinCore

final class AnimationTests: XCTestCase {
    func layer() -> CanvasElement { CanvasElement(kind: .ellipse, name: "Ball", x: 20, y: 40, width: 100, height: 100) }
    func testChannelsAnimateIndependently() {
        var e = layer()
        e.setPropertyKeyframe(.positionX, at: 0, value: 0)
        e.setPropertyKeyframe(.positionX, at: 2, value: 200)
        e.setPropertyKeyframe(.opacity, at: 0, value: 1)
        e.setPropertyKeyframe(.opacity, at: 1, value: 0)
        XCTAssertEqual(e.evaluated(at: 1).x, 100)
        XCTAssertEqual(e.evaluated(at: 1).y, 40)
        XCTAssertEqual(e.evaluated(at: 1).opacity, 0)
        XCTAssertEqual(e.effectiveAnimationChannels.first { $0.property == .positionX }?.keyframes.count, 2)
    }
    func testLegacyMigrationPreservesEverySample() {
        var e = layer()
        var first = Keyframe(time: 0, x: 0, y: 40, scale: 0.5)
        first.interpolation = .easeInOut
        e.keyframes = [first, Keyframe(time: 2, x: 200, y: 160, rotation: 90, opacity: 0.5, scale: 2)]
        let samples = stride(from: 0.0, through: 2, by: 0.125).map { e.evaluated(at: $0) }
        e.migrateAnimationChannels()
        for (index, time) in stride(from: 0.0, through: 2, by: 0.125).enumerated() {
            let current = e.evaluated(at: time)
            XCTAssertEqual(current.x, samples[index].x, accuracy: 0.0001)
            XCTAssertEqual(current.width, samples[index].width, accuracy: 0.0001)
            XCTAssertEqual(current.opacity, samples[index].opacity, accuracy: 0.0001)
        }
    }
    func testDisablingChannelPreservesCurrentPose() {
        var e = layer()
        e.setPropertyKeyframe(.scale, at: 0, value: 1)
        e.setPropertyKeyframe(.scale, at: 2, value: 3)
        e.disableAnimation(.scale, at: 1)
        XCTAssertEqual(e.evaluated(at: 0).width, 200)
        XCTAssertFalse(e.hasAnimation)
    }
    func testKeyframeCollisionReplacesRatherThanDuplicates() {
        var e = layer()
        e.setPropertyKeyframe(.rotation, at: 1, value: 45)
        let id = e.effectiveAnimationChannels[0].keyframes[0].id
        e.setPropertyKeyframe(.rotation, at: 1, value: 90)
        XCTAssertEqual(e.effectiveAnimationChannels[0].keyframes.count, 1)
        XCTAssertEqual(e.effectiveAnimationChannels[0].keyframes[0].id, id)
    }
    func testPlaybackStopsOnLastVisibleFrame() {
        let area = WorkArea(start: 1, end: 2)
        let result = area.advanced(from: 1.99, by: 0.1, fps: 24, loop: false)
        XCTAssertFalse(result.playing)
        XCTAssertEqual(result.time, 47.0 / 24, accuracy: 0.0001)
        let looped = area.advanced(from: 1.99, by: 0.1, fps: 24, loop: true)
        XCTAssertTrue(looped.playing)
        XCTAssertEqual(looped.time, 1.09, accuracy: 0.0001)
    }
    func testChannelAndWorkAreaRoundTrip() throws {
        var document = CreativeDocument(title: "Animation", tool: .motion)
        var e = layer(); e.setPropertyKeyframe(.opacity, at: 1, value: 0.5)
        document.elements = [e]; document.workArea = WorkArea(start: 1, end: 3)
        XCTAssertEqual(try CreativeDocument.load(from: document.encoded()), document)
        document.workArea = WorkArea(start: 2, end: 1)
        XCTAssertThrowsError(try document.encoded())
    }
}
