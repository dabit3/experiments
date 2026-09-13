import SceneKit
import SwiftUI
import UIKit

extension Vec {
  fileprivate var scn: SCNVector3 { SCNVector3(x, y, z) }
}

private func color(_ hex: UInt32) -> UIColor {
  UIColor(
    red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
    blue: CGFloat(hex & 255) / 255, alpha: 1)
}

private func material(_ hex: UInt32, glow: Bool = false, alpha: CGFloat = 1) -> SCNMaterial {
  let mat = SCNMaterial()
  mat.diffuse.contents = color(hex)
  mat.lightingModel = glow ? .constant : .blinn
  mat.specular.contents = glow ? UIColor.black : UIColor(white: 0.22, alpha: 1)
  mat.shininess = 0.4
  mat.transparency = alpha
  if glow {
    mat.emission.contents = color(hex)
    mat.blendMode = alpha < 1 ? .add : .alpha
    mat.writesToDepthBuffer = false
  }
  return mat
}

@MainActor
final class FighterRig {
  let root = SCNNode()
  let body = SCNNode()
  let leftArm = SCNNode()
  let rightArm = SCNNode()
  let leftLeg = SCNNode()
  let rightLeg = SCNNode()
  let aura = SCNNode()
  let ring = SCNNode()
  let slot: Int
  var mode = "idle"
  var attackingUntil = 0.0

