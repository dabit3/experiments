import SceneKit
import SwiftUI
import UIKit

@MainActor
final class SceneCapture: ObservableObject {
  weak var view: SCNView?

  func exportImage() throws -> URL {
    guard let data = view?.snapshot().pngData() else { throw CocoaError(.fileWriteUnknown) }
    let directory = URL.documentsDirectory.appendingPathComponent("Exports")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("TerraTable.png")
    try data.write(to: url, options: .atomic)
    return url
  }
}

struct TerrainCanvas: UIViewRepresentable {
  @ObservedObject var model: StudioModel
  let capture: SceneCapture

  func makeCoordinator() -> Coordinator { Coordinator(model: model) }

  func makeUIView(context: Context) -> SCNView {
    let view = SCNView()
    view.backgroundColor = UIColor(red: 0.935, green: 0.935, blue: 0.910, alpha: 1)
    view.antialiasingMode = .multisampling4X
    view.preferredFramesPerSecond = 30
    view.isPlaying = true
    view.autoenablesDefaultLighting = false
    view.accessibilityLabel = "Interactive terrain. Drag to sculpt; select Orbit to rotate."
    view.accessibilityIdentifier = "terrainCanvas"
    context.coordinator.install(in: view)
    capture.view = view
    return view
  }

  func updateUIView(_ view: SCNView, context: Context) {
    context.coordinator.update()
  }

  @MainActor
  final class Coordinator: NSObject {
    let model: StudioModel
    weak var view: SCNView?
    let scene = SCNScene()
    let terrainNode = SCNNode()
    let waterNode = SCNNode()
    let skirtNode = SCNNode()
    let cameraNode = SCNNode()
    let cursorNode = SCNNode()
    let waterMaterial = SCNMaterial()
    let terrainMaterial = SCNMaterial()
    var lastRevision = -1
    var lastContours = false
    var lastHome = 0
    var yaw: Float = .pi / 4
    var pitch: Float = 0.66
    var lastDrag = CGPoint.zero
    var lastPoint: SCNVector3?
    var pinchStart: Float = 1

    init(model: StudioModel) { self.model = model }

