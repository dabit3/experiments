import Foundation

public enum VectorPathEditor {
    public static func addAnchor(to path: inout [VectorCommand], at point: Point2D, tolerance: Double = 4) -> Bool {
        guard valid(path), valid(point), tolerance.isFinite, tolerance >= 0, path.count < 100000,
              nearestAnchorIndex(on: path, to: point, tolerance: tolerance) == nil,
              let match = nearestSegment(on: path, to: point, within: tolerance), match.t > 0.000001, match.t < 0.999999 else { return false }
        let original = path[match.index]
        var updated = path
        if original.verb == .curve {
            let (left, right) = splitCubic(p0: match.start, c1: original.control1 ?? original.point, c2: original.control2 ?? original.point, p3: original.point, t: match.t)
            updated[match.index] = right
            updated.insert(left, at: match.index)
        } else {
            updated.insert(VectorCommand(.line, match.point), at: match.index)
        }
        guard valid(updated) else { return false }
        path = updated
        return true
    }

    public static func deleteAnchor(from path: inout [VectorCommand], at point: Point2D, tolerance: Double = 4) -> Bool {
        guard let index = nearestAnchorIndex(on: path, to: point, tolerance: tolerance) else { return false }
        return deleteAnchor(at: index, in: &path)
    }

    public static func convertAnchor(in path: inout [VectorCommand], at point: Point2D, tolerance: Double = 4, outgoing: Point2D? = nil) -> Bool {
        guard let index = nearestAnchorIndex(on: path, to: point, tolerance: tolerance), outgoing.map(valid) ?? true else { return false }
        var updated = path
        convertAnchor(at: index, in: &updated, outgoing: outgoing)
        guard updated != path, valid(updated) else { return false }
        path = updated
        return true
    }

    public static func moveNode(in path: inout [VectorCommand], at index: Int, to point: Point2D, control: Int = 0) -> Bool {
        guard valid(path), valid(point), path.indices.contains(index), path[index].verb != .close, (0...2).contains(control) else { return false }
        var updated = path
        if control != 0 {
            guard path[index].verb == .curve, control == 1 ? path[index].control1 != nil : path[index].control2 != nil else { return false }
            if control == 1 { updated[index].control1 = point } else { updated[index].control2 = point }
        } else {
            let range = componentRange(index, in: path)
            let closed = path[range.upperBound - 1].verb == .close
            let last = range.upperBound - (closed ? 2 : 1)
            let seam = closed && last > range.lowerBound && path[last].point == path[range.lowerBound].point
            let target = seam && index == last ? range.lowerBound : index
            let delta = Point2D(point.x - path[target].point.x, point.y - path[target].point.y)
            func translated(_ value: Point2D?) -> Point2D? { value.map { Point2D($0.x + delta.x, $0.y + delta.y) } }
            updated[target].point = point
            updated[target].control2 = translated(path[target].control2)
            if target < last { updated[target + 1].control1 = translated(path[target + 1].control1) }
            if target == range.lowerBound && closed {
                updated[range.upperBound - 1].point = point
                if seam { updated[last].point = point; updated[last].control2 = translated(path[last].control2) }
            }
        }
        guard updated != path, valid(updated) else { return false }
        path = updated
        return true
    }

    public static func nearestAnchorIndex(on path: [VectorCommand], to point: Point2D, tolerance: Double) -> Int? {
        guard valid(path), valid(point), tolerance.isFinite, tolerance >= 0 else { return nil }
        var best: (index: Int, distance: Double)?
        for (i, command) in path.enumerated() where command.verb != .close {
            let d = distance(command.point, point)
            if d <= tolerance, best == nil || d < best!.distance { best = (i, d) }
        }
        return best?.index
    }

    private static func valid(_ point: Point2D) -> Bool {
        point.x.isFinite && point.y.isFinite && abs(point.x) <= 1_000_000 && abs(point.y) <= 1_000_000
    }

    private static func valid(_ path: [VectorCommand]) -> Bool {
        guard path.count <= 100000 else { return false }
        var open = false
        for command in path {
            guard [command.point, command.control1, command.control2].compactMap({ $0 }).allSatisfy(valid) else { return false }
            switch command.verb {
            case .move: open = true
            case .line, .curve: if !open { return false }
            case .close: if !open { return false }; open = false
            }
        }
        return true
    }

