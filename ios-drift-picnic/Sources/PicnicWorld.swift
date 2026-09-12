import SceneKit
import UIKit

enum Palette {
  static let green = UIColor(red: 0.09, green: 0.28, blue: 0.22, alpha: 1)
  static let deepGreen = UIColor(red: 0.05, green: 0.19, blue: 0.15, alpha: 1)
  static let butter = UIColor(red: 1, green: 0.88, blue: 0.52, alpha: 1)
  static let cream = UIColor(red: 1, green: 0.97, blue: 0.85, alpha: 1)
  static let pink = UIColor(red: 0.92, green: 0.28, blue: 0.36, alpha: 1)
  static let blue = UIColor(red: 0.32, green: 0.64, blue: 0.77, alpha: 1)
  static let lilac = UIColor(red: 0.72, green: 0.62, blue: 0.86, alpha: 1)
  static let wood = UIColor(red: 0.55, green: 0.37, blue: 0.23, alpha: 1)
  static let sky = UIColor(red: 0.52, green: 0.78, blue: 0.93, alpha: 1)
  static let horizon = UIColor(red: 0.93, green: 0.90, blue: 0.80, alpha: 1)
  static let grass = UIColor(red: 0.50, green: 0.68, blue: 0.37, alpha: 1)
  static let asphalt = UIColor(red: 0.40, green: 0.53, blue: 0.43, alpha: 1)

  static func shade(_ color: UIColor, _ factor: CGFloat) -> UIColor {
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
    return UIColor(
      hue: h, saturation: min(1, s * (factor < 1 ? 1.08 : 0.92)), brightness: min(1, b * factor),
      alpha: a)
  }
}

enum Textures {
  static func image(_ size: CGFloat, _ draw: (CGContext, CGFloat) -> Void) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    return renderer.image { context in draw(context.cgContext, size) }
  }

  static func gradient(_ colors: [UIColor], _ locations: [CGFloat]) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 512))
    return renderer.image { context in
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map(\.cgColor) as CFArray,
        locations: locations)!
      context.cgContext.drawLinearGradient(
        gradient, start: .zero, end: CGPoint(x: 0, y: 512), options: [])
    }
  }

  static let sky = gradient(
    [
      UIColor(red: 0.36, green: 0.62, blue: 0.86, alpha: 1), Palette.sky,
      UIColor(red: 0.82, green: 0.90, blue: 0.93, alpha: 1), Palette.horizon,
    ], [0, 0.35, 0.62, 0.78])

  static let gingham = image(256) { context, size in
    Palette.cream.setFill()
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    let stripe = UIColor(red: 0.86, green: 0.40, blue: 0.38, alpha: 0.30)
    stripe.setFill()
    for i in 0..<2 {
      let offset = CGFloat(i) * size / 2
      context.fill(CGRect(x: offset, y: 0, width: size / 4, height: size))
      context.fill(CGRect(x: 0, y: offset, width: size, height: size / 4))
    }
    UIColor(white: 1, alpha: 0.10).setFill()
    for i in 0..<16 {
      context.fill(CGRect(x: CGFloat(i) * size / 16, y: 0, width: 1.5, height: size))
    }
  }

  static let grass = image(128) { context, size in
    Palette.grass.setFill()
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    var seed: UInt32 = 7
    for _ in 0..<180 {
      seed = seed &* 1_664_525 &+ 1_013_904_223
      let x = CGFloat(seed % 128)
      seed = seed &* 1_664_525 &+ 1_013_904_223
      let y = CGFloat(seed % 128)
      let dark = seed % 3 == 0
      (dark ? Palette.shade(Palette.grass, 0.9) : Palette.shade(Palette.grass, 1.08)).setFill()
      context.fillEllipse(in: CGRect(x: x, y: y, width: 3, height: 1.6))
    }
  }

  static let road = image(128) { context, size in
    Palette.asphalt.setFill()
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    var seed: UInt32 = 3
    for _ in 0..<420 {
      seed = seed &* 1_664_525 &+ 1_013_904_223
      let x = CGFloat(seed % 128)
      seed = seed &* 1_664_525 &+ 1_013_904_223
      let y = CGFloat(seed % 128)
      UIColor(white: seed % 2 == 0 ? 0.2 : 1, alpha: 0.07).setFill()
      context.fill(CGRect(x: x, y: y, width: 1, height: 1))
    }
  }

}

final class PicnicWorld {
  let scene = SCNScene()
  let camera = SCNNode()
  let karts: [SCNNode]
  var itemNodes: [SCNNode] = []
  var boostNodes: [SCNNode] = []
  private var wheels: [[SCNNode]] = []
  private var bodies: [SCNNode] = []
  private let clouds = SCNNode()
  private var sparks: [SCNNode] = []
  private var sparkLife: [Double] = []
  private var sparkVelocity: [SIMD3<Float>] = []
  private var sparkSpawn = 0.0
  private var sparkSeed: UInt32 = 11
  private let circuit = Circuit()
  private var cameraReady = false
  private var lastElapsed = 0.0
  private var wheelSpin: [Double] = [0, 0, 0, 0]

