import SceneKit
import SwiftUI
import UIKit

@MainActor
final class ArenaRenderer {
  let scene = SCNScene()
  let camera = SCNNode()
  private var rigs: [String: FighterRig] = [:]
  private var preview: FighterRig?
  private var previewStyle = -1
  private var eventID = 0
  private var shake: Float = 0
  private var airFraming: Float = 0
  private let red = FighterRig.material(
    UIColor(red: 1, green: 0.055, blue: 0.12, alpha: 1), glow: 1.3)
  private let steel = FighterRig.material(
    UIColor(red: 0.12, green: 0.15, blue: 0.19, alpha: 1), metallic: 0.8)

  init() {
    scene.background.contents = UIColor(red: 0.015, green: 0.021, blue: 0.04, alpha: 1)
    scene.fogColor = UIColor(red: 0.025, green: 0.035, blue: 0.06, alpha: 1)
    scene.fogStartDistance = 16
    scene.fogEndDistance = 36
    camera.camera = SCNCamera()
    camera.camera?.fieldOfView = 43
    camera.camera?.zFar = 70
    camera.camera?.wantsHDR = true
    camera.camera?.bloomIntensity = 0.65
    camera.camera?.bloomThreshold = 1
    camera.camera?.bloomBlurRadius = 7
    camera.camera?.exposureOffset = 0
    scene.rootNode.addChildNode(camera)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.color = UIColor(red: 0.53, green: 0.64, blue: 0.85, alpha: 1)
    ambient.light?.intensity = 300
    scene.rootNode.addChildNode(ambient)
    light(
      position: SCNVector3(-3, 6, 5), color: UIColor(red: 0.8, green: 0.88, blue: 1, alpha: 1),
      power: 1400)
    light(
      position: SCNVector3(3, 4, -3), color: UIColor(red: 1, green: 0.07, blue: 0.14, alpha: 1),
      power: 1300)
    buildStage()
  }

  private func light(position: SCNVector3, color: UIColor, power: CGFloat) {
    let node = SCNNode()
    node.position = position
    node.light = SCNLight()
    node.light?.type = .omni
    node.light?.color = color
    node.light?.intensity = power
    node.light?.attenuationEndDistance = 24
    scene.rootNode.addChildNode(node)
  }

  private func geometry(_ geometry: SCNGeometry, position: SCNVector3, material: SCNMaterial)
    -> SCNNode
  {
    let node = SCNNode(geometry: geometry)
    node.position = position
    geometry.firstMaterial = material
    scene.rootNode.addChildNode(node)
    return node
  }

  private func beam(
    width: CGFloat, height: CGFloat, depth: CGFloat, position: SCNVector3, material: SCNMaterial
  ) {
    _ = geometry(
      SCNBox(width: width, height: height, length: depth, chamferRadius: 0.02),
      position: position, material: material)
  }

  private func buildStage() {
    let floor = SCNCylinder(radius: 6.8, height: 0.28)
    floor.radialSegmentCount = 96
    _ = geometry(floor, position: SCNVector3(0, -0.20, 0), material: steel)
    let tile = FighterRig.material(
      UIColor(red: 0.20, green: 0.24, blue: 0.28, alpha: 1), metallic: 0.6)
    for x in -5...5 {
      for z in -4...4 {
        if x * x + z * z < 40 {
          beam(
            width: 0.96, height: 0.025, depth: 0.96,
            position: SCNVector3(Double(x), -0.045, Double(z)), material: tile)
        }
      }
    }
    for radius in [3.4, 5.9, 6.65] {
      let ring = SCNTorus(ringRadius: radius, pipeRadius: radius == 3.4 ? 0.012 : 0.04)
      _ = geometry(ring, position: SCNVector3(0, -0.01, 0), material: radius == 3.4 ? tile : red)
    }
    let stencil = SCNText(string: "IRON  /  RELAY", extrusionDepth: 0.001)
    stencil.font = UIFont.systemFont(ofSize: 0.48, weight: .black)
    let mark = geometry(
      stencil, position: SCNVector3(-1.8, 0.001, 1.65),
      material: FighterRig.material(UIColor(white: 0.43, alpha: 1)))
    mark.eulerAngles.x = -.pi / 2
    for side in [-1.0, 1.0] {
      for index in 0..<9 {
        beam(
          width: 0.10, height: 0.012, depth: 0.48,
          position: SCNVector3(side * 4.55, 0.01, Double(index - 4) * 0.28),
          material: FighterRig.material(UIColor(red: 0.6, green: 0.48, blue: 0.27, alpha: 1)))
      }
    }
    for index in 0..<12 {
      let angle = Double(index) * .pi / 6
      let x = sin(angle) * 8.3
      let z = cos(angle) * 8.3
      guard z < 2 else { continue }
      beam(width: 0.44, height: 7, depth: 0.6, position: SCNVector3(x, 3, z), material: steel)
      beam(
        width: 0.08, height: 5.3, depth: 0.64, position: SCNVector3(x + 0.24, 2.7, z), material: red
      )
      for height in [1.0, 3.0, 5.0] {
        beam(
          width: 2.8, height: 0.09, depth: 0.10,
          position: SCNVector3(x, height, z), material: red)
      }
    }
    for index in -6...6 {
      beam(
        width: 0.35, height: CGFloat(3 + (index * index) % 5), depth: 2,
        position: SCNVector3(Double(index) * 2, 2, -15), material: steel)
      for row in 0..<3 {
        beam(
          width: 0.15, height: 0.08, depth: 0.01,
          position: SCNVector3(Double(index) * 2, Double(row) + 1, -13.98), material: red)
      }
    }
    let logo = SCNText(string: "THE FOUNDRY", extrusionDepth: 0.015)
    logo.font = UIFont.monospacedSystemFont(ofSize: 0.52, weight: .bold)
    _ = geometry(logo, position: SCNVector3(-2.15, 3.5, -7), material: red)
    for index in 0..<6 {
      beam(
        width: 1.1, height: 0.16, depth: 0.6,
        position: SCNVector3(Double(index - 3) * 1.6, 0.45, -6.5), material: steel)
    }
  }