    private struct SegmentMatch {
        let index: Int
        let t: Double
        let point: Point2D
        let start: Point2D
        let distance: Double
    }

    private static func nearestSegment(on path: [VectorCommand], to target: Point2D, within tolerance: Double) -> SegmentMatch? {
        var current = Point2D(0, 0), subpathStart = current
        var best: SegmentMatch?
        for (i, command) in path.enumerated() {
            if command.verb == .move { current = command.point; subpathStart = current; continue }
            let end = command.verb == .close ? subpathStart : command.point
            let match = command.verb == .curve
                ? nearestOnCubic(p0: current, c1: command.control1 ?? end, c2: command.control2 ?? end, p3: end, target: target, tolerance: tolerance)
                : nearestOnLine(p0: current, p1: end, target: target)
            if let match, match.distance <= tolerance, best == nil || match.distance < best!.distance {
                best = SegmentMatch(index: i, t: match.t, point: match.point, start: current, distance: match.distance)
            }
            current = end
        }
        return best
    }

    private static func componentRange(_ index: Int, in path: [VectorCommand]) -> Range<Int> {
        let start = (0...index).reversed().first { path[$0].verb == .move } ?? 0
        let end = ((index + 1)..<path.count).first { path[$0].verb == .move } ?? path.count
        return start..<end
    }

    private static func deleteAnchor(at index: Int, in path: inout [VectorCommand]) -> Bool {
        let range = componentRange(index, in: path)
        var part = Array(path[range])
        let closed = part.last?.verb == .close
        let last = part.count - (closed ? 2 : 1)
        let seam = closed && last > 0 && part[last].point == part[0].point
        let lastUnique = seam ? last - 1 : last
        let local = index - range.lowerBound
        let target = seam && local == last ? 0 : local
        if lastUnique == 0 {
            part = []
        } else if target == 0 {
            let next = part[1]
            if closed {
                let incoming = seam ? part[last] : VectorCommand(.line, part[0].point)
                let joined = bridge(from: part[lastUnique].point, incoming: incoming, outgoing: next)
                if seam { part[last] = joined }
                else if joined.verb == .curve { part.insert(joined, at: part.count - 1) }
            }
            part.removeFirst()
            part[0] = VectorCommand(.move, next.point)
            if closed { part[part.count - 1].point = next.point }
        } else if target == last && !closed {
            part.remove(at: target)
        } else {
            let successor = part[target + 1]
            guard successor.verb == .line || successor.verb == .curve || successor.verb == .close else {
                return false
            }
            let outgoing = successor.verb == .close ? VectorCommand(.line, part[0].point) : successor
            let joined = bridge(from: part[target - 1].point, incoming: part[target], outgoing: outgoing)
            if successor.verb == .close {
                if joined.verb == .curve { part[target] = joined }
                else { part.remove(at: target) }
            } else {
                part[target + 1] = joined
                part.remove(at: target)
            }
        }
        var updated = path
        updated.replaceSubrange(range, with: part)
        guard valid(updated) else { return false }
        path = updated
        return true
    }

    private static func bridge(from start: Point2D, incoming: VectorCommand, outgoing: VectorCommand) -> VectorCommand {
        if incoming.verb != .curve && outgoing.verb != .curve { return VectorCommand(.line, outgoing.point) }
        let c1 = incoming.verb == .curve ? incoming.control1 ?? incoming.point : start
        let c2 = outgoing.verb == .curve ? outgoing.control2 ?? outgoing.point : outgoing.point
        return VectorCommand(.curve, outgoing.point, control1: c1, control2: c2)
    }

