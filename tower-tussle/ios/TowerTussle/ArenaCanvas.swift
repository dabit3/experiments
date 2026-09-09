import SwiftUI

struct ArenaCanvas: View {
    @ObservedObject var engine: BattleEngine
    let scale: CGFloat

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            drawGround(&ctx, size: size)
            drawDeployHint(&ctx)
            for tower in engine.towers { drawTower(&ctx, tower) }
            for unit in engine.units.sorted(by: { $0.pos.y < $1.pos.y }) where unit.alive { drawUnit(&ctx, unit) }
            for p in engine.projectiles { drawProjectile(&ctx, p) }
            for e in engine.effects { drawEffect(&ctx, e) }
        }
    }

    private func pt(_ v: Vec) -> CGPoint { CGPoint(x: v.x * scale, y: v.y * scale) }
    private func len(_ d: Double) -> CGFloat { d * scale }

    private func drawGround(_ ctx: inout GraphicsContext, size: CGSize) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.grass))
        // Checkerboard grass
        for gy in 0..<Int(Arena.height) {
            for gx in 0..<Int(Arena.width) where (gx + gy) % 2 == 0 {
                ctx.fill(Path(CGRect(x: len(Double(gx)), y: len(Double(gy)), width: len(1), height: len(1))), with: .color(Theme.grassDark))
            }
        }
        // River
        let river = CGRect(x: 0, y: len(Arena.riverTop), width: size.width, height: len(Arena.riverBottom - Arena.riverTop))
        ctx.fill(Path(river), with: .color(Theme.river))
        for i in 0..<6 {
            let y = len(Arena.riverTop) + CGFloat(i) * river.height / 6 + river.height / 12
            var wave = Path()
            wave.move(to: CGPoint(x: 0, y: y))
            var x: CGFloat = 0
            while x < size.width {
                wave.addQuadCurve(to: CGPoint(x: x + len(1), y: y), control: CGPoint(x: x + len(0.5), y: y - len(0.15)))
                x += len(1)
            }
            ctx.stroke(wave, with: .color(.white.opacity(0.18)), lineWidth: 1)
        }
        // Bridges
        for bx in Arena.bridgeXs {
            let rect = CGRect(x: len(bx - Arena.bridgeHalfWidth), y: len(Arena.riverTop - 0.2),
                              width: len(Arena.bridgeHalfWidth * 2), height: len(Arena.riverBottom - Arena.riverTop + 0.4))
            ctx.fill(Path(roundedRect: rect, cornerRadius: len(0.15)), with: .color(Theme.bridge))
            for i in 0..<5 {
                let y = rect.minY + CGFloat(i) * rect.height / 5 + rect.height / 10
                ctx.stroke(Path { p in p.move(to: CGPoint(x: rect.minX, y: y)); p.addLine(to: CGPoint(x: rect.maxX, y: y)) },
                           with: .color(.black.opacity(0.2)), lineWidth: 1)
            }
        }
        // Mid line
        ctx.stroke(Path { p in
            p.move(to: CGPoint(x: 0, y: len(Arena.riverCenter)))
            p.addLine(to: CGPoint(x: size.width, y: len(Arena.riverCenter)))
        }, with: .color(.white.opacity(0.15)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    private func drawDeployHint(_ ctx: inout GraphicsContext) {
        guard let card = engine.selectedCard, engine.result == nil else { return }
        let affordable = engine.canAfford(card)
        let rect: CGRect
        if card.kind == .spell {
            rect = CGRect(x: 0, y: 0, width: len(Arena.width), height: len(Arena.height))
        } else {
            rect = CGRect(x: 0, y: len(Arena.playerDeployMinY), width: len(Arena.width), height: len(Arena.height - Arena.playerDeployMinY))
        }
        ctx.fill(Path(rect), with: .color((affordable ? Theme.player : Theme.enemy).opacity(0.18)))
        ctx.stroke(Path(rect.insetBy(dx: 1, dy: 1)), with: .color((affordable ? Theme.player : Theme.enemy).opacity(0.6)),
                   style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
    }

    private func drawTower(_ ctx: inout GraphicsContext, _ tower: Tower) {
        let r = len(tower.kind.radius)
        let center = pt(tower.pos)
        let base = CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)
        let color = tower.side == .player ? Theme.player : Theme.enemy
        if !tower.alive {
            ctx.fill(Path(roundedRect: base, cornerRadius: r * 0.3), with: .color(.black.opacity(0.35)))
            ctx.draw(Text("💥").font(.system(size: r * 1.2)), at: center)
            return
        }
        ctx.fill(Path(ellipseIn: base.insetBy(dx: -r * 0.1, dy: -r * 0.1).offsetBy(dx: 0, dy: r * 0.25)), with: .color(.black.opacity(0.25)))
        ctx.fill(Path(roundedRect: base, cornerRadius: r * 0.3),
                 with: .color(tower.hitFlash > 0 ? .white : Color(red: 0.55, green: 0.55, blue: 0.6)))
        ctx.fill(Path(roundedRect: base.insetBy(dx: r * 0.2, dy: r * 0.2), cornerRadius: r * 0.2), with: .color(color))
        let icon = tower.kind == .keep ? "👑" : "🏰"
        ctx.draw(Text(icon).font(.system(size: r * 1.1)), at: center)
        if tower.kind == .keep && !tower.activated {
            ctx.draw(Text("💤").font(.system(size: r * 0.5)), at: CGPoint(x: center.x + r * 0.8, y: center.y - r * 0.8))
        }
        drawHealthBar(&ctx, center: CGPoint(x: center.x, y: base.minY - len(0.35)), width: 2 * r,
                      fraction: tower.hp / tower.kind.maxHp, color: color, label: "\(Int(tower.hp))")
    }

    private func drawUnit(_ ctx: inout GraphicsContext, _ unit: Unit) {
        let r = len(unit.radius)
        let center = pt(unit.pos)
        let color = unit.side == .player ? Theme.player : Theme.enemy
        let shadowOffset: CGFloat = unit.card.flying ? r * 0.9 : r * 0.3
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - r * 0.8, y: center.y + shadowOffset - r * 0.25, width: r * 1.6, height: r * 0.5)),
                 with: .color(.black.opacity(0.3)))
        let bodyCenter = unit.card.flying ? CGPoint(x: center.x, y: center.y - r * 0.6) : center
        let body = CGRect(x: bodyCenter.x - r, y: bodyCenter.y - r, width: 2 * r, height: 2 * r)
        ctx.fill(Path(ellipseIn: body), with: .color(unit.hitFlash > 0 ? .white : color))
        ctx.stroke(Path(ellipseIn: body), with: .color(.white.opacity(0.7)), lineWidth: max(1, r * 0.12))
        ctx.draw(Text(unit.card.emoji).font(.system(size: r * 1.3)), at: bodyCenter)
        drawHealthBar(&ctx, center: CGPoint(x: bodyCenter.x, y: body.minY - len(0.25)), width: max(2 * r, len(0.9)),
                      fraction: unit.hp / unit.card.hp, color: color, label: nil)
    }

    private func drawHealthBar(_ ctx: inout GraphicsContext, center: CGPoint, width: CGFloat, fraction: Double, color: Color, label: String?) {
        let h = len(0.28)
        let rect = CGRect(x: center.x - width / 2, y: center.y - h / 2, width: width, height: h)
        ctx.fill(Path(roundedRect: rect, cornerRadius: h / 2), with: .color(.black.opacity(0.6)))
        let fillRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width * CGFloat(max(0, min(1, fraction))), height: h)
        ctx.fill(Path(roundedRect: fillRect, cornerRadius: h / 2), with: .color(fraction > 0.35 ? Color.green : Color.orange))
        if let label {
            ctx.draw(Text(label).font(.system(size: h * 0.8, weight: .bold, design: .rounded)).foregroundColor(.white), at: center)
        }
    }

    private func drawProjectile(_ ctx: inout GraphicsContext, _ p: Projectile) {
        let c = pt(p.pos)
        let r = len(0.15)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                 with: .color(p.side == .player ? Color.cyan : Color.yellow))
    }

    private func drawEffect(_ ctx: inout GraphicsContext, _ e: SpellEffect) {
        let progress = 1 - max(0, min(1, e.ttl / 0.7))
        let r = len(e.radius) * CGFloat(0.4 + 0.6 * progress)
        let c = pt(e.pos)
        let rect = CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
        ctx.fill(Path(ellipseIn: rect), with: .color(e.color.opacity(0.45 * (1 - progress))))
        ctx.stroke(Path(ellipseIn: rect), with: .color(e.color.opacity(0.9 * (1 - progress))), lineWidth: 3)
    }
}
