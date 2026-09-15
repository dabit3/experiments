import SpriteKit
import UIKit

enum FruitKind: Int, CaseIterable {
    case citrus, kiwi, dragon

    var juice: UIColor {
        switch self {
        case .citrus: Pixel.orange
        case .kiwi: Pixel.lime
        case .dragon: Pixel.pink
        }
    }
}

/// The 8-bit palette shared by the app and the scene.
enum Pixel {
    static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    static let white = UIColor(red: 0.988, green: 0.988, blue: 0.988, alpha: 1)
    static let navy = UIColor(red: 0.047, green: 0.047, blue: 0.24, alpha: 1)
    static let indigo = UIColor(red: 0.13, green: 0.13, blue: 0.47, alpha: 1)
    static let sky = UIColor(red: 0.36, green: 0.58, blue: 0.99, alpha: 1)
    static let red = UIColor(red: 0.97, green: 0.22, blue: 0, alpha: 1)
    static let orange = UIColor(red: 0.99, green: 0.6, blue: 0.22, alpha: 1)
    static let yellow = UIColor(red: 0.99, green: 0.88, blue: 0, alpha: 1)
    static let cream = UIColor(red: 0.99, green: 0.9, blue: 0.66, alpha: 1)
    static let green = UIColor(red: 0, green: 0.66, blue: 0, alpha: 1)
    static let lime = UIColor(red: 0.72, green: 0.9, blue: 0.3, alpha: 1)
    static let darkGreen = UIColor(red: 0, green: 0.42, blue: 0, alpha: 1)
    static let pink = UIColor(red: 0.97, green: 0.47, blue: 0.97, alpha: 1)
    static let magenta = UIColor(red: 0.85, green: 0.1, blue: 0.5, alpha: 1)
    static let brown = UIColor(red: 0.42, green: 0.25, blue: 0.08, alpha: 1)
    static let brick = UIColor(red: 0.78, green: 0.3, blue: 0.05, alpha: 1)
    static let gray = UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1)
    static let darkGray = UIColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1)
}

/// Procedural 8-bit sprite sheet. Every sprite is rasterised on a small pixel
/// grid, given a 1px outline and scaled with nearest-neighbour sampling.
@MainActor
enum FruitArt {
    static let grid = 28
    static let images = FruitKind.allCases.map { raster(kind: $0) }
    static let bomb = raster(kind: nil)
    static let splatter = nearest(drawSplatter())
    static let square = nearest(solid())

    static func image(_ kind: FruitKind) -> UIImage {
        images[kind.rawValue]
    }

    static func texture(_ kind: FruitKind) -> SKTexture {
        nearest(image(kind))
    }

