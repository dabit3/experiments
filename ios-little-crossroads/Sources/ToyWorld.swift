import SceneKit
import UIKit

enum ToyColor {
    static let mint = UIColor(red: 0.68, green: 0.86, blue: 0.73, alpha: 1)
    static let dark = UIColor(red: 0.12, green: 0.27, blue: 0.25, alpha: 1)
    static let yellow = UIColor(red: 1, green: 0.77, blue: 0.20, alpha: 1)
    static let coral = UIColor(red: 0.94, green: 0.39, blue: 0.31, alpha: 1)
    static let cream = UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)
    static let water = UIColor(red: 0.28, green: 0.67, blue: 0.68, alpha: 1)

    static func duck(_ plumage: Plumage) -> UIColor {
        [yellow, UIColor(red: 0.46, green: 0.80, blue: 0.67, alpha: 1),
         UIColor(red: 0.95, green: 0.62, blue: 0.64, alpha: 1),
         UIColor(red: 0.30, green: 0.38, blue: 0.56, alpha: 1)][plumage.rawValue]
    }
}

@MainActor
final class ToyWorld {
    let scene = SCNScene()
    let camera = SCNNode()
    private var duck = SCNNode()
    private var laneNodes: [Int: SCNNode] = [:]
    private var movingNodes: [Int: [SCNNode]] = [:]
    private var coins: [Int: SCNNode] = [:]
    private var cameraRow: Double = 1.5
    private var lastSeed: UInt64?
    private var lastPlumage: Plumage?
    private var lastDirection: Direction = .forward
    private var impactProgress = 0.0
    private let contactShadow = SCNNode()
    private let impactRing = SCNNode()