    private static func convertAnchor(at index: Int, in path: inout [VectorCommand], outgoing: Point2D?) {
        let range = componentRange(index, in: path)
        let closed = path[range.upperBound - 1].verb == .close
        let last = range.upperBound - (closed ? 2 : 1)
        let seam = closed && last > range.lowerBound && path[last].point == path[range.lowerBound].point
        let target = seam && index == last ? range.lowerBound : index
        if target == range.lowerBound {
            convertMoveAnchor(at: target, in: &path, outgoing: outgoing)
            return
        }
        let anchor = path[target].point
        if let outgoing {
            setHandle(in: &path[target], start: path[target - 1].point, incoming: true, point: Point2D(2 * anchor.x - outgoing.x, 2 * anchor.y - outgoing.y))
        } else {
            if path[target].verb == .curve { path[target].control2 = anchor }
        }
        let next = target + 1
        if next <= last {
            if let outgoing { setHandle(in: &path[next], start: anchor, incoming: false, point: outgoing) }
            else if path[next].verb == .curve { path[next].control1 = anchor }
        } else if closed, let outgoing {
            path.insert(VectorCommand(.curve, path[range.lowerBound].point, control1: outgoing, control2: path[range.lowerBound].point), at: next)
        }
    }

    private static func convertMoveAnchor(at index: Int, in path: inout [VectorCommand], outgoing: Point2D?) {
        let range = componentRange(index, in: path)
        let closed = path[range.upperBound - 1].verb == .close
        let last = range.upperBound - (closed ? 2 : 1)
        guard last > index else { return }
        let anchor = path[index].point
        if let outgoing { setHandle(in: &path[index + 1], start: anchor, incoming: false, point: outgoing) }
        else if path[index + 1].verb == .curve { path[index + 1].control1 = anchor }
        if closed {
            let seam = path[last].point == anchor
            if let outgoing {
                let incoming = Point2D(2 * anchor.x - outgoing.x, 2 * anchor.y - outgoing.y)
                if seam { setHandle(in: &path[last], start: path[last - 1].point, incoming: true, point: incoming) }
                else { path.insert(VectorCommand(.curve, anchor, control1: path[last].point, control2: incoming), at: last + 1) }
            } else if seam && path[last].verb == .curve { path[last].control2 = anchor }
        }
    }

    private static func setHandle(in command: inout VectorCommand, start: Point2D, incoming: Bool, point: Point2D) {
        if command.verb == .line {
            command.verb = .curve; command.control1 = start; command.control2 = command.point
        }
        if incoming { command.control2 = point } else { command.control1 = point }
    }

    private static func nearestOnLine(p0: Point2D, p1: Point2D, target: Point2D) -> (t: Double, point: Point2D, distance: Double) {
        let dx = p1.x - p0.x, dy = p1.y - p0.y, len2 = dx * dx + dy * dy
        let t = len2 == 0 ? 0 : max(0, min(1, ((target.x - p0.x) * dx + (target.y - p0.y) * dy) / len2))
        let point = lerp(p0, p1, t)
        return (t, point, distance(point, target))
    }

    private static func nearestOnCubic(p0: Point2D, c1: Point2D, c2: Point2D, p3: Point2D, target: Point2D, tolerance: Double) -> (t: Double, point: Point2D, distance: Double)? {
        var best = (t: 0.0, point: p0, distance: distance(p0, target))
        if distance(p3, target) < best.distance { best = (1, p3, distance(p3, target)) }
        var stack = [(p0, c1, c2, p3, 0.0, 1.0, 0)]
        var visits = 0
        while let (a, b, c, d, lower, upper, depth) = stack.popLast(), visits < 32768 {
            visits += 1
            let xs = [a.x, b.x, c.x, d.x], ys = [a.y, b.y, c.y, d.y]
            let dx = max(0, max(xs.min()! - target.x, target.x - xs.max()!))
            let dy = max(0, max(ys.min()! - target.y, target.y - ys.max()!))
            if hypot(dx, dy) > min(best.distance, tolerance) + 0.000000001 { continue }
            let flatness = max(nearestOnLine(p0: a, p1: d, target: b).distance, nearestOnLine(p0: a, p1: d, target: c).distance)
            if depth >= 20 || flatness <= max(0.0000001, tolerance * 0.05) {
                var lo = lower, hi = upper
                for _ in 0..<40 {
                    let l = lo + (hi - lo) * 0.3819660112501051, r = lo + (hi - lo) * 0.6180339887498949
                    if distance(cubicPoint(p0, c1, c2, p3, l), target) < distance(cubicPoint(p0, c1, c2, p3, r), target) { hi = r }
                    else { lo = l }
                }
                var t = (lo + hi) / 2
                for _ in 0..<12 {
                    let p = cubicPoint(p0, c1, c2, p3, t)
                    let v = cubicDerivative(p0, c1, c2, p3, t), acceleration = cubicSecondDerivative(p0, c1, c2, p3, t)
                    let delta = Point2D(p.x - target.x, p.y - target.y)
                    let denominator = v.x * v.x + v.y * v.y + acceleration.x * delta.x + acceleration.y * delta.y
                    if abs(denominator) < 1e-18 { break }
                    let next = max(lower, min(upper, t - (v.x * delta.x + v.y * delta.y) / denominator))
                    if abs(next - t) < 1e-14 { t = next; break }
                    t = next
                }
                let p = cubicPoint(p0, c1, c2, p3, t), dist = distance(p, target)
                if dist < best.distance { best = (t, p, dist) }
            } else {
                let (left, right) = splitCubic(p0: a, c1: b, c2: c, p3: d, t: 0.5)
                let middle = (lower + upper) / 2
                stack.append((left.point, right.control1!, right.control2!, d, middle, upper, depth + 1))
                stack.append((a, left.control1!, left.control2!, left.point, lower, middle, depth + 1))
            }
        }
        return best.distance <= tolerance ? best : nil
    }

