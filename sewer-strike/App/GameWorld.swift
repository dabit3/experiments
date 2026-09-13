import SceneKit
import SwiftUI
import UIKit

enum Art {
  static let ink = UIColor(hex: 0x091728)
  static func material(_ color: UIColor, glow: CGFloat = 0) -> SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.roughness.contents = 0.8
    if glow > 0 {
      material.emission.contents = color
      material.emission.intensity = glow
    }
    return material
  }
  @discardableResult
  static func box(
    _ parent: SCNNode, _ size: SCNVector3, _ position: SCNVector3,
    _ color: UIColor, radius: CGFloat = 0.03, glow: CGFloat = 0
  ) -> SCNNode {
    let geometry = SCNBox(
      width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z),
      chamferRadius: radius)
    geometry.materials = [material(color, glow: glow)]
    let node = SCNNode(geometry: geometry)
    node.position = position
    parent.addChildNode(node)
    return node
  }
  @discardableResult
  static func sphere(
    _ parent: SCNNode, _ scale: SCNVector3, _ position: SCNVector3,
    _ color: UIColor
  ) -> SCNNode {
    let geometry = SCNSphere(radius: 1)
    geometry.segmentCount = 16
    geometry.materials = [material(color)]
    let node = SCNNode(geometry: geometry)
    node.scale = scale
    node.position = position
    parent.addChildNode(node)
    return node
  }
  @discardableResult
  static func rod(
    _ parent: SCNNode, from a: SCNVector3, to b: SCNVector3,
    radius: CGFloat, color: UIColor, glow: CGFloat = 0
  ) -> SCNNode {
    let length = sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2) + pow(b.z - a.z, 2))
    let geometry = SCNCylinder(radius: radius, height: CGFloat(length))
    geometry.radialSegmentCount = 10
    geometry.materials = [material(color, glow: glow)]
    let node = SCNNode(geometry: geometry)
    node.position = SCNVector3((a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) / 2)
    let direction = simd_normalize(SIMD3<Float>(b.x - a.x, b.y - a.y, b.z - a.z))
    node.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: direction)
    parent.addChildNode(node)
    return node
  }
  @discardableResult
  static func ring(
    _ parent: SCNNode, radius: CGFloat, color: UIColor,
    position: SCNVector3, pipe: CGFloat = 0.025
  ) -> SCNNode {
    let geometry = SCNTorus(ringRadius: radius, pipeRadius: pipe)
    geometry.ringSegmentCount = 32
    geometry.pipeSegmentCount = 6
    geometry.materials = [material(color, glow: 0.65)]
    let node = SCNNode(geometry: geometry)
    node.position = position
    parent.addChildNode(node)
    return node
  }
  @discardableResult
  static func text(
    _ parent: SCNNode, _ string: String, color: UIColor,
    size: CGFloat, position: SCNVector3
  ) -> SCNNode {
    let geometry = SCNText(string: string, extrusionDepth: 0.008)
    geometry.font = UIFont(name: "AvenirNext-HeavyItalic", size: 1) ?? .boldSystemFont(ofSize: 1)
    geometry.flatness = 0.3
    geometry.materials = [material(color, glow: 0.4)]
    let node = SCNNode(geometry: geometry)
    node.scale = SCNVector3(Float(size), Float(size), Float(size))
    let bounds = node.boundingBox
    node.pivot = SCNMatrix4MakeTranslation((bounds.max.x + bounds.min.x) / 2, bounds.min.y, 0)
    node.position = position
    parent.addChildNode(node)
    return node
  }
}

