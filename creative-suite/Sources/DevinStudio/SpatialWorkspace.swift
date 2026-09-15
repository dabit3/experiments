import SwiftUI
import SceneKit
import Metal
import DevinCore

enum SceneGraph {
    static func make(_ document: CreativeDocument) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor(hex: "252B27")
        let camera = SCNNode(); camera.name = "camera"; camera.camera = SCNCamera()
        camera.position = SCNVector3(6, 4.5, 8); camera.look(at: SCNVector3(0, 0, 0))
        camera.camera?.fieldOfView = 42; camera.camera?.zNear = 0.1; camera.camera?.zFar = 100
        if let saved = document.sceneCamera {
            camera.position = SCNVector3(saved.x, saved.y, saved.z)
            camera.eulerAngles = SCNVector3(saved.pitch, saved.yaw, saved.roll)
            camera.camera?.fieldOfView = saved.fieldOfView
        }
        camera.camera?.wantsHDR = true; camera.camera?.exposureOffset = -0.7
        scene.rootNode.addChildNode(camera)
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient
        ambient.light?.intensity = 180; ambient.light?.color = NSColor(hex: "DCE6D8")
        scene.rootNode.addChildNode(ambient)
        let key = SCNNode(); key.light = SCNLight(); key.light?.type = .omni
        key.position = SCNVector3(-3, 7, 5); key.light?.intensity = 450
        key.light?.color = NSColor(hex: "FFF0D6"); key.light?.castsShadow = true; key.light?.shadowRadius = 8
        scene.rootNode.addChildNode(key)
        let fill = SCNNode(); fill.light = SCNLight(); fill.light?.type = .omni
        fill.position = SCNVector3(4, 3, -3); fill.light?.intensity = 250; fill.light?.color = NSColor(hex: "CFDEFF")
        scene.rootNode.addChildNode(fill)
        let floor = SCNFloor(); floor.reflectivity = 0.04
        let floorMaterial = SCNMaterial(); floorMaterial.diffuse.contents = NSColor(hex: "343E35"); floorMaterial.roughness.contents = 0.8
        floor.materials = [floorMaterial]
        let floorNode = SCNNode(geometry: floor); floorNode.position.y = -1.1; floorNode.name = "floor"
        scene.rootNode.addChildNode(floorNode)
        for object in document.objects {
            let geometry: SCNGeometry
            switch object.primitive {
            case "box": geometry = SCNBox(width: 1.5, height: 1.5, length: 1.5, chamferRadius: 0.08)
            case "torus": geometry = SCNTorus(ringRadius: 0.8, pipeRadius: 0.28)
            case "cone": geometry = SCNCone(topRadius: 0, bottomRadius: 0.85, height: 1.8)
            case "cylinder": geometry = SCNCylinder(radius: 0.7, height: 1.6)
            default: let sphere = SCNSphere(radius: 1); sphere.segmentCount = 64; geometry = sphere
            }
            let material = SCNMaterial(); material.lightingModel = .physicallyBased
            material.diffuse.contents = NSColor(hex: object.color); material.metalness.contents = object.metalness; material.roughness.contents = object.roughness
            geometry.materials = [material]
            let node = SCNNode(geometry: geometry); node.name = object.id.uuidString
            node.position = SCNVector3(object.x, object.y, object.z)
            node.scale = SCNVector3(object.scale, object.scale, object.scale)
            node.eulerAngles = SCNVector3(0, object.rotation * .pi / 180, object.primitive == "torus" ? .pi / 2 : 0)
            scene.rootNode.addChildNode(node)
        }
        return scene
    }
    static func snapshot(_ document: CreativeDocument) throws -> CGImage {
        guard let device = MTLCreateSystemDefaultDevice() else { throw DocumentError.invalid("A Metal-capable GPU is required for 3D rendering.") }
        let renderer = SCNRenderer(device: device, options: nil)
        let scene = make(document); renderer.scene = scene; renderer.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: false)
        let image = renderer.snapshot(atTime: 0, with: CGSize(width: 1600, height: 1200), antialiasingMode: .multisampling4X)
        guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw DocumentError.invalid("The 3D scene could not be rendered.") }
        return cg
    }
}