  init(slot: Int) {
    self.slot = slot
    let suit: UInt32 = slot == 0 ? 0xEF7126 : 0x2456AC
    let trim: UInt32 = slot == 0 ? 0x153767 : 0xDCE8EF
    let skin: UInt32 = 0xECB085
    let hair: UInt32 = slot == 0 ? 0xFFCD38 : 0xDAEBFF
    root.addChildNode(body)
    body.addChildNode(aura)
    func sphere(
      _ parent: SCNNode, _ radius: CGFloat, _ scale: SCNVector3, _ pos: SCNVector3, _ hex: UInt32
    ) {
      let g = SCNSphere(radius: radius)
      g.segmentCount = 12
      let n = SCNNode(geometry: g)
      n.geometry?.firstMaterial = material(hex)
      n.scale = scale
      n.position = pos
      parent.addChildNode(n)
    }
    func box(
      _ parent: SCNNode, _ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ pos: SCNVector3, _ hex: UInt32
    ) -> SCNNode {
      let n = SCNNode(geometry: SCNBox(width: w, height: h, length: d, chamferRadius: 0.035))
      n.geometry?.firstMaterial = material(hex)
      n.position = pos
      parent.addChildNode(n)
      return n
    }
    sphere(body, 0.55, SCNVector3(1, 1.18, 0.59), SCNVector3(0, 1.95, 0), suit)
    sphere(body, 0.36, SCNVector3(1.2, 0.64, 0.8), SCNVector3(0, 1.4, 0), trim)
    _ = box(body, 0.93, 0.2, 0.65, SCNVector3(0, 1.38, 0), trim)
    _ = box(body, 0.18, 0.22, 0.07, SCNVector3(0, 1.37, 0.37), 0xF8C84C)
    if slot == 0 {
      let left = box(body, 0.18, 0.85, 0.08, SCNVector3(-0.18, 2.05, 0.34), trim)
      left.eulerAngles.z = -0.37
      let right = box(body, 0.18, 0.85, 0.08, SCNVector3(0.18, 2.05, 0.34), trim)
      right.eulerAngles.z = 0.37
      sphere(body, 0.23, SCNVector3(1, 0.8, 0.35), SCNVector3(0, 2.37, 0.22), skin)
      let tail = box(body, 0.15, 0.6, 0.07, SCNVector3(0.48, 1.17, -0.1), trim)
      tail.eulerAngles.z = 0.6
    } else {
      _ = box(body, 0.83, 0.64, 0.18, SCNVector3(0, 2.13, 0.26), trim)
      for i in 0..<4 {
        _ = box(body, 0.56, 0.055, 0.05, SCNVector3(0, 1.91 + Float(i) * 0.12, 0.37), 0xF5BA4A)
      }
    }
    sphere(body, 0.15, SCNVector3(1, 1.3, 1), SCNVector3(0, 2.58, 0), skin)
    sphere(body, 0.4, SCNVector3(0.82, 1.1, 0.83), SCNVector3(0, 2.94, 0), skin)
    sphere(body, 0.11, SCNVector3(0.6, 1, 0.65), SCNVector3(-0.34, 2.94, 0), skin)
    sphere(body, 0.11, SCNVector3(0.6, 1, 0.65), SCNVector3(0.34, 2.94, 0), skin)
    sphere(body, 0.37, SCNVector3(1, 0.86, 0.95), SCNVector3(0, 3.17, -0.045), hair)
    for i in 0..<9 {
      let angle = Float(i) / 9 * .pi * 2
      let spike = SCNNode(
        geometry: SCNCone(
          topRadius: 0, bottomRadius: 0.19, height: CGFloat(0.55 + Double(i % 3) * 0.15)))
      (spike.geometry as? SCNCone)?.radialSegmentCount = 5
      spike.geometry?.firstMaterial = material(hair)
      spike.position = SCNVector3(
        sin(angle) * 0.26, 3.39 + Float(i % 2) * 0.06, cos(angle) * 0.23 - 0.06)
      spike.eulerAngles = SCNVector3(cos(angle) * 0.6, angle, -sin(angle) * 0.65)
      body.addChildNode(spike)
    }
    for side: Float in [-1, 1] {
      let eye = box(body, 0.2, 0.095, 0.045, SCNVector3(side * 0.16, 2.99, 0.299), 0xFFFFFF)
      eye.eulerAngles.z = -side * 0.16
      _ = box(body, 0.045, 0.075, 0.05, SCNVector3(side * 0.13, 2.99, 0.327), 0x1D3444)
      let brow = box(
        body, 0.22, 0.04, 0.05, SCNVector3(side * 0.16, 3.067, 0.3), slot == 0 ? 0x845418 : 0x335879
      )
      brow.eulerAngles.z = -side * 0.22
    }
    sphere(body, 0.075, SCNVector3(0.6, 1, 1), SCNVector3(0, 2.88, 0.335), skin)
    _ = box(body, 0.13, 0.022, 0.03, SCNVector3(0, 2.76, 0.303), 0x733F36)
    for (arm, sign) in [(leftArm, Float(-1)), (rightArm, Float(1))] {
      arm.position = SCNVector3(sign * 0.57, 2.32, 0)
      body.addChildNode(arm)
      sphere(
        arm, 0.25, SCNVector3(1.0, 1.05, 0.9), SCNVector3(sign * 0.06, -0.04, 0),
        slot == 0 ? skin : trim)
      sphere(arm, 0.21, SCNVector3(0.85, 1.5, 0.87), SCNVector3(sign * 0.11, -0.34, 0), skin)
      sphere(arm, 0.19, SCNVector3(0.88, 1.25, 0.95), SCNVector3(sign * 0.09, -0.66, 0.04), skin)
      _ = box(arm, 0.32, 0.22, 0.34, SCNVector3(sign * 0.09, -0.79, 0.045), trim)
      sphere(
        arm, 0.22, SCNVector3(0.9, 1.02, 1), SCNVector3(sign * 0.09, -0.97, 0.055),
        slot == 0 ? skin : 0xF4F8FF)
      arm.eulerAngles.z = sign * 0.15
    }
    for (leg, sign) in [(leftLeg, Float(-1)), (rightLeg, Float(1))] {
      leg.position = SCNVector3(sign * 0.27, 1.34, 0)
      body.addChildNode(leg)
      sphere(leg, 0.31, SCNVector3(1, 1.46, 1.02), SCNVector3(sign * 0.06, -0.35, 0), suit)
      sphere(leg, 0.24, SCNVector3(0.9, 1.55, 0.94), SCNVector3(sign * 0.07, -0.85, 0), suit)
      _ = box(leg, 0.36, 0.43, 0.38, SCNVector3(sign * 0.07, -1.02, 0.025), trim)
      _ = box(leg, 0.38, 0.2, 0.58, SCNVector3(sign * 0.07, -1.22, 0.12), trim)
      _ = box(leg, 0.38, 0.05, 0.57, SCNVector3(sign * 0.07, -1.31, 0.12), 0x1A253B)
    }
    let energy = slot == 0 ? UInt32(0xFFD852) : UInt32(0x54DDFF)
    for i in 0..<10 {
      let flame = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.32, height: 2.8))
      flame.geometry?.firstMaterial = material(energy, glow: true, alpha: 0.21)
      let angle = Float(i) * .pi / 5
      flame.position = SCNVector3(sin(angle) * 0.85, 1.7, cos(angle) * 0.85)
      flame.eulerAngles = SCNVector3(cos(angle) * 0.2, 0, -sin(angle) * 0.2)
      aura.addChildNode(flame)
      flame.runAction(
        .repeatForever(
          .sequence([
            .scale(to: CGFloat(0.8 + Double(i % 3) * 0.14), duration: 0.12 + Double(i) * 0.01),
            .scale(to: 1.15, duration: 0.18),
          ])))
    }
    let baseRing = SCNTorus(ringRadius: 1.18, pipeRadius: 0.035)
    ring.geometry = baseRing
    ring.geometry?.firstMaterial = material(energy, glow: true)
    ring.position.y = 0.06
    root.addChildNode(ring)
    aura.opacity = 0.15
  }

  func animate(time: Double, flying: Bool) {
    let t = Float(time)
    if time > attackingUntil {
      let moving = mode == "move" || mode == "boost"
      let sway: Float = moving ? sin(t * 13) * 0.55 : sin(t * 2.8) * 0.05
      leftArm.eulerAngles.x = moving && !flying ? sway : -0.3
      rightArm.eulerAngles.x = moving && !flying ? -sway : -0.3
      leftLeg.eulerAngles.x = moving && !flying ? -sway : -0.12
      rightLeg.eulerAngles.x = moving && !flying ? sway : 0.22
      leftArm.eulerAngles.z = -0.15
      rightArm.eulerAngles.z = 0.15
      if mode == "charge" {
        leftArm.eulerAngles.z = -0.6
        rightArm.eulerAngles.z = 0.6
        leftArm.eulerAngles.x = -0.5
        rightArm.eulerAngles.x = -0.5
      }
      if mode == "beam" {
        leftArm.eulerAngles = SCNVector3(-1.5, 0, -0.35)
        rightArm.eulerAngles = SCNVector3(-1.5, 0, 0.35)
      }
    }
    body.position.y = sin(t * 3.5) * (flying ? 0.1 : 0.025)
    body.eulerAngles.x = mode == "boost" ? 0.55 : mode == "hit" ? -0.25 : 0
    aura.opacity =
      mode == "charge" || mode == "beam" ? 0.9 : mode == "boost" ? 0.55 : flying ? 0.22 : 0.07
    ring.eulerAngles.y = t
    if mode == "dodge" { body.opacity = 0.4 } else { body.opacity = 1 }
  }

  func punch(combo: Int) {
    attackingUntil = CACurrentMediaTime() + 0.3
    let limb = combo == 3 ? rightLeg : combo == 2 ? leftArm : rightArm
    limb.removeAction(forKey: "attack")
    limb.runAction(
      .sequence([
        .rotateTo(x: -1.7, y: 0, z: combo == 3 ? 0.4 : 0.1, duration: 0.065),
        .rotateTo(x: -0.25, y: 0, z: 0.1, duration: 0.2),
      ]), forKey: "attack")
  }
}