    private static func splitCubic(p0: Point2D, c1: Point2D, c2: Point2D, p3: Point2D, t: Double) -> (VectorCommand, VectorCommand) {
        let q1 = lerp(p0, c1, t), q2 = lerp(c1, c2, t), q3 = lerp(c2, p3, t)
        let r1 = lerp(q1, q2, t), r2 = lerp(q2, q3, t), s = lerp(r1, r2, t)
        return (VectorCommand(.curve, s, control1: q1, control2: r1), VectorCommand(.curve, p3, control1: r2, control2: q3))
    }

    private static func cubicPoint(_ p0: Point2D, _ c1: Point2D, _ c2: Point2D, _ p3: Point2D, _ t: Double) -> Point2D {
        let a = lerp(p0, c1, t), b = lerp(c1, c2, t), c = lerp(c2, p3, t)
        return lerp(lerp(a, b, t), lerp(b, c, t), t)
    }

    private static func cubicDerivative(_ p0: Point2D, _ c1: Point2D, _ c2: Point2D, _ p3: Point2D, _ t: Double) -> Point2D {
        let u = 1 - t
        return Point2D(3 * u * u * (c1.x - p0.x) + 6 * u * t * (c2.x - c1.x) + 3 * t * t * (p3.x - c2.x),
                       3 * u * u * (c1.y - p0.y) + 6 * u * t * (c2.y - c1.y) + 3 * t * t * (p3.y - c2.y))
    }

    private static func cubicSecondDerivative(_ p0: Point2D, _ c1: Point2D, _ c2: Point2D, _ p3: Point2D, _ t: Double) -> Point2D {
        Point2D(6 * (1 - t) * (c2.x - 2 * c1.x + p0.x) + 6 * t * (p3.x - 2 * c2.x + c1.x),
                6 * (1 - t) * (c2.y - 2 * c1.y + p0.y) + 6 * t * (p3.y - 2 * c2.y + c1.y))
    }

    private static func lerp(_ a: Point2D, _ b: Point2D, _ t: Double) -> Point2D { Point2D(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t) }
    private static func distance(_ a: Point2D, _ b: Point2D) -> Double { hypot(a.x - b.x, a.y - b.y) }
}

public struct FreeformPathStroke {
    public static let curveFitRange = 0.5...10.0
    public static let defaultCurveFit = 2.0
    public static let maximumSamples = 4096
    public static let minimumSpacing = 0.5
    public let curveFit: Double
    public private(set) var samples: [Point2D] = []
    public private(set) var isValid = true

    public init(curveFit: Double = defaultCurveFit) { self.curveFit = Self.clampedCurveFit(curveFit) }

    public static func clampedCurveFit(_ value: Double) -> Double {
        value.isFinite ? min(curveFitRange.upperBound, max(curveFitRange.lowerBound, value)) : defaultCurveFit
    }

    @discardableResult public mutating func append(_ point: Point2D, isFinal: Bool = false) -> Bool {
        guard isValid, Self.valid(point) else { isValid = false; return false }
        if let last = samples.last, last == point || (!isFinal && Self.distance(last, point) < Self.minimumSpacing) { return true }
        guard samples.count < Self.maximumSamples else { isValid = false; return false }
        samples.append(point)
        return true
    }

