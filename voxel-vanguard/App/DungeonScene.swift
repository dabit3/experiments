import SceneKit
import UIKit

final class DungeonScene {
  let scene = SCNScene()
  let camera = SCNNode()
  private var actors: [String: SCNNode] = [:]
  private var props: [String: SCNNode] = [:]
  private var seenEvents = Set<Int>()
  private var gates: [SCNNode] = []
  private var preview: [SCNNode] = []
  private let stone = UIColor(hex: 0x697580)
  private let grass = UIColor(hex: 0x476c3c)
  private let amber = UIColor(hex: 0xffbd57)
  private let cyan = UIColor(hex: 0x70dddb)
  private var materials: [String: SCNMaterial] = [:]

  init() {
    scene.background.contents = UIColor(hex: 0x0b1820)
    scene.fogColor = UIColor(hex: 0x122b2a)
    scene.fogStartDistance = 36
    scene.fogEndDistance = 70
    let lens = SCNCamera()
    lens.usesOrthographicProjection = true
    lens.orthographicScale = 10.8
    lens.zFar = 150
    lens.wantsHDR = true
    lens.bloomIntensity = 0.65
    lens.bloomThreshold = 1.1
    lens.bloomBlurRadius = 6
    lens.exposureOffset = 0.25
    camera.camera = lens
    scene.rootNode.addChildNode(camera)
    setCamera(x: -2, z: 0)
    let moon = SCNNode()
    moon.light = SCNLight()
    moon.light?.type = .directional
    moon.light?.color = UIColor(hex: 0xadcde1)
    moon.light?.intensity = 1100
    moon.light?.castsShadow = true
    moon.light?.shadowMode = .deferred
    moon.light?.shadowColor = UIColor.black.withAlphaComponent(0.5)
    moon.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
    moon.light?.shadowRadius = 3
    moon.eulerAngles = SCNVector3(-1.0, -0.5, 0.1)
    scene.rootNode.addChildNode(moon)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.intensity = 430
    ambient.light?.color = UIColor(hex: 0x718daa)
    scene.rootNode.addChildNode(ambient)
    makeTerrain()
    for slot in 0...1 {
      let hero = makeActor(kind: "hero", slot: slot)
      hero.position = SCNVector3(-5 + slot * 2, 0, 0)
      hero.eulerAngles.y = 0.4
      scene.rootNode.addChildNode(hero)
      preview.append(hero)
    }
  }

  private func material(_ color: UIColor, pixel: Bool = false, glow: Bool = false) -> SCNMaterial {
    let key = "\(color.description)-\(pixel)-\(glow)"
    if let cached = materials[key] { return cached }
    let m = SCNMaterial()
    m.diffuse.contents = pixel ? texture(color) : color
    m.diffuse.magnificationFilter = .nearest
    m.roughness.contents = 0.92
    if glow { m.emission.contents = color }
    materials[key] = m
    return m
  }

