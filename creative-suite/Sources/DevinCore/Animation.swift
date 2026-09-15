import Foundation

public enum AnimationProperty: String, Codable, CaseIterable, Sendable {
    case positionX, positionY, scale, rotation, opacity
    public var title: String {
        switch self { case .positionX: return "Position X"; case .positionY: return "Position Y"; case .scale: return "Scale"; case .rotation: return "Rotation"; case .opacity: return "Opacity" }
    }
    public var limits: ClosedRange<Double> {
        switch self { case .opacity: return 0...1; case .scale: return 0.001...100; default: return -1_000_000...1_000_000 }
    }
    public func value(in frame: Keyframe) -> Double {
        switch self { case .positionX: return frame.x; case .positionY: return frame.y; case .scale: return frame.scale; case .rotation: return frame.rotation; case .opacity: return frame.opacity }
    }
}

public struct PropertyKeyframe: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var time: Double
    public var value: Double
    public var interpolation: Interpolation
    public init(id: UUID = UUID(), time: Double, value: Double, interpolation: Interpolation = .linear) {
        self.id = id; self.time = time; self.value = value; self.interpolation = interpolation
    }
}

public struct AnimationChannel: Codable, Equatable, Identifiable, Sendable {
    public var id: AnimationProperty { property }
    public var property: AnimationProperty
    public var keyframes: [PropertyKeyframe]
    public init(_ property: AnimationProperty, keyframes: [PropertyKeyframe] = []) { self.property = property; self.keyframes = keyframes }
    public func value(at time: Double, fallback: Double) -> Double {
        let frames = keyframes.sorted { $0.time < $1.time }
        guard let first = frames.first, let last = frames.last else { return fallback }
        if time <= first.time { return first.value }
        if time >= last.time { return last.value }
        let index = frames.firstIndex { $0.time > time }!
        let a = frames[index - 1], b = frames[index]
        let t = a.interpolation.evaluate((time - a.time) / (b.time - a.time))
        return a.value + (b.value - a.value) * t
    }
}

public struct WorkArea: Codable, Equatable, Sendable {
    public var start: Double
    public var end: Double
    public var duration: Double { end - start }
    public init(start: Double, end: Double) { self.start = start; self.end = end }
    public func lastFrame(fps: Int) -> Double { max(start, (ceil(end * Double(fps)) - 1) / Double(fps)) }
    public func advanced(from time: Double, by delta: Double, fps: Int, loop: Bool) -> (time: Double, playing: Bool) {
        let next = max(start, time) + max(0, delta)
        if next < end { return (next, true) }
        return loop ? (start + (next - start).truncatingRemainder(dividingBy: duration), true) : (lastFrame(fps: fps), false)
    }
}

extension CanvasElement {
    public var effectiveAnimationChannels: [AnimationChannel] {
        if let animationChannels { return animationChannels }
        guard !keyframes.isEmpty else { return [] }
        return AnimationProperty.allCases.map { property in
            AnimationChannel(property, keyframes: keyframes.map { PropertyKeyframe(id: $0.id, time: $0.time, value: property.value(in: $0), interpolation: $0.interpolation ?? .linear) })
        }
    }
    public var hasAnimation: Bool { effectiveAnimationChannels.contains { !$0.keyframes.isEmpty } }
    public func baseValue(_ property: AnimationProperty) -> Double {
        switch property { case .positionX: return x; case .positionY: return y; case .scale: return baseScale ?? 1; case .rotation: return rotation; case .opacity: return opacity }
    }
    public mutating func setBaseValue(_ value: Double, for property: AnimationProperty) {
        switch property { case .positionX: x = value; case .positionY: y = value; case .scale: baseScale = value; case .rotation: rotation = value; case .opacity: opacity = value }
    }
    public func animationValue(_ property: AnimationProperty, at time: Double) -> Double {
        effectiveAnimationChannels.first { $0.property == property }?.value(at: time, fallback: baseValue(property)) ?? baseValue(property)
    }
    public mutating func migrateAnimationChannels() {
        guard animationChannels == nil else { return }
        animationChannels = effectiveAnimationChannels
        keyframes = []
    }
    public mutating func setPropertyKeyframe(_ property: AnimationProperty, at time: Double, value: Double, tolerance: Double = 0.000001) {
        migrateAnimationChannels()
        if !animationChannels!.contains(where: { $0.property == property }) { animationChannels!.append(AnimationChannel(property)) }
        let index = animationChannels!.firstIndex { $0.property == property }!
        var channel = animationChannels![index]
        let existing = channel.keyframes.first { abs($0.time - time) <= tolerance }
        channel.keyframes.removeAll { abs($0.time - time) <= tolerance }
        channel.keyframes.append(PropertyKeyframe(id: existing?.id ?? UUID(), time: time, value: min(property.limits.upperBound, max(property.limits.lowerBound, value)), interpolation: existing?.interpolation ?? .linear))
        channel.keyframes.sort { $0.time < $1.time }
        animationChannels![index] = channel
    }
    public mutating func disableAnimation(_ property: AnimationProperty, at time: Double) {
        let value = animationValue(property, at: time)
        migrateAnimationChannels()
        animationChannels?.removeAll { $0.property == property }
        setBaseValue(value, for: property)
    }
}

extension CreativeDocument {
    public var playbackArea: WorkArea { workArea ?? WorkArea(start: 0, end: duration) }
    public func validateAnimationChannels() throws {
        if let workArea {
            guard workArea.start.isFinite, workArea.end.isFinite, workArea.start >= 0, workArea.end > workArea.start, workArea.end <= duration else { throw DocumentError.invalid("The work area must be inside the composition.") }
        }
        for layer in elements {
            if let scale = layer.baseScale, !scale.isFinite || !(0.001...100).contains(scale) { throw DocumentError.invalid("A layer has an invalid base scale.") }
            guard let channels = layer.animationChannels else { continue }
            guard channels.count <= AnimationProperty.allCases.count, Set(channels.map(\.property)).count == channels.count else { throw DocumentError.invalid("A layer has duplicate animation channels.") }
            for channel in channels {
                guard channel.keyframes.count <= 10000, Set(channel.keyframes.map(\.id)).count == channel.keyframes.count, Set(channel.keyframes.map(\.time)).count == channel.keyframes.count,
                      channel.keyframes.allSatisfy({ $0.time.isFinite && (0...3600).contains($0.time) && $0.value.isFinite && channel.property.limits.contains($0.value) }) else { throw DocumentError.invalid("An animation channel has invalid keyframes.") }
            }
        }
    }
}