    init() {
        scene.background.contents = ToyColor.mint
        scene.fogColor = ToyColor.mint
        scene.fogStartDistance = 27
        scene.fogEndDistance = 44
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.orthographicScale = 7.2
        camera.camera?.zFar = 70
        camera.camera?.wantsHDR = false
        scene.rootNode.addChildNode(camera)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 600
        ambient.light?.color = UIColor(red: 0.93, green: 0.97, blue: 1, alpha: 1)
        scene.rootNode.addChildNode(ambient)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 850
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .deferred
        sun.light?.shadowRadius = 5
        sun.light?.shadowSampleCount = 16
        sun.light?.shadowColor = UIColor(white: 0.12, alpha: 0.16)
        sun.light?.orthographicScale = 20
        sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sun.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 4, 0)
        scene.rootNode.addChildNode(sun)
        let shadowImage = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128)).image { context in
            let colors = [ToyColor.dark.withAlphaComponent(0.24).cgColor, UIColor.clear.cgColor]
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            ) {
                context.cgContext.drawRadialGradient(
                    gradient, startCenter: CGPoint(x: 64, y: 64), startRadius: 10,
                    endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: []
                )
            }
        }
        let plane = SCNPlane(width: 1.2, height: 1.05)
        let shadowMaterial = SCNMaterial()
        shadowMaterial.diffuse.contents = shadowImage
        shadowMaterial.lightingModel = .constant
        shadowMaterial.writesToDepthBuffer = false
        plane.materials = [shadowMaterial]
        contactShadow.geometry = plane
        contactShadow.eulerAngles.x = -.pi / 2
        scene.rootNode.addChildNode(contactShadow)
        let ring = SCNTorus(ringRadius: 0.45, pipeRadius: 0.035)
        ring.materials = [material(ToyColor.cream)]
        impactRing.geometry = ring
        impactRing.isHidden = true
        scene.rootNode.addChildNode(impactRing)
    }

    func face(_ direction: Direction) {
        lastDirection = direction
    }

    func update(_ game: GameRules, plumage: Plumage, delta: Double, reducedMotion: Bool) {
        if lastSeed != game.course.seed {
            laneNodes.values.forEach { $0.removeFromParentNode() }
            laneNodes.removeAll()
            movingNodes.removeAll()
            coins.removeAll()
            lastSeed = game.course.seed
            cameraRow = 1.5
            lastDirection = .forward
            impactProgress = 0
        }
        if lastPlumage != plumage {
            duck.removeFromParentNode()
            duck = makeDuck(plumage)
            duck.scale = SCNVector3(1.13, 1.13, 1.13)
            scene.rootNode.addChildNode(duck)
            lastPlumage = plumage
        }
        let start = max(-5, game.furthest - 10)
        for row in start ... game.furthest + 22 where laneNodes[row] == nil {
            addLane(game.course.lane(row))
        }
        for row in Array(laneNodes.keys) where row < start {
            laneNodes.removeValue(forKey: row)?.removeFromParentNode()
            movingNodes.removeValue(forKey: row)
            coins.removeValue(forKey: row)
        }
        let time = game.time
        for (row, nodes) in movingNodes {
            let lane = game.course.lane(row)
            for (node, x) in zip(nodes, lane.centers(at: time)) {
                node.position.x = Float(x)
            }
        }
        for (row, node) in coins {
            node.isHidden = game.collectedRows.contains(row)
            node.eulerAngles.y = reducedMotion ? 0 : Float(time * 1.8)
            node.position.y = 0.46 + (reducedMotion ? 0 : Float(sin(time * 3 + Double(row))) * 0.05)
        }
        let target = max(1.5, Double(game.furthest) + 1.9)
        cameraRow += (target - cameraRow) * min(1, delta * 5)
        camera.position = SCNVector3(6.8, 12.5, Float(10 - cameraRow))
        camera.look(at: SCNVector3(0, 0, Float(-cameraRow)))
        duck.position = SCNVector3(Float(game.visibleX), Float(game.height + 0.10), Float(-game.visibleRow))
        let angle: Float = switch lastDirection {
        case .forward: 0
        case .backward: .pi
        case .left: .pi / 2
        case .right: -.pi / 2
        }
        duck.eulerAngles.y = game.state == .ready ? .pi * 0.86 : angle
        let onWater = game.course.lane(game.row).kind == .river
        contactShadow.position = SCNVector3(Float(game.visibleX), onWater ? 0.235 : 0.005, Float(-game.visibleRow))
        impactRing.isHidden = game.state != .finished || game.endReason == "A well-earned rest"
        if game.state == .finished {
            impactProgress = min(1, impactProgress + delta / 0.6)
            duck.eulerAngles.z = -Float.pi / 2 * Float(reducedMotion ? 1 : min(1, impactProgress * 2))
            duck.position.y = game.endReason.contains("splash") ? -Float(impactProgress) * 0.2 : 0.08
            impactRing.position = SCNVector3(Float(game.visibleX), 0.09, Float(-game.visibleRow))
            let scale = Float(reducedMotion ? 1 : 0.6 + impactProgress * 1.5)
            impactRing.scale = SCNVector3(scale, scale, scale)
            impactRing.opacity = CGFloat(1 - impactProgress * 0.8)
        } else {
            duck.eulerAngles.z = 0
        }
    }

    private func material(_ color: UIColor) -> SCNMaterial {
        let result = SCNMaterial()
        result.diffuse.contents = color
        result.roughness.contents = 0.85
        result.lightingModel = .physicallyBased
        return result
    }

    @discardableResult
    private func box(
        _ parent: SCNNode, _ width: CGFloat, _ height: CGFloat, _ length: CGFloat,
        _ color: UIColor, _ x: Float = 0, _ y: Float = 0, _ z: Float = 0, bevel: CGFloat = 0.025
    ) -> SCNNode {
        let geometry = SCNBox(width: width, height: height, length: length, chamferRadius: bevel)
        geometry.materials = [material(color)]
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(x, y, z)
        parent.addChildNode(node)
        return node
    }

    @discardableResult
    private func cylinder(
        _ parent: SCNNode, radius: CGFloat, height: CGFloat, color: UIColor,
        x: Float = 0, y: Float = 0, z: Float = 0
    ) -> SCNNode {
        let geometry = SCNCylinder(radius: radius, height: height)
        geometry.radialSegmentCount = 16
        geometry.materials = [material(color)]
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(x, y, z)
        parent.addChildNode(node)
        return node
    }

    private func addLane(_ lane: Lane) {
        let root = SCNNode()
        root.position.z = -Float(lane.row)
        scene.rootNode.addChildNode(root)
        laneNodes[lane.row] = root
        switch lane.kind {
        case .meadow:
            let green = lane.row % 2 == 0 ? ToyColor.mint : UIColor(red: 0.62, green: 0.81, blue: 0.64, alpha: 1)
            box(root, 18, 0.30, 1, green, 0, -0.18)
            for column in [-5, -4, 4, 5] {
                if (lane.row + column) % 3 == 0 {
                    tree(root, x: Float(column), z: 0.05)
                } else {
                    flowers(root, x: Float(column), z: Float(lane.row % 3) * 0.12 - 0.15)
                }
            }
            if lane.row % 5 == 0 {
                for x in [-3.8, 3.8] {
                    for z in [-0.35, 0.35] {
                        box(root, 0.09, 0.48, 0.09, ToyColor.cream, Float(x), 0.20, Float(z))
                    }
                    box(root, 0.07, 0.08, 0.84, ToyColor.cream, Float(x), 0.21)
                    box(root, 0.07, 0.08, 0.84, ToyColor.cream, Float(x), 0.37)
                }
            }
        case .road:
            box(root, 18, 0.24, 1, UIColor(red: 0.34, green: 0.43, blue: 0.43, alpha: 1), 0, -0.18)
            for x in -9 ... 9 {
                box(root, 0.30, 0.008, 0.045, UIColor(white: 0.84, alpha: 1), Float(x), -0.049, 0.38, bevel: 0)
            }
            movingNodes[lane.row] = lane.centers(at: 0).enumerated().map { index, _ in
                let car = makeCar(index: index + lane.row)
                car.eulerAngles.y = lane.speed < 0 ? .pi : 0
                root.addChildNode(car)
                return car
            }
        case .river:
            box(root, 18, 0.20, 1, ToyColor.water, 0, -0.24)
            for index in -12 ... 12 {
                box(
                    root,
                    0.42,
                    0.008,
                    0.018,
                    UIColor(red: 0.64, green: 0.89, blue: 0.83, alpha: 1),
                    Float(index) * 0.71,
                    -0.134,
                    Float(index % 3) * 0.21,
                    bevel: 0
                )
            }
            movingNodes[lane.row] = lane.centers(at: 0).map { _ in
                let log = SCNNode()
                let wood = cylinder(
                    log,
                    radius: 0.20,
                    height: lane.objectLength,
                    color: UIColor(red: 0.58, green: 0.37, blue: 0.25, alpha: 1),
                    y: 0.03
                )
                wood.eulerAngles.z = .pi / 2
                for x in [-1.54, 1.54] {
                    let end = cylinder(log, radius: 0.16, height: 0.015, color: UIColor(
                        red: 0.85, green: 0.66, blue: 0.43, alpha: 1
                    ), x: Float(x), y: 0.03)
                    end.eulerAngles.z = .pi / 2
                }
                for x in [-0.8, 0.1, 0.9] {
                    box(
                        log,
                        0.24,
                        0.018,
                        0.045,
                        UIColor(red: 0.73, green: 0.50, blue: 0.31, alpha: 1),
                        Float(x),
                        0.22,
                        0.015
                    )
                }
                root.addChildNode(log)
                return log
            }
            for x in [-4.5, 4.6] {
                cylinder(root, radius: 0.22, height: 0.02, color: UIColor(
                    red: 0.47, green: 0.72, blue: 0.46, alpha: 1
                ), x: Float(x), y: -0.08, z: 0.2)
                box(root, 0.10, 0.08, 0.1, ToyColor.cream, Float(x), -0.01, 0.2)
            }
        }
        if let column = lane.coinColumn {
            let coin = SCNNode()
            let disc = cylinder(coin, radius: 0.17, height: 0.07, color: ToyColor.yellow)
            disc.eulerAngles.x = .pi / 2
            box(coin, 0.045, 0.15, 0.075, ToyColor.cream)
            coin.position = SCNVector3(Float(column), 0.46, 0)
            root.addChildNode(coin)
            coins[lane.row] = coin
        }
    }

    private func makeCar(index: Int) -> SCNNode {
        let car = SCNNode()
        let colors = [ToyColor.coral, ToyColor.cream, UIColor(red: 0.42, green: 0.68, blue: 0.80, alpha: 1)]
        let color = colors[abs(index) % colors.count]
        box(car, 1.35, 0.27, 0.61, color, 0, 0.20, bevel: 0.07)
        box(car, 0.66, 0.26, 0.51, color, -0.10, 0.44, bevel: 0.06)
        let glass = UIColor(red: 0.21, green: 0.40, blue: 0.43, alpha: 1)
        box(car, 0.20, 0.18, 0.52, glass, 0.15, 0.45, bevel: 0.02)
        box(car, 0.22, 0.16, 0.52, glass, -0.18, 0.45, bevel: 0.02)
        box(car, 0.08, 0.07, 0.13, ToyColor.cream, 0.67, 0.22, -0.18)
        box(car, 0.08, 0.07, 0.13, ToyColor.cream, 0.67, 0.22, 0.18)
        for x: Float in [-0.43, 0.43] {
            for z: Float in [-0.31, 0.31] {
                let tire = cylinder(car, radius: 0.14, height: 0.08, color: ToyColor.dark, x: x, y: 0.09, z: z)
                tire.eulerAngles.x = .pi / 2
                let hub = cylinder(car, radius: 0.06, height: 0.09, color: ToyColor.cream, x: x, y: 0.09, z: z)
                hub.eulerAngles.x = .pi / 2
            }
        }
        return car
    }

    private func tree(_ parent: SCNNode, x: Float, z: Float) {
        box(parent, 0.17, 0.57, 0.17, UIColor(red: 0.62, green: 0.44, blue: 0.29, alpha: 1), x, 0.22, z)
        box(
            parent,
            0.82,
            0.67,
            0.75,
            UIColor(red: 0.27, green: 0.56, blue: 0.42, alpha: 1),
            x,
            0.73,
            z,
            bevel: 0.12
        )
        box(
            parent,
            0.58,
            0.44,
            0.54,
            UIColor(red: 0.40, green: 0.69, blue: 0.49, alpha: 1),
            x - 0.07,
            1.09,
            z - 0.04,
            bevel: 0.10
        )
    }

    private func flowers(_ parent: SCNNode, x: Float, z: Float) {
        for offset: Float in [-0.16, 0.13] {
            box(parent, 0.025, 0.17, 0.025, ToyColor.dark, x + offset, 0.06, z + offset)
            box(
                parent,
                0.15,
                0.055,
                0.15,
                offset > 0 ? ToyColor.cream : ToyColor.coral,
                x + offset,
                0.16,
                z + offset,
                bevel: 0.03
            )
            box(parent, 0.05, 0.06, 0.05, ToyColor.yellow, x + offset, 0.18, z + offset)
        }
    }

    private func makeDuck(_ plumage: Plumage) -> SCNNode {
        let root = SCNNode()
        let color = ToyColor.duck(plumage)
        box(root, 0.54, 0.40, 0.63, color, 0, 0.29, 0.02, bevel: 0.10)
        box(root, 0.42, 0.39, 0.42, color, 0, 0.59, -0.20, bevel: 0.085)
        box(root, 0.27, 0.105, 0.25, ToyColor.coral, 0, 0.49, -0.47, bevel: 0.035)
        for x: Float in [-0.14, 0.14] {
            box(root, 0.062, 0.074, 0.035, ToyColor.dark, x, 0.65, -0.411, bevel: 0.016)
            box(root, 0.14, 0.075, 0.21, ToyColor.coral, x, 0.035, -0.03, bevel: 0.025)
            box(
                root,
                0.085,
                0.033,
                0.027,
                UIColor(red: 1, green: 0.61, blue: 0.40, alpha: 1),
                x,
                0.55,
                -0.413
            )
        }
        box(root, 0.11, 0.23, 0.36, color.withAlphaComponent(1), -0.29, 0.30, 0.05, bevel: 0.04)
        box(root, 0.11, 0.23, 0.36, color.withAlphaComponent(1), 0.29, 0.30, 0.05, bevel: 0.04)
        box(root, 0.20, 0.16, 0.18, color, 0, 0.38, 0.35, bevel: 0.04)
        if plumage == .midnight {
            box(root, 0.24, 0.08, 0.24, ToyColor.yellow, 0, 0.81, -0.20)
            for x: Float in [-0.08, 0, 0.08] {
                box(root, 0.04, 0.09, 0.04, ToyColor.yellow, x, 0.87, -0.20)
            }
        }
        return root
    }
}
