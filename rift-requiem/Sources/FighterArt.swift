import SpriteKit

enum Ink {
    static let black = UIColor(red: 0.055, green: 0.055, blue: 0.075, alpha: 1)
    static let cream = UIColor(red: 0.96, green: 0.89, blue: 0.71, alpha: 1)
    static let red = UIColor(red: 0.78, green: 0.06, blue: 0.12, alpha: 1)
    static let darkRed = UIColor(red: 0.31, green: 0.025, blue: 0.08, alpha: 1)
    static let gold = UIColor(red: 0.76, green: 0.54, blue: 0.25, alpha: 1)
    static let steel = UIColor(red: 0.31, green: 0.38, blue: 0.43, alpha: 1)
    static let light = UIColor(red: 0.73, green: 0.85, blue: 0.87, alpha: 1)
    static let skin = UIColor(red: 0.91, green: 0.66, blue: 0.48, alpha: 1)
}

@discardableResult
func polygon(_ points: [(CGFloat, CGFloat)], _ fill: UIColor, on parent: SKNode,
             line: UIColor = Ink.black, width: CGFloat = 3) -> SKShapeNode {
    let path = CGMutablePath()
    guard let first = points.first else { return SKShapeNode() }
    path.move(to: CGPoint(x: first.0, y: first.1))
    for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
    path.closeSubpath()
    let shape = SKShapeNode(path: path)
    shape.fillColor = fill
    shape.strokeColor = line
    shape.lineWidth = width
    shape.lineJoin = .miter
    parent.addChild(shape)
    return shape
}

@discardableResult
func ring(_ radius: CGFloat, at point: CGPoint, on parent: SKNode,
          color: UIColor = Ink.gold, width: CGFloat = 3) -> SKShapeNode {
    let node = SKShapeNode(circleOfRadius: radius)
    node.position = point
    node.strokeColor = color
    node.lineWidth = width
    parent.addChild(node)
    return node
}

@MainActor
final class FighterArt: SKNode {
    let style: String
    let torso = SKNode()
    let backLeg = SKNode()
    let frontLeg = SKNode()
    let backArm = SKNode()
    let frontArm = SKNode()
    let weapon = SKNode()
    let coat = SKNode()
    let scarf = SKNode()
    let head = SKNode()
    private var previousPose = "idle"

    init(style: String) {
        self.style = style
        super.init()
        let slender = style == "vesper"
        backLeg.position = CGPoint(x: -15, y: 93)
        frontLeg.position = CGPoint(x: 16, y: 98)
        addChild(backLeg)
        addChild(coat)
        addChild(frontLeg)
        makeLeg(backLeg, slender: slender, back: true)
        makeLeg(frontLeg, slender: slender, back: false)
        torso.position.y = 115
        addChild(torso)
        backArm.position = CGPoint(x: -29, y: 56)
        torso.addChild(backArm)
        makeArm(backArm, slender: slender, armored: false)
        if slender { makeVesper() } else { makeRook() }
        frontArm.position = CGPoint(x: 31, y: 55)
        torso.addChild(frontArm)
        makeArm(frontArm, slender: slender, armored: !slender)
        weapon.position = CGPoint(x: 3, y: -70)
        frontArm.addChild(weapon)
        makeWeapon()
        head.position = CGPoint(x: 3, y: 93)
        torso.addChild(head)
        makeHead(slender: slender)
    }

    required init?(coder: NSCoder) { nil }

    private func makeLeg(_ node: SKNode, slender: Bool, back: Bool) {
        let width: CGFloat = slender ? 12 : 19
        polygon([(-width, 5), (width, 5), (width + 5, -38), (9, -65),
                 (-12, -58), (-width - 5, -24)], back ? Ink.steel : Ink.cream, on: node)
        polygon([(0, 2), (width, 3), (width + 5, -38), (9, -65), (2, -42)], Ink.steel, on: node, width: 1)
        polygon([(-13, -48), (14, -49), (18, -77), (34, -87), (30, -94),
                 (-16, -93), (-19, -82)], Ink.black, on: node)
        polygon([(-11, -55), (11, -55), (12, -62), (-12, -62)], Ink.gold, on: node, width: 1)
        polygon([(-10, -69), (13, -69), (14, -76), (-11, -76)], Ink.gold, on: node, width: 1)
        polygon([(-10, -87), (28, -87), (30, -94), (-16, -93)], Ink.steel, on: node, width: 1)
    }

