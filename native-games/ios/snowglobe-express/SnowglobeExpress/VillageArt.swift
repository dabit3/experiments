import SceneKit
import SwiftUI
import UIKit

enum Winter {
  static let midnight = Color(red: 0.045, green: 0.105, blue: 0.12)
  static let ink = Color(red: 0.13, green: 0.24, blue: 0.26)
  static let powder = Color(red: 0.65, green: 0.77, blue: 0.77)
  static let cream = Color(red: 0.96, green: 0.94, blue: 0.87)
  static let amber = Color(red: 0.83, green: 0.69, blue: 0.43)
  static let cranberry = Color(red: 0.53, green: 0.15, blue: 0.21)
}

struct WinterBackdrop: View {
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Winter.midnight
        RadialGradient(
          colors: [Color(red: 0.16, green: 0.28, blue: 0.29), Winter.midnight],
          center: UnitPoint(x: 0.5, y: 0.37), startRadius: 0,
          endRadius: geometry.size.height * 0.65)
        Canvas { context, size in
          for index in 0..<1800 {
            let x = CGFloat((index * 97 + 21) % 997) / 997 * size.width
            let y = CGFloat((index * 137 + 49) % 991) / 991 * size.height
            context.fill(
              Path(ellipseIn: CGRect(x: x, y: y, width: 0.7, height: 0.7)),
              with: .color(Winter.cream.opacity(0.045)))
          }
        }
      }
    }
    .ignoresSafeArea()
  }
}

struct VillageArt: View {
  let journey: Journey
  var selected: Direction?
  var illuminated = false
  var animate = true
  var showsMarkers = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      GeometryReader { geometry in
        if animate {
          VillageSceneView(
            journey: journey, selected: selected, illuminated: illuminated,
            animate: !reduceMotion, showsMarkers: showsMarkers)
        } else {
          Image(uiImage: VillageScene.postcard(journey: journey, illuminated: illuminated))
            .resizable().scaledToFit()
        }
        Ellipse()
          .fill(.white.opacity(0.035))
          .frame(width: geometry.size.width * 0.035, height: geometry.size.height * 0.22)
          .rotationEffect(.degrees(28))
          .position(x: geometry.size.width * 0.16, y: geometry.size.height * 0.27)
          .blur(radius: 2)
      }
    }
    .aspectRatio(1.12, contentMode: .fit)
    .allowsHitTesting(false)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "Snow globe village. Van at column \(journey.position.van.column + 1), row \(journey.position.van.row + 1). \(journey.position.delivered.count) of 3 homes lit."
    )
  }
}

private struct VillageSceneView: UIViewRepresentable {
  let journey: Journey
  let selected: Direction?
  let illuminated: Bool
  let animate: Bool
  let showsMarkers: Bool

  final class Coordinator {
    var model: VillageScene
    init(journey: Journey) { model = VillageScene(journey: journey) }
  }

  func makeCoordinator() -> Coordinator { Coordinator(journey: journey) }

  func makeUIView(context: Context) -> SCNView {
    let view = SCNView(frame: .zero)
    view.backgroundColor = .clear
    view.isOpaque = false
    view.antialiasingMode = .multisampling4X
    view.preferredFramesPerSecond = 30
    view.isUserInteractionEnabled = false
    return view
  }

  func updateUIView(_ view: SCNView, context: Context) {
    if context.coordinator.model.puzzle != journey.puzzle {
      context.coordinator.model = VillageScene(journey: journey)
    }
    let model = context.coordinator.model
    if view.scene !== model.scene {
      view.scene = model.scene
      view.pointOfView = model.camera
    }
    model.update(
      journey: journey, selected: selected, illuminated: illuminated, animate: animate,
      showsMarkers: showsMarkers)
    view.isPlaying = animate
    view.rendersContinuously = animate
    model.scene.isPaused = !animate
  }
}

private final class VillageScene {
  let puzzle: Puzzle
  let scene = SCNScene()
  let camera = SCNNode()
  private let details = SCNNode()
  private let van = SCNNode()
  private let preview = SCNNode()
  private var position: Position?
  private var glowing = false
  private var markersVisible = true
  private let snow = UIColor(red: 0.82, green: 0.88, blue: 0.86, alpha: 1)
  private let porcelain = UIColor(red: 0.91, green: 0.86, blue: 0.71, alpha: 1)
  private let red = UIColor(red: 0.48, green: 0.07, blue: 0.13, alpha: 1)
  private let pine = UIColor(red: 0.08, green: 0.23, blue: 0.22, alpha: 1)
  private let gold = UIColor(red: 0.65, green: 0.45, blue: 0.20, alpha: 1)