  init() {
    var wheelSets: [[SCNNode]] = []
    var bodySet: [SCNNode] = []
    karts = [Palette.butter, Palette.pink, Palette.blue, Palette.lilac].enumerated().map {
      let built = Self.kart(color: $0.element, animal: $0.offset)
      wheelSets.append(built.wheels)
      bodySet.append(built.body)
      return built.node
    }
    wheels = wheelSets
    bodies = bodySet
    scene.background.contents = Textures.sky
    scene.fogColor = Palette.horizon
    scene.fogStartDistance = 190
    scene.fogEndDistance = 430
    camera.camera = SCNCamera()
    camera.camera?.fieldOfView = 57
    camera.camera?.zFar = 520
    camera.camera?.wantsHDR = false
    camera.camera?.vignettingIntensity = 0.55
    camera.camera?.vignettingPower = 0.9
    #if !targetEnvironment(simulator)
      camera.camera?.screenSpaceAmbientOcclusionIntensity = 0.7
      camera.camera?.screenSpaceAmbientOcclusionRadius = 2.2
    #endif
    scene.rootNode.addChildNode(camera)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.intensity = 380
    ambient.light?.color = UIColor(red: 0.86, green: 0.92, blue: 1, alpha: 1)
    scene.rootNode.addChildNode(ambient)
    let sun = SCNNode()
    sun.light = SCNLight()
    sun.light?.type = .directional
    sun.light?.intensity = 1050
    sun.light?.color = UIColor(red: 1, green: 0.95, blue: 0.84, alpha: 1)
    sun.light?.castsShadow = true
    sun.light?.shadowMode = .forward
    sun.light?.shadowColor = UIColor(red: 0.10, green: 0.22, blue: 0.16, alpha: 0.32)
    sun.light?.shadowRadius = 4
    sun.light?.shadowSampleCount = 8
    sun.light?.shadowMapSize = CGSize(width: 1536, height: 1536)
    sun.light?.orthographicScale = 150
    sun.eulerAngles = SCNVector3(-1.0, -0.6, 0)
    scene.rootNode.addChildNode(sun)
    let fill = SCNNode()
    fill.light = SCNLight()
    fill.light?.type = .directional
    fill.light?.intensity = 220
    fill.light?.color = UIColor(red: 0.75, green: 0.85, blue: 1, alpha: 1)
    fill.eulerAngles = SCNVector3(-0.7, 2.4, 0)
    scene.rootNode.addChildNode(fill)
    buildGround()
    buildTrack()
    buildScenery()
    buildSky()
    for kart in karts {
      let shadow = Self.node(
        SCNCylinder(radius: 1, height: 0.015), UIColor.black.withAlphaComponent(0.2))
      shadow.geometry?.firstMaterial?.lightingModel = .constant
      shadow.scale = SCNVector3(0.85, 1, 1.35)
      shadow.position.y = -0.005
      kart.addChildNode(shadow)
      scene.rootNode.addChildNode(kart)
    }
    buildPlayerMarker()
    for index in 0..<3 {
      let distance = Double(index) * circuit.length / 3 + 38
      let group = SCNNode()
      for lane in [-3.5, 0, 3.5] {
        let item = Self.lemonade()
        let position = circuit.at(distance, offset: lane).point
        item.position = SCNVector3(position.x, 1.3, position.z)
        item.scale = SCNVector3(0.5, 0.5, 0.5)
        let halo = Self.node(SCNTorus(ringRadius: 1.3, pipeRadius: 0.05), Palette.butter)
        halo.geometry?.firstMaterial?.lightingModel = .constant
        halo.position.y = -1.7
        item.addChildNode(halo)
        group.addChildNode(item)
      }
      scene.rootNode.addChildNode(group)
      itemNodes.append(group)
    }
    for x in [-0.36, 0.36] {
      let glow = Self.node(
        SCNCone(topRadius: 0.05, bottomRadius: 0.24, height: 1.6), Palette.butter)
      glow.eulerAngles.x = -.pi / 2
      glow.geometry?.firstMaterial?.lightingModel = .constant
      glow.geometry?.firstMaterial?.emission.contents = Palette.butter
      glow.isHidden = true
      glow.position = SCNVector3(x, 0.36, -1.35)
      karts[0].addChildNode(glow)
      boostNodes.append(glow)
    }
    configureSparks()
  }

  static func node(_ geometry: SCNGeometry, _ color: UIColor, roughness: CGFloat = 0.65) -> SCNNode
  {
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.lightingModel = .blinn
    material.specular.contents = UIColor(white: 0.22, alpha: 1)
    material.shininess = 0.35
    material.roughness.contents = roughness
    geometry.materials = [material]
    return SCNNode(geometry: geometry)
  }

  static func glossy(_ geometry: SCNGeometry, _ color: UIColor) -> SCNNode {
    let built = node(geometry, color, roughness: 0.25)
    built.geometry?.firstMaterial?.specular.contents = UIColor(white: 0.6, alpha: 1)
    built.geometry?.firstMaterial?.shininess = 0.75
    return built
  }

  static func box(
    _ width: CGFloat, _ height: CGFloat, _ depth: CGFloat, _ color: UIColor, radius: CGFloat = 0.08
  ) -> SCNNode {
    node(SCNBox(width: width, height: height, length: depth, chamferRadius: radius), color)
  }

  private func buildGround() {
    let lawn = Self.box(560, 1, 560, Palette.grass, radius: 0)
    lawn.position.y = -0.8
    let lawnMaterial = lawn.geometry!.firstMaterial!
    lawnMaterial.diffuse.contents = Textures.grass
    lawnMaterial.diffuse.wrapS = .repeat
    lawnMaterial.diffuse.wrapT = .repeat
    lawnMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(70, 70, 1)
    scene.rootNode.addChildNode(lawn)
    let blanket = Self.box(150, 0.3, 118, Palette.cream, radius: 1.6)
    blanket.position.y = -0.22
    let blanketMaterial = blanket.geometry!.firstMaterial!
    blanketMaterial.diffuse.contents = Textures.gingham
    blanketMaterial.diffuse.wrapS = .repeat
    blanketMaterial.diffuse.wrapT = .repeat
    blanketMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(19, 15, 1)
    blanketMaterial.roughness.contents = 0.95
    scene.rootNode.addChildNode(blanket)
    let hem = Self.box(152, 0.34, 120, Palette.pink, radius: 1.8)
    hem.position.y = -0.27
    scene.rootNode.addChildNode(hem)
    for i in 0..<6 {
      let hill = Self.node(
        SCNSphere(radius: 70 + Double(i % 3) * 25),
        Palette.shade(Palette.grass, 1.05 + Double(i % 2) * 0.06))
      let t = Double(i) / 6 * .pi * 2 + 0.4
      hill.position = SCNVector3(cos(t) * 300, -55 - Double(i % 3) * 10, sin(t) * 300)
      hill.scale = SCNVector3(1.6, 1, 1)
      scene.rootNode.addChildNode(hill)
    }
  }