struct SpatialViewport: NSViewRepresentable {
    @ObservedObject var session: StudioSession
    func makeCoordinator() -> Coordinator { Coordinator(session) }
    func makeNSView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero, options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.metal.rawValue])
        view.allowsCameraControl = true; view.antialiasingMode = .multisampling4X; view.backgroundColor = NSColor(hex: "252B27")
        view.autoenablesDefaultLighting = false
        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.select(_:)))
        view.addGestureRecognizer(click)
        return view
    }
    func updateNSView(_ view: SCNView, context: Context) {
        session.captureSceneCamera = { [weak view] in
            guard let node = view?.pointOfView else { return nil }
            return SceneCamera(x: Double(node.position.x), y: Double(node.position.y), z: Double(node.position.z), pitch: Double(node.eulerAngles.x), yaw: Double(node.eulerAngles.y), roll: Double(node.eulerAngles.z), fieldOfView: Double(node.camera?.fieldOfView ?? 42))
        }
        let cameraChanged = context.coordinator.camera != session.document.sceneCamera
        guard context.coordinator.objects != session.document.objects || cameraChanged else { return }
        let previousCamera = cameraChanged ? nil : view.pointOfView?.transform
        let scene = SceneGraph.make(session.document)
        view.scene = scene
        let camera = scene.rootNode.childNode(withName: "camera", recursively: false)
        if let previousCamera { camera?.transform = previousCamera }
        view.pointOfView = camera
        context.coordinator.objects = session.document.objects
        context.coordinator.camera = session.document.sceneCamera
    }
    final class Coordinator: NSObject {
        let session: StudioSession
        var objects: [SpatialObject]?
        var camera: SceneCamera?
        init(_ session: StudioSession) { self.session = session }
        @objc func select(_ recognizer: NSClickGestureRecognizer) {
            guard let view = recognizer.view as? SCNView else { return }
            if let node = view.hitTest(recognizer.location(in: view), options: nil).first?.node, let name = node.name, let id = UUID(uuidString: name) { session.selectedID = id }
        }
    }
}