    func install(in view: SCNView) {
      self.view = view
      view.scene = scene
      scene.rootNode.addChildNode(terrainNode)
      terrainNode.name = "terrain"
      scene.rootNode.addChildNode(skirtNode)
      let base = SCNBox(width: 10.16, height: 0.22, length: 10.16, chamferRadius: 0.035)
      base.firstMaterial?.diffuse.contents = UIColor(red: 0.28, green: 0.32, blue: 0.28, alpha: 1)
      let baseNode = SCNNode(geometry: base)
      baseNode.position.y = -0.13
      scene.rootNode.addChildNode(baseNode)

      let floor = SCNFloor()
      floor.reflectivity = 0
      floor.firstMaterial?.diffuse.contents = UIColor(
        red: 0.935, green: 0.935, blue: 0.910, alpha: 1)
      floor.firstMaterial?.lightingModel = .constant
      let floorNode = SCNNode(geometry: floor)
      floorNode.position.y = -0.26
      scene.rootNode.addChildNode(floorNode)

      let shadowImage = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256)).image {
        context in
        let colors = [UIColor.black.withAlphaComponent(0.16).cgColor, UIColor.clear.cgColor]
        if let gradient = CGGradient(
          colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])
        {
          context.cgContext.drawRadialGradient(
            gradient, startCenter: CGPoint(x: 128, y: 128), startRadius: 50,
            endCenter: CGPoint(x: 128, y: 128), endRadius: 128, options: [])
        }
      }
      let shadow = SCNPlane(width: 14, height: 14)
      shadow.firstMaterial?.diffuse.contents = shadowImage
      shadow.firstMaterial?.lightingModel = .constant
      shadow.firstMaterial?.writesToDepthBuffer = false
      let shadowNode = SCNNode(geometry: shadow)
      shadowNode.eulerAngles.x = -.pi / 2
      shadowNode.position = SCNVector3(0.35, -0.25, 0.35)
      scene.rootNode.addChildNode(shadowNode)

      let water = SCNBox(width: 10.02, height: 0.035, length: 10.02, chamferRadius: 0)
      waterMaterial.diffuse.contents = UIColor(red: 0.25, green: 0.61, blue: 0.60, alpha: 1)
      waterMaterial.metalness.contents = 0.12
      waterMaterial.roughness.contents = 0.28
      waterMaterial.lightingModel = .constant
      waterMaterial.shaderModifiers = [
        .surface: """
        #pragma arguments
        float ambientMotion;
        float studyTime;
        #pragma body
        float t = scn_frame.time * ambientMotion + studyTime;
        float2 p = _surface.diffuseTexcoord * 10.0;
        float swell = sin(p.x * 2.1 + p.y * 1.3 + t * 0.45)
                    + sin(p.y * 3.7 - p.x * 0.8 - t * 0.33);
        float detail = sin(p.x * 21.0 + sin(p.y * 7.0 + t * 0.4) * 2.0 + t)
                     * sin(p.y * 17.0 - p.x * 3.0 - t * 0.7);
        float glint = pow(max(0.0, detail), 12.0) * 0.10;
        _surface.diffuse.rgb += float3(0.022, 0.035, 0.031) * swell + glint;
        """
      ]
      let waterSide = SCNMaterial()
      waterSide.diffuse.contents = UIColor(red: 0.29, green: 0.49, blue: 0.48, alpha: 1)
      waterSide.lightingModel = .constant
      water.materials = [waterSide, waterSide, waterSide, waterSide, waterMaterial, waterSide]
      waterNode.geometry = water
      scene.rootNode.addChildNode(waterNode)

      terrainMaterial.diffuse.contents = UIColor.white
      terrainMaterial.roughness.contents = 0.95
      terrainMaterial.lightingModel = .lambert
      terrainMaterial.shaderModifiers = [
        .surface: """
        #pragma arguments
        float waterLevel;
        float contourAmount;
        #pragma body
        float elevation = _surface.diffuseTexcoord.x;
        float level = elevation / 0.15;
        float line = 1.0 - smoothstep(0.025, 0.075, abs(fract(level) - 0.5));
        _surface.diffuse.rgb = mix(_surface.diffuse.rgb,
          float3(0.12, 0.22, 0.18), line * contourAmount * 0.8);
        float shore = 1.0 - smoothstep(0.015, 0.055, abs(elevation - waterLevel));
        _surface.diffuse.rgb = mix(_surface.diffuse.rgb, float3(0.85, 0.92, 0.80), shore * 0.7);
        """
      ]

      let ambient = SCNNode()
      ambient.light = SCNLight()
      ambient.light?.type = .ambient
      ambient.light?.intensity = 450
      ambient.light?.color = UIColor(red: 0.94, green: 0.96, blue: 1, alpha: 1)
      scene.rootNode.addChildNode(ambient)

      let sun = SCNNode()
      sun.light = SCNLight()
      sun.light?.type = .directional
      sun.light?.intensity = 650
      sun.light?.castsShadow = true
      sun.light?.shadowMode = .deferred
      sun.light?.shadowColor = UIColor.black.withAlphaComponent(0.16)
      sun.light?.shadowRadius = 8
      sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
      sun.light?.orthographicScale = 16
      sun.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 5, 0)
      scene.rootNode.addChildNode(sun)

      cameraNode.camera = SCNCamera()
      cameraNode.camera?.usesOrthographicProjection = true
      cameraNode.camera?.zNear = 0.1
      cameraNode.camera?.zFar = 100
      cameraNode.camera?.wantsHDR = false
      scene.rootNode.addChildNode(cameraNode)
      view.pointOfView = cameraNode

      cursorNode.geometry = SCNTorus(ringRadius: CGFloat(model.radius), pipeRadius: 0.018)
      cursorNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
      cursorNode.geometry?.firstMaterial?.emission.contents = UIColor.white
      cursorNode.isHidden = true
      scene.rootNode.addChildNode(cursorNode)

      let pan = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
      pan.maximumNumberOfTouches = 1
      view.addGestureRecognizer(pan)
      view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(_:))))
      view.addGestureRecognizer(
        UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:))))
      update()
    }

    func update() {
      if lastRevision != model.revision || lastContours != model.contours {
        rebuildMesh()
        lastRevision = model.revision
        lastContours = model.contours
      }
      if lastHome != model.homeRevision {
        yaw = .pi / 4
        pitch = 0.66
        lastHome = model.homeRevision
      }
      terrainMaterial.setValue(model.terrain.water * 3, forKey: "waterLevel")
      terrainMaterial.setValue(
        model.journeyActive ? model.journeyFrame.contours : (model.contours ? Float(1) : Float(0)),
        forKey: "contourAmount")
      waterMaterial.setValue(
        model.reducedMotion || model.journeyActive ? Float(0) : Float(1), forKey: "ambientMotion")
      waterMaterial.setValue(
        model.journeyActive && !model.reducedMotion ? Float(model.journeyTime) : Float(0),
        forKey: "studyTime")
      view?.rendersContinuously =
        !model.reducedMotion && (!model.journeyActive || model.journeyPlaying)
      (waterNode.geometry as? SCNBox)?.height = CGFloat(model.terrain.water * 3 + 0.02)
      waterNode.position.y = (model.terrain.water * 3 - 0.02) / 2
      waterNode.isHidden = model.terrain.water < 0.02
      updateCamera()
    }

    func updateCamera() {
      let distance: Float = 20
      let journey = model.journeyFrame
      let cameraYaw = model.journeyActive && !model.reducedMotion ? journey.yaw : yaw
      let cameraPitch = model.journeyActive && !model.reducedMotion ? journey.pitch : pitch
      cameraNode.position = SCNVector3(
        sin(cameraYaw) * cos(cameraPitch) * distance,
        sin(cameraPitch) * distance + 0.5,
        cos(cameraYaw) * cos(cameraPitch) * distance)
      cameraNode.look(
        at: SCNVector3(0, 0.5, 0), up: SCNVector3(0, 1, 0),
        localFront: SCNVector3(0, 0, -1))
      let scale = model.journeyActive && !model.reducedMotion ? journey.scale : model.zoom
      cameraNode.camera?.orthographicScale = Double(7.4 / scale)
    }

    func rebuildMesh() {
      let n = Terrain.resolution
      let heights = model.terrain.heights
      let step: Float = 10 / Float(n - 1)
      var vertices: [SCNVector3] = []
      var normals: [SCNVector3] = []
      var coordinates: [CGPoint] = []
      var colors: [Float] = []
      var indices: [Int32] = []
      for z in 0..<n {
        for x in 0..<n {
          let h = heights[z * n + x]
          vertices.append(SCNVector3(Float(x) * step - 5, h * 3, Float(z) * step - 5))
          coordinates.append(CGPoint(x: CGFloat(h * 3), y: 0))
          let dx = (heights[z * n + min(n - 1, x + 1)] - heights[z * n + max(0, x - 1)]) * 3
          let dz = (heights[min(n - 1, z + 1) * n + x] - heights[max(0, z - 1) * n + x]) * 3
          let length = sqrt(dx * dx + 4 * step * step + dz * dz)
          normals.append(SCNVector3(-dx / length, 2 * step / length, -dz / length))
          let color = terrainColor(h, slope: hypot(dx, dz), water: model.terrain.water)
          colors.append(contentsOf: color)
          if x < n - 1 && z < n - 1 {
            let a = Int32(z * n + x)
            indices.append(contentsOf: [
              a, a + Int32(n), a + 1, a + 1, a + Int32(n), a + Int32(n) + 1,
            ])
          }
        }
      }
      let colorData = colors.withUnsafeBufferPointer { Data(buffer: $0) }
      let colorSource = SCNGeometrySource(
        data: colorData, semantic: .color, vectorCount: vertices.count, usesFloatComponents: true,
        componentsPerVector: 4, bytesPerComponent: 4, dataOffset: 0, dataStride: 16)
      let geometry = SCNGeometry(
        sources: [
          SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals),
          SCNGeometrySource(textureCoordinates: coordinates), colorSource,
        ],
        elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
      geometry.materials = [terrainMaterial]
      terrainNode.geometry = geometry

      var skirtVertices: [SCNVector3] = []
      var skirtIndices: [Int32] = []
      var skirtCoordinates: [CGPoint] = []
      var edge: [Int] = []
      for x in 0..<n { edge.append(x) }
      for z in 1..<n { edge.append(z * n + n - 1) }
      for x in stride(from: n - 2, through: 0, by: -1) { edge.append((n - 1) * n + x) }
      for z in stride(from: n - 2, through: 1, by: -1) { edge.append(z * n) }
      for index in edge {
        let vertex = vertices[index]
        skirtVertices.append(vertex)
        skirtVertices.append(SCNVector3(vertex.x, -0.02, vertex.z))
        skirtCoordinates.append(CGPoint(x: CGFloat(vertex.x + vertex.z), y: CGFloat(vertex.y)))
        skirtCoordinates.append(CGPoint(x: CGFloat(vertex.x + vertex.z), y: -0.02))
      }
      for i in 0..<edge.count {
        let a = Int32(i * 2)
        let b = Int32(((i + 1) % edge.count) * 2)
        skirtIndices.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
      }
      let skirt = SCNGeometry(
        sources: [
          SCNGeometrySource(vertices: skirtVertices),
          SCNGeometrySource(textureCoordinates: skirtCoordinates),
        ],
        elements: [SCNGeometryElement(indices: skirtIndices, primitiveType: .triangles)])
      skirt.firstMaterial?.diffuse.contents = UIColor(red: 0.45, green: 0.44, blue: 0.35, alpha: 1)
      skirt.firstMaterial?.isDoubleSided = true
      skirt.firstMaterial?.shaderModifiers = [
        .surface: """
        float2 p = _surface.diffuseTexcoord;
        float strata = sin(p.y * 55.0 + sin(p.x * 1.4) * 0.8);
        _surface.diffuse.rgb *= 0.88 + strata * 0.12;
        """
      ]
      skirtNode.geometry = skirt
    }

    func terrainColor(_ height: Float, slope: Float, water: Float) -> [Float] {
      let sand: [Float] = [0.79, 0.77, 0.61, 1]
      let moss: [Float] = [0.40, 0.49, 0.30, 1]
      let forest: [Float] = [0.23, 0.35, 0.27, 1]
      let stone: [Float] = [0.64, 0.65, 0.59, 1]
      let snow: [Float] = [0.91, 0.91, 0.86, 1]
      if height < water + 0.045 { return sand }
      if height > 0.80 { return mix(stone, snow, min(1, (height - 0.80) * 5)) }
      if height > 0.56 || slope > 0.25 {
        return mix(forest, stone, min(1, max((height - 0.50) * 3, slope * 2)))
      }
      return mix(moss, forest, min(1, (height - water) * 2.7))
    }

    func mix(_ a: [Float], _ b: [Float], _ amount: Float) -> [Float] {
      zip(a, b).map { $0 + ($1 - $0) * max(0, amount) }
    }

    func terrainPoint(_ location: CGPoint) -> SCNVector3? {
      guard let view else { return nil }
      let hits = view.hitTest(location, options: [.searchMode: SCNHitTestSearchMode.all.rawValue])
      return hits.first(where: { $0.node === terrainNode })?.localCoordinates
    }

    func paint(_ point: SCNVector3) {
      if let previous = lastPoint {
        let distance = hypot(point.x - previous.x, point.z - previous.z)
        let steps = max(1, min(40, Int(distance / 0.09)))
        for i in 1...steps {
          let t = Float(i) / Float(steps)
          model.sculpt(
            x: previous.x + (point.x - previous.x) * t,
            z: previous.z + (point.z - previous.z) * t)
        }
      } else {
        model.sculpt(x: point.x, z: point.z)
      }
      lastPoint = point
      cursorNode.isHidden = false
      cursorNode.position = SCNVector3(
        point.x, max(point.y, model.terrain.water * 3) + 0.04, point.z)
      (cursorNode.geometry as? SCNTorus)?.ringRadius = CGFloat(model.radius)
    }

    @objc func drag(_ gesture: UIPanGestureRecognizer) {
      guard !model.journeyActive else { return }
      let position = gesture.location(in: view)
      if gesture.state == .began {
        lastDrag = position
        lastPoint = nil
        if model.brush != .orbit { model.begin() }
      }
      if gesture.state == .began || gesture.state == .changed {
        if model.brush == .orbit {
          yaw -= Float(position.x - lastDrag.x) * 0.009
          pitch = max(0.24, min(1.35, pitch + Float(position.y - lastDrag.y) * 0.006))
          updateCamera()
        } else if let point = terrainPoint(position) {
          paint(point)
        }
        lastDrag = position
      }
      if [.ended, .cancelled, .failed].contains(gesture.state) {
        model.end()
        lastPoint = nil
        cursorNode.isHidden = true
      }
    }

    @objc func tap(_ gesture: UITapGestureRecognizer) {
      guard !model.journeyActive, model.brush != .orbit,
        let point = terrainPoint(gesture.location(in: view))
      else {
        return
      }
      model.begin()
      for _ in 0..<4 { model.sculpt(x: point.x, z: point.z) }
      model.end()
    }

    @objc func pinch(_ gesture: UIPinchGestureRecognizer) {
      guard !model.journeyActive else { return }
      if gesture.state == .began { pinchStart = model.zoom }
      model.zoom = max(0.7, min(1.8, pinchStart * Float(gesture.scale)))
      updateCamera()
    }
  }
}