  init(journey: Journey) {
    puzzle = journey.puzzle
    configureLight()
    pedestal()
    glassDome()
    for row in 0..<5 {
      for column in 0..<5 {
        let square = Square(column: column, row: row)
        let tile = box(
          0.985, 0.07, 0.985,
          color: UIColor(
            red: 0.36 + Double((row + column) % 3) * 0.012, green: 0.46, blue: 0.45,
            alpha: 1), bevel: 0.035)
        tile.position = point(square, height: 0.035)
        scene.rootNode.addChildNode(tile)
        if puzzle.trees.contains(square) {
          let tree = fir()
          tree.position = point(square)
          scene.rootNode.addChildNode(tree)
        }
      }
    }
    scene.rootNode.addChildNode(details)
    makeVan()
    scene.rootNode.addChildNode(van)
    let geometry = SCNBox(width: 0.92, height: 0.025, length: 0.92, chamferRadius: 0.10)
    let finish = material(gold, metal: 0.35)
    finish.emission.contents = UIColor(red: 0.35, green: 0.20, blue: 0.06, alpha: 1)
    geometry.firstMaterial = finish
    preview.geometry = geometry
    scene.rootNode.addChildNode(preview)
    snowfall()
  }

  private func configureLight() {
    let lens = SCNCamera()
    lens.usesOrthographicProjection = true
    lens.orthographicScale = 3.55
    lens.zFar = 100
    lens.wantsHDR = true
    lens.exposureOffset = -0.1
    lens.bloomIntensity = 0.08
    lens.bloomThreshold = 1.1
    lens.screenSpaceAmbientOcclusionIntensity = 0.8
    lens.screenSpaceAmbientOcclusionRadius = 0.22
    camera.camera = lens
    camera.position = SCNVector3(8, 10.5, 12)
    camera.look(at: SCNVector3(0, 0.35, 0))
    scene.rootNode.addChildNode(camera)
    let ambient = SCNNode()
    ambient.light = SCNLight()
    ambient.light?.type = .ambient
    ambient.light?.color = UIColor(red: 0.76, green: 0.86, blue: 1, alpha: 1)
    ambient.light?.intensity = 350
    scene.rootNode.addChildNode(ambient)
    let key = SCNNode()
    key.light = SCNLight()
    key.light?.type = .directional
    key.light?.intensity = 720
    key.light?.color = UIColor(red: 1, green: 0.91, blue: 0.74, alpha: 1)
    key.light?.castsShadow = true
    key.light?.shadowRadius = 6
    key.light?.shadowSampleCount = 16
    key.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
    key.light?.shadowColor = UIColor(red: 0.035, green: 0.09, blue: 0.12, alpha: 0.48)
    key.position = SCNVector3(-5, 10, 6)
    key.look(at: SCNVector3Zero)
    scene.rootNode.addChildNode(key)
    let fill = SCNNode()
    fill.light = SCNLight()
    fill.light?.type = .omni
    fill.light?.intensity = 130
    fill.light?.color = UIColor(red: 0.73, green: 0.83, blue: 0.86, alpha: 1)
    fill.position = SCNVector3(4, 5, -4)
    scene.rootNode.addChildNode(fill)
  }

  private func pedestal() {
    let base = SCNCylinder(radius: 3.66, height: 0.44)
    base.radialSegmentCount = 96
    base.firstMaterial = material(pine, metal: 0.3)
    let node = SCNNode(geometry: base)
    node.position.y = -0.46
    scene.rootNode.addChildNode(node)
    for height: Float in [-0.68, -0.25] {
      let ring = SCNTorus(ringRadius: 3.65, pipeRadius: 0.025)
      ring.ringSegmentCount = 96
      ring.firstMaterial = material(gold, metal: 0.7)
      let rim = SCNNode(geometry: ring)
      rim.position.y = height
      scene.rootNode.addChildNode(rim)
    }
    let snowfield = SCNCylinder(radius: 3.61, height: 0.24)
    snowfield.radialSegmentCount = 96
    snowfield.firstMaterial = material(snow)
    let ground = SCNNode(geometry: snowfield)
    ground.position.y = -0.15
    scene.rootNode.addChildNode(ground)
    for index in 0..<45 {
      let angle = Double(index) * .pi * 2 / 45
      let radius = 3.16 + Double((index * 13) % 7) * 0.012
      let mound = orb(0.28 + CGFloat((index * 7) % 5) * 0.035, color: snow)
      mound.scale = SCNVector3(1, 0.20, 1)
      mound.position = SCNVector3(cos(angle) * radius, -0.055, sin(angle) * radius)
      mound.castsShadow = false
      scene.rootNode.addChildNode(mound)
    }
  }

