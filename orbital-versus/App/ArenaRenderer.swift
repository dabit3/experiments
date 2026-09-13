import SceneKit
import SwiftUI
import UIKit

extension UIColor {
  convenience init(rgb: UInt32, alpha: CGFloat = 1) {
    self.init(
      red: CGFloat((rgb >> 16) & 255) / 255,
      green: CGFloat((rgb >> 8) & 255) / 255, blue: CGFloat(rgb & 255) / 255, alpha: alpha)
  }
}

@MainActor
final class ArenaRenderer {
  let scene = SCNScene()
  let camera = SCNNode()
  weak var view: SCNView?
  var reticleChanged: ((CGPoint) -> Void)?
  private var units: [String: SCNNode] = [:]
  private var beams: [Int: SCNNode] = [:]
  private var snapshot: ArenaState?
  private var playerID = ""
  private var time: Float = 0
  private let showroom = SCNNode()
  private var cameraInitialized = false

  init() {
    scene.background.contents = UIColor(rgb: 0x09172C)
    scene.fogColor = UIColor(rgb: 0x182E45)
    scene.fogStartDistance = 65
    scene.fogEndDistance = 190
    camera.camera = SCNCamera()
    camera.camera?.fieldOfView = 65
    camera.camera?.zFar = 400
    camera.camera?.wantsHDR = true
    camera.camera?.bloomIntensity = 0.7
    camera.camera?.bloomThreshold = 0.9
    camera.camera?.exposureOffset = 0.1
    scene.rootNode.addChildNode(camera)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.color = UIColor(rgb: 0xA5CDE7)
    ambient.light?.intensity = 350
    scene.rootNode.addChildNode(ambient)
    let sun = SCNNode()
    sun.light = SCNLight()
    sun.light?.type = .directional
    sun.light?.intensity = 1050
    sun.light?.color = UIColor(rgb: 0xFFF5DA)
    sun.eulerAngles = SCNVector3(-0.8, -0.5, 0)
    scene.rootNode.addChildNode(sun)
    let rim = SCNNode()
    rim.light = SCNLight()
    rim.light?.type = .directional
    rim.light?.color = UIColor(rgb: 0x42CAFF)
    rim.light?.intensity = 700
    rim.eulerAngles = SCNVector3(0.5, 2.2, 0)
    scene.rootNode.addChildNode(rim)
    makeArena()
    showroom.addChildNode(makeMecha(team: 0))
    scene.rootNode.addChildNode(showroom)
    camera.position = SCNVector3(10, 6, 13)
    camera.look(at: SCNVector3(0, 2.5, 0))
  }

  func material(_ color: UInt32, glow: Bool = false, metal: CGFloat = 0.55) -> SCNMaterial {
    let value = SCNMaterial()
    value.lightingModel = .physicallyBased
    value.diffuse.contents = UIColor(rgb: color)
    value.metalness.contents = metal
    value.roughness.contents = 0.35
    if glow {
      value.emission.contents = UIColor(rgb: color)
      value.lightingModel = .constant
    }
    return value
  }

  @discardableResult
  private func box(
    _ parent: SCNNode, _ size: SCNVector3, _ position: SCNVector3,
    _ color: UInt32, bevel: CGFloat = 0.05, glow: Bool = false, name: String? = nil
  ) -> SCNNode {
    let shape = SCNBox(
      width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: bevel
    )
    shape.chamferSegmentCount = 1
    shape.materials = [material(color, glow: glow)]
    let node = SCNNode(geometry: shape)
    node.position = position
    node.name = name
    parent.addChildNode(node)
    return node
  }

  private func cylinder(
    _ parent: SCNNode, radius: CGFloat, height: CGFloat,
    position: SCNVector3, color: UInt32, glow: Bool = false
  ) -> SCNNode {
    let geometry = SCNCylinder(radius: radius, height: height)
    geometry.radialSegmentCount = 12
    geometry.materials = [material(color, glow: glow)]
    let node = SCNNode(geometry: geometry)
    node.position = position
    parent.addChildNode(node)
    return node
  }