@MainActor
final class ArenaRenderer: NSObject {
  let scene = SCNScene()
  let camera = SCNNode()
  private var rigs: [String: FighterRig] = [:]
  private var shots: [Int: SCNNode] = [:]
  private let effects = SCNNode()
  private let target = SCNNode()
  private var latest: ArenaState?
  private var localID = ""
  private var eventID = 0
  private var link: CADisplayLink?
  private var previewing = true
  private var cameraReady = false

  override init() {
    super.init()
    makeWorld()
    camera.camera = SCNCamera()
    camera.camera?.fieldOfView = 57
    camera.camera?.zFar = 400
    camera.camera?.wantsHDR = true
    camera.camera?.bloomIntensity = 0.8
    camera.camera?.bloomThreshold = 0.85
    camera.camera?.bloomBlurRadius = 8
    camera.camera?.exposureOffset = -0.15
    scene.rootNode.addChildNode(camera)
    scene.rootNode.addChildNode(effects)
    let reticle = SCNTorus(ringRadius: 1.2, pipeRadius: 0.025)
    target.geometry = reticle
    target.geometry?.firstMaterial = material(0xFFCF42, glow: true)
    target.eulerAngles.x = .pi / 2
    let billboard = SCNBillboardConstraint()
    billboard.freeAxes = .all
    let carrier = SCNNode()
    carrier.addChildNode(target)
    carrier.constraints = [billboard]
    scene.rootNode.addChildNode(carrier)
    target.name = "target"
    target.isHidden = true
    link = CADisplayLink(target: self, selector: #selector(animate))
    link?.preferredFramesPerSecond = 30
    link?.add(to: .main, forMode: .common)
  }

  private func makeWorld() {
    let size = CGSize(width: 512, height: 1024)
    scene.background.contents = UIGraphicsImageRenderer(size: size).image { context in
      let colors =
        [color(0x063F82).cgColor, color(0x38A5D5).cgColor, color(0xC6F1E9).cgColor] as CFArray
      if let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.6, 1])
      {
        context.cgContext.drawLinearGradient(
          gradient, start: .zero, end: CGPoint(x: 0, y: 1024), options: [])
      }
    }
    scene.fogColor = color(0xA0DADE)
    scene.fogStartDistance = 70
    scene.fogEndDistance = 185
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.color = color(0xD2E2F3)
    ambient.light?.intensity = 650
    scene.rootNode.addChildNode(ambient)
    let sun = SCNNode()
    sun.light = SCNLight()
    sun.light?.type = .directional
    sun.light?.color = color(0xFFF0C7)
    sun.light?.intensity = 1450
    sun.light?.castsShadow = true
    sun.light?.shadowMode = .deferred
    sun.light?.shadowColor = UIColor(white: 0.05, alpha: 0.35)
    sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
    sun.light?.orthographicScale = 65
    sun.eulerAngles = SCNVector3(-0.9, -0.6, 0)
    scene.rootNode.addChildNode(sun)
    let water = SCNNode(geometry: SCNPlane(width: 600, height: 600))
    water.geometry?.firstMaterial = material(0x168FAD)
    water.eulerAngles.x = -.pi / 2
    water.position.y = -4
    scene.rootNode.addChildNode(water)
    plateau(x: 0, z: 0, radius: 33, height: 4, top: 0, grass: true)
    let arenaRing = SCNNode(geometry: SCNTorus(ringRadius: 30, pipeRadius: 0.075))
    arenaRing.geometry?.firstMaterial = material(0xA9EEDF, glow: true, alpha: 0.5)
    arenaRing.position.y = 0.08
    scene.rootNode.addChildNode(arenaRing)
    for i in 0..<28 {
      let angle = Double(i) * 2.39996
      let radius = Double(50 + (i % 5) * 10)
      plateau(
        x: sin(angle) * radius, z: cos(angle) * radius,
        radius: Double(4 + i % 7), height: Double(6 + i % 6 * 3), top: Double(i % 5 * 3),
        grass: true)
    }
    for i in 0..<40 {
      let angle = Double(i) * 2.39996
      let r = 10 + Double(i % 9) * 2
      let rock = SCNNode(geometry: SCNSphere(radius: CGFloat(0.2 + Double(i % 3) * 0.12)))
      (rock.geometry as? SCNSphere)?.segmentCount = 6
      rock.scale = SCNVector3(1.4, 0.5, 1)
      rock.position = SCNVector3(sin(angle) * r, 0.1, cos(angle) * r)
      rock.geometry?.firstMaterial = material(i % 2 == 0 ? 0xA8AD76 : 0x6E8B60)
      scene.rootNode.addChildNode(rock)
    }
    for i in 0..<12 {
      let angle = Double(i) * .pi / 6
      let cloud = SCNNode()
      cloud.position = SCNVector3(sin(angle) * 100, Double(30 + i % 4 * 4), cos(angle) * 100)
      for j in 0..<4 {
        let puff = SCNNode(geometry: SCNSphere(radius: CGFloat(3 + j)))
        (puff.geometry as? SCNSphere)?.segmentCount = 12
        puff.geometry?.firstMaterial = material(0xDFF5F8)
        puff.position.x = Float(j) * 5
        puff.scale.y = 0.4
        cloud.addChildNode(puff)
      }
      scene.rootNode.addChildNode(cloud)
    }
    for i in 0..<8 {
      let angle = Double(i) * .pi / 4 + 0.3
      let tree = SCNNode()
      tree.position = SCNVector3(sin(angle) * 31, 0, cos(angle) * 31)
      let trunk = SCNNode(geometry: SCNCylinder(radius: 0.19, height: 2.6))
      trunk.position.y = 1.3
      trunk.geometry?.firstMaterial = material(0x705B3F)
      tree.addChildNode(trunk)
      for j in 0..<3 {
        let crown = SCNNode(geometry: SCNSphere(radius: 1.4))
        (crown.geometry as? SCNSphere)?.segmentCount = 8
        crown.position = SCNVector3(Float(j - 1) * 0.7, 2.8 + Float(j % 2) * 0.7, 0)
        crown.scale.y = 0.75
        crown.geometry?.firstMaterial = material(j == 1 ? 0x80AF50 : 0x487D48)
        tree.addChildNode(crown)
      }
      scene.rootNode.addChildNode(tree)
    }
  }

  private func plateau(
    x: Double, z: Double, radius: Double, height: Double, top: Double, grass: Bool
  ) {
    let rock = SCNNode(geometry: SCNCylinder(radius: radius, height: height))
    (rock.geometry as? SCNCylinder)?.radialSegmentCount = 9
    rock.geometry?.firstMaterial = material(0xAA9765)
    rock.position = SCNVector3(x, top - height / 2, z)
    scene.rootNode.addChildNode(rock)
    for i in 0..<3 {
      let layer = SCNNode(geometry: SCNCylinder(radius: radius + 0.15, height: 0.25))
      (layer.geometry as? SCNCylinder)?.radialSegmentCount = 9
      layer.position = SCNVector3(x, top - Double(i) * height / 3 - 0.4, z)
      layer.geometry?.firstMaterial = material(0x897653)
      scene.rootNode.addChildNode(layer)
    }
    let cap = SCNNode(geometry: SCNCylinder(radius: radius + 0.03, height: 0.15))
    (cap.geometry as? SCNCylinder)?.radialSegmentCount = 9
    cap.position = SCNVector3(x, top - 0.04, z)
    cap.geometry?.firstMaterial = material(grass ? 0x7EAD53 : 0xBFBA87)
    scene.rootNode.addChildNode(cap)
    if radius > 20 {
      let stone = SCNNode(geometry: SCNCylinder(radius: 12, height: 0.05))
      (stone.geometry as? SCNCylinder)?.radialSegmentCount = 12
      stone.position.y = 0.065
      stone.geometry?.firstMaterial = material(0xB9B78A)
      scene.rootNode.addChildNode(stone)
      for i in 0..<12 {
        let line = SCNNode(
          geometry: SCNBox(width: 0.035, height: 0.02, length: 24, chamferRadius: 0))
        line.geometry?.firstMaterial = material(0x9C9D78)
        line.position.y = 0.1
        line.eulerAngles.y = Float(i) * .pi / 6
        scene.rootNode.addChildNode(line)
      }
    }
  }

  func preview() {
    for rig in rigs.values { rig.root.removeFromParentNode() }
    for shot in shots.values { shot.removeFromParentNode() }
    shots = [:]
    eventID = 0
    rigs = [:]
    let rig = FighterRig(slot: 0)
    scene.rootNode.addChildNode(rig.root)
    rig.root.position = SCNVector3(0, 0, 0)
    rigs["preview"] = rig
    previewing = true
    cameraReady = false
    target.isHidden = true
  }

  func update(_ state: ArenaState, localID: String) {
    if previewing {
      rigs["preview"]?.root.removeFromParentNode()
      rigs.removeValue(forKey: "preview")
      previewing = false
      cameraReady = false
    }
    latest = state
    self.localID = localID
    for p in state.players {
      if rigs[p.id] == nil {
        let rig = FighterRig(slot: p.slot)
        rigs[p.id] = rig
        scene.rootNode.addChildNode(rig.root)
        rig.root.position = p.pos.scn
      }
      guard let rig = rigs[p.id] else { continue }
      rig.mode = p.mode
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.09
      rig.root.position = p.pos.scn
      let currentYaw = rig.root.eulerAngles.y
      var delta = Float(p.yaw) - currentYaw
      while delta > .pi { delta -= 2 * .pi }
      while delta < -.pi { delta += 2 * .pi }
      rig.root.eulerAngles.y = currentYaw + delta
      SCNTransaction.commit()
    }
    for id in Array(rigs.keys) where !state.players.contains(where: { $0.id == id }) {
      rigs.removeValue(forKey: id)?.root.removeFromParentNode()
    }
    for shot in state.projectiles {
      if shots[shot.id] == nil {
        let node = orb(radius: 0.24, hex: 0xFFD659)
        shots[shot.id] = node
        effects.addChildNode(node)
        node.position = shot.pos.scn
      }
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.067
      shots[shot.id]?.position = shot.pos.scn
      SCNTransaction.commit()
    }
    for id in Array(shots.keys) where !state.projectiles.contains(where: { $0.id == id }) {
      shots.removeValue(forKey: id)?.removeFromParentNode()
    }
    for event in state.effects where event.event > eventID {
      show(event, state: state)
      eventID = event.event
    }
  }

  @objc private func animate() {
    let time = CACurrentMediaTime()
    if previewing {
      let angle = Float(sin(time * 0.15) * 0.3)
      camera.position = SCNVector3(5 + sin(angle) * 2, 3.1, 9)
      camera.look(
        at: SCNVector3(0, 1.95, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
      rigs["preview"]?.root.eulerAngles.y = 0.3
      rigs["preview"]?.animate(time: time, flying: false)
      return
    }
    guard let state = latest, let me = state.players.first(where: { $0.id == localID }),
      let rig = rigs[localID]
    else { return }
    for p in state.players { rigs[p.id]?.animate(time: time, flying: p.flying) }
    let pos = rig.root.presentation.position
    let enemy = state.players.first { $0.id != localID }
    let other =
      enemy.flatMap { rigs[$0.id]?.root.presentation.position }
      ?? SCNVector3(pos.x, pos.y, pos.z + 10)
    let dx = other.x - pos.x
    let dz = other.z - pos.z
    let distance = max(0.01, sqrt(dx * dx + dz * dz))
    let forwardX = dx / distance
    let forwardZ = dz / distance
    let back: Float = me.mode == "boost" ? 10.5 : 8.8
    let desired = SCNVector3(
      pos.x - forwardX * back + forwardZ * 2.8, pos.y + 5.1,
      pos.z - forwardZ * back - forwardX * 2.8)
    let old = camera.position
    let smoothing: Float = cameraReady ? 0.12 : 1
    camera.position = SCNVector3(
      old.x + (desired.x - old.x) * smoothing, old.y + (desired.y - old.y) * smoothing,
      old.z + (desired.z - old.z) * smoothing)
    cameraReady = true
    let focusDistance = min(distance * 0.4, 6)
    camera.look(
      at: SCNVector3(
        pos.x + forwardX * focusDistance, pos.y + 2.0 + (other.y - pos.y) * 0.3,
        pos.z + forwardZ * focusDistance),
      up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
    target.isHidden = !me.locked || enemy == nil || state.phase == "result"
    target.parent?.position = SCNVector3(other.x, other.y + 1.7, other.z)
  }

  private func orb(radius: CGFloat, hex: UInt32) -> SCNNode {
    let root = SCNNode()
    for (scale, alpha) in [(1.0, 1.0), (1.8, 0.28), (2.5, 0.12)] {
      let node = SCNNode(geometry: SCNSphere(radius: radius * scale))
      (node.geometry as? SCNSphere)?.segmentCount = 12
      node.geometry?.firstMaterial = material(scale == 1 ? 0xFFF8DC : hex, glow: true, alpha: alpha)
      root.addChildNode(node)
    }
    return root
  }

  private func show(_ event: CombatEffect, state: ArenaState) {
    if event.type == "melee", let id = event.player {
      rigs[id]?.punch(combo: event.combo ?? 1)
    }
    if event.type == "hit", let pos = event.pos {
      let burst = orb(radius: event.kind == "beam" ? 1.2 : 0.65, hex: 0xFFB533)
      burst.position = SCNVector3(pos.x, pos.y + 1.7, pos.z)
      effects.addChildNode(burst)
      burst.runAction(
        .sequence([
          .group([.scale(to: 2.6, duration: 0.25), .fadeOut(duration: 0.3)]),
          .removeFromParentNode(),
        ]))
      for i in 0..<12 {
        let spark = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.055, height: 1.2))
        spark.geometry?.firstMaterial = material(0xFFF4AA, glow: true)
        spark.position = burst.position
        let angle = Double(i) * 2.39996
        spark.eulerAngles = SCNVector3(angle, angle * 0.7, angle * 0.5)
        effects.addChildNode(spark)
        spark.runAction(
          .sequence([
            .group([
              .moveBy(x: sin(angle) * 3, y: cos(angle * 1.7) * 2, z: cos(angle) * 3, duration: 0.3),
              .fadeOut(duration: 0.35),
            ]),
            .removeFromParentNode(),
          ]))
      }
    }
    if event.type == "beamCharge", let id = event.player, let rig = rigs[id] {
      let ball = orb(radius: 0.5, hex: 0x39DFFF)
      ball.position = SCNVector3(0, 1.9, 0.9)
      rig.root.addChildNode(ball)
      ball.runAction(.sequence([.scale(to: 2.2, duration: 0.75), .removeFromParentNode()]))
    }
    if event.type == "beam", let pos = event.pos, let dir = event.dir {
      let beam = SCNNode()
      beam.position = SCNVector3(pos.x, pos.y + 1.7, pos.z)
      beam.look(at: SCNVector3(pos.x + dir.x * 45, pos.y + 1.7 + dir.y * 45, pos.z + dir.z * 45))
      for (radius, alpha) in [(0.3, 1.0), (0.65, 0.45), (1.0, 0.18)] {
        let tube = SCNNode(geometry: SCNCylinder(radius: radius, height: 45))
        tube.eulerAngles.x = .pi / 2
        tube.position.z = -22.5
        tube.geometry?.firstMaterial = material(
          radius == 0.3 ? 0xF2FFFF : 0x30CFFF, glow: true, alpha: alpha)
        beam.addChildNode(tube)
      }
      for i in 0..<8 {
        let wave = SCNNode(geometry: SCNTorus(ringRadius: 0.9, pipeRadius: 0.055))
        wave.eulerAngles.x = .pi / 2
        wave.position.z = -Float(i) * 4
        wave.geometry?.firstMaterial = material(0xA9F8FF, glow: true)
        beam.addChildNode(wave)
        wave.runAction(.moveBy(x: 0, y: 0, z: -5, duration: 0.45))
      }
      effects.addChildNode(beam)
      beam.runAction(
        .sequence([.wait(duration: 0.25), .fadeOut(duration: 0.35), .removeFromParentNode()]))
    }
    if event.type == "dodge", let pos = event.pos {
      for i in 0..<5 {
        let streak = SCNNode(
          geometry: SCNBox(width: 0.035, height: 0.03, length: 4, chamferRadius: 0))
        streak.geometry?.firstMaterial = material(0xC4F7FF, glow: true)
        streak.position = SCNVector3(pos.x + Double(i - 2) * 0.25, pos.y + Double(i) * 0.5, pos.z)
        effects.addChildNode(streak)
        streak.runAction(.sequence([.fadeOut(duration: 0.4), .removeFromParentNode()]))
      }
    }
  }
}

struct ArenaView: UIViewRepresentable {
  let renderer: ArenaRenderer
  func makeUIView(context: Context) -> SCNView {
    let view = SCNView()
    view.scene = renderer.scene
    view.pointOfView = renderer.camera
    view.backgroundColor = .black
    view.antialiasingMode = .multisampling4X
    view.preferredFramesPerSecond = 30
    view.isPlaying = true
    view.accessibilityLabel = "Nova Brawl three dimensional arena"
    return view
  }
  func updateUIView(_ uiView: SCNView, context: Context) {}
}
