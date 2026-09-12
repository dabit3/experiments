import SceneKit
import UIKit

enum Palette {
  static let green = UIColor(red: 0.09, green: 0.28, blue: 0.22, alpha: 1)
  static let butter = UIColor(red: 1, green: 0.88, blue: 0.52, alpha: 1)
  static let cream = UIColor(red: 1, green: 0.97, blue: 0.85, alpha: 1)
  static let pink = UIColor(red: 0.92, green: 0.28, blue: 0.36, alpha: 1)
  static let blue = UIColor(red: 0.32, green: 0.64, blue: 0.77, alpha: 1)
}

final class PicnicWorld {
  let scene = SCNScene()
  let camera = SCNNode()
  let karts: [SCNNode]
  var itemNodes: [SCNNode] = []
  var boostNodes: [SCNNode] = []
  private let circuit = Circuit()
  private var cameraReady = false

  init() {
    karts = [Palette.butter, Palette.pink, Palette.blue, UIColor.white].enumerated().map {
      Self.kart(color: $0.element, animal: $0.offset)
    }
    scene.background.contents = UIColor(red: 0.76, green: 0.88, blue: 0.81, alpha: 1)
    scene.fogColor = UIColor(red: 0.76, green: 0.88, blue: 0.81, alpha: 1)
    scene.fogStartDistance = 150
    scene.fogEndDistance = 240
    camera.camera = SCNCamera()
    camera.camera?.fieldOfView = 57
    camera.camera?.zFar = 350
    camera.camera?.wantsHDR = true
    camera.camera?.exposureOffset = 0.1
    scene.rootNode.addChildNode(camera)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.intensity = 650
    ambient.light?.color = Palette.cream
    scene.rootNode.addChildNode(ambient)
    let sun = SCNNode()
    sun.light = SCNLight()
    sun.light?.type = .directional
    sun.light?.intensity = 1450
    sun.light?.color = UIColor(red: 1, green: 0.94, blue: 0.81, alpha: 1)
    sun.light?.castsShadow = true
    sun.light?.shadowMode = .deferred
    sun.light?.shadowColor = UIColor(red: 0.12, green: 0.25, blue: 0.16, alpha: 0.27)
    sun.light?.shadowRadius = 5
    sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
    sun.light?.orthographicScale = 150
    sun.eulerAngles = SCNVector3(-1.0, -0.6, 0)
    scene.rootNode.addChildNode(sun)
    buildGround()
    buildTrack()
    buildScenery()
    for kart in karts { scene.rootNode.addChildNode(kart) }
    for index in 0..<3 {
      let distance = Double(index) * circuit.length / 3 + 38
      let group = SCNNode()
      for lane in [-3.5, 0, 3.5] {
        let item = Self.lemonade()
        let position = circuit.at(distance, offset: lane).point
        item.position = SCNVector3(position.x, 1.3, position.z)
        item.scale = SCNVector3(0.5, 0.5, 0.5)
        group.addChildNode(item)
      }
      scene.rootNode.addChildNode(group)
      itemNodes.append(group)
    }
    for _ in 0..<2 {
      let glow = Self.node(SCNCone(topRadius: 0.08, bottomRadius: 0.3, height: 1.8), Palette.butter)
      glow.eulerAngles.x = -.pi / 2
      glow.isHidden = true
      karts[0].addChildNode(glow)
      boostNodes.append(glow)
    }
    boostNodes[0].position = SCNVector3(-0.35, 0.3, -1.3)
    boostNodes[1].position = SCNVector3(0.35, 0.3, -1.3)
  }

  static func node(_ geometry: SCNGeometry, _ color: UIColor, roughness: CGFloat = 0.65) -> SCNNode
  {
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.lightingModel = .physicallyBased
    material.roughness.contents = roughness
    geometry.materials = [material]
    return SCNNode(geometry: geometry)
  }

  static func box(
    _ width: CGFloat, _ height: CGFloat, _ depth: CGFloat, _ color: UIColor, radius: CGFloat = 0.08
  ) -> SCNNode {
    node(SCNBox(width: width, height: height, length: depth, chamferRadius: radius), color)
  }