  private func makeArena() {
    box(scene.rootNode, SCNVector3(104, 1, 104), SCNVector3(0, -0.7, 0), 0x263E51, bevel: 0)
    for index in -5...5 {
      let coordinate = Float(index) * 9
      box(
        scene.rootNode, SCNVector3(0.07, 0.02, 94), SCNVector3(coordinate, -0.17, 0), 0x7094A1,
        bevel: 0)
      box(
        scene.rootNode, SCNVector3(94, 0.02, 0.07), SCNVector3(0, -0.16, coordinate), 0x7094A1,
        bevel: 0)
    }
    for side in [-1, 1] {
      let sign = Float(side)
      box(
        scene.rootNode, SCNVector3(0.24, 0.15, 90), SCNVector3(sign * 44.5, 0, 0), 0x42E4FF,
        glow: true)
      box(
        scene.rootNode, SCNVector3(90, 0.15, 0.24), SCNVector3(0, 0, sign * 44.5), 0x42E4FF,
        glow: true)
      for index in -4...4 {
        box(
          scene.rootNode, SCNVector3(2, 0.04, 0.65), SCNVector3(sign * 36, 0, Float(index) * 8),
          0xFBD878, bevel: 0)
        let building = box(
          scene.rootNode, SCNVector3(7, 8 + Float(abs(index) % 3) * 7, 8),
          SCNVector3(sign * 61, 3, Float(index) * 17), 0x26374E, bevel: 0.3)
        for floor in 0...4 {
          box(
            building, SCNVector3(7.1, 0.3, 8.1), SCNVector3(0, Float(floor) * 2 - 3, 0),
            floor % 2 == 0 ? 0x329DAF : 0x536C7B, glow: true)
        }
      }
      box(scene.rootNode, SCNVector3(103, 3, 3), SCNVector3(0, 0.5, sign * 53), 0x182A40)
      box(
        scene.rootNode, SCNVector3(105, 0.3, 0.5), SCNVector3(0, 2.2, sign * 53), 0x54C5FF,
        glow: true)
    }
    let pad = cylinder(
      scene.rootNode, radius: 13, height: 0.03, position: SCNVector3(0, -0.14, 0), color: 0x334F63)
    pad.geometry?.firstMaterial?.roughness.contents = 0.8
    let ring = SCNTorus(ringRadius: 12, pipeRadius: 0.12)
    ring.materials = [material(0x87B9C7, glow: true)]
    let ringNode = SCNNode(geometry: ring)
    ringNode.position.y = -0.1
    scene.rootNode.addChildNode(ringNode)
    for index in 0..<12 {
      let angle = Float(index) / 12 * .pi * 2
      let marker = box(
        scene.rootNode, SCNVector3(0.12, 0.03, 2),
        SCNVector3(sin(angle) * 10, -0.07, cos(angle) * 10), 0xCDDDE4, bevel: 0)
      marker.eulerAngles.y = angle
    }
    let planet = SCNSphere(radius: 34)
    planet.segmentCount = 64
    planet.materials = [material(0x427CAB, metal: 0)]
    let planetNode = SCNNode(geometry: planet)
    planetNode.position = SCNVector3(-100, 66, 140)
    scene.rootNode.addChildNode(planetNode)
    let orbit = SCNTorus(ringRadius: 48, pipeRadius: 0.55)
    orbit.materials = [material(0xA2D5E7, glow: true)]
    let orbitNode = SCNNode(geometry: orbit)
    orbitNode.eulerAngles = SCNVector3(0.3, 0, -0.4)
    planetNode.addChildNode(orbitNode)
    for index in 0..<100 {
      let angle = Float(index) * 2.39996
      let geometry = SCNSphere(radius: index % 7 == 0 ? 0.2 : 0.09)
      geometry.segmentCount = 4
      geometry.materials = [material(0xCCE6FF, glow: true)]
      let star = SCNNode(geometry: geometry)
      star.position = SCNVector3(sin(angle) * 180, 15 + Float((index * 37) % 95), cos(angle) * 180)
      scene.rootNode.addChildNode(star)
    }
    for side in [-1, 1] {
      let tower = box(
        scene.rootNode, SCNVector3(5, 45, 5), SCNVector3(Float(side) * 47, 21, 65), 0x405265,
        bevel: 0.5)
      box(tower, SCNVector3(1, 44, 5.1), SCNVector3(0, 0, 0), 0x4DD3FD, glow: true)
    }
    box(scene.rootNode, SCNVector3(102, 3, 6), SCNVector3(0, 41, 65), 0x526878, bevel: 0.3)
  }

