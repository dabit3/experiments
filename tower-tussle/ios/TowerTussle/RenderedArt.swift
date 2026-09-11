import SwiftUI
import UIKit

typealias SceneryBackdrop = ArcadeBackdrop

enum RenderedArt {
    private static let bitmaps: [String: UIImage] = {
        let names = Cards.all.map { "card_\($0.id)" }
            + Cards.all.filter { $0.kind == .troop }.map { "units_\($0.id)" }
            + ["arena", "hero", "emblem", "tower_keep_blue", "tower_keep_red", "tower_guard_blue", "tower_guard_red"]
        return Dictionary(uniqueKeysWithValues: names.map { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                  let bitmap = UIImage(contentsOfFile: url.path) else {
                preconditionFailure("Missing rendered artwork: \(name)")
            }
            return (name, bitmap)
        })
    }()

    static func image(_ name: String) -> Image {
        Image(uiImage: bitmaps[name]!)
    }

    static let frames: [String: [Image]] = {
        Dictionary(uniqueKeysWithValues: Cards.all.filter { $0.kind == .troop }.map { card in
            let atlas = bitmaps["units_\(card.id)"]!.cgImage!
            return (card.id, (0..<12).map { index in
                let frame = atlas.cropping(to: CGRect(x: (index % 6) * 256, y: (index / 6) * 256, width: 256, height: 256))!
                return Image(decorative: frame, scale: 1)
            })
        })
    }()

    static func unit(_ ctx: inout GraphicsContext, unit: Unit, foot: CGPoint, radius: CGFloat) {
        let frame = unit.attackAnim > 0
            ? (unit.attackAnim > 0.12 ? 4 : 5)
            : (unit.moving ? Int(abs(unit.walkPhase) / (.pi / 2)) % 4 : 0)
        guard let image = frames[unit.card.id]?[frame + (unit.side == .enemy ? 6 : 0)] else { return }
        let width = radius * 5.0
        let float = unit.card.flying ? radius * 1.5 + CGFloat(sin(unit.walkPhase)) * radius * 0.2 : 0
        var g = ctx
        g.translateBy(x: foot.x, y: foot.y - float)
        g.scaleBy(x: unit.facing < 0 ? -1 : 1, y: 1)
        if unit.hitFlash > 0 { g.addFilter(.brightness(0.35)) }
        g.draw(image, in: CGRect(x: -width * 0.5, y: -width * 0.79, width: width, height: width))
    }
}

struct RenderedImage: View {
    let name: String
    var body: some View {
        RenderedArt.image(name).resizable().interpolation(.high).scaledToFit().accessibilityHidden(true)
    }
}

struct ArcadeBackdrop: View {
    var dim: Double = 0

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [Color(red: 0.025, green: 0.07, blue: 0.16), Color(red: 0.055, green: 0.19, blue: 0.28), Color(red: 0.025, green: 0.045, blue: 0.12)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
            let center = CGPoint(x: w * 0.5, y: h * 0.45)
            ctx.fill(Art.circle(center.x, center.y, w * 0.8), with: .radialGradient(
                Gradient(colors: [Color.cyan.opacity(0.15), .clear]), center: center, startRadius: 0, endRadius: w * 0.8))
            for i in 0..<3 {
                let r = w * (0.52 + CGFloat(i) * 0.22)
                ctx.stroke(Art.circle(center.x, center.y, r), with: .color(.cyan.opacity(0.06)), lineWidth: 1)
            }
            for i in 0..<65 {
                let x = CGFloat((Double(i) * 0.618 + 0.13).truncatingRemainder(dividingBy: 1)) * w
                let y = CGFloat((Double(i) * 0.2713 + 0.04).truncatingRemainder(dividingBy: 1)) * h
                ctx.fill(Art.circle(x, y, i % 5 == 0 ? 1.6 : 0.7), with: .color((i % 4 == 0 ? Art.gold : .cyan).opacity(0.35)))
            }
            if dim > 0 { ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(dim))) }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