struct SpatialWorkspace: View {
    @ObservedObject var session: StudioSession
    var selected: SpatialObject? { session.document.objects.first { $0.id == session.selectedID } }
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack { Text("Scene").font(.system(size: 12, weight: .semibold)); Spacer(); Text("\(session.document.objects.count)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.muted) }.padding(18).frame(height: 46)
                ForEach(session.document.objects) { object in
                    HStack(spacing: 10) { Image(systemName: "cube").foregroundStyle(Color(hex: object.color)); Text(object.name).font(.system(size: 11)).lineLimit(1); Spacer() }
                        .padding(13).background(session.selectedID == object.id ? Theme.accent.opacity(0.1) : .clear)
                        .contentShape(Rectangle()).onTapGesture { session.selectedID = object.id }
                }
                Spacer()
                Button { session.deleteSelection() } label: { Label("Remove object", systemImage: "trash") }.buttonStyle(StudioButtonStyle()).padding(15).disabled(selected == nil)
            }.frame(width: 208).background(Theme.sidebar)
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(["sphere", "box", "torus", "cone", "cylinder"], id: \.self) { primitive in
                        Button(primitive.capitalized) { add(primitive) }.buttonStyle(StudioButtonStyle())
                    }
                    Spacer()
                }.padding(12).background(Theme.sidebar)
                SpatialViewport(session: session)
                    .overlay(alignment: .topLeading) { VStack(alignment: .leading, spacing: 6) { Text("PERSPECTIVE").tracking(1.5); Text("PHYSICALLY BASED MATERIALS").foregroundStyle(Theme.muted) }.font(.system(size: 8, design: .monospaced)).padding(20).allowsHitTesting(false) }
                HStack { Text("Drag to orbit · scroll to dolly · click to select"); Spacer(); Text("METAL / SCENEKIT") }.font(.system(size: 9)).foregroundStyle(Theme.muted).padding(12).background(Theme.panel)
            }
            ScrollView {
                VStack(spacing: 0) {
                    if let object = selected {
                        InspectorSection(title: "Object") {
                            TextField("Name", text: binding(\.name, fallback: "Object")).textFieldStyle(.roundedBorder)
                            Text(object.primitive.capitalized).font(.system(size: 11)).foregroundStyle(Theme.muted)
                        }
                        InspectorSection(title: "Transform") {
                            NumberField(label: "X", value: binding(\.x, fallback: 0), range: -20...20)
                            NumberField(label: "Y", value: binding(\.y, fallback: 0), range: -20...20)
                            NumberField(label: "Z", value: binding(\.z, fallback: 0), range: -20...20)
                            LabeledSlider(title: "Scale", value: binding(\.scale, fallback: 1), range: 0.05...5)
                            LabeledSlider(title: "Rotation", value: binding(\.rotation, fallback: 0), range: -180...180)
                        }
                        InspectorSection(title: "Material") {
                            ColorPicker("Base color", selection: Binding(get: { Color(hex: object.color) }, set: { binding(\.color, fallback: "FFFFFF").wrappedValue = $0.hex }), supportsOpacity: false).font(.system(size: 11))
                            LabeledSlider(title: "Metalness", value: binding(\.metalness, fallback: 0), range: 0...1)
                            LabeledSlider(title: "Roughness", value: binding(\.roughness, fallback: 0.5), range: 0...1)
                        }
                        InspectorSection(title: "Actions") {
                            Button("Duplicate object") { var copy = object; copy.id = UUID(); copy.x += 1; copy.name += " copy"; session.mutate { $0.objects.append(copy) }; session.selectedID = copy.id }.buttonStyle(StudioButtonStyle())
                            Button("Reset transform") { binding(\.x, fallback: 0).wrappedValue = 0; binding(\.y, fallback: 0).wrappedValue = 0; binding(\.z, fallback: 0).wrappedValue = 0; binding(\.scale, fallback: 1).wrappedValue = 1; binding(\.rotation, fallback: 0).wrappedValue = 0 }.buttonStyle(StudioButtonStyle())
                        }
                    } else { InspectorSection(title: "No object selected") { Text("Add a primitive or select an object in the scene.").font(.system(size: 11)).foregroundStyle(Theme.muted) } }
                    InspectorSection(title: "Render") {
                        Button("Use Current Camera for Export") { if let camera = session.captureSceneCamera?() { session.mutate { $0.sceneCamera = camera }; session.message = "Camera saved for export" } }.buttonStyle(StudioButtonStyle())
                        Text("Export a 1600 × 1200 PNG from the saved camera, or a native SceneKit scene. The default camera is used until you save a view.").font(.system(size: 10)).foregroundStyle(Theme.muted).lineSpacing(4)
                    }
                }
            }.frame(width: 252).background(Theme.sidebar)
        }
    }
    func binding<T>(_ key: WritableKeyPath<SpatialObject, T>, fallback: T) -> Binding<T> {
        Binding(get: { selected?[keyPath: key] ?? fallback }, set: { value in
            guard let index = session.document.objects.firstIndex(where: { $0.id == session.selectedID }) else { return }
            session.mutate { $0.objects[index][keyPath: key] = value }
        })
    }
    func add(_ primitive: String) {
        var object = SpatialObject(name: primitive.capitalized + " \(session.document.objects.count + 1)", primitive: primitive)
        object.x = Double(session.document.objects.count % 3) - 1
        session.mutate { $0.objects.append(object) }; session.selectedID = object.id
    }
}