  private func makeMecha(team: Int) -> SCNNode {
    let root = SCNNode()
    let armor: UInt32 = team == 0 ? 0x237CB7 : 0xC94047
    let accent: UInt32 = team == 0 ? 0x36E3FF : 0xFF9C42
    let white: UInt32 = 0xDCE7EC
    let joint: UInt32 = 0x172635
    box(root, SCNVector3(1.5, 0.5, 0.8), SCNVector3(0, 2.2, 0), joint)
    box(root, SCNVector3(1.8, 1.15, 1.05), SCNVector3(0, 3.12, 0), armor, bevel: 0.2)
    box(root, SCNVector3(0.5, 0.7, 0.25), SCNVector3(0, 3.1, 0.61), joint)
    box(root, SCNVector3(0.24, 0.35, 0.15), SCNVector3(0, 3.12, 0.78), accent, glow: true)
    for sign: Float in [-1, 1] {
      let breast = box(
        root, SCNVector3(0.62, 0.37, 0.2), SCNVector3(sign * 0.55, 3.42, 0.61), white)
      breast.eulerAngles.z = sign * -0.14
      for vent in 0..<3 {
        box(
          root, SCNVector3(0.42, 0.06, 0.1), SCNVector3(sign * 0.55, 3.3 - Float(vent) * 0.11, 0.7),
          0xE9BF53, bevel: 0)
      }
      let skirt = box(root, SCNVector3(0.62, 0.8, 0.32), SCNVector3(sign * 0.48, 2.12, 0.52), white)
      skirt.eulerAngles.x = -0.22
      box(skirt, SCNVector3(0.36, 0.4, 0.08), SCNVector3(0, 0, 0.19), armor)
      let leg = SCNNode()
      leg.name = sign < 0 ? "legL" : "legR"
      leg.position = SCNVector3(sign * 0.5, 2, 0)
      root.addChildNode(leg)
      box(leg, SCNVector3(0.48, 0.8, 0.6), SCNVector3(0, -0.36, 0), joint)
      box(leg, SCNVector3(0.66, 0.68, 0.65), SCNVector3(0, -0.3, 0.04), white)
      let knee = cylinder(
        leg, radius: 0.22, height: 0.68, position: SCNVector3(0, -0.8, 0), color: joint)
      knee.eulerAngles.z = .pi / 2
      box(leg, SCNVector3(0.55, 0.42, 0.3), SCNVector3(0, -0.8, 0.35), armor)
      box(leg, SCNVector3(0.67, 0.91, 0.62), SCNVector3(0, -1.3, -0.02), white, bevel: 0.14)
      box(leg, SCNVector3(0.16, 0.55, 0.1), SCNVector3(0, -1.27, 0.33), armor)
      box(leg, SCNVector3(0.73, 0.34, 1.3), SCNVector3(0, -1.83, 0.32), armor, bevel: 0.11)
      box(leg, SCNVector3(0.74, 0.09, 1.31), SCNVector3(0, -1.97, 0.32), joint, bevel: 0.03)
      let arm = SCNNode()
      arm.position = SCNVector3(sign * 1.14, 3.5, 0)
      arm.name = sign < 0 ? "armL" : "armR"
      root.addChildNode(arm)
      let shoulder = box(
        arm, SCNVector3(0.9, 0.58, 1), SCNVector3(sign * 0.15, 0.05, 0), white, bevel: 0.12)
      shoulder.eulerAngles.z = sign * -0.18
      box(shoulder, SCNVector3(0.76, 0.15, 0.85), SCNVector3(0, 0.31, 0), armor)
      box(arm, SCNVector3(0.4, 0.65, 0.42), SCNVector3(0, -0.53, 0), joint)
      box(arm, SCNVector3(0.56, 0.7, 0.56), SCNVector3(0, -1.02, 0.1), white, bevel: 0.1)
      box(arm, SCNVector3(0.4, 0.33, 0.42), SCNVector3(0, -1.47, 0.12), joint)
      let wing = box(root, SCNVector3(0.32, 2.6, 0.8), SCNVector3(sign * 0.85, 3.8, -0.9), armor)
      wing.eulerAngles.z = sign * -0.36
      box(wing, SCNVector3(0.12, 2.3, 0.12), SCNVector3(0, 0, -0.45), accent, glow: true)
      let nozzle = cylinder(
        root, radius: 0.26, height: 0.5, position: SCNVector3(sign * 0.45, 2.85, -1), color: joint)
      nozzle.eulerAngles.x = .pi / 2
      let flame = SCNCone(topRadius: 0.22, bottomRadius: 0, height: 2.8)
      flame.radialSegmentCount = 8
      flame.materials = [material(accent, glow: true)]
      let exhaust = SCNNode(geometry: flame)
      exhaust.name = sign < 0 ? "exhaustL" : "exhaustR"
      exhaust.position = SCNVector3(sign * 0.45, 2.85, -2.2)
      exhaust.eulerAngles.x = .pi / 2
      root.addChildNode(exhaust)
    }
    box(root, SCNVector3(1.05, 1.15, 0.72), SCNVector3(0, 3.05, -0.78), joint)
    box(root, SCNVector3(0.67, 0.64, 0.65), SCNVector3(0, 4.1, 0.03), white, bevel: 0.13)
    box(root, SCNVector3(0.53, 0.13, 0.07), SCNVector3(0, 4.13, 0.39), joint, bevel: 0)
    box(
      root, SCNVector3(0.42, 0.065, 0.08), SCNVector3(0, 4.14, 0.44), accent, bevel: 0, glow: true)
    box(root, SCNVector3(0.18, 0.25, 0.12), SCNVector3(0, 3.95, 0.42), armor)
    for sign: Float in [-1, 1] {
      let fin = box(
        root, SCNVector3(0.09, 0.85, 0.16), SCNVector3(sign * 0.26, 4.55, 0.1), 0xEED080, bevel: 0)
      fin.eulerAngles.z = sign * -0.7
    }
    if let arm = root.childNode(withName: "armR", recursively: false) {
      box(arm, SCNVector3(0.38, 0.4, 2.3), SCNVector3(0, -1.34, 0.91), joint)
      box(arm, SCNVector3(0.48, 0.45, 0.9), SCNVector3(0, -1.34, 0.3), armor)
      box(arm, SCNVector3(0.13, 0.13, 1.3), SCNVector3(0, -1.1, 0.9), accent, glow: true)
    }
    if let arm = root.childNode(withName: "armL", recursively: false) {
      box(arm, SCNVector3(0.85, 1.8, 0.27), SCNVector3(-0.2, -0.75, 0.65), armor, bevel: 0.15)
      box(arm, SCNVector3(0.11, 1.5, 0.06), SCNVector3(-0.2, -0.75, 0.82), white)
      box(arm, SCNVector3(0.62, 0.1, 0.07), SCNVector3(-0.2, -0.65, 0.84), white)
    }
    let saber = cylinder(
      root, radius: 0.09, height: 4.8, position: SCNVector3(1.65, 3.4, 1.5), color: 0xFF6DE9,
      glow: true)
    saber.name = "saber"
    saber.eulerAngles.x = .pi / 3
    saber.isHidden = true
    let shield = SCNSphere(radius: 2.9)
    shield.materials = [material(0x45D6FF, glow: true)]
    let shieldNode = SCNNode(geometry: shield)
    shieldNode.position.y = 2.2
    shieldNode.name = "shield"
    shieldNode.opacity = 0.13
    shieldNode.isHidden = true
    root.addChildNode(shieldNode)
    return root
  }