  private func ribbon(inner: Double, outer: Double, height: Double, color: UIColor)
    -> SCNNode
  {
    var vertices: [SCNVector3] = []
    var coordinates: [CGPoint] = []
    var indices: [Int32] = []
    for i in 0...300 {
      let distance = Double(i) / 300 * circuit.length
      let a = circuit.at(distance, offset: inner).point
      let b = circuit.at(distance, offset: outer).point
      vertices.append(SCNVector3(a.x, height, a.z))
      vertices.append(SCNVector3(b.x, height, b.z))
      coordinates.append(CGPoint(x: 0, y: distance / 6))
      coordinates.append(CGPoint(x: 1, y: distance / 6))
      if i < 300 {
        let j = Int32(i * 2)
        indices += [j, j + 2, j + 1, j + 1, j + 2, j + 3]
      }
    }
    let geometry = SCNGeometry(
      sources: [
        SCNGeometrySource(vertices: vertices),
        SCNGeometrySource(normals: Array(repeating: SCNVector3(0, 1, 0), count: vertices.count)),
        SCNGeometrySource(textureCoordinates: coordinates),
      ],
      elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
    let road = Self.node(geometry, color)
    road.geometry?.firstMaterial?.isDoubleSided = true
    scene.rootNode.addChildNode(road)
    return road
  }

  private func buildTrack() {
    _ = ribbon(inner: -7.3, outer: 7.3, height: 0.00, color: Palette.green)
    let surface = ribbon(inner: -6.5, outer: 6.5, height: 0.04, color: Palette.asphalt)
    let surfaceMaterial = surface.geometry!.firstMaterial!
    surfaceMaterial.diffuse.contents = Textures.road
    surfaceMaterial.diffuse.wrapS = .repeat
    surfaceMaterial.diffuse.wrapT = .repeat
    surfaceMaterial.roughness.contents = 0.9
    _ = ribbon(inner: -6.0, outer: -5.82, height: 0.055, color: Palette.cream)
    _ = ribbon(inner: 5.82, outer: 6.0, height: 0.055, color: Palette.cream)
    let curbs = SCNNode()
    for i in 0..<120 {
      let distance = Double(i) / 120 * circuit.length
      for side in [-1.0, 1.0] {
        let pose = circuit.at(distance, offset: side * 6.75)
        let curb = Self.box(
          0.7, 0.18, 1.62, i % 2 == 0 ? Palette.cream : Palette.pink, radius: 0.05)
        curb.position = SCNVector3(pose.point.x, 0.11, pose.point.z)
        curb.eulerAngles.y = Float(pose.heading)
        curbs.addChildNode(curb)
      }
      if i % 3 == 0 {
        let pose = circuit.at(distance)
        let dash = Self.box(0.11, 0.015, 1.5, Palette.cream, radius: 0)
        dash.geometry?.firstMaterial?.diffuse.contents = Palette.cream.withAlphaComponent(0.7)
        dash.position = SCNVector3(pose.point.x, 0.065, pose.point.z)
        dash.eulerAngles.y = Float(pose.heading)
        curbs.addChildNode(dash)
      }
    }
    scene.rootNode.addChildNode(curbs.flattenedClone())
    let startPose = circuit.at(0)
    let start = SCNNode()
    start.position = SCNVector3(startPose.point.x, 0, startPose.point.z)
    start.eulerAngles.y = Float(startPose.heading)
    let grid = SCNNode()
    for x in -6...6 {
      for z in 0...2 {
        let tile = Self.box(1, 0.02, 1, (x + z) % 2 == 0 ? Palette.cream : Palette.green, radius: 0)
        tile.position = SCNVector3(Double(x), 0.08, Double(z - 1))
        grid.addChildNode(tile)
      }
    }
    start.addChildNode(grid.flattenedClone())
    let gantry = SCNNode()
    gantry.position.z = 11
    let signage = SCNNode()
    signage.position.z = 11
    for x in [-7.9, 7.9] {
      let pillar = Self.node(SCNCylinder(radius: 0.28, height: 7.4), Palette.cream)
      pillar.position = SCNVector3(x, 3.7, 0)
      gantry.addChildNode(pillar)
      for stripe in 0..<6 {
        let ring = Self.node(SCNCylinder(radius: 0.3, height: 0.5), Palette.pink)
        ring.position = SCNVector3(x, 0.5 + Double(stripe) * 1.2, 0)
        gantry.addChildNode(ring)
      }
      let finial = Self.glossy(SCNSphere(radius: 0.5), Palette.butter)
      finial.position = SCNVector3(x, 7.6, 0)
      gantry.addChildNode(finial)
    }
    let banner = Self.box(16.4, 1.35, 0.3, Palette.green, radius: 0.12)
    banner.position.y = 6.6
    gantry.addChildNode(banner)
    let trim = Self.box(16.6, 0.12, 0.34, Palette.butter, radius: 0.02)
    trim.position.y = 7.33
    gantry.addChildNode(trim)
    let trimLow = Self.box(16.6, 0.12, 0.34, Palette.butter, radius: 0.02)
    trimLow.position.y = 5.87
    gantry.addChildNode(trimLow)
    for side in [-1.0, 1.0] {
      let text = SCNText(string: "DRIFT PICNIC", extrusionDepth: 0.02)
      text.font = UIFont(name: "Georgia-BoldItalic", size: 0.78)
      text.flatness = 0.05
      let label = Self.node(text, Palette.butter)
      label.geometry?.firstMaterial?.lightingModel = .constant
      let bounds = text.boundingBox
      label.pivot = SCNMatrix4MakeTranslation(
        (bounds.min.x + bounds.max.x) / 2, (bounds.min.y + bounds.max.y) / 2, 0)
      label.position = SCNVector3(0, 6.6, side * 0.18)
      label.eulerAngles.y = side < 0 ? .pi : 0
      signage.addChildNode(label)
    }
    for i in 0..<14 {
      let flag = Self.node(
        SCNPyramid(width: 0.7, height: 0.9, length: 0.04),
        [Palette.butter, Palette.pink, Palette.cream, Palette.blue][i % 4])
      flag.geometry?.firstMaterial?.isDoubleSided = true
      flag.position = SCNVector3(-7.2 + Double(i) * 1.1, 5.75, 0)
      flag.eulerAngles.x = .pi
      gantry.addChildNode(flag)
    }
    start.addChildNode(gantry.flattenedClone())
    start.addChildNode(signage)
    scene.rootNode.addChildNode(start)
  }

  private func buildScenery() {
    buildCake(at: SCNVector3(1, 0, 1))
    let berries = SCNNode()
    for i in 0..<22 {
      let pose = circuit.at(Double(i) / 22 * circuit.length, offset: i % 2 == 0 ? 10.5 : -11)
      let berry = Self.strawberry()
      berry.scale = SCNVector3(1.6, 1.6, 1.6)
      berry.position = SCNVector3(pose.point.x, 0.05, pose.point.z)
      berry.eulerAngles.y = Float(i) * 1.5
      berries.addChildNode(berry)
    }
    scene.rootNode.addChildNode(berries)
    for (x, z) in [(27.0, 6.0), (-30, 0), (30, 54), (-48, -53)] {
      let lemonade = Self.lemonade()
      lemonade.scale = SCNVector3(4, 4, 4)
      lemonade.position = SCNVector3(x, 0, z)
      scene.rootNode.addChildNode(lemonade.flattenedClone())
    }
    buildParasol(at: SCNVector3(-54, 0, 44))
    buildBasket(at: SCNVector3(52, 0, -40))
    buildTeaSet(at: SCNVector3(-16, 0, -55))
    buildBunting()
    let trees = SCNNode()
    for i in 0..<34 {
      let t = Double(i) / 34 * .pi * 2
      let ring = i % 3 == 0 ? 1.28 : 1.0
      let tree = Self.tree(seed: i)
      tree.position = SCNVector3(cos(t) * 112 * ring, 0, sin(t) * 94 * ring)
      trees.addChildNode(tree)
    }
    scene.rootNode.addChildNode(trees.flattenedClone())
    let flowers = SCNNode()
    for i in 0..<160 {
      let angle = Double(i) * 2.399
      let radius = 88.0 + Double(i % 11) * 3.2
      let flower = Self.flower(seed: i)
      flower.position = SCNVector3(cos(angle) * radius, 0.05, sin(angle) * radius * 0.82)
      flowers.addChildNode(flower)
    }
    for i in 0..<40 {
      let angle = Double(i) * 2.399 + 1
      let radius = 15.0 + Double(i % 7) * 1.8
      let flower = Self.flower(seed: i + 7)
      flower.scale = SCNVector3(0.7, 0.7, 0.7)
      flower.position = SCNVector3(cos(angle) * radius, 0.05, sin(angle) * radius * 0.6)
      flowers.addChildNode(flower)
    }
    scene.rootNode.addChildNode(flowers.flattenedClone())
  }

  private func buildCake(at position: SCNVector3) {
    let cake = SCNNode()
    cake.position = position
    let plate = Self.glossy(SCNCylinder(radius: 14.5, height: 0.5), UIColor.white)
    plate.position.y = 0.25
    cake.addChildNode(plate)
    let plateRim = Self.glossy(SCNTorus(ringRadius: 14.3, pipeRadius: 0.25), Palette.butter)
    plateRim.position.y = 0.5
    cake.addChildNode(plateRim)
    let tiers: [(radius: Double, height: Double)] = [(12, 4.2), (8.6, 3.4), (5.4, 3.0)]
    var y = 0.5
    for (index, tier) in tiers.enumerated() {
      let sponge = Self.node(
        SCNCylinder(radius: tier.radius, height: tier.height),
        UIColor(red: 0.95, green: 0.74, blue: 0.47, alpha: 1))
      sponge.position.y = Float(y + tier.height / 2)
      cake.addChildNode(sponge)
      let jam = Self.node(
        SCNCylinder(radius: tier.radius + 0.02, height: 0.35), Palette.pink, roughness: 0.3)
      jam.position.y = Float(y + tier.height * 0.5)
      cake.addChildNode(jam)
      let icing = Self.node(
        SCNCylinder(radius: tier.radius + 0.15, height: 0.8), Palette.cream, roughness: 0.4)
      icing.position.y = Float(y + tier.height + 0.3)
      cake.addChildNode(icing)
      for i in 0..<Int(tier.radius * 2.2) {
        let t = Double(i) / (tier.radius * 2.2) * .pi * 2
        let drip = Self.node(
          SCNCapsule(capRadius: 0.32, height: 1.0 + Double(i % 3) * 0.5), Palette.cream)
        drip.position = SCNVector3(
          cos(t) * (tier.radius + 0.12), y + tier.height - 0.3 - Double(i % 3) * 0.2,
          sin(t) * (tier.radius + 0.12))
        cake.addChildNode(drip)
      }
      let berryCount = index == 2 ? 5 : 9
      for i in 0..<berryCount {
        let t = Double(i) / Double(berryCount) * .pi * 2 + Double(index)
        let berry = Self.strawberry()
        berry.scale = SCNVector3(1.1, 1.1, 1.1)
        berry.position = SCNVector3(
          cos(t) * (tier.radius - 1.4), y + tier.height + 0.65, sin(t) * (tier.radius - 1.4))
        cake.addChildNode(berry)
      }
      y += tier.height + 0.7
    }
    for i in 0..<3 {
      let t = Double(i) / 3 * .pi * 2
      let candle = Self.node(SCNCylinder(radius: 0.28, height: 2.6), Palette.blue)
      candle.position = SCNVector3(cos(t) * 2.2, y + 1.3, sin(t) * 2.2)
      cake.addChildNode(candle)
      let flame = Self.glossy(SCNSphere(radius: 0.36), Palette.butter)
      flame.geometry?.firstMaterial?.emission.contents = Palette.butter
      flame.scale.y = 1.5
      flame.position = SCNVector3(cos(t) * 2.2, y + 2.95, sin(t) * 2.2)
      cake.addChildNode(flame)
    }
    scene.rootNode.addChildNode(cake.flattenedClone())
  }

  private func buildParasol(at position: SCNVector3) {
    let parasol = SCNNode()
    parasol.position = position
    let pole = Self.node(SCNCylinder(radius: 0.32, height: 20), Palette.cream)
    pole.position.y = 10
    parasol.addChildNode(pole)
    let canopy = SCNNode()
    canopy.position.y = 18
    let cone = Self.node(SCNCone(topRadius: 0, bottomRadius: 13, height: 5.5), Palette.cream)
    cone.geometry?.firstMaterial?.isDoubleSided = true
    cone.position.y = 2.75
    canopy.addChildNode(cone)
    let stripes = SCNNode()
    for i in 0..<12 {
      let stripe = Self.box(
        1.3, 0.12, 12.4, i % 2 == 0 ? Palette.pink : Palette.cream, radius: 0.02)
      stripe.position = SCNVector3(0, 2.7, 6.2)
      stripe.eulerAngles.x = 0.4
      let pivot = SCNNode()
      pivot.eulerAngles.y = Float(i) * .pi / 6
      pivot.addChildNode(stripe)
      stripes.addChildNode(pivot)
    }
    canopy.addChildNode(stripes)
    let tip = Self.glossy(SCNSphere(radius: 0.7), Palette.butter)
    tip.position.y = 5.8
    canopy.addChildNode(tip)
    parasol.addChildNode(canopy)
    scene.rootNode.addChildNode(parasol.flattenedClone())
  }

  private func buildBasket(at position: SCNVector3) {
    let basket = SCNNode()
    basket.position = position
    basket.eulerAngles.y = 0.6
    let body = Self.box(11, 6, 7.5, Palette.wood, radius: 0.8)
    body.position.y = 3
    basket.addChildNode(body)
    for i in 0..<5 {
      let band = Self.box(11.2, 0.5, 7.7, Palette.shade(Palette.wood, 0.78), radius: 0.2)
      band.position.y = Float(0.9 + Double(i) * 1.15)
      basket.addChildNode(band)
    }
    let cloth = Self.box(11.6, 0.6, 8.1, Palette.cream, radius: 0.3)
    cloth.geometry?.firstMaterial?.diffuse.contents = Textures.gingham
    cloth.geometry?.firstMaterial?.diffuse.wrapS = .repeat
    cloth.geometry?.firstMaterial?.diffuse.wrapT = .repeat
    cloth.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(3, 2, 1)
    cloth.position.y = 6.2
    cloth.eulerAngles.z = 0.06
    basket.addChildNode(cloth)
    let handle = Self.node(SCNTorus(ringRadius: 4.5, pipeRadius: 0.35), Palette.wood)
    handle.eulerAngles.x = .pi / 2
    handle.position.y = 6.3
    basket.addChildNode(handle)
    let loaf = Self.node(
      SCNCapsule(capRadius: 1.4, height: 6), UIColor(red: 0.85, green: 0.62, blue: 0.36, alpha: 1))
    loaf.eulerAngles.z = .pi / 2
    loaf.position = SCNVector3(-1, 7.4, 0.6)
    basket.addChildNode(loaf)
    let apple = Self.glossy(SCNSphere(radius: 1.4), Palette.pink)
    apple.position = SCNVector3(3.3, 7.6, -1)
    basket.addChildNode(apple)
    scene.rootNode.addChildNode(basket.flattenedClone())
  }

  private func buildTeaSet(at position: SCNVector3) {
    let set = SCNNode()
    set.position = position
    let pot = Self.glossy(SCNSphere(radius: 3.6), Palette.blue)
    pot.position.y = 3.6
    set.addChildNode(pot)
    let lid = Self.glossy(SCNSphere(radius: 0.7), Palette.cream)
    lid.position.y = 7.4
    set.addChildNode(lid)
    let spout = Self.glossy(SCNCone(topRadius: 0.5, bottomRadius: 1.0, height: 4.5), Palette.blue)
    spout.position = SCNVector3(3.6, 4.8, 0)
    spout.eulerAngles.z = -0.9
    set.addChildNode(spout)
    let handle = Self.glossy(SCNTorus(ringRadius: 1.8, pipeRadius: 0.35), Palette.blue)
    handle.position = SCNVector3(-3.6, 4.2, 0)
    set.addChildNode(handle)
    for (index, offset) in [(-7.0, 5.0), (7.0, 6.0)].enumerated() {
      let cup = Self.glossy(
        SCNCylinder(radius: 1.5, height: 1.8), index == 0 ? Palette.cream : Palette.butter)
      cup.position = SCNVector3(offset.0, 0.9, offset.1)
      set.addChildNode(cup)
      let saucer = Self.glossy(SCNCylinder(radius: 2.4, height: 0.2), UIColor.white)
      saucer.position = SCNVector3(offset.0, 0.1, offset.1)
      set.addChildNode(saucer)
    }
    scene.rootNode.addChildNode(set.flattenedClone())
  }

  private func buildBunting() {
    let bunting = SCNNode()
    let posts: [(Double, Double)] = [
      (-72, -56), (-20, -62), (34, -60), (72, -50), (76, 10), (70, 56), (20, 62), (-36, 62),
      (-74, 52),
    ]
    for (x, z) in posts {
      let post = Self.node(SCNCylinder(radius: 0.28, height: 9), Palette.cream)
      post.position = SCNVector3(x, 4.5, z)
      bunting.addChildNode(post)
      let knob = Self.glossy(SCNSphere(radius: 0.5), Palette.pink)
      knob.position = SCNVector3(x, 9.1, z)
      bunting.addChildNode(knob)
    }
    for i in 0..<posts.count - 1 {
      let a = posts[i]
      let b = posts[i + 1]
      let count = 12
      for k in 0...count {
        let f = Double(k) / Double(count)
        let sag = sin(f * .pi) * 1.8
        let x = a.0 + (b.0 - a.0) * f
        let z = a.1 + (b.1 - a.1) * f
        if k < count {
          let flag = Self.node(
            SCNPyramid(width: 1.1, height: 1.5, length: 0.05),
            [Palette.butter, Palette.pink, Palette.cream, Palette.blue][k % 4])
          flag.geometry?.firstMaterial?.isDoubleSided = true
          flag.position = SCNVector3(x, 8.9 - sag, z)
          flag.eulerAngles = SCNVector3(.pi, atan2(b.0 - a.0, b.1 - a.1) + .pi / 2, 0)
          bunting.addChildNode(flag)
        }
      }
      let length = hypot(b.0 - a.0, b.1 - a.1)
      let string = Self.node(SCNCylinder(radius: 0.06, height: length), Palette.green)
      string.position = SCNVector3((a.0 + b.0) / 2, 8.4, (a.1 + b.1) / 2)
      string.eulerAngles = SCNVector3(.pi / 2, atan2(b.0 - a.0, b.1 - a.1), 0)
      bunting.addChildNode(string)
    }
    scene.rootNode.addChildNode(bunting.flattenedClone())
  }

  private func buildSky() {
    for i in 0..<9 {
      let cloud = SCNNode()
      let t = Double(i) / 9 * .pi * 2
      let radius = 190.0 + Double(i % 3) * 40
      cloud.position = SCNVector3(cos(t) * radius, 52 + Double(i % 4) * 9, sin(t) * radius)
      for (index, part) in [(0.0, 0.0, 9.0), (7.5, 1.5, 6.5), (-7.0, 1.0, 6.0), (2.0, 4.5, 6.0)]
        .enumerated()
      {
        let puff = Self.node(
          SCNSphere(radius: part.2), UIColor(white: index == 0 ? 1 : 0.985, alpha: 1))
        puff.geometry?.firstMaterial?.lightingModel = .lambert
        puff.position = SCNVector3(part.0, part.1, 0)
        cloud.addChildNode(puff)
      }
      cloud.scale = SCNVector3(1.3, 0.75, 1)
      clouds.addChildNode(cloud)
    }
    scene.rootNode.addChildNode(clouds.flattenedClone())
  }

  private func buildPlayerMarker() {
    let marker = SCNNode()
    marker.position.y = 2.75
    marker.constraints = [SCNBillboardConstraint()]
    let pill = Self.node(SCNCapsule(capRadius: 0.24, height: 1.35), Palette.green)
    pill.eulerAngles.z = .pi / 2
    pill.geometry?.firstMaterial?.lightingModel = .constant
    marker.addChildNode(pill)
    let markerText = SCNText(string: "YOU", extrusionDepth: 0)
    markerText.font = UIFont.systemFont(ofSize: 0.28, weight: .black)
    let markerLabel = Self.node(markerText, Palette.butter)
    markerLabel.geometry?.firstMaterial?.lightingModel = .constant
    let markerBounds = markerText.boundingBox
    markerLabel.pivot = SCNMatrix4MakeTranslation(
      (markerBounds.min.x + markerBounds.max.x) / 2,
      (markerBounds.min.y + markerBounds.max.y) / 2, 0)
    markerLabel.position = SCNVector3(0, 0, 0.26)
    marker.addChildNode(markerLabel)
    let tail = Self.node(SCNPyramid(width: 0.34, height: 0.3, length: 0.05), Palette.green)
    tail.geometry?.firstMaterial?.lightingModel = .constant
    tail.geometry?.firstMaterial?.isDoubleSided = true
    tail.position = SCNVector3(0, -0.22, 0)
    tail.eulerAngles.x = .pi
    marker.addChildNode(tail)
    karts[0].addChildNode(marker)
  }

  private func configureSparks() {
    for _ in 0..<36 {
      let geometry = SCNSphere(radius: 0.11)
      geometry.segmentCount = 8
      let spark = Self.node(geometry, Palette.butter)
      spark.geometry?.firstMaterial?.lightingModel = .constant
      spark.geometry?.firstMaterial?.emission.contents = Palette.butter
      spark.castsShadow = false
      spark.isHidden = true
      scene.rootNode.addChildNode(spark)
      sparks.append(spark)
      sparkLife.append(0)
      sparkVelocity.append(.zero)
    }
  }

  private func random() -> Float {
    sparkSeed = sparkSeed &* 1_664_525 &+ 1_013_904_223
    return Float(sparkSeed >> 8) / Float(1 << 24)
  }

  private func emitSpark(
    from origin: SIMD3<Float>, velocity: SIMD3<Float>, color: UIColor, size: Float
  ) {
    guard let index = sparkLife.firstIndex(where: { $0 <= 0 }) else { return }
    let spark = sparks[index]
    spark.isHidden = false
    spark.position = SCNVector3(origin.x, origin.y, origin.z)
    spark.scale = SCNVector3(size, size, size)
    spark.geometry?.firstMaterial?.diffuse.contents = color
    spark.geometry?.firstMaterial?.emission.contents = color
    sparkVelocity[index] = velocity
    sparkLife[index] = 1
  }

  private func updateSparks(race: RaceEngine, dt: Double, reducedMotion: Bool) {
    let player = race.player
    let heading = Float(player.heading)
    let forward = SIMD3<Float>(sin(heading), 0, cos(heading))
    let side = SIMD3<Float>(cos(heading), 0, -sin(heading))
    let rear = SIMD3<Float>(Float(player.point.x), 0.18, Float(player.point.z)) - forward * 0.95
    let boosting = player.boost > 0
    let drifting = race.drifting && player.speed > 8
    let rate: Double =
      reducedMotion ? 0 : (boosting ? 70 : (drifting ? (player.driftCharge >= 0.65 ? 60 : 32) : 0))
    sparkSpawn = rate > 0 ? sparkSpawn + rate * dt : 0
    while sparkSpawn >= 1 {
      sparkSpawn -= 1
      if boosting {
        let jitter = side * (random() - 0.5) * 0.5
        emitSpark(
          from: rear + jitter + SIMD3<Float>(0, 0.25, 0),
          velocity: -forward * (5 + random() * 2) + SIMD3<Float>(0, 0.6 + random(), 0),
          color: Palette.cream, size: 1.6 + random() * 0.8)
      } else {
        let lateral = Float(race.steering > 0 ? 1 : -1) * (0.45 + random() * 0.4)
        emitSpark(
          from: rear + side * lateral,
          velocity: -forward * (2 + random() * 2) + side * lateral * 2
            + SIMD3<Float>(0, 1.4 + random() * 1.6, 0),
          color: player.driftCharge >= 0.65 ? Palette.butter : Palette.cream,
          size: 0.7 + random() * 0.5)
      }
    }
    for index in sparks.indices where sparkLife[index] > 0 {
      sparkLife[index] -= dt / 0.45
      let spark = sparks[index]
      if sparkLife[index] <= 0 {
        spark.isHidden = true
        continue
      }
      sparkVelocity[index].y -= Float(dt) * 6
      let velocity = sparkVelocity[index]
      spark.position = SCNVector3(
        spark.position.x + velocity.x * Float(dt),
        max(0.08, spark.position.y + velocity.y * Float(dt)),
        spark.position.z + velocity.z * Float(dt))
      let fade = Float(sparkLife[index])
      spark.scale = SCNVector3(
        spark.scale.x * (0.94 + 0.06 * fade), spark.scale.y * (0.94 + 0.06 * fade),
        spark.scale.z * (0.94 + 0.06 * fade))
    }
  }

  static func tree(seed: Int) -> SCNNode {
    let tree = SCNNode()
    let scale = 0.85 + Double(seed % 4) * 0.12
    let trunk = node(SCNCylinder(radius: 0.7, height: 6), Palette.shade(Palette.wood, 0.9))
    trunk.position.y = 3
    tree.addChildNode(trunk)
    let leaf = [
      UIColor(red: 0.27, green: 0.50, blue: 0.29, alpha: 1),
      UIColor(red: 0.36, green: 0.58, blue: 0.31, alpha: 1),
      UIColor(red: 0.20, green: 0.42, blue: 0.27, alpha: 1),
    ][seed % 3]
    for layer in 0..<4 {
      let puff = node(
        SCNSphere(radius: 3.6 - Double(layer) * 0.55),
        Palette.shade(leaf, 0.9 + Double(layer) * 0.06))
      puff.position = SCNVector3(
        [-0.9, 1.6, 0.2, -0.4][layer], 6.2 + Double(layer) * 1.55, [0.4, 0.6, -1.4, 0.2][layer])
      tree.addChildNode(puff)
    }
    tree.scale = SCNVector3(scale, scale, scale)
    tree.eulerAngles.y = Float(seed) * 0.7
    return tree
  }

  static func flower(seed: Int) -> SCNNode {
    let flower = SCNNode()
    let stem = node(SCNCylinder(radius: 0.08, height: 1.3), Palette.green)
    stem.position.y = 0.65
    flower.addChildNode(stem)
    let color = [Palette.butter, Palette.cream, Palette.pink, Palette.lilac][seed % 4]
    for i in 0..<5 {
      let petal = node(SCNSphere(radius: 0.26), color)
      petal.scale = SCNVector3(1, 0.5, 1)
      let t = Double(i) / 5 * .pi * 2
      petal.position = SCNVector3(cos(t) * 0.3, 1.35, sin(t) * 0.3)
      flower.addChildNode(petal)
    }
    let center = node(SCNSphere(radius: 0.17), seed % 4 == 0 ? Palette.pink : Palette.butter)
    center.position.y = 1.45
    flower.addChildNode(center)
    return flower
  }

  static func strawberry() -> SCNNode {
    let group = SCNNode()
    let fruit = glossy(SCNSphere(radius: 0.85), Palette.pink)
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
    return group.flattenedClone()
  }

  static func lemonade() -> SCNNode {
    let group = SCNNode()
    let glass = glossy(SCNCylinder(radius: 0.74, height: 1.9), UIColor(white: 1, alpha: 0.35))
    glass.geometry?.firstMaterial?.transparency = 0.45
    glass.position.y = 1.02
    group.addChildNode(glass)
    let drink = glossy(SCNCylinder(radius: 0.66, height: 1.5), Palette.butter)
    drink.position.y = 0.85
    group.addChildNode(drink)
    for y in [0.13, 1.96] {
      let rim = glossy(SCNTorus(ringRadius: 0.72, pipeRadius: 0.05), Palette.cream)
      rim.position.y = Float(y)
      group.addChildNode(rim)
    }
    for i in 0..<3 {
      let ice = glossy(
        SCNBox(width: 0.34, height: 0.34, length: 0.34, chamferRadius: 0.06),
        UIColor(white: 1, alpha: 0.8))
      ice.position = SCNVector3(Double(i - 1) * 0.3, 1.45, Double(i % 2) * 0.25 - 0.1)
      ice.eulerAngles = SCNVector3(Double(i) * 0.5, Double(i) * 0.8, 0)
      group.addChildNode(ice)
    }
    let straw = box(0.12, 2.4, 0.12, Palette.pink, radius: 0.02)
    straw.position = SCNVector3(0.26, 1.7, 0)
    straw.eulerAngles.z = -0.15
    group.addChildNode(straw)
    let slice = glossy(
      SCNCylinder(radius: 0.48, height: 0.13), UIColor(red: 1, green: 0.85, blue: 0.25, alpha: 1))
    slice.eulerAngles.x = .pi / 2
    slice.position = SCNVector3(-0.44, 2.0, 0)
    group.addChildNode(slice)
    let pith = glossy(SCNCylinder(radius: 0.5, height: 0.11), Palette.cream)
    pith.eulerAngles.x = .pi / 2
    pith.position = SCNVector3(-0.44, 2.0, 0)
    group.addChildNode(pith)
    return group
  }

  static func kart(color: UIColor, animal: Int) -> (node: SCNNode, body: SCNNode, wheels: [SCNNode])
  {
    let group = SCNNode()
    let body = SCNNode()
    group.addChildNode(body)
    let dark = Palette.shade(color, 0.72)
    let chassis = glossy(SCNBox(width: 1.3, height: 0.4, length: 2.05, chamferRadius: 0.2), color)
    chassis.position.y = 0.5
    body.addChildNode(chassis)
    let nose = glossy(SCNSphere(radius: 0.64), color)
    nose.scale = SCNVector3(1.0, 0.5, 0.78)
    nose.position = SCNVector3(0, 0.63, 0.86)
    body.addChildNode(nose)
    let hood = glossy(SCNBox(width: 1.05, height: 0.26, length: 0.9, chamferRadius: 0.13), color)
    hood.position = SCNVector3(0, 0.79, 0.5)
    body.addChildNode(hood)
    let stripe = box(0.22, 0.03, 1.2, Palette.cream, radius: 0.01)
    stripe.position = SCNVector3(0, 0.93, 0.7)
    body.addChildNode(stripe)
    let roundel = glossy(SCNCylinder(radius: 0.24, height: 0.03), Palette.cream)
    roundel.position = SCNVector3(0, 0.94, 0.42)
    body.addChildNode(roundel)
    let number = SCNText(string: "\(animal + 1)", extrusionDepth: 0.01)
    number.font = UIFont(name: "Georgia-BoldItalic", size: 0.3)
    let numberNode = node(number, Palette.green)
    let numberBounds = number.boundingBox
    let numberCentre = SCNVector3(
      (numberBounds.min.x + numberBounds.max.x) / 2, (numberBounds.min.y + numberBounds.max.y) / 2,
      0)
    numberNode.eulerAngles.x = -.pi / 2
    numberNode.position = SCNVector3(-numberCentre.x, 0.965, 0.42 + numberCentre.y)
    body.addChildNode(numberNode)
    for x in [-0.74, 0.74] {
      let pod = glossy(SCNBox(width: 0.3, height: 0.3, length: 1.05, chamferRadius: 0.12), dark)
      pod.position = SCNVector3(x, 0.5, -0.05)
      body.addChildNode(pod)
      let light = glossy(SCNSphere(radius: 0.11), Palette.cream)
      light.geometry?.firstMaterial?.emission.contents = UIColor(white: 0.6, alpha: 1)
      light.position = SCNVector3(x * 0.5, 0.6, 1.36)
      body.addChildNode(light)
      let exhaust = node(SCNCylinder(radius: 0.08, height: 0.3), UIColor(white: 0.3, alpha: 1))
      exhaust.eulerAngles.x = .pi / 2
      exhaust.position = SCNVector3(x * 0.4, 0.4, -1.1)
      body.addChildNode(exhaust)
    }
    let bumper = glossy(
      SCNBox(width: 1.36, height: 0.14, length: 0.2, chamferRadius: 0.07), Palette.cream)
    bumper.position = SCNVector3(0, 0.42, 1.12)
    body.addChildNode(bumper)
    let cockpit = node(SCNTorus(ringRadius: 0.44, pipeRadius: 0.06), Palette.cream)
    cockpit.position = SCNVector3(0, 0.72, -0.3)
    body.addChildNode(cockpit)
    let seat = glossy(SCNBox(width: 0.72, height: 0.5, length: 0.16, chamferRadius: 0.07), dark)
    seat.position = SCNVector3(0, 0.98, -0.72)
    body.addChildNode(seat)
    let wing = glossy(
      SCNBox(width: 1.36, height: 0.07, length: 0.36, chamferRadius: 0.03), Palette.cream)
    wing.position = SCNVector3(0, 1.08, -1.02)
    body.addChildNode(wing)
    for x in [-0.5, 0.5] {
      let strut = box(0.08, 0.36, 0.08, dark, radius: 0.02)
      strut.position = SCNVector3(x, 0.88, -1.0)
      body.addChildNode(strut)
    }
    let wheel = node(SCNTorus(ringRadius: 0.16, pipeRadius: 0.035), UIColor(white: 0.2, alpha: 1))
    wheel.position = SCNVector3(0, 1.0, 0.12)
    wheel.eulerAngles.x = -1.1
    body.addChildNode(wheel)
    var wheels: [SCNNode] = []
    for x in [-0.74, 0.74] {
      for z in [-0.66, 0.68] {
        let pivot = SCNNode()
        pivot.position = SCNVector3(x, 0.33, z)
        let tire = node(SCNCylinder(radius: 0.33, height: 0.3), UIColor(white: 0.13, alpha: 1))
        tire.geometry?.firstMaterial?.roughness.contents = 0.95
        tire.eulerAngles.z = .pi / 2
        pivot.addChildNode(tire)
        let hub = glossy(SCNCylinder(radius: 0.17, height: 0.32), Palette.cream)
        hub.eulerAngles.z = .pi / 2
        pivot.addChildNode(hub)
        for spoke in 0..<4 {
          let bar = box(0.04, 0.26, 0.05, Palette.green, radius: 0.01)
          bar.position = SCNVector3(x > 0 ? 0.165 : -0.165, 0, 0)
          bar.eulerAngles.x = Float(spoke) * .pi / 4
          pivot.addChildNode(bar)
        }
        let flatWheel = pivot.flattenedClone()
        group.addChildNode(flatWheel)
        wheels.append(flatWheel)
      }
    }
    let fur = [
      Palette.cream, UIColor(red: 0.73, green: 0.44, blue: 0.28, alpha: 1),
      UIColor(red: 0.42, green: 0.42, blue: 0.46, alpha: 1), UIColor(white: 0.93, alpha: 1),
    ][animal]
    let torso = node(SCNSphere(radius: 0.36), fur)
    torso.position = SCNVector3(0, 0.95, -0.3)
    body.addChildNode(torso)
    let shirt = glossy(SCNSphere(radius: 0.31), dark)
    shirt.scale = SCNVector3(1.05, 0.7, 1.05)
    shirt.position = SCNVector3(0, 0.98, -0.3)
    body.addChildNode(shirt)
    let head = node(SCNSphere(radius: 0.4), fur)
    head.position = SCNVector3(0, 1.5, -0.25)
    body.addChildNode(head)
    if animal == 3 {
      for i in 0..<6 {
        let t = Double(i) / 6 * .pi * 2
        let curl = node(SCNSphere(radius: 0.15), UIColor.white)
        curl.position = SCNVector3(cos(t) * 0.3, 1.85, -0.25 + sin(t) * 0.3)
        body.addChildNode(curl)
      }
    }
    let muzzle = node(SCNSphere(radius: 0.16), Palette.shade(fur, 1.06))
    muzzle.scale = SCNVector3(1.3, 0.9, 0.9)
    muzzle.position = SCNVector3(0, 1.42, 0.08)
    body.addChildNode(muzzle)
    let noseTip = glossy(SCNSphere(radius: 0.05), animal == 2 ? Palette.pink : Palette.green)
    noseTip.position = SCNVector3(0, 1.47, 0.22)
    body.addChildNode(noseTip)
    for x in [-0.23, 0.23] {
      let ear: SCNNode
      switch animal {
      case 0:
        ear = node(SCNCapsule(capRadius: 0.12, height: 0.7), fur)
        ear.position = SCNVector3(x, 2.02, -0.3)
        ear.eulerAngles.z = Float(x * -0.7)
        let inner = node(SCNCapsule(capRadius: 0.06, height: 0.45), Palette.pink)
        inner.position = SCNVector3(0, 0.02, 0.07)
        ear.addChildNode(inner)
      case 1:
        ear = node(SCNSphere(radius: 0.15), fur)
        ear.position = SCNVector3(x * 1.3, 1.8, -0.3)
      case 2:
        ear = node(SCNCone(topRadius: 0, bottomRadius: 0.15, height: 0.34), fur)
        ear.position = SCNVector3(x * 1.2, 1.9, -0.3)
        ear.eulerAngles.z = Float(x * -0.5)
      default:
        ear = node(SCNCapsule(capRadius: 0.09, height: 0.36), fur)
        ear.position = SCNVector3(x * 1.6, 1.6, -0.3)
        ear.eulerAngles.z = Float(x * 1.6)
      }
      body.addChildNode(ear)
      let eye = glossy(SCNSphere(radius: 0.05), Palette.deepGreen)
      eye.position = SCNVector3(x * 0.7, 1.56, 0.1)
      body.addChildNode(eye)
      let cheek = node(SCNSphere(radius: 0.07), Palette.pink)
      cheek.scale.z = 0.3
      cheek.position = SCNVector3(x * 1.05, 1.4, 0.06)
      body.addChildNode(cheek)
    }
    let scarf = node(
      SCNTorus(ringRadius: 0.25, pipeRadius: 0.07),
      [Palette.green, Palette.cream, Palette.butter, Palette.pink][animal])
    scarf.position = SCNVector3(0, 1.17, -0.25)
    body.addChildNode(scarf)
    let helmet = glossy(
      SCNSphere(radius: 0.43), [Palette.green, Palette.cream, Palette.butter, Palette.blue][animal])
    helmet.scale = SCNVector3(1, 0.62, 1)
    helmet.position = SCNVector3(0, 1.72, -0.26)
    body.addChildNode(helmet)
    let helmetTrim = node(SCNTorus(ringRadius: 0.41, pipeRadius: 0.04), Palette.cream)
    helmetTrim.position = SCNVector3(0, 1.66, -0.26)
    body.addChildNode(helmetTrim)
    let flatBody = body.flattenedClone()
    group.replaceChildNode(body, with: flatBody)
    return (group, flatBody, wheels)
  }

  func update(race: RaceEngine, racing: Bool, reducedMotion: Bool) {
    let dt = max(0, race.elapsed - lastElapsed)
    lastElapsed = race.elapsed
    for (index, kart) in karts.enumerated() {
      kart.isHidden = index >= race.drivers.count
      guard index < race.drivers.count else { continue }
      let driver = race.drivers[index]
      kart.position = SCNVector3(driver.point.x, 0.06, driver.point.z)
      let slide = index == 0 && race.drifting ? race.steering * 0.24 : 0
      kart.eulerAngles.y = Float(driver.heading - slide)
      wheelSpin[index] += driver.speed * dt / 0.33
      for wheel in wheels[index] { wheel.eulerAngles.x = Float(wheelSpin[index]) }
      let lean = index == 0 ? race.steering * 0.07 : 0
      let bob =
        reducedMotion
        ? 0 : sin(race.elapsed * 21 + Double(index)) * 0.008 * min(1, driver.speed / 10)
      bodies[index].eulerAngles.z = Float(lean)
      bodies[index].position.y = Float(bob)
    }
    let boosting = race.player.boost > 0
    for node in boostNodes { node.isHidden = !boosting }
    updateSparks(race: race, dt: dt, reducedMotion: reducedMotion)
    for (index, node) in itemNodes.enumerated() {
      node.isHidden = race.player.lastItemZone == race.player.tracker.laps * 3 + index
      if !reducedMotion {
        for item in node.childNodes {
          item.eulerAngles.y = Float(race.elapsed * 1.2)
          item.position.y = Float(1.3 + sin(race.elapsed * 2.2 + Double(index)) * 0.12)
        }
      }
    }
    if !reducedMotion { clouds.eulerAngles.y = Float(race.elapsed * 0.004) }
    if racing {
      camera.camera?.usesOrthographicProjection = false
      let driver = race.player
      let target = SCNVector3(
        driver.point.x - sin(driver.heading) * 9.6,
        6.3,
        driver.point.z - cos(driver.heading) * 9.6)
      let blend: Float = cameraReady ? 0.11 : 1
      camera.position = SCNVector3(
        camera.position.x + (target.x - camera.position.x) * blend,
        camera.position.y + (target.y - camera.position.y) * blend,
        camera.position.z + (target.z - camera.position.z) * blend)
      camera.look(
        at: SCNVector3(
          driver.point.x + sin(driver.heading) * 6, 0.4, driver.point.z + cos(driver.heading) * 6),
        up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
      let fov = camera.camera?.fieldOfView ?? 57
      camera.camera?.fieldOfView = fov + ((boosting ? 63 : 57) - fov) * 0.08
      cameraReady = true
    } else {
      cameraReady = false
      camera.camera?.usesOrthographicProjection = true
      camera.camera?.orthographicScale = 79
      camera.camera?.fieldOfView = 57
      camera.position = SCNVector3(-70, 105, 105)
      camera.look(
        at: SCNVector3(0, 0, 0),
        up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
    }
  }
}