final class FighterModel {
  let root = SCNNode()
  let body = SCNNode()
  let leftArm = SCNNode()
  let rightArm = SCNNode()
  let leftLeg = SCNNode()
  let rightLeg = SCNNode()
  let halo: SCNNode
  let slash: SCNNode
  let label: SCNNode
  let hero: Int
  init(hero: Int, name: String) {
    self.hero = hero
    let mask = UIColor(hex: Hero.all[hero].hex)
    let skins: [UInt32] = [0x70C844, 0x94D63A, 0x4FAB6F, 0x4BBA48]
    let skin = UIColor(hex: skins[hero])
    halo = Art.ring(root, radius: 0.49, color: mask, position: SCNVector3(0, 0.025, 0))
    label = Art.text(root, name, color: mask, size: 0.14, position: SCNVector3(0, 1.94, 0))
    label.constraints = [SCNBillboardConstraint()]
    root.addChildNode(body)
    Art.sphere(body, SCNVector3(0.39, 0.49, 0.24), SCNVector3(0, 0.92, -0.13), Art.ink)
    Art.sphere(
      body, SCNVector3(0.35, 0.44, 0.23), SCNVector3(0, 0.94, -0.18), UIColor(hex: 0x314E30))
    for y: Float in [0.72, 0.96, 1.2] {
      Art.box(body, SCNVector3(0.32, 0.035, 0.025), SCNVector3(0, y, -0.39), UIColor(hex: 0xABC85D))
    }
    Art.sphere(body, SCNVector3(0.32, 0.42, 0.23), SCNVector3(0, 0.99, 0.04), skin)
    for column: Float in [-1, 1] {
      for row in 0..<3 {
        Art.box(
          body, SCNVector3(0.24, 0.19, 0.1),
          SCNVector3(column * 0.13, 0.76 + Float(row) * 0.20, 0.255),
          UIColor(hex: row == 2 ? 0xFFE196 : 0xD7AC57), radius: 0.06)
      }
    }
    Art.box(body, SCNVector3(0.61, 0.11, 0.49), SCNVector3(0, 0.72, 0), UIColor(hex: 0x64432C))
    Art.box(body, SCNVector3(0.15, 0.14, 0.05), SCNVector3(0, 0.73, 0.29), mask)
    let head = SCNNode()
    head.position = SCNVector3(0, 1.46, 0.04)
    body.addChildNode(head)
    Art.sphere(head, SCNVector3(0.32, 0.29, 0.27), SCNVector3Zero, Art.ink)
    Art.sphere(head, SCNVector3(0.30, 0.27, 0.25), SCNVector3(0, 0.015, 0.02), skin)
    Art.sphere(
      head, SCNVector3(0.31, 0.14, 0.25), SCNVector3(0, -0.10, 0.105),
      UIColor(hex: skins[hero] + 0x050500))
    Art.box(head, SCNVector3(0.59, 0.14, 0.16), SCNVector3(0, 0.055, 0.235), mask, radius: 0.05)
    for side: Float in [-1, 1] {
      let eye = Art.box(
        head, SCNVector3(0.17, 0.075, 0.055), SCNVector3(side * 0.14, 0.065, 0.323), .white)
      eye.eulerAngles.z = side * -0.18
      Art.box(head, SCNVector3(0.043, 0.065, 0.025), SCNVector3(side * 0.12, 0.07, 0.359), Art.ink)
    }
    Art.box(head, SCNVector3(0.20, 0.039, 0.025), SCNVector3(0.03, -0.135, 0.34), Art.ink)
    Art.box(head, SCNVector3(0.13, 0.019, 0.03), SCNVector3(0.04, -0.12, 0.35), .white)
    for side: Float in [-1, 1] {
      let tail = Art.box(
        head, SCNVector3(0.10, 0.44, 0.02), SCNVector3(side * 0.15, -0.12, -0.29), mask)
      tail.eulerAngles = SCNVector3(-0.65, 0, side * 0.4)
      tail.runAction(
        .repeatForever(
          .sequence([
            .rotateBy(x: 0.16, y: 0, z: 0.12, duration: 0.25),
            .rotateBy(x: -0.16, y: 0, z: -0.12, duration: 0.25),
          ])))
    }
    for (side, arm, leg) in [(-1.0 as Float, leftArm, leftLeg), (1.0 as Float, rightArm, rightLeg)]
    {
      arm.position = SCNVector3(side * 0.36, 1.19, 0.03)
      body.addChildNode(arm)
      Art.sphere(arm, SCNVector3(0.15, 0.20, 0.15), SCNVector3(0, -0.13, 0), skin)
      Art.sphere(arm, SCNVector3(0.14, 0.09, 0.15), SCNVector3(0, -0.28, 0), UIColor(hex: 0x5B3D31))
      Art.rod(
        arm, from: SCNVector3(0, -0.27, 0), to: SCNVector3(0, -0.46, 0.17), radius: 0.12,
        color: skin)
      Art.sphere(
        arm, SCNVector3(0.14, 0.11, 0.12), SCNVector3(0, -0.47, 0.17), UIColor(hex: 0xDBCBB0))
      leg.position = SCNVector3(side * 0.19, 0.64, 0)
      body.addChildNode(leg)
      Art.rod(
        leg, from: SCNVector3Zero, to: SCNVector3(side * 0.04, -0.25, 0), radius: 0.13, color: skin)
      Art.sphere(
        leg, SCNVector3(0.15, 0.1, 0.15), SCNVector3(side * 0.04, -0.25, 0.04),
        UIColor(hex: 0x5B3D31))
      Art.rod(
        leg, from: SCNVector3(side * 0.04, -0.28, 0), to: SCNVector3(side * 0.05, -0.49, 0.05),
        radius: 0.12, color: skin)
      Art.box(
        leg, SCNVector3(0.22, 0.17, 0.32), SCNVector3(side * 0.06, -0.53, 0.10),
        UIColor(hex: 0xD4C4A7), radius: 0.08)
      Self.weapon(arm, hero: hero, side: side)
    }
    slash = Art.ring(body, radius: 0.8, color: mask, position: SCNVector3(0, 0.9, 0.3), pipe: 0.045)
    slash.eulerAngles.x = .pi / 3
    slash.opacity = 0
  }
  private static func weapon(_ arm: SCNNode, hero: Int, side: Float) {
    let steel = UIColor(hex: 0xD8F5FF)
    let mask = UIColor(hex: Hero.all[hero].hex)
    let hand = SCNVector3(0, -0.47, 0.17)
    let weapon = SCNNode()
    weapon.position = hand
    arm.addChildNode(weapon)
    switch hero {
    case 0:
      Art.rod(
        weapon, from: SCNVector3(0, -0.12, 0), to: SCNVector3(0, 0.18, 0), radius: 0.045,
        color: Art.ink)
      Art.box(weapon, SCNVector3(0.30, 0.035, 0.07), SCNVector3(0, 0.18, 0), mask)
      let blade = Art.box(weapon, SCNVector3(0.07, 0.82, 0.027), SCNVector3(0, 0.6, 0), steel)
      blade.eulerAngles.z = side * -0.1
    case 1:
      Art.rod(
        weapon, from: SCNVector3(0, -0.1, 0), to: SCNVector3(0, 0.35, 0), radius: 0.055, color: mask
      )
      Art.rod(
        weapon, from: SCNVector3(0, 0.35, 0), to: SCNVector3(side * 0.22, 0.55, 0), radius: 0.018,
        color: steel)
      Art.rod(
        weapon, from: SCNVector3(side * 0.22, 0.55, 0), to: SCNVector3(side * 0.4, 0.15, 0),
        radius: 0.055, color: mask)
    case 2:
      if side > 0 {
        Art.rod(
          weapon, from: SCNVector3(0, -0.60, 0), to: SCNVector3(0, 1.20, 0), radius: 0.046,
          color: UIColor(hex: 0xCF9758))
        for y: Float in [-0.6, 1.12] {
          Art.rod(
            weapon, from: SCNVector3(0, y, 0), to: SCNVector3(0, y + 0.16, 0), radius: 0.065,
            color: mask, glow: 0.8)
        }
      }
    default:
      Art.rod(
        weapon, from: SCNVector3(0, -0.1, 0), to: SCNVector3(0, 0.45, 0), radius: 0.033,
        color: steel)
      for x: Float in [-0.12, 0.12] {
        Art.rod(
          weapon, from: SCNVector3(0, 0.10, 0), to: SCNVector3(x, 0.10, 0), radius: 0.025,
          color: steel)
        Art.rod(
          weapon, from: SCNVector3(x, 0.10, 0), to: SCNVector3(x, 0.26, 0), radius: 0.025,
          color: steel)
      }
    }
  }
  func update(_ p: PlayerState, time: Float, local: Bool) {
    root.position = SCNVector3(Float(p.x / 100), 0, Float(p.y / 100))
    body.position.y = Float(p.z / 100)
    body.eulerAngles.y = Float(p.face) * 0.7
    body.eulerAngles.z = p.hp == 0 ? .pi / 2 : 0
    let walk: Float = p.action == "walk" ? sin(time * 13) * 0.55 : sin(time * 3) * 0.025
    leftLeg.eulerAngles.x = walk
    rightLeg.eulerAngles.x = -walk
    leftArm.eulerAngles = SCNVector3(-0.18 - walk, 0, -0.18)
    rightArm.eulerAngles = SCNVector3(-0.18 + walk, 0, 0.18)
    if ["attack", "airkick", "special"].contains(p.action) {
      let swing = sin(Float(p.actionTime) * 16)
      rightArm.eulerAngles = SCNVector3(-1.3, swing, -0.7)
      leftArm.eulerAngles = SCNVector3(-1.0, -swing, 0.65)
      if p.action == "airkick" { rightLeg.eulerAngles.x = -1.25 }
    }
    slash.opacity = p.action == "special" ? 0.85 : p.action == "attack" ? 0.3 : 0
    slash.eulerAngles.y = time * 18
    slash.scale = p.action == "special" ? SCNVector3(1.65, 1.65, 1.65) : SCNVector3(1, 1, 1)
    body.opacity = !p.connected ? 0.3 : p.invuln > 0 && Int(time * 12) % 2 == 0 ? 0.5 : 1
    label.position.y = 1.94 + Float(p.z / 100)
    halo.opacity = local ? 1 : 0.65
    if p.hp == 0 {
      halo.scale = SCNVector3(1 + Float(p.revive / 3), 1, 1 + Float(p.revive / 3))
    } else {
      halo.scale = SCNVector3(1, 1, 1)
    }
  }
}