  private func glassDome() {
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var indices: [Int32] = []
    let segments = 64
    let rings = 24
    for ring in 0...rings {
      let latitude = Double(ring) / Double(rings) * .pi / 2
      for segment in 0...segments {
        let longitude = Double(segment) / Double(segments) * .pi * 2
        let x = sin(latitude) * cos(longitude)
        let z = sin(latitude) * sin(longitude)
        vertices.append(SCNVector3(x * 3.59, cos(latitude) * 2.8 - 0.04, z * 3.59))
        normals.append(SCNVector3(x / 3.59, cos(latitude) / 2.8, z / 3.59))
        if ring < rings && segment < segments {
          let a = Int32(ring * (segments + 1) + segment)
          let b = a + Int32(segments + 1)
          indices.append(contentsOf: [a, a + 1, b, a + 1, b + 1, b])
        }
      }
    }
    let geometry = SCNGeometry(
      sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)],
      elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
    let glass = SCNMaterial()
    glass.lightingModel = .constant
    glass.diffuse.contents = UIColor.white
    glass.writesToDepthBuffer = false
    glass.blendMode = .alpha
    glass.shaderModifiers = [
      .fragment: """
      #pragma transparent
      #pragma body
      float edge = pow(1.0 - abs(dot(normalize(_surface.normal), normalize(_surface.view))), 3.0);
        float alpha = edge * 0.22;
        _output.color = float4(float3(0.70, 0.83, 0.84) * alpha, alpha);
      """
    ]
    geometry.firstMaterial = glass
    let dome = SCNNode(geometry: geometry)
    dome.castsShadow = false
    dome.renderingOrder = 100
    scene.rootNode.addChildNode(dome)
  }

  func update(
    journey: Journey, selected: Direction?, illuminated: Bool, animate: Bool,
    showsMarkers: Bool = true
  ) {
    if position != journey.position || glowing != illuminated || markersVisible != showsMarkers {
      for child in details.childNodes { child.removeFromParentNode() }
      for (index, home) in puzzle.homes.enumerated() {
        let lit = illuminated || journey.position.delivered.contains(home.square)
        let cottage = house(index: index, lit: lit)
        cottage.position = point(home.square, height: 0.07)
        details.addChildNode(cottage)
        let sign = badge(lit ? "✓" : "\(index + 1)", color: lit ? gold : index == 0 ? red : pine)
        sign.position = point(home.square, height: 1.58)
        sign.isHidden = !showsMarkers
        details.addChildNode(sign)
      }
      for index in 0..<25 where journey.position.snow[index] > 0 {
        let square = Square(column: index % 5, row: index / 5)
        let depth = journey.position.snow[index]
        for layer in 0..<depth {
          let drift = box(0.75, 0.12, 0.72, color: snow, bevel: 0.06)
          drift.position = point(square, height: 0.13 + Float(layer) * 0.10)
          drift.eulerAngles.y = Float(layer) * 0.08
          details.addChildNode(drift)
        }
        let marker = badge(
          "\(depth)", color: UIColor(red: 0.19, green: 0.31, blue: 0.34, alpha: 1), snowDepth: true)
        marker.scale = SCNVector3(0.95, 0.95, 0.95)
        marker.position = point(square, height: Float(depth) * 0.10 + 0.29)
        marker.isHidden = !showsMarkers
        details.addChildNode(marker)
      }
      var destination = point(journey.position.van, height: 0.09)
      if puzzle.homes.contains(where: { $0.square == journey.position.van }) {
        destination.x -= 0.66
        destination.z += 0.18
      }
      SCNTransaction.begin()
      SCNTransaction.animationDuration = animate && position != nil ? 0.32 : 0
      SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      van.position = destination
      if let prior = journey.history.last {
        let dx = journey.position.van.column - prior.van.column
        let dz = journey.position.van.row - prior.van.row
        van.eulerAngles.y = Float(atan2(Double(dx), Double(dz)))
      }
      SCNTransaction.commit()
      position = journey.position
      glowing = illuminated
      markersVisible = showsMarkers
    }
    preview.isHidden = selected == nil || !(selected.map { journey.preview($0).allowed } ?? false)
    if let selected { preview.position = point(journey.position.van.next(selected), height: 0.083) }
  }

  private func house(index: Int, lit: Bool) -> SCNNode {
    let cottage = SCNNode()
    let wallColor = index == 1 ? UIColor(red: 0.60, green: 0.74, blue: 0.74, alpha: 1) : porcelain
    let body = box(0.70, 0.72, 0.65, color: wallColor, bevel: 0.045)
    body.position.y = 0.36
    cottage.addChildNode(body)
    let gable = UIBezierPath()
    gable.move(to: CGPoint(x: -0.39, y: 0))
    gable.addLine(to: CGPoint(x: 0, y: 0.40))
    gable.addLine(to: CGPoint(x: 0.39, y: 0))
    gable.close()
    let attic = SCNShape(path: gable, extrusionDepth: 0.66)
    attic.firstMaterial = material(wallColor)
    let atticNode = SCNNode(geometry: attic)
    atticNode.position.y = 0.71
    cottage.addChildNode(atticNode)
    for side: Float in [-1, 1] {
      let roof = box(0.62, 0.10, 0.84, color: index == 0 ? red : pine, bevel: 0.035)
      roof.position = SCNVector3(side * 0.21, 0.92, 0)
      roof.eulerAngles.z = -side * .pi / 4
      cottage.addChildNode(roof)
      let cap = box(0.62, 0.065, 0.86, color: snow, bevel: 0.032)
      cap.position = SCNVector3(side * 0.21, 0.98, 0)
      cap.eulerAngles.z = -side * .pi / 4
      cottage.addChildNode(cap)
    }
    let chimney = box(0.15, 0.33, 0.17, color: wallColor, bevel: 0.015)
    chimney.position = SCNVector3(0.20, 1.16, -0.15)
    cottage.addChildNode(chimney)
    let chimneyCap = box(0.21, 0.06, 0.22, color: snow, bevel: 0.025)
    chimneyCap.position = SCNVector3(0.20, 1.34, -0.15)
    cottage.addChildNode(chimneyCap)
    let door = box(0.16, 0.31, 0.04, color: index == 0 ? red : pine, bevel: 0.03)
    door.position = SCNVector3(0, 0.17, 0.34)
    cottage.addChildNode(door)
    let handle = orb(0.018, color: gold)
    handle.position = SCNVector3(0.045, 0.17, 0.37)
    cottage.addChildNode(handle)
    for x: Float in [-0.23, 0.23] {
      let window = window(lit: lit)
      window.position = SCNVector3(x, 0.47, 0.34)
      cottage.addChildNode(window)
    }
    for z: Float in [-0.16, 0.16] {
      let window = window(lit: lit)
      window.position = SCNVector3(0.36, 0.47, z)
      window.eulerAngles.y = .pi / 2
      cottage.addChildNode(window)
    }
    let atticWindow = window(lit: lit)
    atticWindow.scale = SCNVector3(0.65, 0.65, 0.65)
    atticWindow.position = SCNVector3(0, 0.85, 0.34)
    cottage.addChildNode(atticWindow)
    if index == 0 {
      for stripe in 0..<5 {
        let awning = box(
          0.085, 0.055, 0.19, color: stripe.isMultiple(of: 2) ? red : snow, bevel: 0.012)
        awning.position = SCNVector3(Float(stripe - 2) * 0.085, 0.36, 0.43)
        awning.eulerAngles.x = 0.12
        cottage.addChildNode(awning)
      }
    }
    let doorstep = box(0.25, 0.05, 0.21, color: snow, bevel: 0.025)
    doorstep.position = SCNVector3(0, 0.02, 0.40)
    cottage.addChildNode(doorstep)
    if lit {
      let lamp = SCNNode()
      lamp.light = SCNLight()
      lamp.light?.type = .omni
      lamp.light?.color = UIColor(red: 1, green: 0.56, blue: 0.18, alpha: 1)
      lamp.light?.intensity = 0.45
      lamp.light?.attenuationFalloffExponent = 1
      lamp.light?.attenuationStartDistance = 0.2
      lamp.light?.attenuationEndDistance = 1.1
      lamp.position = SCNVector3(0, 0.35, 0.65)
      cottage.addChildNode(lamp)
    }
    return cottage
  }

  private func window(lit: Bool) -> SCNNode {
    let frame = box(0.17, 0.23, 0.035, color: porcelain, bevel: 0.015)
    let glass = box(
      0.12, 0.18, 0.012,
      color: lit ? UIColor(red: 1, green: 0.63, blue: 0.22, alpha: 1) : pine, bevel: 0.008)
    glass.geometry?.firstMaterial?.emission.contents =
      lit ? UIColor(red: 0.65, green: 0.29, blue: 0.055, alpha: 1) : UIColor.black
    glass.position.z = 0.025
    frame.addChildNode(glass)
    let mullion = box(0.014, 0.18, 0.014, color: porcelain, bevel: 0)
    mullion.position.z = 0.04
    frame.addChildNode(mullion)
    let crossbar = box(0.12, 0.014, 0.014, color: porcelain, bevel: 0)
    crossbar.position.z = 0.04
    frame.addChildNode(crossbar)
    return frame
  }

  private func fir() -> SCNNode {
    let tree = SCNNode()
    let trunk = SCNCylinder(radius: 0.055, height: 0.35)
    trunk.firstMaterial = material(gold)
    let wood = SCNNode(geometry: trunk)
    wood.position.y = 0.18
    tree.addChildNode(wood)
    for layer in 0..<6 {
      let radius = 0.34 - CGFloat(layer) * 0.047
      let cone = SCNCone(topRadius: 0, bottomRadius: radius, height: 0.47)
      cone.radialSegmentCount = 7
      cone.firstMaterial = material(pine)
      let branch = SCNNode(geometry: cone)
      branch.position.y = 0.36 + Float(layer) * 0.13
      branch.eulerAngles.y = Float(layer) * 0.63
      branch.scale = SCNVector3(1, 1, 0.86)
      tree.addChildNode(branch)
      for patch in 0..<3 {
        let angle = Double(patch) * 2.1 + Double(layer) * 0.7
        let powder = orb(radius * 0.48, color: snow)
        powder.scale = SCNVector3(1.15, 0.24, 0.85)
        powder.position = SCNVector3(
          cos(angle) * Double(radius) * 0.65, Double(branch.position.y) - 0.055,
          sin(angle) * Double(radius) * 0.65)
        tree.addChildNode(powder)
      }
    }
    return tree
  }

  private func makeVan() {
    let body = box(0.48, 0.31, 0.65, color: red, bevel: 0.08)
    body.position.y = 0.27
    van.addChildNode(body)
    let roof = box(0.46, 0.045, 0.49, color: snow, bevel: 0.02)
    roof.position = SCNVector3(0, 0.44, -0.045)
    van.addChildNode(roof)
    let windshield = box(
      0.36, 0.13, 0.025, color: UIColor(red: 0.53, green: 0.73, blue: 0.78, alpha: 1), bevel: 0.025)
    windshield.position = SCNVector3(0, 0.33, 0.322)
    van.addChildNode(windshield)
    for side: Float in [-1, 1] {
      for z: Float in [-0.20, 0.20] {
        let wheel = SCNCylinder(radius: 0.10, height: 0.07)
        wheel.firstMaterial = material(pine)
        let tire = SCNNode(geometry: wheel)
        tire.eulerAngles.z = .pi / 2
        tire.position = SCNVector3(side * 0.245, 0.12, z)
        van.addChildNode(tire)
        let hub = orb(0.042, color: porcelain)
        hub.scale.x = 0.3
        hub.position = SCNVector3(side * 0.287, 0.12, z)
        van.addChildNode(hub)
      }
      let lamp = orb(0.04, color: porcelain)
      lamp.position = SCNVector3(side * 0.16, 0.20, 0.34)
      lamp.geometry?.firstMaterial?.emission.contents = UIColor(
        red: 0.7, green: 0.43, blue: 0.1, alpha: 1)
      van.addChildNode(lamp)
      let parcelMark = box(0.012, 0.13, 0.17, color: porcelain, bevel: 0.012)
      parcelMark.position = SCNVector3(side * 0.245, 0.29, -0.13)
      van.addChildNode(parcelMark)
    }
    let plow = box(0.66, 0.17, 0.075, color: gold, bevel: 0.025)
    plow.position = SCNVector3(0, 0.1, 0.44)
    plow.eulerAngles.x = -0.25
    van.addChildNode(plow)
    let parcel = box(0.18, 0.12, 0.21, color: gold, bevel: 0.02)
    parcel.position = SCNVector3(0.03, 0.52, -0.1)
    van.addChildNode(parcel)
    let ribbon = box(0.025, 0.125, 0.215, color: porcelain, bevel: 0.004)
    ribbon.position = parcel.position
    van.addChildNode(ribbon)
  }

  private func snowfall() {
    for index in 0..<30 {
      let flake = orb(index.isMultiple(of: 3) ? 0.017 : 0.01, color: snow)
      let x = Float((index * 71) % 100) / 24 - 2
      let z = Float((index * 37) % 100) / 24 - 2
      flake.position = SCNVector3(x, 1.4 + Float((index * 13) % 100) / 65, z)
      flake.opacity = 0.35 + CGFloat(index % 3) * 0.15
      let drift = SCNAction.sequence([
        .moveBy(x: 0.10, y: -0.24, z: 0, duration: 3 + Double(index % 4)),
        .moveBy(x: -0.10, y: 0.24, z: 0, duration: 3 + Double(index % 4)),
      ])
      flake.runAction(.repeatForever(drift))
      scene.rootNode.addChildNode(flake)
    }
  }

  private func badge(_ text: String, color: UIColor, snowDepth: Bool = false) -> SCNNode {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    let image = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64), format: format).image {
      _ in
      color.setFill()
      let outline =
        snowDepth
        ? UIBezierPath(roundedRect: CGRect(x: 1, y: 13, width: 62, height: 38), cornerRadius: 12)
        : UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 58, height: 58))
      outline.fill()
      porcelain.setStroke()
      outline.lineWidth = 1.5
      outline.stroke()
      if snowDepth {
        UIImage(systemName: "snowflake")?
          .withTintColor(.white, renderingMode: .alwaysOriginal)
          .draw(in: CGRect(x: 8, y: 23, width: 18, height: 18))
      }
      let attributes: [NSAttributedString.Key: NSObject] = [
        .font: UIFont.systemFont(ofSize: snowDepth ? 26 : 32, weight: .semibold),
        .foregroundColor: UIColor.white,
      ]
      let size = (text as NSString).size(withAttributes: attributes)
      (text as NSString).draw(
        at: CGPoint(x: snowDepth ? 34 : (64 - size.width) / 2, y: (64 - size.height) / 2),
        withAttributes: attributes)
    }
    let plane = SCNPlane(width: 0.36, height: 0.36)
    let finish = SCNMaterial()
    finish.diffuse.contents = image
    finish.lightingModel = .constant
    finish.isDoubleSided = true
    finish.readsFromDepthBuffer = false
    finish.writesToDepthBuffer = false
    plane.firstMaterial = finish
    let node = SCNNode(geometry: plane)
    node.renderingOrder = 200
    node.constraints = [SCNBillboardConstraint()]
    return node
  }

  private func material(_ color: UIColor, metal: CGFloat = 0) -> SCNMaterial {
    let finish = SCNMaterial()
    finish.diffuse.contents = color
    finish.lightingModel = .physicallyBased
    finish.roughness.contents = metal > 0 ? 0.45 : 0.85
    finish.metalness.contents = metal
    return finish
  }

  private func box(
    _ width: CGFloat, _ height: CGFloat, _ length: CGFloat, color: UIColor, bevel: CGFloat
  ) -> SCNNode {
    let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: bevel)
    geometry.firstMaterial = material(color)
    return SCNNode(geometry: geometry)
  }

  private func orb(_ radius: CGFloat, color: UIColor) -> SCNNode {
    let sphere = SCNSphere(radius: radius)
    sphere.segmentCount = 24
    sphere.firstMaterial = material(color)
    return SCNNode(geometry: sphere)
  }

  private func point(_ square: Square, height: Float = 0) -> SCNVector3 {
    SCNVector3(Float(square.column - 2), height, Float(square.row - 2))
  }

  static func postcard(journey: Journey, illuminated: Bool) -> UIImage {
    let model = VillageScene(journey: journey)
    model.update(
      journey: journey, selected: nil, illuminated: illuminated, animate: false, showsMarkers: false
    )
    let renderer = SCNRenderer(device: nil, options: nil)
    renderer.scene = model.scene
    renderer.pointOfView = model.camera
    return renderer.snapshot(
      atTime: 0, with: CGSize(width: 1120, height: 1000), antialiasingMode: .multisampling4X)
  }
}