    private func makeArm(_ node: SKNode, slender: Bool, armored: Bool) {
        let width: CGFloat = slender ? 11 : 17
        polygon([(-width, 8), (width + 2, 4), (width + 7, -30), (8, -46),
                 (-width, -32)], slender ? Ink.cream : Ink.skin, on: node)
        polygon([(4, 2), (width + 2, 4), (width + 7, -30), (8, -46),
                 (2, -25)], slender ? Ink.steel : Ink.gold, on: node, width: 1)
        polygon([(-12, -28), (18, -25), (22, -62), (10, -77),
                 (-11, -70), (-18, -48)], armored ? Ink.gold : Ink.black, on: node)
        for idx in 0..<3 {
            let offset = CGFloat(idx) * 11
            polygon([(-12, -33 - offset), (19, -30 - offset), (20, -35 - offset),
                     (-12, -38 - offset)], armored ? Ink.cream : Ink.steel, on: node, width: 1)
        }
        ring(7, at: CGPoint(x: 2, y: -52), on: node, color: Ink.red, width: 4)
        polygon([(-10, -64), (13, -62), (17, -76), (8, -84), (-12, -78)], Ink.skin, on: node)
    }

    private func makeRook() {
        polygon([(-40, 79), (-8, 89), (33, 81), (48, 50), (25, -10),
                 (-22, -7), (-48, 40)], Ink.red, on: torso)
        polygon([(-15, 77), (17, 74), (24, 37), (16, -5), (-18, -5),
                 (-24, 40)], Ink.black, on: torso)
        polygon([(-40, 79), (-20, 71), (-27, 26), (-44, 13), (-48, 40)], Ink.darkRed, on: torso, width: 1)
        polygon([(-27, 82), (-13, 78), (-21, 48), (-36, 68)], Ink.cream, on: torso)
        polygon([(18, 83), (32, 79), (39, 52), (21, 43)], Ink.cream, on: torso)
        polygon([(-27, 32), (31, 45), (33, 31), (-23, 18)], Ink.gold, on: torso)
        polygon([(-33, 8), (30, 5), (28, -10), (-30, -10)], Ink.black, on: torso)
        polygon([(-9, 9), (10, 9), (10, -10), (-9, -10)], Ink.gold, on: torso)
        polygon([(-4, 4), (5, 4), (5, -5), (-4, -5)], Ink.black, on: torso, width: 1)
        polygon([(-29, 116), (-6, 113), (-25, 58), (-57, 26), (-43, 78)],
                Ink.darkRed, on: coat)
        polygon([(8, 112), (30, 107), (59, 44), (36, 15), (20, 70)], Ink.red, on: coat)
        let shoulder = polygon([(-55, 71), (-47, 94), (-28, 92), (-21, 62),
                                (-32, 51)], Ink.gold, on: torso)
        ring(9, at: CGPoint(x: -39, y: 76), on: shoulder, color: Ink.black)
        for offset in [CGFloat(-46), -35, -24] {
            polygon([(offset, 70), (offset + 4, 70), (offset + 4, 60), (offset, 60)],
                    Ink.cream, on: torso, width: 1)
        }
        scarf.position = CGPoint(x: -14, y: 89)
        torso.addChild(scarf)
        polygon([(0, 0), (-39, 10), (-71, 3), (-104, 23), (-81, -2),
                 (-39, -7)], Ink.red, on: scarf)
    }

