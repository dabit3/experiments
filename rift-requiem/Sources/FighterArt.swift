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
    static let skinShadow = color(0x98566b)
    static let skinLight = color(0xffd7b0)
    static let leather = color(0x282b42)
    static let leatherLight = color(0x51556b)
    static let white = color(0xfff5df)
    static let violet = color(0x77738d)

    static func color(_ rgb: UInt32) -> UIColor {
        UIColor(red: CGFloat((rgb >> 16) & 255) / 255,
                green: CGFloat((rgb >> 8) & 255) / 255,
                blue: CGFloat(rgb & 255) / 255, alpha: 1)
    }
}

@discardableResult
func polygon(_ points: [(CGFloat, CGFloat)], _ fill: UIColor, on parent: SKNode,
             line: UIColor = Ink.black, width: CGFloat = 3) -> SKShapeNode {
    let shape = contour(points, fill, on: parent, line: line, width: width, tension: 0)
    shape.lineJoin = .miter
    return shape
}

@discardableResult
private func contour(_ points: [(CGFloat, CGFloat)], _ fill: UIColor, on parent: SKNode,
                     line: UIColor = Ink.black, width: CGFloat = 2,
                     tension: CGFloat = 0.17) -> SKShapeNode {
    let path = CGMutablePath()
    guard let first = points.first, points.count >= 3 else { return SKShapeNode() }
    path.move(to: CGPoint(x: first.0, y: first.1))
    for index in points.indices {
        let previous = points[(index + points.count - 1) % points.count]
        let point = points[index]
        let next = points[(index + 1) % points.count]
        let following = points[(index + 2) % points.count]
        path.addCurve(to: CGPoint(x: next.0, y: next.1),
                      control1: CGPoint(x: point.0 + (next.0 - previous.0) * tension,
                                        y: point.1 + (next.1 - previous.1) * tension),
                      control2: CGPoint(x: next.0 - (following.0 - point.0) * tension,
                                        y: next.1 - (following.1 - point.1) * tension))
    }
    path.closeSubpath()
    let shape = SKShapeNode(path: path)
    shape.fillColor = fill
    shape.strokeColor = line
    shape.lineWidth = width
    shape.lineJoin = .round
    parent.addChild(shape)
    return shape
}