final class EnemyModel {
  let root = SCNNode()
  let body = SCNNode()
  let arm = SCNNode()
  let legs = [SCNNode(), SCNNode()]
  let warning: SCNNode
  let health: SCNNode
  let kind: String
  init(kind: String) {
    self.kind = kind
    warning = Art.ring(
      root, radius: kind == "boss" ? 1.45 : 0.65, color: UIColor(hex: 0xFF3C5F),
      position: SCNVector3(0, 0.04, 0), pipe: 0.05)
    warning.opacity = 0
    root.addChildNode(body)
    let armor = UIColor(hex: kind == "boss" ? 0x879CAB : kind == "brute" ? 0x52627C : 0x463E68)
    let accent = UIColor(hex: kind == "boss" ? 0xFF6130 : 0xFFCF3B)
    if kind == "drone" {
      Art.sphere(body, SCNVector3(0.27, 0.23, 0.36), SCNVector3(0, 0.37, 0), armor)
      Art.box(body, SCNVector3(0.35, 0.15, 0.12), SCNVector3(0, 0.37, 0.3), Art.ink)
      Art.box(
        body, SCNVector3(0.24, 0.05, 0.05), SCNVector3(0, 0.42, 0.37), UIColor(hex: 0xFF4260),
        glow: 1)
      for side: Float in [-1, 1] {
        Art.rod(
          body, from: SCNVector3(side * 0.2, 0.3, 0), to: SCNVector3(side * 0.38, 0.09, 0.15),
          radius: 0.04, color: armor)
        Art.box(body, SCNVector3(0.12, 0.08, 0.29), SCNVector3(side * 0.38, 0.06, 0.18), armor)
        Art.rod(
          body, from: SCNVector3(side * 0.1, 0.34, 0.3), to: SCNVector3(side * 0.17, 0.29, 0.6),
          radius: 0.025, color: .white)
      }
    } else {
      let boss = kind == "boss"
      Art.box(body, SCNVector3(0.67, 0.70, 0.43), SCNVector3(0, 0.98, 0), armor, radius: 0.14)
      Art.box(body, SCNVector3(0.42, 0.23, 0.07), SCNVector3(0, 1.04, 0.25), Art.ink)
      Art.box(body, SCNVector3(0.23, 0.13, 0.05), SCNVector3(0, 1.04, 0.30), accent, glow: 0.8)
      Art.sphere(body, SCNVector3(0.24, 0.25, 0.23), SCNVector3(0, 1.5, 0), Art.ink)
      Art.box(body, SCNVector3(0.38, 0.12, 0.09), SCNVector3(0, 1.52, 0.22), accent, glow: 0.7)
      Art.box(body, SCNVector3(0.24, 0.10, 0.1), SCNVector3(0, 1.37, 0.21), armor)
      for (i, side) in [-1.0 as Float, 1.0].enumerated() {
        let leg = legs[i]
        leg.position = SCNVector3(side * 0.2, 0.65, 0)
        body.addChildNode(leg)
        Art.rod(leg, from: .init(0, 0, 0), to: .init(0, -0.48, 0), radius: 0.13, color: armor)
        Art.box(leg, SCNVector3(0.24, 0.15, 0.36), SCNVector3(0, -0.52, 0.12), Art.ink)
        Art.sphere(body, SCNVector3(0.24, 0.18, 0.25), SCNVector3(side * 0.4, 1.24, 0), armor)
        Art.rod(
          body, from: SCNVector3(side * 0.43, 1.15, 0), to: SCNVector3(side * 0.5, 0.72, 0.13),
          radius: 0.14, color: armor)
        if boss {
          for z: Float in [-0.12, 0.10] {
            let spike = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.32))
            spike.geometry?.materials = [Art.material(.white)]
            spike.position = SCNVector3(side * 0.4, 1.53, z)
            body.addChildNode(spike)
          }
        }
      }
      arm.position = SCNVector3(0.55, 0.88, 0.17)
      body.addChildNode(arm)
      Art.rod(
        arm, from: SCNVector3(0, -0.15, 0), to: SCNVector3(0, 0.6, 0), radius: 0.06, color: accent)
      Art.box(
        arm, SCNVector3(boss ? 0.55 : 0.16, boss ? 0.35 : 0.45, 0.3), SCNVector3(0, 0.62, 0),
        boss ? UIColor(hex: 0xFF743B) : armor, radius: 0.04)
      if boss { body.scale = SCNVector3(1.45, 1.45, 1.45) }
      if kind == "brute" { body.scale = SCNVector3(1.2, 1.1, 1.1) }
    }
    health = Art.box(
      root, SCNVector3(0.65, 0.035, 0.025),
      SCNVector3(0, kind == "boss" ? 2.65 : kind == "drone" ? 0.82 : 1.88, 0),
      UIColor(hex: 0xFF546A), glow: 0.8)
    health.constraints = [SCNBillboardConstraint()]
  }
  func update(_ e: EnemyState, time: Float) {
    root.position = SCNVector3(Float(e.x / 100), 0, Float(e.y / 100))
    body.eulerAngles.y = Float(e.face) * 0.75
    body.eulerAngles.z = e.stun > 0 ? 0.13 * Float(-e.face) : 0
    for (i, leg) in legs.enumerated() {
      leg.eulerAngles.x = e.action == "walk" ? sin(time * 10 + Float(i) * .pi) * 0.4 : 0
    }
    arm.eulerAngles.x = e.action == "windup" ? -1.9 : e.action == "strike" ? 1.0 : 0
    health.scale.x = Float(e.hp) / Float(e.maxHP)
    warning.opacity = e.action == "windup" ? 0.6 + CGFloat(sin(time * 18)) * 0.3 : 0
    warning.position.x = Float((e.targetX - e.x) / 100)
    warning.position.z = Float((e.targetY - e.y) / 100)
    if kind == "drone" { body.position.y = sin(time * 10) * 0.045 }
  }
}