  private func texture(_ color: UIColor) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = false
    format.preferredRange = .standard
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32), format: format)
    return renderer.image { context in
      let drawing = context.cgContext
      drawing.setFillColor(color.cgColor)
      drawing.fill(CGRect(x: 0, y: 0, width: 32, height: 32))
      for i in 0..<72 {
        let x = (i * 13 + i / 3 * 7) % 32
        let y = (i * 19 + 3) % 32
        drawing.setFillColor(
          (i % 3 == 0 ? UIColor.white : UIColor.black)
            .withAlphaComponent(i % 3 == 0 ? 0.09 : 0.12).cgColor)
        drawing.fill(CGRect(x: x, y: y, width: 2 + i % 4, height: 2 + i % 3))
      }
    }
  }

  @discardableResult
  private func box(
    _ parent: SCNNode, _ size: (Double, Double, Double),
    _ position: (Double, Double, Double), _ color: UIColor,
    pixel: Bool = true, glow: Bool = false, name: String? = nil
  ) -> SCNNode {
    let geometry = SCNBox(width: size.0, height: size.1, length: size.2, chamferRadius: 0)
    geometry.materials = [material(color, pixel: pixel, glow: glow)]
    let node = SCNNode(geometry: geometry)
    node.position = SCNVector3(position.0, position.1, position.2)
    node.name = name
    parent.addChildNode(node)
    return node
  }

  private func makeTerrain() {
    let terrain = SCNNode()
    for (center, _, width, depth) in DungeonMap.areas {
      let bridge = width == 6
      for ix in 0..<Int(width) {
        for iz in 0..<Int(depth) {
          let x = center - width / 2 + Double(ix) + 0.5
          let z = -depth / 2 + Double(iz) + 0.5
          let road = abs(z) < 2.4 || center == 48 && abs(x - center) < 4
          let seed = (ix * 13 + iz * 7) % 7
          let c =
            bridge
            ? UIColor(hex: seed % 2 == 0 ? 0x704b2f : 0x896039)
            : road
              ? (seed < 2 ? UIColor(hex: 0x8b8c78) : stone)
              : seed < 2 ? UIColor(hex: 0x5c7843) : grass
          box(terrain, (0.99, bridge ? 0.3 : 1.1, 0.99), (x, bridge ? -0.16 : -0.56, z), c)
          if !bridge && !road && seed == 2 {
            box(terrain, (0.09, 0.35, 0.09), (x - 0.2, 0.15, z), UIColor(hex: 0x78a459))
            box(terrain, (0.09, 0.22, 0.09), (x + 0.1, 0.1, z + 0.2), UIColor(hex: 0x9fb35c))
          }
          if bridge && iz == 0 || bridge && iz == Int(depth) - 1 {
            if ix % 2 == 0 {
              box(terrain, (0.2, 1.0, 0.2), (x, 0.4, z), UIColor(hex: 0x4e3527))
            }
            box(terrain, (1, 0.12, 0.13), (x, 0.78, z), UIColor(hex: 0x9b8050))
          }
        }
      }
      if !bridge {
        for i in 0..<Int(width) {
          let x = center - width / 2 + Double(i) + 0.5
          for side in [-1.0, 1.0] {
            let z = side * (depth / 2 + 0.5)
            let height = 1.3 + Double((i * 7) % 3) * 0.4
            box(terrain, (1, height, 1.4), (x, height / 2 - 0.8, z), UIColor(hex: 0x3e4e54))
            box(terrain, (1.05, 0.25, 1.45), (x, height - 0.75, z), grass)
          }
        }
      }
    }
    for (x, z) in DungeonMap.columns {
      box(terrain, (2.3, 0.35, 2.3), (x, 0.15, z), UIColor(hex: 0x495960))
      for level in 0..<5 {
        box(
          terrain, (1.6, 0.52, 1.6), (x, 0.55 + Double(level) * 0.54, z),
          level % 2 == 0 ? stone : UIColor(hex: 0x566469))
      }
      box(terrain, (2.0, 0.25, 2.0), (x, 3.1, z), grass)
      box(terrain, (0.18, 0.8, 0.05), (x, 1.8, z + 0.82), cyan, glow: true)
    }
    for center in [0.0, 24.0, 48.0] {
      for (dx, z) in [(-7.0, -6.0), (6, -6), (-7, 6), (7, 6)] {
        tree(terrain, x: center + dx, z: z)
      }
      for z in [-4.8, 4.8] { torch(x: center - 4.5, z: z) }
      arch(terrain, x: center + 8.0)
    }
    for x in [8.2, 32.2] {
      let gate = SCNNode()
      for z in stride(from: -1.8, through: 1.8, by: 0.6) {
        box(gate, (0.18, 2.3, 0.16), (x, 1.1, z), UIColor(hex: 0x91c5c6), glow: true)
      }
      scene.rootNode.addChildNode(gate)
      gates.append(gate)
    }
    for x in stride(from: -5.0, through: 53.0, by: 3) {
      let rune = box(terrain, (0.32, 0.035, 0.32), (x, 0.035, 0), amber, glow: true)
      rune.eulerAngles.y = .pi / 4
    }
    let floor = terrain.flattenedClone()
    scene.rootNode.addChildNode(floor)
    let water = box(
      scene.rootNode, (90, 0.1, 45), (23, -2.8, 0), UIColor(hex: 0x173e45), pixel: false)
    water.geometry?.firstMaterial?.metalness.contents = 0.5
    water.geometry?.firstMaterial?.roughness.contents = 0.15
    for i in 0..<45 {
      let mote = box(
        scene.rootNode, (0.045, 0.045, 0.045),
        (Double((i * 17) % 62) - 8, 0.6 + Double(i % 7) * 0.4, Double((i * 11) % 17) - 8),
        UIColor(hex: 0xc3e584), glow: true)
      mote.runAction(
        .repeatForever(
          .sequence([
            .moveBy(x: 0.3, y: 0.8, z: 0.2, duration: 2 + Double(i % 3)),
            .moveBy(x: -0.3, y: -0.8, z: -0.2, duration: 2 + Double(i % 3)),
          ])))
    }
  }

  private func tree(_ parent: SCNNode, x: Double, z: Double) {
    box(parent, (0.7, 3.8, 0.7), (x, 1.7, z), UIColor(hex: 0x493a2a))
    for level in 0..<3 {
      let size = 3.0 - Double(level) * 0.6
      box(
        parent, (size, 1.1, size), (x, 3 + Double(level) * 0.8, z),
        UIColor(hex: level == 0 ? 0x284c32 : level == 1 ? 0x35613c : 0x456e40))
    }
    box(parent, (0.2, 1.4, 0.24), (x + 0.3, 0.3, z + 0.3), UIColor(hex: 0x729757))
  }

  private func arch(_ parent: SCNNode, x: Double) {
    for z in [-2.8, 2.8] {
      for level in 0..<6 {
        box(
          parent, (0.9, 0.65, 1.0), (x, Double(level) * 0.66 + 0.32, z),
          level % 2 == 0 ? stone : UIColor(hex: 0x4d5c68))
      }
    }
    for z in stride(from: -2.8, through: 2.8, by: 0.7) {
      box(parent, (0.95, 0.7, 0.69), (x, 4, z), stone)
    }
    box(parent, (1, 0.3, 1), (x, 4.5, 0), amber, glow: true)
  }

  private func torch(x: Double, z: Double) {
    let node = SCNNode()
    box(node, (0.45, 1.5, 0.45), (0, 0.7, 0), UIColor(hex: 0x423931))
    box(node, (0.65, 0.2, 0.65), (0, 1.5, 0), UIColor(hex: 0x202c31))
    let flame = box(node, (0.3, 0.65, 0.3), (0, 1.8, 0), amber, glow: true)
    flame.runAction(
      .repeatForever(.sequence([.scale(to: 0.8, duration: 0.15), .scale(to: 1.2, duration: 0.19)])))
    let light = SCNLight()
    light.type = .omni
    light.color = amber
    light.intensity = 470
    light.attenuationStartDistance = 0
    light.attenuationEndDistance = 7
    let lamp = SCNNode()
    lamp.light = light
    lamp.position.y = 2.2
    node.addChildNode(lamp)
    node.position = SCNVector3(x, 0, z)
    scene.rootNode.addChildNode(node)
  }

  private func makeActor(kind: String, slot: Int = 0) -> SCNNode {
    let root = SCNNode()
    let rig = SCNNode()
    rig.name = "rig"
    root.addChildNode(rig)
    let hero = kind == "hero"
    let boss = kind == "boss"
    let cloth =
      hero
      ? UIColor(hex: slot == 0 ? 0x2678a2 : 0xb75236)
      : UIColor(hex: kind == "archer" ? 0x65577e : boss ? 0x364d50 : 0x426344)
    let skin =
      hero
      ? UIColor(hex: slot == 0 ? 0xd7a878 : 0xb87c5e)
      : UIColor(hex: kind == "archer" ? 0xb9b59b : boss ? 0x626f64 : 0x779357)
    let metal = UIColor(hex: hero ? 0x8ba6b5 : 0x676f71)
    box(rig, (0.72, 0.85, 0.46), (0, 1.05, 0), cloth)
    box(rig, (0.76, 0.14, 0.5), (0, 0.71, 0), UIColor(hex: 0x443528))
    box(rig, (0.15, 0.13, 0.06), (0, 0.71, 0.27), amber)
    box(rig, (0.64, 0.62, 0.6), (0, 1.78, 0), skin)
    if hero {
      box(rig, (0.7, 0.21, 0.66), (0, 2.01, 0), UIColor(hex: slot == 0 ? 0x56412f : 0x332b2e))
      box(rig, (0.7, 0.1, 0.65), (0, 1.89, 0), metal)
      box(rig, (0.56, 0.22, 0.12), (0, 1.43, -0.29), metal)
      box(rig, (0.62, 1.1, 0.09), (0, 0.99, -0.29), UIColor(hex: slot == 0 ? 0x163d64 : 0x7d2832))
      box(rig, (0.5, 0.5, 0.07), (0, 1.11, 0.26), metal)
      box(rig, (0.18, 0.22, 0.06), (0, 1.14, 0.31), slot == 0 ? cyan : amber, glow: true)
    } else if kind == "brute" || boss {
      box(rig, (0.79, 0.33, 0.74), (0, 2, 0), metal)
      box(rig, (0.25, 0.4, 0.2), (-0.45, 2.17, 0), amber)
      box(rig, (0.25, 0.4, 0.2), (0.45, 2.17, 0), amber)
      box(rig, (0.65, 0.7, 0.12), (0, 1.05, 0.29), metal)
      box(rig, (0.19, 0.4, 0.13), (0, 1.07, 0.37), boss ? cyan : amber, glow: true)
    }
    for side in [-1.0, 1.0] {
      box(rig, (0.12, 0.09, 0.03), (side * 0.16, 1.8, 0.315), hero ? .white : amber, glow: !hero)
      box(rig, (0.055, 0.08, 0.04), (side * 0.14, 1.8, 0.337), UIColor(hex: 0x172529), pixel: false)
      let arm = SCNNode()
      arm.name = side < 0 ? "leftArm" : "rightArm"
      arm.position = SCNVector3(side * 0.52, 1.35, 0)
      box(arm, (0.29, 0.55, 0.36), (0, -0.22, 0), cloth)
      box(arm, (0.29, 0.25, 0.34), (0, -0.6, 0), skin)
      box(arm, (0.38, 0.25, 0.43), (0, 0.02, 0), metal)
      rig.addChildNode(arm)
      let leg = SCNNode()
      leg.name = side < 0 ? "leftLeg" : "rightLeg"
      leg.position = SCNVector3(side * 0.2, 0.68, 0)
      box(leg, (0.3, 0.43, 0.34), (0, -0.2, 0), UIColor(hex: 0x283646))
      box(leg, (0.34, 0.22, 0.45), (0, -0.55, 0.045), UIColor(hex: 0x40372f))
      rig.addChildNode(leg)
      if side > 0 && kind != "archer" {
        box(arm, (0.13, 0.13, 0.5), (0, -0.55, 0.36), UIColor(hex: 0x533c29))
        box(arm, (0.48, 0.12, 0.14), (0, -0.55, 0.6), amber)
        box(arm, (0.21, 0.09, boss ? 1.1 : 0.83), (0, -0.55, 1.02), metal)
        box(arm, (0.1, 0.09, 0.18), (0, -0.55, 1.5), cyan, glow: boss)
      }
      if side < 0 && (hero || kind == "archer") {
        for i in -2...2 {
          box(
            arm, (0.08, 0.23, 0.1), (0, Double(i) * 0.2 - 0.3, 0.2 + Double(abs(i)) * -0.055),
            UIColor(hex: 0xa67643))
        }
        box(arm, (0.025, 0.8, 0.025), (0, -0.3, 0.05), .white, pixel: false)
      }
    }
    if boss { rig.scale = SCNVector3(2.1, 2.1, 2.1) }
    if kind == "brute" { rig.scale = SCNVector3(1.2, 1.2, 1.2) }
    let ring = SCNTorus(ringRadius: boss ? 1.6 : 0.67, pipeRadius: 0.025)
    ring.materials = [
      material(hero ? (slot == 0 ? cyan : amber) : UIColor(hex: 0xba554b), glow: true)
    ]
    let ringNode = SCNNode(geometry: ring)
    ringNode.position.y = 0.06
    root.addChildNode(ringNode)
    let health = SCNNode()
    health.name = "health"
    health.position.y = boss ? 5.2 : 2.55
    health.constraints = [SCNBillboardConstraint()]
    box(health, (1, 0.08, 0.015), (0, 0, 0), UIColor(hex: 0x25333c), pixel: false)
    box(
      health, (0.94, 0.045, 0.02), (0, 0, 0.015), hero ? cyan : UIColor(hex: 0xf07660),
      pixel: false, name: "fill")
    root.addChildNode(health)
    return root
  }

  func setCamera(x: Double, z: Double) {
    let target = SCNVector3(x + 1.2, 0.7, z)
    camera.position = SCNVector3(x + 13.2, 18.7, z + 16)
    camera.look(at: target)
  }

  func apply(_ state: Snapshot, identity: String) {
    for node in preview { node.removeFromParentNode() }
    preview.removeAll()
    let allIDs = Set(state.players.map(\.id) + state.enemies.map(\.id))
    for id in Array(actors.keys) where !allIDs.contains(id) {
      actors.removeValue(forKey: id)?.removeFromParentNode()
    }
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.08
    if let hero = state.players.first(where: { $0.id == identity }) {
      setCamera(x: hero.x, z: hero.z * 0.75)
    }
    for (index, gate) in gates.enumerated() {
      gate.opacity = state.completedStages > index ? 0 : 0.72
    }
    for p in state.players {
      let node = actor(id: p.id, kind: "hero", slot: p.slot)
      pose(
        node, x: p.x, z: p.z, angle: p.angle, action: p.action, tick: state.tick,
        hp: Double(p.hp) / Double(p.maxHP), down: p.down)
      node.opacity = p.connected ? 1 : 0.4
    }
    for e in state.enemies {
      let node = actor(id: e.id, kind: e.kind)
      pose(
        node, x: e.x, z: e.z, angle: e.angle, action: e.action, tick: state.tick,
        hp: Double(e.hp) / Double(e.maxHP), down: false)
    }
    SCNTransaction.commit()
    let propIDs = Set(state.loot.map(\.id) + state.projectiles.map(\.id))
    for id in Array(props.keys) where !propIDs.contains(id) {
      props.removeValue(forKey: id)?.removeFromParentNode()
    }
    for item in state.loot {
      if props[item.id] == nil {
        let node = SCNNode()
        if item.kind == "gem" {
          let gem = box(node, (0.3, 0.5, 0.3), (0, 0.4, 0), UIColor(hex: 0x75ed91), glow: true)
          gem.eulerAngles.z = .pi / 5
          node.runAction(.repeatForever(.rotateBy(x: 0, y: 3, z: 0, duration: 1.8)))
          node.runAction(
            .repeatForever(
              .sequence([
                .moveBy(x: 0, y: 0.2, z: 0, duration: 0.6),
                .moveBy(x: 0, y: -0.2, z: 0, duration: 0.6),
              ])))
        } else {
          box(node, (1.2, 0.65, 0.75), (0, 0.3, 0), UIColor(hex: 0x9b6233))
          box(node, (1.25, 0.2, 0.8), (0, 0.74, 0), UIColor(hex: 0xc88c40))
          for x in [-0.4, 0.4] { box(node, (0.1, 0.85, 0.84), (x, 0.4, 0), amber) }
          box(node, (0.2, 0.22, 0.08), (0, 0.6, 0.43), cyan, glow: true)
          let beam = box(node, (0.1, 3, 0.1), (0, 2, 0), amber, glow: true)
          beam.opacity = 0.35
        }
        node.position = SCNVector3(item.x, 0, item.z)
        scene.rootNode.addChildNode(node)
        props[item.id] = node
      }
      if item.kind == "chest" {
        props[item.id]?.opacity = (item.claimed ?? []).contains(identity) ? 0.45 : 1
      }
    }
    for arrow in state.projectiles {
      let node: SCNNode
      if let prior = props[arrow.id] {
        node = prior
      } else {
        node = SCNNode()
        box(node, (0.07, 0.07, 0.9), (0, 0, 0), amber, glow: true)
        box(node, (0.18, 0.08, 0.2), (0, 0, 0.5), .white, glow: true)
        props[arrow.id] = node
        scene.rootNode.addChildNode(node)
      }
      node.position = SCNVector3(arrow.x, 1, arrow.z)
      node.eulerAngles.y = Float(atan2(arrow.vx, arrow.vz))
    }
    for event in state.events where !seenEvents.contains(event.id) {
      seenEvents.insert(event.id)
      effect(event)
    }
  }

  private func actor(id: String, kind: String, slot: Int = 0) -> SCNNode {
    if let node = actors[id] { return node }
    let node = makeActor(kind: kind, slot: slot)
    actors[id] = node
    scene.rootNode.addChildNode(node)
    return node
  }

  private func pose(
    _ node: SCNNode, x: Double, z: Double, angle: Double, action: String,
    tick: Int, hp: Double, down: Bool
  ) {
    node.position = SCNVector3(x, 0, z)
    let rig = node.childNode(withName: "rig", recursively: false)
    rig?.eulerAngles.y = Float(angle)
    rig?.eulerAngles.z = down ? .pi / 2 : 0
    let walking = action == "walk" || action == "dodge"
    let stride = walking ? Float(sin(Double(tick) * 0.8)) * 0.65 : 0
    rig?.position.y = walking ? abs(stride) * 0.12 : 0
    rig?.eulerAngles.x = action == "dodge" ? Float(tick % 8) * .pi / 4 : 0
    rig?.childNode(withName: "leftLeg", recursively: false)?.eulerAngles.x = stride
    rig?.childNode(withName: "rightLeg", recursively: false)?.eulerAngles.x = -stride
    rig?.childNode(withName: "leftArm", recursively: false)?.eulerAngles.x =
      action == "ranged" ? -1.5 : -stride * 0.6
    rig?.childNode(withName: "rightArm", recursively: false)?.eulerAngles.x =
      action == "melee" ? -1.1 + Float(tick % 6) * 0.4 : stride * 0.6
    rig?.childNode(withName: "rightArm", recursively: false)?.eulerAngles.z =
      action == "melee" ? -0.8 : 0
    node.childNode(withName: "fill", recursively: true)?.scale.x = Float(max(0.01, hp))
  }

  private func effect(_ event: WorldEvent) {
    let origin = SCNVector3(event.x, 0.15, event.z)
    let green = ["heal", "gem", "equip"].contains(event.kind)
    let color =
      green
      ? UIColor(hex: 0x81f0a2)
      : ["hurt", "warning", "slam"].contains(event.kind)
        ? UIColor(hex: 0xff674f) : event.kind == "artifact" ? UIColor(hex: 0xc784ff) : amber
    if ["slash", "claw", "dodge", "heal", "artifact", "slam", "warning", "clear"].contains(
      event.kind)
    {
      let radius =
        event.kind == "warning" || event.kind == "slam" ? 5.0 : event.kind == "artifact" ? 7.5 : 1.3
      let geometry = SCNTorus(ringRadius: radius, pipeRadius: event.kind == "warning" ? 0.04 : 0.07)
      geometry.materials = [material(color, glow: true)]
      let ring = SCNNode(geometry: geometry)
      ring.position = origin
      if event.kind == "slash" {
        ring.position.y = 1
        ring.eulerAngles.z = 0.3
      }
      scene.rootNode.addChildNode(ring)
      ring.runAction(
        .sequence([
          .group([
            .scale(to: 1.25, duration: 0.4),
            .fadeOut(duration: event.kind == "warning" ? 1.4 : 0.5),
          ]), .removeFromParentNode(),
        ]))
    }
    if ["hit", "burst", "artifact", "heal", "slam", "equip"].contains(event.kind) {
      for i in 0..<8 {
        let spark = box(scene.rootNode, (0.1, 0.1, 0.1), (event.x, 1, event.z), color, glow: true)
        let angle = Double(i) * .pi / 4
        spark.runAction(
          .sequence([
            .group([
              .moveBy(
                x: sin(angle) * 1.1, y: 0.8,
                z: cos(angle) * 1.1, duration: 0.4), .fadeOut(duration: 0.5),
            ]), .removeFromParentNode(),
          ]))
      }
    }
    if !event.text.isEmpty && ["hit", "heal", "equip", "clear", "artifact"].contains(event.kind) {
      let text = SCNText(string: event.text, extrusionDepth: 0)
      text.font = .monospacedSystemFont(ofSize: 0.34, weight: .heavy)
      text.flatness = 0.4
      text.materials = [material(color, pixel: false, glow: true)]
      let label = SCNNode(geometry: text)
      label.position = SCNVector3(event.x - 0.3, 2.7, event.z)
      label.constraints = [SCNBillboardConstraint()]
      scene.rootNode.addChildNode(label)
      label.runAction(
        .sequence([
          .group([
            .moveBy(x: 0, y: 1.1, z: 0, duration: 0.8),
            .fadeOut(duration: 0.85),
          ]), .removeFromParentNode(),
        ]))
    }
  }
}

extension UIColor {
  convenience init(hex: UInt32) {
    self.init(
      red: CGFloat((hex >> 16) & 255) / 255,
      green: CGFloat((hex >> 8) & 255) / 255,
      blue: CGFloat(hex & 255) / 255, alpha: 1)
  }
}