  func reset() {
    snapshot = nil
    for node in units.values { node.removeFromParentNode() }
    for node in beams.values { node.removeFromParentNode() }
    units.removeAll()
    beams.removeAll()
    showroom.isHidden = false
    cameraInitialized = false
  }

  func apply(_ state: ArenaState, playerID: String) {
    snapshot = state
    self.playerID = playerID
    if state.phase == "lobby" { return }
    showroom.isHidden = true
    for unit in state.units {
      if units[unit.id] == nil {
        let node = makeMecha(team: unit.team)
        node.position = SCNVector3(unit.x, unit.y, unit.z)
        scene.rootNode.addChildNode(node)
        units[unit.id] = node
        if unit.id != playerID {
          let label = SCNText(
            string: unit.ai ? unit.name : "\(unit.name) • HUMAN", extrusionDepth: 0)
          label.font = UIFont.monospacedSystemFont(ofSize: 0.55, weight: .bold)
          label.flatness = 0.2
          label.materials = [material(unit.team == 0 ? 0x53DFFF : 0xFFA178, glow: true)]
          let text = SCNNode(geometry: label)
          text.position = SCNVector3(-1.9, 5.4, 0)
          let billboard = SCNBillboardConstraint()
          text.constraints = [billboard]
          node.addChildNode(text)
        }
      }
    }
    let ids = Set(state.projectiles.map(\.id))
    for id in Array(beams.keys) where !ids.contains(id) {
      beams[id]?.removeFromParentNode()
      beams.removeValue(forKey: id)
    }
    for beam in state.projectiles {
      if beams[beam.id] == nil {
        let node = box(
          scene.rootNode, SCNVector3(0.22, 0.22, 3.3), SCNVector3(beam.x, beam.y, beam.z),
          beam.team == 0 ? 0x5FFFF1 : 0xFF72B4, glow: true)
        beams[beam.id] = node
      }
      beams[beam.id]?.position = SCNVector3(beam.x, beam.y, beam.z)
      beams[beam.id]?.look(at: SCNVector3(beam.x + beam.vx, beam.y + beam.vy, beam.z + beam.vz))
    }
  }