    private func makeVesper() {
        polygon([(-28, 85), (5, 91), (27, 78), (30, 50), (17, 0),
                 (-17, 0), (-33, 49)], Ink.cream, on: torso)
        polygon([(-7, 85), (7, 86), (15, 1), (-15, 1)], Ink.black, on: torso)
        polygon([(13, 83), (27, 78), (30, 50), (17, 0), (9, 0)], Ink.steel, on: torso, width: 1)
        polygon([(-31, 77), (-14, 91), (-7, 70), (-21, 50)], Ink.cream, on: torso)
        polygon([(7, 87), (16, 94), (32, 77), (15, 53)], Ink.cream, on: torso)
        polygon([(-22, 6), (24, 8), (24, -7), (-23, -10)], Ink.gold, on: torso)
        ring(10, at: CGPoint(x: 2, y: 2), on: torso, color: Ink.black)
        for index in 0..<4 {
            let yy = CGFloat(20 + index * 12)
            polygon([(-6, yy), (7, yy), (7, yy + 3), (-6, yy + 3)], Ink.gold, on: torso, width: 1)
        }
        polygon([(-23, 126), (-1, 121), (-13, 67), (-55, 8), (-77, 28),
                 (-47, 68)], Ink.cream, on: coat)
        polygon([(2, 121), (26, 120), (48, 64), (72, 21), (40, 5),
                 (10, 66)], Ink.cream, on: coat)
        polygon([(-27, 109), (-30, 70), (-59, 23), (-67, 27)],
                Ink.steel, on: coat, width: 1)
        polygon([(26, 109), (48, 64), (72, 21), (55, 13), (34, 70)], Ink.steel, on: coat, width: 1)
        polygon([(-52, 20), (-42, 34), (-39, 29), (-48, 14)], Ink.gold, on: coat, width: 1)
        scarf.position = CGPoint(x: -14, y: 83)
        torso.addChild(scarf)
        polygon([(2, 0), (-30, 16), (-63, 12), (-95, 32), (-69, 3),
                 (-30, -3)], Ink.black, on: scarf)
    }

    private func makeHead(slender: Bool) {
        polygon([(-7, -10), (12, -10), (13, 12), (-8, 17)], Ink.skin, on: head)
        polygon([(-15, 12), (-16, 38), (0, 52), (22, 40), (23, 14),
                 (10, 1), (-1, 2)], Ink.skin, on: head)
        polygon([(12, 39), (22, 39), (23, 14), (10, 1), (4, 13)], Ink.gold, on: head, width: 1)
        if slender {
            polygon([(-18, 14), (-25, 35), (-14, 59), (6, 67), (39, 53),
                     (25, 51), (34, 35), (18, 42), (15, 25), (8, 46),
                     (-7, 30), (-4, 9)], Ink.cream, on: head)
            polygon([(-20, 36), (-27, 12), (-42, 3), (-29, 31), (-31, 52),
                     (-9, 60)], Ink.steel, on: head)
        } else {
            polygon([(-21, 16), (-30, 36), (-25, 52), (-36, 59), (-10, 61),
                     (-1, 77), (8, 61), (27, 65), (24, 51), (41, 48),
                     (22, 33), (14, 44), (2, 24), (-2, 44), (-14, 25)], Ink.black, on: head)
            polygon([(-27, 50), (-11, 61), (2, 66), (-2, 48), (-13, 37)],
                    Ink.darkRed, on: head, width: 1)
            polygon([(-18, 33), (22, 37), (25, 30), (-17, 27)], Ink.red, on: head)
        }
        polygon([(6, 25), (20, 25), (17, 20), (9, 20)], UIColor.white, on: head, width: 1)
        polygon([(16, 25), (20, 25), (17, 20), (15, 20)], Ink.red, on: head, width: 1)
        polygon([(12, 10), (20, 12), (17, 8)], Ink.black, on: head, width: 1)
    }