    static func nearest(_ image: UIImage) -> SKTexture {
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    private static func solid() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2), format: pixelFormat()).image { renderer in
            renderer.cgContext.setFillColor(UIColor.white.cgColor)
            renderer.cgContext.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    private static func pixelFormat() -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return format
    }

    /// Colour of one grid cell, or nil for transparency. `nil` kind draws the bomb.
    private static func cell(_ x: Int, _ y: Int, kind: FruitKind?) -> UIColor? {
        let cx = 13.5, cy = 15.5
        let dx = Double(x) + 0.5 - cx
        let dy = Double(y) + 0.5 - cy
        let d = (dx * dx + dy * dy).squareRoot()
        let angle = atan2(dy, dx)
        let radius = 11.5
        let lit = dx + dy < -6
        let shade = dx + dy > 7 && (x + y) % 2 == 0
        guard let kind else {
            if y < 3 {
                if x == 13 || x == 14, y >= 1 {
                    return Pixel.darkGray
                }
                if x == 15 || x == 16, y == 0 {
                    return Pixel.yellow
                }
                if x == 17, y == 1 {
                    return Pixel.red
                }
                if x == 12, y == 0 {
                    return Pixel.red
                }
                return nil
            }
            if d > radius + 1 {
                return nil
            }
            if d > radius {
                return Pixel.black
            }
            if d > radius - 1.5 {
                return Pixel.red
            }
            if d > radius - 2.5 {
                return Pixel.black
            }
            if abs(dx) < 1.2, abs(dy) < 5.5 {
                return Pixel.red
            }
            if abs(dy) < 1.2, abs(dx) < 5.5 {
                return Pixel.red
            }
            if x >= 8, x <= 9, y >= 8, y <= 9 {
                return Pixel.white
            }
            if x == 10, y == 8 {
                return Pixel.white
            }
            return shade ? Pixel.black : Pixel.darkGray
        }
        if kind != .dragon, y < 4 {
            let leaf = [(13, 3), (14, 3), (15, 2), (16, 2), (17, 1), (18, 1), (16, 1)]
            if leaf.contains(where: { $0 == (x, y) }) {
                return Pixel.green
            }
            if [(15, 3), (17, 2), (18, 0)].contains(where: { $0 == (x, y) }) {
                return Pixel.darkGreen
            }
            if [(12, 3), (19, 1), (19, 0), (16, 0)].contains(where: { $0 == (x, y) }) {
                return Pixel.black
            }
            return nil
        }
        if kind == .dragon, d > radius + 1, d < radius + 4 {
            let petal = Int(((angle + .pi) / (.pi * 2) * 6).rounded()) % 6
            let petalAngle = Double(petal) / 6 * .pi * 2 - .pi
            let off = abs(atan2(sin(angle - petalAngle), cos(angle - petalAngle)))
            let reach = radius + 4 - off * 9
            if d < reach - 1.2 {
                return Pixel.green
            }
            if d < reach {
                return Pixel.darkGreen
            }
            return nil
        }
        if d > radius + 1 {
            return nil
        }
        if d > radius {
            return Pixel.black
        }
        let rind: UIColor = switch kind {
        case .citrus: Pixel.orange
        case .kiwi: Pixel.brown
        case .dragon: Pixel.magenta
        }
        if d > radius - 1.6 {
            return lit ? Pixel.white : rind
        }
        if d > radius - 2.6 {
            return kind == .dragon ? Pixel.pink : Pixel.cream
        }
        switch kind {
        case .citrus:
            let seg = angle / (.pi / 5)
            if abs(seg - seg.rounded()) < 0.09, d > 2.2 {
                return Pixel.cream
            }
            if d < 1.6 {
                return Pixel.cream
            }
            if shade {
                return Pixel.orange
            }
            return Pixel.yellow
        case .kiwi:
            if d < 2.6 {
                return Pixel.cream
            }
            let ring = Int((angle + .pi) / (.pi * 2) * 16) % 16
            if d > 4, d < 7.4, ring % 2 == (Int(d) % 2) {
                return Pixel.black
            }
            if shade {
                return Pixel.green
            }
            return Pixel.lime
        case .dragon:
            if (x * 73 + y * 151 + x * y * 31) % 9 == 0, d < radius - 3.4 {
                return Pixel.black
            }
            if shade {
                return Pixel.cream
            }
            return Pixel.white
        }
    }

    private static func raster(kind: FruitKind?) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: grid, height: grid + 4), format: pixelFormat()).image { renderer in
            let c = renderer.cgContext
            c.setShouldAntialias(false)
            for y in 0 ..< (grid + 4) {
                for x in 0 ..< grid {
                    guard let color = cell(x, y, kind: kind) else { continue }
                    c.setFillColor(color.cgColor)
                    c.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
    }

    private static func drawSplatter() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 24, height: 12), format: pixelFormat()).image { renderer in
            let c = renderer.cgContext
            c.setFillColor(UIColor.white.cgColor)
            let blobs = [(6, 3, 12, 6), (2, 5, 4, 3), (18, 4, 4, 3), (0, 6, 2, 2), (22, 5, 2, 2), (9, 1, 3, 2), (13, 9, 3, 2), (4, 9, 2, 1)]
            for (x, y, w, h) in blobs {
                c.fill(CGRect(x: x, y: y, width: w, height: h))
            }
        }
    }
}