  func animate() {
    time += 1 / 30
    guard let snapshot, snapshot.phase != "lobby",
      let me = snapshot.units.first(where: { $0.id == playerID }),
      let node = units[playerID]
    else {
      showroom.eulerAngles.y = time * 0.22
      camera.position = SCNVector3(10, 6, 13)
      camera.look(at: SCNVector3(-2.5, 2.5, 0))
      return
    }
    for unit in snapshot.units {
      guard let suit = units[unit.id] else { continue }
      let target = SCNVector3(unit.x, unit.y, unit.z)
      let travel = hypot(target.x - suit.position.x, target.z - suit.position.z)
      suit.position = lerp(suit.position, target, 0.5)
      suit.eulerAngles.y = unit.yaw
      suit.isHidden = unit.hp <= 0
      suit.opacity = unit.invulnerable > 0 && sin(time * 25) > 0 ? 0.4 : 1
      let moving = travel > 0.025
      let airborne = unit.y > 0.3
      suit.childNode(withName: "legL", recursively: false)?.eulerAngles.x =
        airborne ? -0.45 : moving ? sin(time * 15) * 0.35 : 0
      suit.childNode(withName: "legR", recursively: false)?.eulerAngles.x =
        airborne ? 0.4 : moving ? -sin(time * 15) * 0.35 : 0
      suit.childNode(withName: "armR", recursively: false)?.eulerAngles.x =
        unit.melee > 0 ? -1.8 : -0.75
      for name in ["exhaustL", "exhaustR"] {
        let flame = suit.childNode(withName: name, recursively: false)
        flame?.isHidden = !airborne && unit.dodge <= 0 && unit.overdrive <= 0
        flame?.scale.y = 0.8 + abs(sin(time * 37)) * 0.6
      }
      let saber = suit.childNode(withName: "saber", recursively: false)
      saber?.isHidden = unit.melee <= 0
      saber?.eulerAngles.z = Float(unit.melee) * 12 - 2
      suit.childNode(withName: "shield", recursively: false)?.isHidden = !unit.blocking
    }
    let direction = SCNVector3(sin(me.yaw), 0, cos(me.yaw))
    let desired = SCNVector3(
      node.position.x - direction.x * 14,
      node.position.y + 8.5, node.position.z - direction.z * 14)
    camera.position = cameraInitialized ? lerp(camera.position, desired, 0.15) : desired
    cameraInitialized = true
    camera.look(
      at: SCNVector3(
        node.position.x + direction.x * 13, node.position.y + 2.6,
        node.position.z + direction.z * 13))
    if let target = snapshot.units.first(where: { $0.id == me.target }), let view {
      let projected = view.projectPoint(SCNVector3(target.x, target.y + 2.5, target.z))
      reticleChanged?(
        projected.z < 1 && projected.z > 0
          ? CGPoint(x: CGFloat(projected.x), y: CGFloat(projected.y)) : CGPoint(x: -500, y: -500))
    }
  }