    private func makeWeapon() {
        if style == "vesper" {
            polygon([(-4, -63), (4, -63), (4, 176), (-4, 176)], Ink.steel, on: weapon)
            polygon([(-2, -54), (1, -54), (1, 163), (-2, 163)], Ink.cream, on: weapon, width: 0)
            polygon([(-8, 160), (-8, 181), (12, 201), (52, 207), (92, 191),
                     (117, 159), (123, 112), (110, 143), (83, 171), (51, 179),
                     (20, 171), (8, 157)], Ink.cream, on: weapon)
            polygon([(12, 188), (48, 196), (84, 186), (108, 161), (110, 143),
                     (83, 171), (51, 179), (20, 171)], Ink.steel, on: weapon, width: 1)
            ring(11, at: CGPoint(x: 0, y: 158), on: weapon, color: Ink.gold, width: 6)
            polygon([(-7, -28), (8, -28), (8, -9), (-7, -9)], Ink.red, on: weapon)
            for index in 0..<7 {
                ring(5, at: CGPoint(x: CGFloat(index) * -8, y: -55 - CGFloat(index % 3) * 4),
                     on: weapon, color: Ink.gold, width: 2)
            }
        } else {
            polygon([(-7, -34), (8, -34), (8, 30), (-7, 30)], Ink.black, on: weapon)
            polygon([(-31, 27), (35, 27), (38, 42), (-32, 42)], Ink.gold, on: weapon)
            polygon([(-27, 43), (32, 43), (47, 152), (28, 184), (-24, 172),
                     (-36, 145)], Ink.red, on: weapon)
            polygon([(16, 46), (32, 43), (47, 152), (28, 184), (19, 164)],
                    Ink.cream, on: weapon)
            polygon([(-20, 50), (8, 50), (17, 157), (-19, 147)], Ink.black, on: weapon)
            for index in 0..<5 {
                let yy = CGFloat(58 + index * 18)
                polygon([(-33, yy), (-20, yy + 3), (-21, yy + 12), (-39, yy + 11)],
                        Ink.steel, on: weapon)
                polygon([(-12, yy), (7, yy), (8, yy + 7), (-12, yy + 7)],
                        Ink.gold, on: weapon, width: 1)
            }
            ring(12, at: CGPoint(x: -4, y: 143), on: weapon, color: Ink.gold, width: 5)
        }
    }

    func animate(pose: String, frame: Int, time: Double, facing: Double, stunned: Bool) {
        let pulse = CGFloat(sin(time * 4))
        xScale = facing
        let running = pose == "run"
        let stride = CGFloat(sin(time * 19))
        backLeg.zRotation = running ? stride * 0.65 : -0.24
        frontLeg.zRotation = running ? -stride * 0.65 : 0.27
        torso.zRotation = pose == "dash" ? -0.43 : stunned ? 0.24 : pulse * 0.016
        torso.position.y = 113 + (running ? abs(stride) * 5 : pulse * 2)
        frontArm.zRotation = -0.22
        backArm.zRotation = 0.35
        weapon.zRotation = style == "vesper" ? -0.55 : 0.55
        scarf.zRotation = pulse * 0.10 + (running || pose == "dash" ? -0.24 : 0)
        coat.zRotation = pulse * 0.04
        head.zRotation = -torso.zRotation * 0.3
        if pose == "jump" || pose == "dash" {
            frontLeg.zRotation = 0.95; backLeg.zRotation = -0.8
            backArm.zRotation = -0.7
        }
        if pose == "guard" {
            frontArm.zRotation = -1.7
            weapon.zRotation = 0.4
            torso.zRotation = 0.10
        }
        if ["slash", "heavy", "special"].contains(pose) {
            let startup = pose == "heavy" ? 15.0 : pose == "special" ? 19.0 : 6.0
            let progress = CGFloat(min(1, max(0, (Double(frame) - startup + 4) / 9)))
            frontArm.zRotation = 1.9 - progress * 3.1
            weapon.zRotation = 0.15 - progress * 0.95
            torso.zRotation = 0.18 - progress * 0.45
            backArm.zRotation = -0.5 + progress
            frontLeg.zRotation = 0.40
            if pose == "special" { weapon.zRotation = -0.2; frontArm.zRotation = 1.1 }
        }
        alpha = stunned && Int(time * 24) % 2 == 0 ? 0.72 : 1
        previousPose = pose
    }
}