  private func buildGround() {
    let lawn = Self.box(
      500, 1, 500, UIColor(red: 0.47, green: 0.64, blue: 0.36, alpha: 1), radius: 0)
    lawn.position.y = -0.8
    scene.rootNode.addChildNode(lawn)
    let blanket = Self.box(148, 0.24, 116, Palette.cream, radius: 2)
    blanket.position.y = -0.22
    scene.rootNode.addChildNode(blanket)
    for x in -18...18 {
      let stripe = Self.box(
        2, 0.015, 116, UIColor(red: 0.86, green: 0.44, blue: 0.38, alpha: 0.25), radius: 0)
      stripe.position = SCNVector3(Double(x) * 4, -0.083, 0)
      scene.rootNode.addChildNode(stripe)
    }
    for z in -14...14 {
      let stripe = Self.box(
        148, 0.015, 2, UIColor(red: 0.86, green: 0.44, blue: 0.38, alpha: 0.22), radius: 0)
      stripe.position = SCNVector3(0, -0.065, Double(z) * 4)
      scene.rootNode.addChildNode(stripe)
    }
  }

  private func ribbon(inner: Double, outer: Double, height: Double, color: UIColor) {
    var vertices: [SCNVector3] = []
    var indices: [Int32] = []
    for i in 0...300 {
      let distance = Double(i) / 300 * circuit.length
      let a = circuit.at(distance, offset: inner).point
      let b = circuit.at(distance, offset: outer).point
      vertices.append(SCNVector3(a.x, height, a.z))
      vertices.append(SCNVector3(b.x, height, b.z))
      if i < 300 {
        let j = Int32(i * 2)
        indices += [j, j + 2, j + 1, j + 1, j + 2, j + 3]
      }
    }
    let geometry = SCNGeometry(
      sources: [SCNGeometrySource(vertices: vertices)],
      elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
    let road = Self.node(geometry, color)
    road.geometry?.firstMaterial?.isDoubleSided = true
    scene.rootNode.addChildNode(road)
  }

  private func buildTrack() {
    ribbon(inner: -7.2, outer: 7.2, height: 0.00, color: Palette.green)
    ribbon(
      inner: -6.5, outer: 6.5, height: 0.04,
      color: UIColor(red: 0.66, green: 0.69, blue: 0.53, alpha: 1))
    ribbon(inner: -6.0, outer: -5.85, height: 0.055, color: Palette.cream)
    ribbon(inner: 5.85, outer: 6.0, height: 0.055, color: Palette.cream)
    for i in 0..<120 {
      let distance = Double(i) / 120 * circuit.length
      for side in [-1.0, 1.0] {
        let pose = circuit.at(distance, offset: side * 6.7)
        let curb = Self.box(
          0.65, 0.16, 1.6, i % 2 == 0 ? Palette.cream : Palette.pink, radius: 0.03)
        curb.position = SCNVector3(pose.point.x, 0.11, pose.point.z)
        curb.eulerAngles.y = Float(pose.heading)
        scene.rootNode.addChildNode(curb)
      }
      if i % 3 == 0 {
        let pose = circuit.at(distance)
        let dash = Self.box(0.11, 0.015, 1.5, Palette.cream, radius: 0)
        dash.position = SCNVector3(pose.point.x, 0.065, pose.point.z)
        dash.eulerAngles.y = Float(pose.heading)
        scene.rootNode.addChildNode(dash)
      }
    }
    let startPose = circuit.at(0)
    let start = SCNNode()
    start.position = SCNVector3(startPose.point.x, 0, startPose.point.z)
    start.eulerAngles.y = Float(startPose.heading)
    for x in -6...6 {
      for z in 0...2 {
        let tile = Self.box(1, 0.02, 1, (x + z) % 2 == 0 ? Palette.cream : Palette.green, radius: 0)
        tile.position = SCNVector3(Double(x), 0.08, Double(z - 1))
        start.addChildNode(tile)
      }
    }
    for x in [-7.7, 7.7] {
      let pillar = Self.box(0.5, 7, 0.5, Palette.green)
      pillar.position = SCNVector3(x, 3.5, 0)
      start.addChildNode(pillar)
    }
    let banner = Self.box(16, 2, 0.4, Palette.butter, radius: 0.25)
    banner.position.y = 7
    start.addChildNode(banner)
    let text = SCNText(string: "DRIFT  PICNIC", extrusionDepth: 0.02)
    text.font = UIFont.systemFont(ofSize: 1, weight: .black)
    text.flatness = 0.1
    let label = Self.node(text, Palette.green)
    let bounds = text.boundingBox
    let width = bounds.max.x - bounds.min.x
    label.position = SCNVector3(-width / 2, 6.5, 0.25)
    start.addChildNode(label)
    scene.rootNode.addChildNode(start)
  }

  private func buildScenery() {
    let cake = Self.node(
      SCNCylinder(radius: 12, height: 4), UIColor(red: 0.94, green: 0.72, blue: 0.44, alpha: 1))
    cake.position = SCNVector3(1, 2, 1)
    scene.rootNode.addChildNode(cake)
    let icing = Self.node(SCNCylinder(radius: 12.1, height: 0.8), Palette.cream)
    icing.position = SCNVector3(1, 4.2, 1)
    scene.rootNode.addChildNode(icing)
    for i in 0..<9 {
      let t = Double(i) / 9 * .pi * 2
      let berry = Self.strawberry()
      berry.position = SCNVector3(1 + cos(t) * 9, 4.6, 1 + sin(t) * 9)
      berry.scale = SCNVector3(1.6, 1.6, 1.6)
      scene.rootNode.addChildNode(berry)
    }
    for i in 0..<22 {
      let pose = circuit.at(Double(i) / 22 * circuit.length, offset: i % 2 == 0 ? 10.5 : -11)
      let berry = Self.strawberry()
      berry.scale = SCNVector3(1.6, 1.6, 1.6)
      berry.position = SCNVector3(pose.point.x, 0.05, pose.point.z)
      berry.eulerAngles.y = Float(i) * 1.5
      scene.rootNode.addChildNode(berry)
    }
    for (x, z) in [(27.0, 6.0), (-30, 0), (30, 54), (-48, -53)] {
      let lemonade = Self.lemonade()
      lemonade.scale = SCNVector3(4, 4, 4)
      lemonade.position = SCNVector3(x, 0, z)
      scene.rootNode.addChildNode(lemonade)
    }
    for i in 0..<28 {
      let t = Double(i) / 28 * .pi * 2
      let tree = Self.node(
        SCNCapsule(capRadius: 3.5, height: 14),
        UIColor(red: 0.30, green: 0.48, blue: 0.28, alpha: 1))
      tree.position = SCNVector3(cos(t) * 110, 4, sin(t) * 92)
      scene.rootNode.addChildNode(tree)
    }
    for i in 0..<45 {
      let angle = Double(i) * 2.399
      let radius = 15.0 + Double(i % 7) * 1.8
      let flower = Self.node(SCNSphere(radius: 0.3), i % 2 == 0 ? Palette.butter : Palette.cream)
      flower.position = SCNVector3(cos(angle) * radius, 0.3, sin(angle) * radius * 0.6)
      scene.rootNode.addChildNode(flower)
    }
  }

  static func strawberry() -> SCNNode {
    let group = SCNNode()
    let fruit = node(SCNSphere(radius: 0.85), Palette.pink, roughness: 0.38)
    fruit.scale = SCNVector3(0.9, 1.2, 0.9)
    fruit.position.y = 0.95
    group.addChildNode(fruit)
    for i in 0..<5 {
      let leaf = node(SCNCapsule(capRadius: 0.16, height: 0.9), Palette.green)
      leaf.position = SCNVector3(0, 1.85, 0)
      leaf.eulerAngles = SCNVector3(0.9, Double(i) * .pi * 2 / 5, 0.5)
      group.addChildNode(leaf)
    }
    for i in 0..<14 {
      let t = Double(i) * 2.399
      let y = 0.5 + Double(i % 4) * 0.26
      let seed = node(SCNSphere(radius: 0.065), Palette.butter)
      seed.scale.y = 1.6
      seed.position = SCNVector3(cos(t) * 0.73, y, sin(t) * 0.73)
      group.addChildNode(seed)
    }
    return group
  }

  static func lemonade() -> SCNNode {
    let group = SCNNode()
    let drink = node(SCNCylinder(radius: 0.7, height: 1.8), Palette.butter, roughness: 0.18)
    drink.position.y = 1
    group.addChildNode(drink)
    for y in [0.13, 1.9] {
      let rim = node(SCNTorus(ringRadius: 0.69, pipeRadius: 0.055), Palette.cream, roughness: 0.15)
      rim.position.y = Float(y)
      group.addChildNode(rim)
    }
    let straw = box(0.12, 2.3, 0.12, Palette.pink, radius: 0.02)
    straw.position = SCNVector3(0.26, 1.65, 0)
    straw.eulerAngles.z = -0.15
    group.addChildNode(straw)
    let slice = node(SCNCylinder(radius: 0.46, height: 0.13), UIColor.systemYellow)
    slice.eulerAngles.x = .pi / 2
    slice.position = SCNVector3(-0.42, 1.95, 0)
    group.addChildNode(slice)
    return group
  }

  static func kart(color: UIColor, animal: Int) -> SCNNode {
    let group = SCNNode()
    let chassis = box(1.25, 0.42, 2.0, color, radius: 0.22)
    chassis.position.y = 0.5
    group.addChildNode(chassis)
    let hood = box(1.1, 0.27, 0.85, color, radius: 0.13)
    hood.position = SCNVector3(0, 0.8, 0.57)
    group.addChildNode(hood)
    let stripe = box(0.2, 0.025, 0.85, Palette.cream, radius: 0.005)
    stripe.position = SCNVector3(0, 0.948, 0.57)
    group.addChildNode(stripe)
    let bumper = box(1.35, 0.15, 0.18, Palette.cream)
    bumper.position = SCNVector3(0, 0.4, 1.05)
    group.addChildNode(bumper)
    for x in [-0.7, 0.7] {
      for z in [-0.65, 0.65] {
        let tire = node(SCNCylinder(radius: 0.32, height: 0.28), UIColor(white: 0.14, alpha: 1))
        tire.eulerAngles.z = .pi / 2
        tire.position = SCNVector3(x, 0.33, z)
        group.addChildNode(tire)
        let hub = node(SCNCylinder(radius: 0.15, height: 0.30), Palette.cream, roughness: 0.28)
        hub.eulerAngles.z = .pi / 2
        hub.position = SCNVector3(x, 0.33, z)
        group.addChildNode(hub)
      }
    }
    let fur =
      animal == 0
      ? Palette.cream
      : (animal == 1
        ? UIColor(red: 0.73, green: 0.44, blue: 0.28, alpha: 1) : UIColor(white: 0.82, alpha: 1))
    let body = node(SCNSphere(radius: 0.35), fur)
    body.position = SCNVector3(0, 0.93, -0.3)
    group.addChildNode(body)
    let head = node(SCNSphere(radius: 0.39), fur)
    head.position = SCNVector3(0, 1.47, -0.25)
    group.addChildNode(head)
    for x in [-0.23, 0.23] {
      let ear = node(
        SCNCapsule(capRadius: animal == 0 ? 0.12 : 0.16, height: animal == 0 ? 0.66 : 0.32), fur)
      ear.position = SCNVector3(x, animal == 0 ? 1.95 : 1.79, -0.27)
      ear.eulerAngles.z = Float(x * -0.6)
      group.addChildNode(ear)
      let eye = node(SCNSphere(radius: 0.047), Palette.green)
      eye.position = SCNVector3(x * 0.65, 1.52, 0.097)
      group.addChildNode(eye)
      let cheek = node(SCNSphere(radius: 0.069), Palette.pink)
      cheek.scale.z = 0.3
      cheek.position = SCNVector3(x * 0.95, 1.38, 0.07)
      group.addChildNode(cheek)
    }
    let scarf = node(SCNTorus(ringRadius: 0.24, pipeRadius: 0.06), Palette.green)
    scarf.position = SCNVector3(0, 1.15, -0.25)
    group.addChildNode(scarf)
    return group
  }

  func update(race: RaceEngine, racing: Bool, reducedMotion: Bool) {
    for (index, kart) in karts.enumerated() {
      kart.isHidden = index >= race.drivers.count
      guard index < race.drivers.count else { continue }
      let driver = race.drivers[index]
      kart.position = SCNVector3(driver.point.x, 0.06, driver.point.z)
      kart.eulerAngles.y = Float(
        driver.heading + (index == 0 && race.drifting ? race.steering * 0.22 : 0))
      kart.eulerAngles.z = index == 0 ? Float(-race.steering * 0.06) : 0
    }
    for node in boostNodes { node.isHidden = race.player.boost <= 0 }
    for (index, node) in itemNodes.enumerated() {
      node.isHidden = race.player.lastItemZone == race.player.tracker.laps * 3 + index
      if !reducedMotion {
        for item in node.childNodes { item.eulerAngles.y = Float(race.elapsed * 1.2) }
      }
    }
    if racing {
      let driver = race.player
      let target = SCNVector3(
        driver.point.x - sin(driver.heading) * 11,
        7.8,
        driver.point.z - cos(driver.heading) * 11)
      let blend: Float = cameraReady ? 0.11 : 1
      camera.position = SCNVector3(
        camera.position.x + (target.x - camera.position.x) * blend,
        camera.position.y + (target.y - camera.position.y) * blend,
        camera.position.z + (target.z - camera.position.z) * blend)
      camera.look(
        at: SCNVector3(
          driver.point.x + sin(driver.heading) * 7, 0.3, driver.point.z + cos(driver.heading) * 7))
      cameraReady = true
    } else {
      cameraReady = false
      camera.position = SCNVector3(-85, 87, 103)
      camera.look(at: SCNVector3(0, 0, -4))
    }
  }
}