  private func lerp(_ a: SCNVector3, _ b: SCNVector3, _ t: Float) -> SCNVector3 {
    SCNVector3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t)
  }

  func effect(_ event: CombatEvent) {
    guard ["hit", "destroy", "saber", "dodge", "burst", "guard"].contains(event.kind) else {
      return
    }
    let large = event.kind == "destroy" || event.kind == "burst"
    let color: UInt32 =
      event.kind == "dodge"
      ? 0x64FFCB : event.kind == "saber" ? 0xFF67E4 : event.kind == "burst" ? 0x8BCEFF : 0xFFD18A
    let geometry = SCNSphere(radius: large ? 1.5 : 0.6)
    geometry.segmentCount = 12
    geometry.materials = [material(color, glow: true)]
    let flash = SCNNode(geometry: geometry)
    flash.position = SCNVector3(event.x, event.y, event.z)
    scene.rootNode.addChildNode(flash)
    flash.runAction(
      .sequence([
        .group([.scale(to: large ? 5 : 2, duration: 0.25), .fadeOut(duration: 0.35)]),
        .removeFromParentNode(),
      ]))
    for index in 0..<(large ? 18 : 7) {
      let spark = box(
        scene.rootNode, SCNVector3(0.07, 0.07, 0.9), flash.position, color, glow: true)
      let angle = Float(index) * 2.4
      let delta = SCNVector3(sin(angle) * 4, Float(index % 5) * 1.2 - 1, cos(angle) * 4)
      spark.look(at: SCNVector3(event.x + delta.x, event.y + delta.y, event.z + delta.z))
      spark.runAction(
        .sequence([
          .group([.move(by: delta, duration: 0.4), .fadeOut(duration: 0.4)]),
          .removeFromParentNode(),
        ]))
    }
  }
}

struct ArenaView: UIViewRepresentable {
  let renderer: ArenaRenderer
  func makeUIView(context: Context) -> SCNView {
    let view = SCNView()
    view.scene = renderer.scene
    view.pointOfView = renderer.camera
    view.preferredFramesPerSecond = 60
    view.antialiasingMode = .multisampling4X
    view.isPlaying = true
    view.backgroundColor = .black
    renderer.view = view
    return view
  }
  func updateUIView(_ uiView: SCNView, context: Context) {}
}