  func update(client: GameClient) {
    let time = Date.timeIntervalSinceReferenceDate
    guard let world = client.state, world.players.count == 2, world.phase != "lobby" else {
      for rig in rigs.values { rig.root.isHidden = true }
      if previewStyle != client.team[0] {
        preview?.root.removeFromParentNode()
        preview = FighterRig(style: client.team[0])
        previewStyle = client.team[0]
        if let preview { scene.rootNode.addChildNode(preview.root) }
      }
      preview?.root.isHidden = false
      preview?.root.position = SCNVector3(-1.1, 0, 0)
      preview?.pose(time: time, state: nil, preview: true)
      camera.position = SCNVector3(0.2, 2.2, 5.4)
      camera.look(at: SCNVector3(-0.2, 1.65, 0))
      return
    }
    preview?.root.isHidden = true
    for player in world.players {
      let style = player.team[player.active]
      if rigs[player.id]?.styleIndex != style {
        rigs[player.id]?.root.removeFromParentNode()
        let rig = FighterRig(style: style)
        rig.root.position = SCNVector3(player.x, player.y, player.z)
        rigs[player.id] = rig
        scene.rootNode.addChildNode(rig.root)
      }
      rigs[player.id]?.root.isHidden = false
      rigs[player.id]?.pose(time: time, state: player, phase: world.phase)
    }
    let midpoint = Float((world.players[0].x + world.players[1].x) / 2)
    let midZ = Float((world.players[0].z + world.players[1].z) / 2)
    let separation = abs(world.players[0].x - world.players[1].x)
    let airborne = world.players.contains {
      $0.y > 0 || ($0.attack == "launch" && $0.age >= 9)
    }
    airFraming += ((airborne ? 2.65 : 0) - airFraming) * 0.16
    let cameraZ = Float(max(7.8, 6.2 + separation * 0.75)) + airFraming * 1.9
    let impact = Float(sin(time * 105)) * shake
    camera.position = SCNVector3(
      midpoint + impact, 3.0 + airFraming * 0.6 + impact, cameraZ + midZ)
    camera.look(at: SCNVector3(midpoint, 1.4 + airFraming * 0.6, midZ))
    shake *= 0.85
    for event in world.events where event.id > eventID {
      if ["hit", "launch", "juggle", "block", "tag", "land", "wall"].contains(event.kind) {
        let target = world.players.first {
          $0.id == (event.target.isEmpty ? event.actor : event.target)
        }
        if let target {
          sparks(
            at: SCNVector3(target.x, target.y + (event.kind == "land" ? 0.1 : 1.8), target.z),
            blocked: event.kind == "block", tag: event.kind == "tag")
          shake = event.kind == "block" ? 0.025 : 0.07
        }
      }
    }
    eventID = world.events.last?.id ?? eventID
  }

  private func sparks(at position: SCNVector3, blocked: Bool, tag: Bool) {
    let color: UIColor = blocked ? .cyan : tag ? .systemPink : .orange
    let particle = SCNParticleSystem()
    particle.birthRate = 0
    particle.particleLifeSpan = 0.25
    particle.particleLifeSpanVariation = 0.12
    particle.particleSize = 0.06
    particle.particleSizeVariation = 0.025
    particle.particleColor = color
    particle.particleVelocity = 5
    particle.particleVelocityVariation = 3
    particle.spreadingAngle = 180
    particle.emitterShape = SCNSphere(radius: 0.12)
    particle.blendMode = .additive
    particle.isLightingEnabled = false
    let node = SCNNode()
    node.position = position
    scene.rootNode.addChildNode(node)
    particle.birthRate = 1800
    particle.emissionDuration = 0.035
    particle.loops = false
    node.addParticleSystem(particle)
    let ring = SCNNode(geometry: SCNTorus(ringRadius: 0.20, pipeRadius: 0.025))
    ring.geometry?.firstMaterial = FighterRig.material(color, glow: 2)
    ring.eulerAngles.x = .pi / 2
    node.addChildNode(ring)
    ring.runAction(.group([.scale(to: 4, duration: 0.22), .fadeOut(duration: 0.25)]))
    node.runAction(.sequence([.wait(duration: 0.6), .removeFromParentNode()]))
  }
}

struct ArenaView: UIViewRepresentable {
  @ObservedObject var client: GameClient

  func makeCoordinator() -> Coordinator { Coordinator(client: client) }
  func makeUIView(context: Context) -> SCNView {
    let view = SCNView()
    view.scene = context.coordinator.renderer.scene
    view.pointOfView = context.coordinator.renderer.camera
    view.antialiasingMode = .multisampling4X
    view.preferredFramesPerSecond = 60
    view.isPlaying = true
    view.isUserInteractionEnabled = false
    context.coordinator.start()
    return view
  }
  func updateUIView(_ uiView: SCNView, context: Context) {}
  static func dismantleUIView(_ uiView: SCNView, coordinator: Coordinator) {
    coordinator.displayLink?.invalidate()
  }

  @MainActor
  final class Coordinator: NSObject {
    let client: GameClient
    let renderer = ArenaRenderer()
    var displayLink: CADisplayLink?
    init(client: GameClient) { self.client = client }
    func start() {
      displayLink = CADisplayLink(target: self, selector: #selector(frame))
      displayLink?.add(to: .main, forMode: .common)
    }
    @objc private func frame() { renderer.update(client: client) }
  }
}