private func seam(_ points: [(CGFloat, CGFloat)], on parent: SKNode,
                  color: UIColor = Ink.black, width: CGFloat = 1.2) {
    guard let first = points.first else { return }
    let path = CGMutablePath()
    path.move(to: CGPoint(x: first.0, y: first.1))
    for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0, y: point.1)) }
    let shape = SKShapeNode(path: path)
    shape.strokeColor = color
    shape.lineWidth = width
    shape.lineCap = .round
    shape.lineJoin = .round
    parent.addChild(shape)
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
    private let torso = SKNode()
    private let backLeg = SKNode()
    private let frontLeg = SKNode()
    private let backShin = SKNode()
    private let frontShin = SKNode()
    private let backArm = SKNode()
    private let frontArm = SKNode()
    private let backForearm = SKNode()
    private let frontForearm = SKNode()
    private let weapon = SKNode()
    private let backTail = SKNode()
    private let frontTail = SKNode()
    private let scarf = SKNode()
    private let head = SKNode()
    private let swing = SKNode()
    private var slender: Bool { style == "vesper" }

    init(style: String) {
        self.style = style
        super.init()
        addChild(backTail)
        addChild(backLeg)
        addChild(frontTail)
        addChild(frontLeg)
        makeLeg(backLeg, shin: backShin, rear: true)
        makeLeg(frontLeg, shin: frontShin, rear: false)
        makeTails()
        addChild(torso)
        backArm.position = CGPoint(x: slender ? -20 : -27, y: 61)
        torso.addChild(backArm)
        makeArm(backArm, forearm: backForearm, rear: true)
        makeBody()
        head.position = CGPoint(x: 3, y: 81)
        torso.addChild(head)
        makeHead()
        frontArm.position = CGPoint(x: slender ? 21 : 29, y: 61)
        torso.addChild(frontArm)
        makeArm(frontArm, forearm: frontForearm, rear: false)
        weapon.position.y = -33
        frontForearm.addChild(weapon)
        makeWeapon()
        makeHand(on: frontForearm)
        makeHand(on: backForearm)
        addChild(swing)
        makeSwing()
    }

    required init?(coder: NSCoder) { nil }

    private func makeLeg(_ thigh: SKNode, shin: SKNode, rear: Bool) {
        let wide: CGFloat = slender ? 10 : 14
        contour([(-wide, 6), (wide - 1, 5), (wide + 2, -17), (8, -48),
                 (-8, -50), (-wide - 3, -24)], Ink.leather, on: thigh)
        contour([(-wide + 2, 3), (0, 2), (1, -17), (-4, -40), (-9, -35)],
                rear ? Ink.steel : Ink.leatherLight, on: thigh, width: 0)
        polygon([(5, -5), (wide - 1, -14), (6, -44), (0, -37)],
                Ink.black, on: thigh, width: 0)
        seam([(-wide, -9), (-3, -12), (wide, -8)], on: thigh, color: Ink.gold, width: 2)
        polygon([(-5, -7), (3, -8), (2, -15), (-5, -14)], Ink.gold, on: thigh, width: 1)
        polygon([(-3, -9), (1, -10), (0, -13), (-3, -12)], Ink.black, on: thigh, width: 0)
        seam([(-10, -20), (-5, -23), (-7, -29)], on: thigh)
        shin.position.y = -48
        thigh.addChild(shin)
        contour([(-9, 4), (10, 4), (11, -15), (7, -34), (20, -42),
                 (25, -46), (24, -52), (-11, -52), (-13, -42), (-10, -24)],
                Ink.black, on: shin)
        contour([(-7, 1), (4, 2), (6, -13), (2, -37), (-8, -42), (-9, -23)],
                rear ? Ink.leather : Ink.steel, on: shin, width: 0)
        polygon([(5, -15), (10, -12), (7, -34), (20, -43), (8, -42), (0, -37)],
                Ink.leatherLight, on: shin, width: 0)
        contour([(-10, 3), (-3, 8), (7, 6), (11, -1), (7, -10), (-5, -13), (-11, -6)],
                slender ? Ink.cream : Ink.gold, on: shin, width: 1.6)
        polygon([(0, 5), (8, 1), (7, -7), (-5, -10), (2, -3)],
                slender ? Ink.violet : Ink.steel, on: shin, width: 0)
        seam([(-7, 1), (-3, 5), (3, 4)], on: shin, color: Ink.white)
        for offset: CGFloat in [18, 29] {
            seam([(-10, -offset), (0, -offset - 2), (8, -offset + 1)],
                 on: shin, color: Ink.gold, width: 3)
            polygon([(-3, -offset + 2), (3, -offset + 2), (3, -offset - 5), (-3, -offset - 5)],
                    Ink.cream, on: shin, width: 1)
        }
        seam([(-10, -48), (5, -49), (22, -48)], on: shin, color: Ink.steel, width: 2)
        seam([(7, -41), (14, -40), (20, -43)], on: shin, color: Ink.light)
    }

    private func makeArm(_ upper: SKNode, forearm: SKNode, rear: Bool) {
        let wide: CGFloat = slender ? 8 : 12
        contour([(-wide, 3), (-6, 10), (6, 9), (wide, 1), (wide + 1, -13),
                 (7, -30), (3, -36), (-7, -34), (-wide, -16)],
                slender ? Ink.cream : Ink.skin, on: upper)
        contour([(3, 8), (wide - 1, 1), (wide, -12), (6, -29), (1, -34),
                 (-4, -29), (2, -18)],
                slender ? Ink.violet : Ink.skinShadow, on: upper, width: 0)
        contour([(-7, 2), (-2, 6), (3, 0), (0, -10), (-6, -17), (-9, -8)],
                slender ? Ink.white : Ink.skinLight, on: upper, width: 0)
        seam([(-8, -17), (-3, -13), (2, -17), (1, -23)], on: upper,
             color: slender ? Ink.gold : Ink.skinShadow)
        seam([(-5, -28), (1, -26), (5, -28)], on: upper)
        if slender {
            seam([(-9, -7), (0, -10), (8, -5)], on: upper, color: Ink.gold, width: 2)
        } else if !rear {
            contour([(-13, 1), (-14, 9), (-5, 16), (8, 12), (14, 3), (10, -5), (-6, -8)],
                    Ink.gold, on: upper)
            contour([(-12, 8), (-4, 13), (7, 9), (10, 3), (2, 6), (-8, 4)],
                    Ink.cream, on: upper, width: 0)
            polygon([(3, 5), (12, 1), (9, -4), (-5, -6), (0, 0)], Ink.steel, on: upper, width: 0)
            ring(4, at: CGPoint(x: -3, y: 4), on: upper, color: Ink.black, width: 2)
        }
        forearm.position.y = -34
        upper.addChild(forearm)
        contour([(-7, 4), (8, 3), (11, -7), (8, -23), (5, -31),
                 (-6, -31), (-10, -12)], slender || rear ? Ink.leather : Ink.gold, on: forearm)
        contour([(-6, 1), (0, 2), (2, -9), (-1, -26), (-5, -28), (-7, -14)],
                slender || rear ? Ink.steel : Ink.cream, on: forearm, width: 0)
        polygon([(6, -2), (10, -8), (7, -23), (3, -30), (0, -26)],
                slender || rear ? Ink.black : Ink.darkRed, on: forearm, width: 0)
        for offset: CGFloat in [8, 18] {
            seam([(-8, -offset), (0, -offset - 3), (8, -offset + 1)],
                 on: forearm, color: slender ? Ink.gold : Ink.black, width: 1.8)
        }
        ring(slender ? 3 : 4, at: CGPoint(x: 1, y: -13), on: forearm,
             color: slender ? Ink.light : Ink.red, width: 2)
        seam([(-7, -27), (5, -28)], on: forearm, color: Ink.gold, width: 2)
    }

    private func makeHand(on forearm: SKNode) {
        contour([(-5, -29), (4, -29), (8, -34), (7, -40), (-2, -41), (-7, -37)],
                Ink.skin, on: forearm, width: 1.6)
        contour([(-4, -30), (1, -30), (3, -34), (0, -37), (-5, -35)],
                Ink.skinLight, on: forearm, width: 0)
        for offset: CGFloat in [0, 3, 6] {
            seam([(offset, -35), (offset, -39)], on: forearm, color: Ink.skinShadow, width: 1)
        }
        seam([(-5, -32), (-1, -35), (3, -34)], on: forearm, width: 1.1)
    }

    private func makeTails() {
        for (index, tail) in [backTail, frontTail].enumerated() {
            let side: CGFloat = index == 0 ? -1 : 1
            tail.xScale = side
            let length: CGFloat = slender ? 89 : 72
            contour([(1, 5), (22, 5), (28, -23), (41, -length + 16),
                     (33, -length), (11, -length + 11), (4, -30)],
                    slender ? Ink.cream : Ink.red, on: tail)
            contour([(14, 1), (22, 2), (26, -23), (38, -length + 15),
                     (32, -length + 3), (22, -length + 18), (20, -29)],
                    slender ? Ink.violet : Ink.darkRed, on: tail, width: 0)
            contour([(3, 2), (9, 3), (10, -28), (18, -length + 17),
                     (13, -length + 13), (7, -38)],
                    slender ? Ink.white : Ink.color(0xf14448), on: tail, width: 0)
            seam([(3, -8), (8, -38), (14, -length + 14), (32, -length + 4)],
                 on: tail, color: Ink.gold, width: 1.5)
            if slender {
                polygon([(20, -56), (24, -63), (20, -74), (16, -65)], Ink.gold, on: tail, width: 1)
                seam([(16, -62), (27, -65)], on: tail, color: Ink.gold, width: 1.5)
            }
        }
    }

    private func makeBody() {
        let wide: CGFloat = slender ? 24 : 32
        contour([(-wide, 62), (-17, 73), (2, 76), (wide, 63), (wide - 4, 41),
                 (16, 22), (21, 0), (8, -8), (-20, -3), (-19, 25), (-wide, 44)],
                slender ? Ink.cream : Ink.red, on: torso)
        contour([(-wide, 60), (-20, 62), (-13, 45), (-15, 28), (-12, 5),
                 (-20, 0), (-21, 25), (-wide + 2, 40)],
                slender ? Ink.violet : Ink.darkRed, on: torso, width: 0)
        contour([(15, 69), (wide - 1, 61), (wide - 6, 43), (14, 26), (19, 3),
                 (11, -3), (7, 29), (16, 51)],
                slender ? Ink.violet : Ink.darkRed, on: torso, width: 0)
        contour([(-17, 63), (-5, 72), (13, 65), (12, 47), (7, 27), (11, 0),
                 (-11, -2), (-12, 30), (-19, 47)], Ink.black, on: torso, width: 1.5)
        contour([(-14, 57), (-3, 61), (8, 54), (5, 43), (-4, 40), (-12, 46)],
                Ink.leatherLight, on: torso, width: 0)
        polygon([(-10, 39), (5, 38), (4, 21), (-6, 16), (-9, 26)],
                Ink.leather, on: torso, width: 0)
        seam([(-10, 48), (0, 46), (7, 49)], on: torso)
        seam([(-7, 33), (4, 32)], on: torso, color: Ink.steel)
        seam([(-6, 22), (4, 22)], on: torso, color: Ink.steel)
        contour([(-7, 69), (-8, 87), (6, 91), (10, 72), (3, 65)],
                Ink.skin, on: torso, width: 1.5)
        polygon([(-7, 86), (5, 89), (7, 76), (1, 69), (-5, 73)],
                Ink.skinShadow, on: torso, width: 0)
        polygon([(-21, 78), (-7, 73), (-11, 56), (-24, 68)], Ink.cream, on: torso, width: 1.8)
        polygon([(10, 74), (19, 82), (29, 67), (13, 54)], Ink.cream, on: torso, width: 1.8)
        polygon([(-20, 74), (-10, 71), (-12, 63)], Ink.white, on: torso, width: 0)
        polygon([(14, 73), (19, 77), (25, 67), (17, 65)], Ink.white, on: torso, width: 0)
        seam([(-25, 57), (-21, 39), (-16, 12)], on: torso, color: slender ? Ink.gold : Ink.color(0xf96a5e))
        seam([(24, 52), (17, 35), (19, 16)], on: torso, color: Ink.gold)
        if slender {
            for height: CGFloat in [19, 30, 41] {
                seam([(-7, height), (-1, height - 2), (7, height + 1)], on: torso, color: Ink.gold, width: 2)
                ring(1.7, at: CGPoint(x: 8, y: height + 1), on: torso, color: Ink.cream, width: 1)
            }
            polygon([(0, 62), (4, 56), (0, 46), (-4, 56)], Ink.red, on: torso, line: Ink.gold, width: 1.2)
        } else {
            polygon([(-25, 45), (26, 64), (29, 56), (-22, 36)], Ink.leather, on: torso, width: 1.5)
            seam([(-22, 43), (25, 60)], on: torso, color: Ink.gold, width: 1.5)
            polygon([(3, 57), (13, 60), (15, 49), (5, 46)], Ink.gold, on: torso, width: 1)
            polygon([(6, 54), (11, 56), (12, 51), (8, 50)], Ink.black, on: torso, width: 0)
            for offset: CGFloat in [-17, -10, -3] {
                ring(1.2, at: CGPoint(x: offset, y: 43 + offset * 0.35), on: torso, color: Ink.cream, width: 1)
            }
        }
        contour([(-21, 7), (-3, 5), (20, 8), (21, -1), (-4, -6), (-22, -3)],
                Ink.black, on: torso, width: 1.5)
        seam([(-21, 4), (-4, 2), (20, 5)], on: torso, color: Ink.gold)
        polygon([(-6, 7), (7, 8), (9, -5), (-6, -7)], Ink.gold, on: torso, width: 1.5)
        polygon([(-2, 4), (4, 5), (5, -2), (-2, -3)], Ink.black, on: torso, width: 0)
        for index in 0..<6 {
            let xx = CGFloat(index) * 3.3 + 11
            let yy = -8 - sin(CGFloat(index) * .pi / 6) * 9
            ring(2.2, at: CGPoint(x: xx, y: yy), on: torso, color: Ink.gold, width: 1.2)
        }
        scarf.position = CGPoint(x: -8, y: 77)
        scarf.zPosition = -1
        torso.addChild(scarf)
        contour([(2, 1), (-19, 8), (-45, 4), (-77, 17), (-60, -1), (-34, -8), (-12, -5)],
                slender ? Ink.leather : Ink.darkRed, on: scarf, width: 1.6)
        contour([(-13, 4), (-35, 0), (-55, 4), (-72, 13), (-52, -1), (-33, -4)],
                slender ? Ink.steel : Ink.red, on: scarf, width: 0)
        seam([(-17, 5), (-38, 3), (-55, 7)], on: scarf, color: slender ? Ink.gold : Ink.color(0xf76a5f))
    }

    private func makeHead() {
        contour([(-12, 12), (-13, 27), (-4, 35), (9, 33), (15, 25),
                 (14, 16), (18, 12), (15, 9), (14, 3), (5, -2), (-3, 2)],
                Ink.skin, on: head, width: 1.8)
        contour([(-12, 26), (-5, 29), (-4, 17), (0, 7), (9, 1), (5, -1), (-4, 3), (-11, 12)],
                Ink.skinShadow, on: head, width: 0)
        polygon([(3, 26), (11, 27), (13, 20), (10, 14), (15, 12), (7, 11), (3, 16)],
                Ink.skinLight, on: head, width: 0)
        contour([(-12, 19), (-16, 19), (-17, 14), (-13, 10), (-10, 12)],
                Ink.skin, on: head, width: 1.2)
        seam([(-14, 17), (-12, 16), (-13, 13)], on: head, color: Ink.skinShadow)
        polygon([(0, 20), (5, 22), (13, 21), (10, 17), (4, 17)],
                Ink.white, on: head, width: 0.8)
        contour([(7, 21), (10, 21), (10, 17), (7, 17)],
                slender ? Ink.color(0x9071da) : Ink.red, on: head, width: 0)
        seam([(9, 20), (9, 18)], on: head, width: 1)
        seam([(-1, 23), (5, 24), (13, 22)], on: head, width: slender ? 1.3 : 2)
        seam([(11, 18), (10, 13), (13, 12)], on: head, color: Ink.skinShadow, width: 0.8)
        seam([(8, 6), (13, 7)], on: head, width: 0.9)
        seam([(8, 3), (11, 4)], on: head, color: Ink.skinLight, width: 1)
        if slender {
            contour([(-14, 12), (-20, 25), (-15, 39), (-3, 47), (15, 43), (28, 34),
                     (17, 35), (19, 27), (10, 31), (4, 23), (1, 33), (-6, 25), (-8, 10)],
                    Ink.cream, on: head, width: 1.8, tension: 0.05)
            polygon([(-16, 28), (-9, 40), (6, 43), (19, 37), (4, 37), (-4, 31), (-8, 17)],
                    Ink.white, on: head, width: 0)
            polygon([(-15, 29), (-7, 34), (-10, 18), (-7, 9), (-15, 13), (-20, 25)],
                    Ink.violet, on: head, width: 0)
            seam([(-8, 38), (5, 39), (15, 36)], on: head, color: Ink.gold, width: 0.8)
            seam([(5, 32), (4, 27)], on: head, color: Ink.violet, width: 0.8)
            contour([(-17, 25), (-21, 16), (-19, 4), (-31, -5), (-24, 11), (-25, 26)],
                    Ink.violet, on: head, width: 1.3)
            seam([(-22, 20), (-22, 5), (-28, -2)], on: head, color: Ink.white)
            ring(2.2, at: CGPoint(x: -14, y: 10), on: head, color: Ink.gold, width: 1.4)
            polygon([(-14, 7), (-11, 3), (-14, -4), (-17, 3)], Ink.red, on: head, width: 0.8)
        } else {
            contour([(-14, 12), (-22, 27), (-19, 36), (-27, 42), (-13, 42), (-7, 51),
                     (0, 43), (12, 48), (12, 39), (26, 38), (18, 30), (11, 28),
                     (8, 35), (1, 23), (-2, 34), (-10, 24), (-10, 12)],
                    Ink.black, on: head, width: 1.8, tension: 0.03)
            polygon([(-18, 36), (-8, 44), (-3, 42), (-8, 35), (-13, 28)],
                    Ink.leatherLight, on: head, width: 0)
            polygon([(0, 40), (8, 44), (7, 36), (1, 28)], Ink.darkRed, on: head, width: 0)
            seam([(-17, 36), (-11, 38), (-16, 29)], on: head, color: Ink.steel, width: 0.8)
            polygon([(-13, 27), (15, 30), (15, 26), (-12, 22)], Ink.red, on: head, width: 0.7)
            seam([(-11, 26), (12, 29)], on: head, color: Ink.color(0xff7262), width: 1)
            seam([(-1, 14), (2, 8)], on: head, color: Ink.skinShadow, width: 1.1)
        }
    }

    private func makeWeapon() {
        if slender {
            polygon([(-3, -58), (3, -58), (3, 144), (-3, 144)], Ink.steel, on: weapon, width: 1.5)
            seam([(-1, -52), (-1, 139)], on: weapon, color: Ink.white, width: 1.5)
            contour([(-7, 140), (-8, 157), (13, 178), (49, 182), (84, 166), (104, 132),
                     (102, 103), (92, 133), (67, 153), (40, 157), (17, 149), (8, 136)],
                    Ink.cream, on: weapon, width: 2.5, tension: 0.14)
            contour([(6, 159), (20, 169), (48, 172), (78, 159), (94, 137),
                     (90, 135), (66, 153), (40, 157), (18, 152)],
                    Ink.steel, on: weapon, width: 0)
            seam([(16, 175), (45, 178), (77, 165), (97, 141)], on: weapon, color: Ink.white, width: 2)
            contour([(19, 164), (40, 168), (63, 164), (75, 157), (42, 161)],
                    Ink.light, on: weapon, width: 0)
            ring(9, at: CGPoint(x: 0, y: 143), on: weapon, color: Ink.gold, width: 4)
            ring(3, at: CGPoint(x: 0, y: 143), on: weapon, color: Ink.red, width: 3)
            for yy: CGFloat in [-25, -13, -1, 11] {
                seam([(-4, yy), (4, yy + 4)], on: weapon, color: Ink.darkRed, width: 4)
            }
            for index in 0..<7 {
                ring(3, at: CGPoint(x: CGFloat(index) * -5, y: -53 - CGFloat(index % 3) * 3),
                     on: weapon, color: Ink.gold, width: 1.5)
            }
        } else {
            polygon([(-5, -24), (5, -24), (5, 24), (-5, 24)], Ink.black, on: weapon, width: 1.5)
            for yy: CGFloat in [-17, -7, 3, 13] {
                seam([(-4, yy), (4, yy + 3)], on: weapon, color: Ink.gold, width: 2)
            }
            polygon([(-26, 23), (28, 23), (31, 33), (-27, 33)], Ink.gold, on: weapon, width: 2)
            seam([(-24, 31), (28, 31)], on: weapon, color: Ink.cream, width: 2)
            polygon([(-22, 35), (27, 35), (37, 128), (22, 153), (-20, 144), (-30, 119)],
                    Ink.darkRed, on: weapon, width: 2.5)
            polygon([(-18, 39), (19, 38), (23, 121), (14, 142), (-16, 135)],
                    Ink.red, on: weapon, width: 0)
            polygon([(15, 39), (27, 35), (37, 128), (22, 153), (16, 136)],
                    Ink.cream, on: weapon, width: 1.5)
            seam([(28, 43), (34, 128), (22, 149)], on: weapon, color: Ink.white, width: 2)
            polygon([(-16, 43), (5, 43), (12, 132), (-15, 125)], Ink.black, on: weapon, width: 1.2)
            for index in 0..<5 {
                let yy = CGFloat(48 + index * 15)
                polygon([(-25, yy), (-16, yy + 2), (-17, yy + 10), (-32, yy + 8)],
                        Ink.steel, on: weapon, width: 1.2)
                seam([(-30, yy + 8), (-18, yy + 9)], on: weapon, color: Ink.light)
                polygon([(-10, yy), (4, yy), (5, yy + 5), (-10, yy + 5)],
                        Ink.gold, on: weapon, width: 0.8)
            }
            ring(9, at: CGPoint(x: -2, y: 119), on: weapon, color: Ink.gold, width: 3)
            ring(4, at: CGPoint(x: -2, y: 119), on: weapon, color: Ink.cream, width: 2)
        }
    }

    private func makeSwing() {
        contour([(-58, 232), (42, 246), (152, 201), (217, 116), (186, 132),
                 (134, 193), (37, 232)], Ink.white.withAlphaComponent(0.65), on: swing, width: 0)
        contour([(-43, 222), (48, 230), (135, 185), (181, 136), (149, 156),
                 (96, 190), (30, 218)], (slender ? Ink.light : Ink.red).withAlphaComponent(0.65),
                on: swing, width: 0)
    }

    private func aim(_ upper: SKNode, lower: SKNode, at target: CGPoint,
                     lengths: (CGFloat, CGFloat), bend: CGFloat) {
        let delta = CGPoint(x: target.x - upper.position.x, y: target.y - upper.position.y)
        let distance = min(lengths.0 + lengths.1 - 0.01, max(1, hypot(delta.x, delta.y)))
        let base = atan2(delta.x, -delta.y)
        let cosine = (lengths.0 * lengths.0 + distance * distance - lengths.1 * lengths.1)
            / (2 * lengths.0 * distance)
        upper.zRotation = base + bend * acos(min(1, max(-1, cosine)))
        let end = CGPoint(x: sin(base) * distance, y: -cos(base) * distance)
        let elbow = CGPoint(x: sin(upper.zRotation) * lengths.0, y: -cos(upper.zRotation) * lengths.0)
        lower.zRotation = atan2(end.x - elbow.x, -(end.y - elbow.y)) - upper.zRotation
    }

    func animate(pose: String, frame: Int, time: Double, facing: Double, stunned: Bool) {
        let breath = CGFloat(sin(time * 3.4))
        let stride = CGFloat(sin(time * 17))
        let running = pose == "run"
        xScale = facing
        torso.position = CGPoint(x: 0, y: 108 + breath * 1.2)
        torso.zRotation = slender ? -0.045 : -0.025
        backLeg.position = CGPoint(x: -12, y: 99)
        frontLeg.position = CGPoint(x: 12, y: 99)
        var frontFoot = CGPoint(x: 37, y: 13)
        var backFoot = CGPoint(x: -37, y: 13)
        var frontHand = CGPoint(x: slender ? 50 : 54, y: 12)
        var backHand = CGPoint(x: -15, y: 18)
        var blade: CGFloat = slender ? 0.22 : -0.48
        var frontBend: CGFloat = -1
        var backBend: CGFloat = 1
        swing.isHidden = true
        if running {
            torso.position.y += abs(stride) * 3
            torso.zRotation = -0.22
            frontFoot = CGPoint(x: 12 + stride * 40, y: 13 + max(0, stride) * 31)
            backFoot = CGPoint(x: -12 - stride * 40, y: 13 + max(0, -stride) * 31)
            frontHand = CGPoint(x: 37, y: 20 + stride * 10)
            backHand = CGPoint(x: -38, y: 24 - stride * 16)
            blade = slender ? 0.60 : 0.35
        } else if pose == "dash" || pose == "jump" {
            torso.zRotation = pose == "dash" ? -0.47 : -0.14
            torso.position.y -= 5
            frontFoot = CGPoint(x: 53, y: 45)
            backFoot = CGPoint(x: -40, y: 61)
            frontHand = CGPoint(x: 47, y: 33)
            backHand = CGPoint(x: -50, y: 57)
            blade = 0.75
        } else if pose == "guard" {
            torso.position.y -= 8
            torso.zRotation = 0.12
            frontLeg.position.y -= 6
            backLeg.position.y -= 6
            frontHand = CGPoint(x: 49, y: 65)
            backHand = CGPoint(x: 9, y: 58)
            blade = -0.08
            backBend = -1
        } else if ["slash", "heavy", "special"].contains(pose) {
            let heavy = pose == "heavy"
            let startup: CGFloat = heavy ? 15 : pose == "special" ? 19 : 6
            let active: CGFloat = heavy ? 7 : pose == "special" ? 1 : 5
            let recovery: CGFloat = heavy ? 25 : pose == "special" ? 30 : 15
            let tick = CGFloat(frame)
            let swingTime = min(1, max(0, (tick - startup + 2) / (active + 2)))
            let snap = swingTime * swingTime * (3 - 2 * swingTime)
            let settle = min(1, max(0, (tick - startup - active - 3) / max(1, recovery - 3)))
            let hold = 1 - settle * settle
            let wind = min(1, tick / max(1, startup - 2))
            let startHand = CGPoint(x: heavy ? -3 : 2, y: heavy ? 112 : 79)
            let endHand = CGPoint(x: heavy ? 54 : 81, y: heavy ? 37 : 56)
            frontHand = CGPoint(x: (startHand.x + (endHand.x - startHand.x) * snap) * hold + 54 * (1 - hold),
                                y: (startHand.y + (endHand.y - startHand.y) * snap) * hold + 12 * (1 - hold))
            blade = ((heavy ? 0.95 : 1.45) - (heavy ? 2.8 : 3.1) * snap) * hold - 0.48 * (1 - hold)
            torso.zRotation = (0.16 * wind - 0.48 * snap) * hold
            torso.position.x = 8 * snap * hold
            torso.position.y -= 7 * snap * hold
            frontLeg.position.y -= 5 * snap * hold
            backLeg.position.y -= 5 * snap * hold
            frontFoot.x += 10 * snap * hold
            backFoot.x -= 10 * snap * hold
            backHand = heavy
                ? CGPoint(x: frontHand.x - 12, y: frontHand.y - 7)
                : CGPoint(x: -43 + snap * 17, y: 67 - snap * 33)
            frontBend = heavy ? 1 : -1
            backBend = -1
            swing.isHidden = tick < startup || tick >= startup + active || pose == "special"
            swing.alpha = 0.8 - snap * 0.35
            if pose == "special" {
                frontHand = CGPoint(x: 58, y: 36)
                backHand = CGPoint(x: 38 + 20 * snap, y: 55)
                blade = -0.24 - snap * 0.95 * hold
                torso.zRotation = -0.12 * hold
                frontBend = -1
            }
        }
        if stunned || pose == "hurt" {
            torso.zRotation = 0.28
            torso.position.x = -7
            frontHand = CGPoint(x: 22, y: 31)
            backHand = CGPoint(x: -49, y: 73)
            blade = -0.7
        }
        aim(frontLeg, lower: frontShin, at: frontFoot, lengths: (48, 43), bend: 1)
        aim(backLeg, lower: backShin, at: backFoot, lengths: (48, 43), bend: 1)
        aim(frontArm, lower: frontForearm, at: frontHand, lengths: (34, 33), bend: frontBend)
        aim(backArm, lower: backForearm, at: backHand, lengths: (34, 33), bend: backBend)
        weapon.zRotation = blade - frontArm.zRotation - frontForearm.zRotation - torso.zRotation
        head.zRotation = -torso.zRotation * 0.65
        scarf.zRotation = breath * 0.05 + (running || pose == "dash" ? -0.28 : 0)
        for (index, tail) in [backTail, frontTail].enumerated() {
            tail.position = CGPoint(x: torso.position.x + (index == 0 ? -7 : 4), y: torso.position.y + 4)
            tail.zRotation = torso.zRotation * 0.3 + breath * 0.025
                + (running || pose == "dash" ? -0.35 + CGFloat(index) * 0.2 : 0)
        }
        alpha = stunned && Int(time * 24) % 2 == 0 ? 0.78 : 1
    }
}