    public func path(closingDistance: Double = 10) -> [VectorCommand]? {
        guard isValid, samples.count >= 2, closingDistance.isFinite, closingDistance >= 0,
              let first = samples.first, let last = samples.last,
              let farthest = samples.indices.max(by: { Self.distance(samples[$0], first) < Self.distance(samples[$1], first) }),
              Self.distance(samples[farthest], first) >= Self.minimumSpacing else { return nil }
        var points = samples
        var closed = false
        var seeds = [0, points.count - 1]
        if points.count >= 4, Self.distance(first, last) <= closingDistance, Self.distance(points[farthest], first) > closingDistance,
           let third = points.indices.dropLast().max(by: { Self.lineDistance(points[$0], first, points[farthest]) < Self.lineDistance(points[$1], first, points[farthest]) }),
           Self.lineDistance(points[third], first, points[farthest]) > 0.000001 {
            points[points.count - 1] = first
            seeds = [0, farthest, third, points.count - 1].sorted()
            closed = true
        }
        points = Self.simplify(points, tolerance: curveFit / 2, seeds: seeds)
        if closed { points.removeLast() }
        guard points.count >= (closed ? 3 : 2) else { return nil }
        let handles = points.indices.map { index -> Point2D in
            let current = points[index]
            let previous = index > 0 ? points[index - 1] : closed ? points.last! : current
            let next = index + 1 < points.count ? points[index + 1] : closed ? points[0] : current
            let dx = next.x - previous.x, dy = next.y - previous.y, magnitude = hypot(dx, dy)
            guard magnitude > 0 else { return Point2D(0, 0) }
            let ux = dx / magnitude, uy = dy / magnitude
            let neighbors = [previous, next].filter { $0 != current }
            var length = (neighbors.map { Self.distance($0, current) }.min() ?? 0) / 3
            for neighbor in neighbors {
                let distance = Self.distance(neighbor, current)
                let sine = abs(ux * (neighbor.y - current.y) - uy * (neighbor.x - current.x)) / distance
                if sine > 0 { length = min(length, curveFit / (2 * sine)) }
            }
            return Point2D(ux * length, uy * length)
        }
        var result = [VectorCommand(.move, points[0])]
        for i in 1..<(points.count + (closed ? 1 : 0)) {
            let previous = i - 1, next = i % points.count
            let a = points[previous], b = points[next]
            result.append(VectorCommand(.curve, b, control1: Point2D(a.x + handles[previous].x, a.y + handles[previous].y), control2: Point2D(b.x - handles[next].x, b.y - handles[next].y)))
        }
        if closed { result.append(VectorCommand(.close, points[0])) }
        guard result.allSatisfy({ [$0.point, $0.control1, $0.control2].compactMap { $0 }.allSatisfy(Self.valid) }) else { return nil }
        return result
    }

    private static func simplify(_ points: [Point2D], tolerance: Double, seeds: [Int]) -> [Point2D] {
        var keep = Set(seeds)
        var stack = zip(seeds, seeds.dropFirst()).map { ($0, $1) }
        while let (start, end) = stack.popLast() {
            guard end > start + 1 else { continue }
            var maximum = tolerance, split: Int?
            for i in (start + 1)..<end {
                let distance = lineDistance(points[i], points[start], points[end])
                if distance > maximum { maximum = distance; split = i }
            }
            if let split { keep.insert(split); stack.append((start, split)); stack.append((split, end)) }
        }
        return keep.sorted().map { points[$0] }
    }

    private static func lineDistance(_ point: Point2D, _ a: Point2D, _ b: Point2D) -> Double {
        let dx = b.x - a.x, dy = b.y - a.y, length = dx * dx + dy * dy
        let t = length == 0 ? 0 : max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / length))
        return distance(point, Point2D(a.x + t * dx, a.y + t * dy))
    }

    private static func valid(_ point: Point2D) -> Bool { point.x.isFinite && point.y.isFinite && abs(point.x) <= 1_000_000 && abs(point.y) <= 1_000_000 }
    private static func distance(_ a: Point2D, _ b: Point2D) -> Double { hypot(a.x - b.x, a.y - b.y) }
}
