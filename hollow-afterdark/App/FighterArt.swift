import SpriteKit
import UIKit

extension UIColor {
  convenience init(hex: UInt32, alpha: CGFloat = 1) {
    self.init(
      red: CGFloat((hex >> 16) & 255) / 255,
      green: CGFloat((hex >> 8) & 255) / 255,
      blue: CGFloat(hex & 255) / 255, alpha: alpha)
  }
}

@discardableResult
func polygon(
  _ points: [CGPoint], fill: UIColor, stroke: UIColor = UIColor(hex: 0x100f20),
  width: CGFloat = 1.4, parent: SKNode
) -> SKShapeNode {
  let path = CGMutablePath()
  if let first = points.first {
    path.move(to: first)
    for point in points.dropFirst() { path.addLine(to: point) }
    path.closeSubpath()
  }
  let node = SKShapeNode(path: path)
  node.fillColor = fill
  node.strokeColor = stroke
  node.lineWidth = width
  node.isAntialiased = true
  parent.addChild(node)
  return node
}

@discardableResult
func shape(
  _ coordinates: [CGFloat], _ fill: UIColor, parent: SKNode,
  stroke: UIColor = UIColor(hex: 0x100f20)
) -> SKShapeNode {
  var points: [CGPoint] = []
  for index in stride(from: 0, to: coordinates.count, by: 2) {
    points.append(CGPoint(x: coordinates[index], y: coordinates[index + 1]))
  }
  return polygon(points, fill: fill, stroke: stroke, parent: parent)
}

@MainActor
final class FighterArt: SKNode {
  let torso = SKNode()
  let frontArm = SKNode()
  let rearArm = SKNode()
  let frontLeg = SKNode()
  let rearLeg = SKNode()
  let hair = SKNode()
  let scarf = SKNode()
  let aura = SKShapeNode(ellipseOf: CGSize(width: 108, height: 196))
  let shield = SKShapeNode(ellipseOf: CGSize(width: 77, height: 178))
  let blade = SKNode()
  let accent: UIColor
  let slot: Int
  private var target = CGPoint.zero
  private var initialized = false

