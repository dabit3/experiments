import SpriteKit
import UIKit

/// CoreGraphics painting helpers that bake shaded, gradient-lit artwork into
/// SpriteKit textures. Contexts are centred and y-up so drawing code shares the
/// arena's coordinate system.
enum Paint {
    static func texture(size: CGSize, scale: CGFloat = 3, _ draw: (CGContext) -> Void) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let ctx = context.cgContext
            ctx.translateBy(x: size.width / 2, y: size.height / 2)
            ctx.scaleBy(x: 1, y: -1)
            draw(ctx)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static func sprite(size: CGSize, scale: CGFloat = 3, z: CGFloat = 0, _ draw: (CGContext) -> Void) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(size: size, scale: scale, draw))
        node.size = size
        node.zPosition = z
        return node
    }

    static func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
        CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    }

    static func gradient(_ colors: [UIColor], locations: [CGFloat]? = nil) -> CGGradient {
        CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map(\.cgColor) as CFArray,
            locations: locations
        )!
    }

    static func fill(_ ctx: CGContext, _ path: CGPath, _ color: UIColor) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setFillColor(color.cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }

    static func stroke(_ ctx: CGContext, _ path: CGPath, _ color: UIColor, width: CGFloat) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.setLineCap(.round)
        ctx.strokePath()
        ctx.restoreGState()
    }

    static func linear(_ ctx: CGContext, _ path: CGPath, _ colors: [UIColor], from: CGPoint, to: CGPoint) {
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(
            gradient(colors),
            start: from,
            end: to,
            options: [.drawsAfterEndLocation, .drawsBeforeStartLocation]
        )
        ctx.restoreGState()
    }

    static func radial(_ ctx: CGContext, _ path: CGPath?, _ colors: [UIColor], center: CGPoint, radius: CGFloat) {
        ctx.saveGState()
        if let path {
            ctx.addPath(path)
            ctx.clip()
        }
        ctx.drawRadialGradient(
            gradient(colors), startCenter: center, startRadius: 0,
            endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation]
        )
        ctx.restoreGState()
    }

    static func glow(_ ctx: CGContext, _ path: CGPath, _ color: UIColor, blur: CGFloat, fill: UIColor? = nil) {
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: blur, color: color.cgColor)
        ctx.addPath(path)
        ctx.setFillColor((fill ?? color).cgColor)
        ctx.fillPath()
        ctx.restoreGState()
    }

    static func line(_ ctx: CGContext, _ points: [CGPoint], _ color: UIColor, width: CGFloat) {
        guard let first = points.first else { return }
        let path = CGMutablePath()
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        stroke(ctx, path, color, width: width)
    }

    /// Soft additive light blob used for trails, glows and floodlight haze.
    static func softLight(diameter: CGFloat, color: UIColor) -> SKTexture {
        texture(size: CGSize(width: diameter, height: diameter), scale: 2) { ctx in
            radial(ctx, nil, [color, color.withAlphaComponent(0)], center: .zero, radius: diameter / 2)
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255,
            alpha: 1
        )
    }

    func mixed(with other: UIColor, _ amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(
            red: r1 + (r2 - r1) * amount, green: g1 + (g2 - g1) * amount,
            blue: b1 + (b2 - b1) * amount, alpha: a1 + (a2 - a1) * amount
        )
    }

    var lighter: UIColor {
        mixed(with: .white, 0.32)
    }

    var darker: UIColor {
        mixed(with: .black, 0.4)
    }
}
