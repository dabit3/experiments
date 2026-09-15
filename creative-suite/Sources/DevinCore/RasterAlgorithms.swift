import Foundation

public struct RasterGrid: Sendable {
    public let width: Int
    public let height: Int
    public var rgba: [UInt8]
    public init(width: Int, height: Int, rgba: [UInt8]) throws {
        guard width > 0, height > 0, width <= 16384, height <= 16384, width * height <= 16_777_216, rgba.count == width * height * 4 else { throw DocumentError.invalid("Raster processing supports valid RGBA images up to 16 megapixels.") }
        self.width = width; self.height = height; self.rgba = rgba
    }
    public func region(x: Int, y: Int, tolerance: Int, contiguous: Bool) -> [UInt8] {
        var mask = [UInt8](repeating: 0, count: width * height)
        guard (0..<width).contains(x), (0..<height).contains(y) else { return mask }
        let seed = (y * width + x) * 4, threshold = max(0, min(255, tolerance))
        func matches(_ pixel: Int) -> Bool {
            let index = pixel * 4
            guard abs(Int(rgba[index + 3]) - Int(rgba[seed + 3])) <= threshold else { return false }
            if rgba[seed + 3] == 0 && rgba[index + 3] == 0 { return true }
            return (0..<3).allSatisfy { abs(Int(rgba[index + $0]) - Int(rgba[seed + $0])) <= threshold }
        }
        if !contiguous {
            for i in mask.indices where matches(i) { mask[i] = 255 }
            return mask
        }
        var visited = [UInt8](repeating: 0, count: mask.count)
        var queue = [y * width + x], head = 0
        visited[queue[0]] = 1
        func visit(_ index: Int) {
            guard visited[index] == 0 else { return }
            visited[index] = 1
            if matches(index) { queue.append(index) }
        }
        while head < queue.count {
            let index = queue[head]; head += 1; mask[index] = 255
            if index % width > 0 { visit(index - 1) }
            if index % width < width - 1 { visit(index + 1) }
            if index >= width { visit(index - width) }
            if index + width < mask.count { visit(index + width) }
        }
        return mask
    }
    public func average(x: Int, y: Int, radius: Int) -> [Double] {
        let x0 = max(0, x - radius), x1 = min(width - 1, x + radius)
        let y0 = max(0, y - radius), y1 = min(height - 1, y + radius)
        guard x0 <= x1, y0 <= y1 else { return [0, 0, 0, 0] }
        var sum = [Double](repeating: 0, count: 4), count = 0.0
        for row in y0...y1 { for column in x0...x1 {
            let index = (row * width + column) * 4
            for c in 0..<4 { sum[c] += Double(rgba[index + c]) / 255 }
            count += 1
        } }
        return sum.map { $0 / count }
    }
    public static func gradientFraction(at point: Point2D, from start: Point2D, to end: Point2D, radial: Bool) -> Double {
        let dx = end.x - start.x, dy = end.y - start.y, lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0.00000001 else { return 0 }
        let x = point.x - start.x, y = point.y - start.y
        let fraction = radial ? hypot(x, y) / sqrt(lengthSquared) : (x * dx + y * dy) / lengthSquared
        return min(1, max(0, fraction))
    }
}