  init(slot: Int) {
    self.slot = slot
    accent = UIColor(hex: slot == 0 ? 0xff385f : 0x69e0ff)
    super.init()
    let dark = UIColor(hex: 0x1a172c)
    let coat = UIColor(hex: slot == 0 ? 0x29263e : 0xd7d9ee)
    let trim = UIColor(hex: slot == 0 ? 0xa4a9c5 : 0x595274)
    let skin = UIColor(hex: 0xf2d3ce)
    aura.position.y = 101
    aura.fillColor = UIColor(hex: 0x606bff, alpha: 0.12)
    aura.strokeColor = UIColor(hex: 0x899eff, alpha: 0.8)
    aura.glowWidth = 16
    aura.lineWidth = 1
    addChild(aura)
    rearLeg.position = CGPoint(x: -10, y: 78)
    frontLeg.position = CGPoint(x: 10, y: 78)
    addChild(rearLeg)
    addChild(frontLeg)
    shape([-13, 4, 9, 2, 4, -41, -18, -70, -28, -66, -18, -33], dark, parent: rearLeg)
    shape(
      [-26, -60, -14, -66, -15, -75, -39, -76, -38, -71], UIColor(hex: 0x101322), parent: rearLeg)
    shape([-3, -6, 1, -32, -16, -58, -20, -53], trim.withAlphaComponent(0.5), parent: rearLeg)
    shape([-8, 3, 13, 3, 16, -36, 29, -70, 17, -75, 0, -44], dark, parent: frontLeg)
    shape([15, -67, 28, -67, 42, -73, 43, -79, 17, -79], UIColor(hex: 0x101322), parent: frontLeg)
    shape(
      [5, -9, 10, -30, 22, -61, 18, -62, 4, -36], trim.withAlphaComponent(0.7), parent: frontLeg)
    shape([17, -71, 35, -75, 36, -77, 17, -76], accent, parent: frontLeg)
    torso.position.y = 78
    addChild(torso)
    rearArm.position = CGPoint(x: -17, y: 52)
    torso.addChild(rearArm)
    shape([-8, 1, 8, 5, 10, -26, -7, -49, -16, -43, -4, -24], coat, parent: rearArm)
    shape([-15, -42, -5, -46, -4, -53, -12, -55, -20, -48], skin, parent: rearArm)
    // Split coat panels follow the character's animated center of mass.
    shape(
      [-21, 53, 18, 57, 23, 10, 40, -46, 11, -34, -2, -1, -14, -48, -35, -34, -24, 12], coat,
      parent: torso)
    shape(
      [-20, 13, -7, 4, -13, -35, -28, -29], UIColor(hex: slot == 0 ? 0x151426 : 0xaaa9c7),
      parent: torso)
    shape(
      [6, 12, 20, 20, 28, -26, 16, -20], UIColor(hex: slot == 0 ? 0x47405c : 0xf7f0ff),
      parent: torso)
    shape([-10, 54, 5, 59, 11, 15, -11, 13], UIColor(hex: 0xefedf9), parent: torso)
    shape([-21, 51, -7, 56, -4, 31, -16, 39], trim, parent: torso)
    shape([7, 55, 20, 55, 17, 38, 3, 27], trim, parent: torso)
    shape([-3, 50, 1, 48, 5, 23, -1, 17, -5, 25], accent, parent: torso)
    shape([-21, 11, 21, 13, 22, 5, -22, 3], UIColor(hex: 0x171423), parent: torso)
    shape([4, 13, 14, 13, 14, 4, 4, 4], UIColor(hex: 0xded4e9), parent: torso)
    shape([7, 11, 11, 11, 11, 6, 7, 6], accent, parent: torso)
    shape([-21, 41, -14, 40, -13, 34, -20, 35], accent, parent: torso)
    shape([-8, 64, 5, 66, 8, 53, -6, 50], skin, parent: torso)
    scarf.position = CGPoint(x: -5, y: 59)
    torso.addChild(scarf)
    shape([0, 4, -12, 6, -41, 18, -67, 11, -45, 8, -17, -2, -2, -5], accent, parent: scarf)
    shape(
      [-21, 6, -48, 12, -63, 11, -39, 15], UIColor.white.withAlphaComponent(0.4), parent: scarf)
    shape([-15, 92, 3, 99, 18, 88, 17, 71, 9, 61, -5, 64, -16, 76], skin, parent: torso)
    shape([13, 83, 22, 77, 15, 76], skin, parent: torso)
    shape([2, 80, 13, 80, 11, 77, 3, 77], UIColor(hex: 0xfaf5ff), parent: torso)
    shape([9, 80, 12, 80, 12, 76, 9, 76], accent, parent: torso)
    shape([6, 69, 12, 69, 11, 68], UIColor(hex: 0x9b626e), parent: torso)
    hair.position = CGPoint(x: 0, y: 83)
    torso.addChild(hair)
    let hairColor = UIColor(hex: slot == 0 ? 0xdce1ef : 0x6460ab)
    shape(
      [
        -22, -4, -24, 13, -33, 20, -20, 20, -27, 31, -8, 24, -5, 35, 4, 24, 17, 28, 13, 19, 27, 15,
        17, 6, 18, -3, 7, 8, 5, -8, -3, 0, -10, -15, -14, 0,
      ], hairColor, parent: hair)
    shape(
      [-23, 18, -9, 18, -15, 9, -11, 15, 1, 22, -4, 29, -8, 21],
      UIColor.white.withAlphaComponent(0.5), parent: hair)
    if slot == 1 {
      shape(
        [-20, 13, -32, 4, -26, -16, -43, -42, -46, -17, -38, 6, -31, 19], hairColor, parent: hair)
      shape([-30, 6, -35, -9, -34, -19, -28, -7], UIColor(hex: 0x9291ce), parent: hair)
    }
    frontArm.position = CGPoint(x: 15, y: 50)
    torso.addChild(frontArm)
    shape([-4, 6, 10, 7, 23, -9, 36, -12, 31, -25, 15, -19, 0, -8], coat, parent: frontArm)
    shape([24, -12, 33, -13, 30, -23, 21, -20], trim, parent: frontArm)
    shape([33, -12, 42, -13, 46, -19, 39, -25, 30, -22], skin, parent: frontArm)
    blade.position = CGPoint(x: 40, y: -16)
    frontArm.addChild(blade)
    shape([-15, -3, 15, -3, 15, 2, -15, 2], UIColor(hex: 0xc9bdd5), parent: blade)
    shape([-2, -15, 3, -15, 4, 14, -3, 14], UIColor(hex: 0x201d30), parent: blade)
    shape([-4, 11, 3, 11, 102, 4, 124, 0, 104, -4, 0, 1], accent, parent: blade, stroke: .white)
    shape([5, 6, 108, 1, 87, -1, 4, 3], .white, parent: blade)
    blade.zRotation = -0.55
    shield.position = CGPoint(x: 48, y: 87)
    shield.fillColor = accent.withAlphaComponent(0.12)
    shield.strokeColor = accent
    shield.lineWidth = 2
    shield.glowWidth = 7
    addChild(shield)
  }

  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func render(_ player: Duelist, time: TimeInterval) {
    target = CGPoint(x: player.x, y: 149 + player.y)
    if !initialized {
      position = target
      initialized = true
    }
    position.x += (target.x - position.x) * 0.55
    position.y += (target.y - position.y) * 0.55
    xScale = CGFloat(player.face)
    let walk = player.action == "walk"
    let t = CGFloat(time)
    let bob = sin(t * (walk ? 16 : 3)) * (walk ? 3 : 1.4)
    torso.position.y = 78 + bob
    frontLeg.zRotation = walk ? sin(t * 16) * 0.38 : player.y > 0 ? 0.45 : 0
    rearLeg.zRotation = walk ? -sin(t * 16) * 0.38 : player.y > 0 ? -0.65 : 0
    torso.zRotation = player.stun > 0 && player.action != "block" ? 0.16 : walk ? -0.09 : 0
    scarf.zRotation = sin(t * 7) * 0.12 + (walk ? 0.25 : 0)
    hair.zRotation = sin(t * 3) * 0.025
    if !player.move.isEmpty {
      let frame = CGFloat(player.frame)
      let start: CGFloat = player.move == "light" ? 6 : player.move == "heavy" ? 14 : 17
      let swing = max(0, min(1, (frame - start + 2) / 7))
      frontArm.zRotation = 0.9 - swing * 2.0
      blade.zRotation = 0.7 - swing * 0.9
      torso.zRotation = -0.16 * swing
    } else {
      frontArm.zRotation =
        ["guard", "shield", "block"].contains(player.action) ? 1.2 : sin(t * 3) * 0.04
      blade.zRotation = -0.55
    }
    aura.isHidden = !player.ascend
    aura.alpha = 0.65 + sin(t * 7) * 0.25
    shield.isHidden = !["shield", "block"].contains(player.action)
    shield.alpha = 0.7 + sin(t * 12) * 0.2
    alpha = player.hp == 0 ? 0.55 : 1
    if player.hp == 0 {
      torso.zRotation = -0.6
      torso.position.y = 47
    }
  }
}