@MainActor
final class GameWorld {
  let scene = SCNScene()
  let camera = SCNNode()
  private var heroes: [String: FighterModel] = [:]
  private var enemies: [String: EnemyModel] = [:]
  private var slices: [String: SCNNode] = [:]
  private var lastEvent = 0
  private var lastTick = -1
  private var preview: [FighterModel] = []
  init() {
    scene.background.contents = UIColor(hex: 0x071021)
    scene.fogColor = UIColor(hex: 0x142032)
    scene.fogStartDistance = 18
    scene.fogEndDistance = 40
    camera.camera = SCNCamera()
    camera.camera?.usesOrthographicProjection = true
    camera.camera?.orthographicScale = 3.7
    camera.camera?.zFar = 80
    camera.position = SCNVector3(4.1, 6.8, 10)
    camera.look(at: SCNVector3(4.1, 0.8, 0))
    scene.rootNode.addChildNode(camera)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.color = UIColor(hex: 0x9EC9E8)
    ambient.light?.intensity = 650
    scene.rootNode.addChildNode(ambient)
    let key = SCNNode()
    key.light = SCNLight()
    key.light?.type = .directional
    key.light?.intensity = 1100
    key.light?.color = UIColor(hex: 0xFFF0CE)
    key.light?.castsShadow = true
    key.light?.shadowColor = UIColor.black.withAlphaComponent(0.35)
    key.light?.shadowMapSize = CGSize(width: 1024, height: 1024)
    key.eulerAngles = SCNVector3(-0.75, -0.4, -0.25)
    scene.rootNode.addChildNode(key)
    buildStage()
    for i in 0..<4 {
      let model = FighterModel(hero: i, name: "")
      model.root.position = SCNVector3(2.4 + Float(i) * 1.15, 0, 0)
      model.body.eulerAngles.y = 0.25
      scene.rootNode.addChildNode(model.root)
      model.body.runAction(
        .repeatForever(
          .sequence([
            .moveBy(x: 0, y: 0.04, z: 0, duration: 0.7),
            .moveBy(x: 0, y: -0.04, z: 0, duration: 0.7),
          ])))
      preview.append(model)
    }
  }
  private func buildStage() {
    let root = scene.rootNode
    let cyan = UIColor(hex: 0x38EBD1)
    let violet = UIColor(hex: 0xC753FF)
    let water = Art.box(
      root, SCNVector3(28, 0.13, 1.9), SCNVector3(12, -0.23, 2.85), UIColor(hex: 0x066C65),
      glow: 0.2)
    water.geometry?.firstMaterial?.specular.contents = UIColor.white
    for sector in 0..<3 {
      let x = Float(sector) * 8 + 4
      Art.box(
        root, SCNVector3(8, 0.2, 4.5), SCNVector3(x, -0.14, -0.1),
        UIColor(hex: sector == 0 ? 0x293F51 : 0x30414E))
      Art.box(root, SCNVector3(8, 0.18, 0.16), SCNVector3(x, -0.01, 2.03), cyan, glow: 0.25)
      Art.box(
        root, SCNVector3(8, 5.6, 0.35), SCNVector3(x, 2.65, -2.65),
        UIColor(hex: sector == 0 ? 0x162139 : 0x18333C))
      for row in 0..<10 {
        for col in 0..<12 {
          let xx = Float(sector * 8) + Float(col) * 0.69 + (row % 2 == 0 ? 0 : 0.34)
          Art.box(
            root, SCNVector3(0.63, 0.25, 0.04), SCNVector3(xx, Float(row) * 0.35 + 0.2, -2.43),
            UIColor(hex: (row + col) % 4 == 0 ? 0x35475B : 0x223D4A), radius: 0.01)
        }
      }
      for i in 0..<15 {
        Art.box(
          root, SCNVector3(0.014, 0.005, 4.2),
          SCNVector3(Float(sector * 8) + Float(i) * 0.56, -0.03, -0.1),
          UIColor(hex: 0x52716F), radius: 0)
      }
      for z: Float in [-1.65, 0, 1.4] {
        Art.box(
          root, SCNVector3(8, 0.005, 0.015), SCNVector3(x, -0.025, z), UIColor(hex: 0x69847D),
          radius: 0)
      }
      for pipeY: Float in [2.55, 2.95] {
        Art.rod(
          root, from: SCNVector3(x - 4, pipeY, -2.16), to: SCNVector3(x + 4, pipeY, -2.16),
          radius: 0.105, color: UIColor(hex: 0x865C48))
      }
      for xx in stride(from: Float(sector * 8) + 0.4, to: Float(sector * 8 + 8), by: 2.5) {
        Art.box(root, SCNVector3(0.3, 4.8, 0.55), SCNVector3(xx, 2, -2.26), UIColor(hex: 0x344F59))
        Art.box(
          root, SCNVector3(0.08, 1.35, 0.05), SCNVector3(xx, 1.5, -1.96),
          sector == 1 ? cyan : violet, glow: 1)
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.light?.color = sector == 1 ? cyan : violet
        light.light?.intensity = 170
        light.light?.attenuationEndDistance = 4
        light.position = SCNVector3(xx, 2, -1.5)
        root.addChildNode(light)
      }
    }
    for xx: Float in [1.3, 5.6] {
      Art.box(root, SCNVector3(1.4, 2.8, 0.3), SCNVector3(xx, 1.4, -2.17), Art.ink)
      for yy: Float in [0.6, 1.1, 1.6, 2.1] {
        Art.box(
          root, SCNVector3(1.15, 0.09, 0.07), SCNVector3(xx, yy, -1.98), UIColor(hex: 0x415A74))
      }
    }
    sign("SLICE / 24", x: 3.5, y: 2.0, width: 2.0, color: UIColor(hex: 0xFF8D38))
    sign("UNDERCURRENT", x: 11.8, y: 2.02, width: 3.0, color: cyan)
    sign("REACTOR ZERO", x: 20, y: 2.2, width: 3, color: UIColor(hex: 0xFF5764))
    for xx: Float in [9.0, 13.7, 17.1, 22.2] {
      let drain = Art.ring(
        root, radius: 0.68, color: UIColor(hex: 0x70868A), position: SCNVector3(xx, 1.1, -2.07),
        pipe: 0.12)
      drain.eulerAngles.x = .pi / 2
      for i in -2...2 {
        Art.rod(
          root, from: SCNVector3(xx + Float(i) * 0.19, 0.6, -2.04),
          to: SCNVector3(xx + Float(i) * 0.19, 1.6, -2.04), radius: 0.025, color: Art.ink)
      }
    }
    for xx: Float in [0.5, 6.8, 10.2, 15.1, 18, 22.4] {
      let barrel = Art.rod(
        root, from: SCNVector3(xx, 0, -1.65), to: SCNVector3(xx, 0.65, -1.65),
        radius: 0.28, color: UIColor(hex: 0x476E67))
      barrel.castsShadow = true
      Art.ring(
        root, radius: 0.285, color: UIColor(hex: 0xAACB7A), position: SCNVector3(xx, 0.4, -1.65),
        pipe: 0.035)
      Art.text(
        root, "!", color: UIColor(hex: 0xFFCE5F), size: 0.25, position: SCNVector3(xx, 0.18, -1.35))
    }
    for i in 0..<45 {
      let x = Float(i) * 0.55
      let ripple = Art.box(
        root, SCNVector3(0.45, 0.012, 0.035), SCNVector3(x, -0.14, 2.2 + Float(i % 4) * 0.3),
        UIColor(hex: 0x45CAAF), glow: 0.2)
      ripple.runAction(
        .repeatForever(
          .sequence([
            .moveBy(x: 0.2, y: 0, z: 0, duration: 0.9), .moveBy(x: -0.2, y: 0, z: 0, duration: 0.9),
          ])))
    }
    for i in 0..<6 {
      let geometry = SCNCylinder(radius: 0.065, height: 2.5)
      geometry.materials = [Art.material(UIColor(hex: 0x23ACBD))]
      let drip = SCNNode(geometry: geometry)
      drip.opacity = 0.35
      drip.position = SCNVector3(Float(i) * 4 + 1, 1.1, -1.94)
      root.addChildNode(drip)
    }
    for x: Float in [7.7, 15.5] {
      for i in 0..<6 {
        let stripe = Art.box(
          root, SCNVector3(0.08, 0.01, 0.24), SCNVector3(x, 0.02, Float(i) * 0.55 - 1.4),
          UIColor(hex: 0xFFD956), radius: 0)
        stripe.eulerAngles.y = 0.6
      }
    }
  }
  private func sign(_ text: String, x: Float, y: Float, width: Float, color: UIColor) {
    Art.box(
      scene.rootNode, SCNVector3(width + 0.12, 0.51, 0.1), SCNVector3(x, y, -2.0), color, glow: 0.65
    )
    Art.box(scene.rootNode, SCNVector3(width, 0.41, 0.13), SCNVector3(x, y, -1.94), Art.ink)
    Art.text(
      scene.rootNode, text, color: color, size: 0.23, position: SCNVector3(x, y - 0.12, -1.84))
  }
  func update(_ state: GameState, localID: String) {
    guard state.tick != lastTick else { return }
    lastTick = state.tick
    if !state.players.isEmpty {
      for model in preview { model.root.removeFromParentNode() }
      preview = []
    }
    let time = Float(state.tick) / 30
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 1.0 / 30
    for p in state.players {
      if heroes[p.id] == nil {
        let model = FighterModel(hero: p.hero, name: p.id == localID ? "\(p.name) • YOU" : p.name)
        scene.rootNode.addChildNode(model.root)
        heroes[p.id] = model
      }
      heroes[p.id]?.update(p, time: time, local: p.id == localID)
    }
    for id in heroes.keys where !state.players.contains(where: { $0.id == id }) {
      heroes.removeValue(forKey: id)?.root.removeFromParentNode()
    }
    for e in state.enemies {
      if enemies[e.id] == nil {
        let model = EnemyModel(kind: e.kind)
        scene.rootNode.addChildNode(model.root)
        enemies[e.id] = model
      }
      enemies[e.id]?.update(e, time: time)
    }
    for id in enemies.keys where !state.enemies.contains(where: { $0.id == id }) {
      if let model = enemies.removeValue(forKey: id) {
        model.root.runAction(
          .sequence([
            .group([.fadeOut(duration: 0.25), .scale(to: 0.1, duration: 0.25)]),
            .removeFromParentNode(),
          ]))
      }
    }
    for s in state.pickups where slices[s.id] == nil {
      let node = makeSlice()
      node.position = SCNVector3(Float(s.x / 100), 0.23, Float(s.y / 100))
      scene.rootNode.addChildNode(node)
      slices[s.id] = node
    }
    for id in slices.keys where !state.pickups.contains(where: { $0.id == id }) {
      slices.removeValue(forKey: id)?.removeFromParentNode()
    }
    let average =
      state.players.filter { $0.connected }.map(\.x).reduce(0, +)
      / Double(max(1, state.players.filter { $0.connected }.count))
    let center = Float(min(2050, max(400, average + 90)) / 100)
    camera.position.x = center
    SCNTransaction.commit()
    for event in state.events where event.id > lastEvent {
      lastEvent = event.id
      guard event.tick > state.tick - 15 else { continue }
      effect(event)
    }
  }
  private func makeSlice() -> SCNNode {
    let node = SCNNode()
    let path = UIBezierPath()
    path.move(to: CGPoint(x: -0.22, y: 0))
    path.addLine(to: CGPoint(x: 0.22, y: 0))
    path.addLine(to: CGPoint(x: 0, y: 0.44))
    path.close()
    let geometry = SCNShape(path: path, extrusionDepth: 0.07)
    geometry.materials = [Art.material(UIColor(hex: 0xFFD35A), glow: 0.3)]
    node.addChildNode(SCNNode(geometry: geometry))
    Art.rod(
      node, from: SCNVector3(-0.23, 0, 0.04), to: SCNVector3(0.23, 0, 0.04), radius: 0.05,
      color: UIColor(hex: 0xCB6F2A))
    for position in [
      SCNVector3(-0.08, 0.11, 0.08), SCNVector3(0.07, 0.16, 0.08), SCNVector3(0, 0.28, 0.08),
    ] {
      Art.sphere(node, SCNVector3(0.055, 0.055, 0.018), position, UIColor(hex: 0xED5742))
    }
    node.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.5)))
    Art.ring(node, radius: 0.4, color: UIColor(hex: 0xFFCF42), position: SCNVector3(0, -0.16, 0))
    return node
  }
  private func effect(_ event: GameEvent) {
    guard
      ["hit", "specialHit", "heal", "revive", "hurt", "power", "defeat", "slam"].contains(
        event.kind)
    else { return }
    let color = UIColor(
      hex: event.kind == "heal" || event.kind == "revive"
        ? 0xAFFF54 : event.kind == "hurt" ? 0xFF526D : 0xFFF270)
    let point = SCNVector3(Float(event.x / 100), 1.9, Float(event.y / 100))
    if !event.text.isEmpty {
      let text = Art.text(
        scene.rootNode, event.text, color: color, size: event.kind == "power" ? 0.22 : 0.31,
        position: point)
      text.constraints = [SCNBillboardConstraint()]
      text.eulerAngles.z = Float(event.id % 3 - 1) * 0.1
      text.runAction(
        .sequence([
          .group([
            .moveBy(x: 0, y: 0.65, z: 0, duration: 0.65),
            .sequence([.wait(duration: 0.3), .fadeOut(duration: 0.35)]),
          ]), .removeFromParentNode(),
        ]))
    }
    for i in 0..<7 {
      let angle = Float(i) / 7 * .pi * 2
      let node = Art.box(
        scene.rootNode, SCNVector3(0.09, 0.09, 0.09),
        SCNVector3(point.x, 0.9, point.z), color, radius: 0.01, glow: 1)
      node.runAction(
        .sequence([
          .group([
            .moveBy(
              x: CGFloat(cos(angle) * 0.75), y: CGFloat(sin(angle) * 0.7), z: 0, duration: 0.3),
            .fadeOut(duration: 0.3),
          ]), .removeFromParentNode(),
        ]))
    }
    if event.kind == "power" || event.kind == "slam" {
      let ring = Art.ring(
        scene.rootNode, radius: 0.3, color: color, position: SCNVector3(point.x, 0.07, point.z),
        pipe: 0.06)
      ring.runAction(
        .sequence([
          .group([.scale(to: 5, duration: 0.45), .fadeOut(duration: 0.45)]),
          .removeFromParentNode(),
        ]))
    }
  }
}

struct WorldView: UIViewRepresentable {
  let world: GameWorld
  func makeUIView(context: Context) -> SCNView {
    let view = SCNView()
    view.scene = world.scene
    view.pointOfView = world.camera
    view.backgroundColor = .black
    view.isPlaying = true
    view.preferredFramesPerSecond = 60
    view.antialiasingMode = .multisampling4X
    view.isUserInteractionEnabled = false
    return view
  }
  func updateUIView(_ uiView: SCNView, context: Context) {}
}
