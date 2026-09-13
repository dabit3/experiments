import SceneKit
import UIKit

@MainActor
final class FighterRig {
  let root = SCNNode()
  private let hips = SCNNode()
  private let torso = SCNNode()
  private let head = SCNNode()
  private let leftArm = SCNNode()
  private let rightArm = SCNNode()
  private let leftElbow = SCNNode()
  private let rightElbow = SCNNode()
  private let leftLeg = SCNNode()
  private let rightLeg = SCNNode()
  private let leftKnee = SCNNode()
  private let rightKnee = SCNNode()
  private let tails = SCNNode()
  let styleIndex: Int
  private let accent: SCNMaterial
  private let skin: SCNMaterial
  private let hair: SCNMaterial
  private let cloth = FighterRig.fabric(UIColor(red: 0.04, green: 0.05, blue: 0.08, alpha: 1))
  private let ivory = FighterRig.fabric(UIColor(red: 0.82, green: 0.78, blue: 0.65, alpha: 1))
  private let metal = FighterRig.material(UIColor(white: 0.28, alpha: 1), metallic: 0.6)

  static func material(_ color: UIColor, metallic: CGFloat = 0, glow: CGFloat = 0) -> SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.metalness.contents = metallic
    material.roughness.contents = metallic > 0 ? 0.32 : 0.64
    material.lightingModel = .physicallyBased
    if glow > 0 {
      material.emission.contents = color
      material.emission.intensity = glow
    }
    return material
  }

  private static func fabric(_ color: UIColor) -> SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.lightingModel = .lambert
    material.isDoubleSided = true
    return material
  }

  init(style: Int) {
    styleIndex = style
    let design = FighterStyle.all[style]
    accent = Self.fabric(design.color)
    skin = Self.fabric(design.skin)
    hair = Self.fabric(
      style == 1
        ? UIColor(red: 0.38, green: 0.31, blue: 0.49, alpha: 1)
        : UIColor(red: 0.045, green: 0.025, blue: 0.018, alpha: 1))
    root.addChildNode(hips)
    hips.position.y = 1.23
    hips.addChildNode(torso)
    torso.position.y = 0.22
    buildBody()
    buildFace()
    buildLimbs()
    buildCostume()
    if style == 2 {
      root.scale = SCNVector3(1.12, 1.06, 1.08)
    } else if style == 1 {
      root.scale = SCNVector3(0.93, 0.98, 0.94)
    }
  }

  private func buildBody() {
    let muscular: Float = styleIndex == 2 ? 1.17 : 1
    contour(
      torso,
      rings: [
        (-0.14, 0.23, 0.15, 0), (0, 0.25, 0.16, 0),
        (0.18, 0.28, 0.18, 0), (0.39, 0.36, 0.205, 0),
        (0.57, 0.38, 0.19, 0), (0.68, 0.28, 0.145, 0),
        (0.76, 0.13, 0.115, 0), (0.78, 0.10, 0.10, 0),
      ], material: styleIndex == 1 ? cloth : skin, width: muscular)
    contour(
      hips,
      rings: [
        (-0.14, 0.29, 0.17, 0), (0, 0.31, 0.19, 0),
        (0.20, 0.25, 0.16, 0), (0.26, 0.24, 0.15, 0),
      ], material: styleIndex == 3 ? ivory : cloth)
    if styleIndex == 0 || styleIndex == 2 {
      for side: Float in [-1, 1] {
        oval(
          torso, size: SCNVector3(0.175 * muscular, 0.14, 0.075),
          at: SCNVector3(side * 0.17, 0.48, 0.17), material: skin)
        for row in 0..<3 {
          oval(
            torso, size: SCNVector3(0.087, 0.060, 0.03),
            at: SCNVector3(side * 0.092, 0.27 - Float(row) * 0.11, 0.16), material: skin)
        }
        tube(
          torso, from: SCNVector3(side * 0.09, 0.66, 0.12),
          to: SCNVector3(side * 0.29, 0.61, 0.15), radius: 0.023, material: skin)
      }
    }
    torso.addChildNode(head)
    head.position.y = 0.82
    contour(
      head,
      rings: [
        (-0.10, 0.095, 0.09, -0.015), (0.02, 0.11, 0.12, 0),
        (0.04, 0.115, 0.15, 0.025), (0.10, 0.17, 0.17, 0),
        (0.22, 0.192, 0.19, -0.015), (0.34, 0.185, 0.19, -0.025),
        (0.43, 0.15, 0.16, -0.035), (0.48, 0.09, 0.10, -0.035),
        (0.495, 0.005, 0.005, -0.035),
      ], material: skin, segments: 32)
  }

  private func buildFace() {
    let eyeWhite = Self.fabric(UIColor(red: 0.91, green: 0.85, blue: 0.72, alpha: 1))
    let iris = Self.fabric(
      styleIndex == 1 ? UIColor(red: 0.10, green: 0.24, blue: 0.27, alpha: 1) : .black)
    let lip = Self.fabric(
      styleIndex == 2
        ? UIColor(red: 0.22, green: 0.09, blue: 0.07, alpha: 1)
        : UIColor(red: 0.42, green: 0.17, blue: 0.14, alpha: 1))
    for side: Float in [-1, 1] {
      oval(
        head, size: SCNVector3(0.046, 0.063, 0.028),
        at: SCNVector3(side * 0.186, 0.23, -0.014), material: skin)
      oval(
        head, size: SCNVector3(0.019, 0.04, 0.009),
        at: SCNVector3(side * 0.208, 0.23, 0.008), material: lip)
      oval(
        head, size: SCNVector3(0.054, 0.028, 0.017),
        at: SCNVector3(side * 0.08, 0.277, 0.160), material: lip)
      oval(
        head, size: SCNVector3(0.045, 0.019, 0.013),
        at: SCNVector3(side * 0.08, 0.281, 0.176), material: eyeWhite)
      oval(
        head, size: SCNVector3(0.014, 0.018, 0.008),
        at: SCNVector3(side * 0.074, 0.281, 0.189), material: iris)
      tube(
        head, from: SCNVector3(side * 0.035, 0.313, 0.184),
        to: SCNVector3(side * 0.132, 0.327, 0.154),
        radius: styleIndex == 2 ? 0.017 : 0.012, material: hair)
      oval(
        head, size: SCNVector3(0.063, 0.047, 0.026),
        at: SCNVector3(side * 0.116, 0.208, 0.152), material: skin)
    }
    contour(
      head,
      rings: [
        (0.15, 0.031, 0.025, 0.183), (0.175, 0.047, 0.045, 0.192),
        (0.21, 0.026, 0.040, 0.190), (0.305, 0.020, 0.015, 0.178),
      ], material: skin, segments: 12)
    tube(
      head, from: SCNVector3(-0.065, 0.115, 0.168),
      to: SCNVector3(0.065, 0.115, 0.168), radius: 0.009, material: lip)
    oval(
      head, size: SCNVector3(0.075, 0.017, 0.017),
      at: SCNVector3(0, 0.098, 0.163), material: skin)
    if styleIndex == 2 {
      for index in -5...5 {
        let x = Float(index) * 0.022
        tube(
          head, from: SCNVector3(x, 0.115, 0.152),
          to: SCNVector3(x * 0.74, 0.03 + abs(x) * 0.2, 0.155),
          radius: 0.016, material: hair)
      }
      for side: Float in [-1, 1] {
        tube(
          head, from: SCNVector3(side * 0.17, 0.24, 0.07),
          to: SCNVector3(side * 0.12, 0.08, 0.14), radius: 0.029, material: hair)
      }
    }
    buildHair()
  }

  private func buildHair() {
    contour(
      head,
      rings: [
        (0.36, 0.187, 0.190, -0.038), (0.43, 0.170, 0.182, -0.038),
        (0.50, 0.112, 0.12, -0.038), (0.53, 0.005, 0.005, -0.038),
      ], material: hair)
    if styleIndex == 0 {
      for row in 0..<3 {
        for index in -3...3 {
          let x = Float(index) * 0.048
          tube(
            head, from: SCNVector3(x, 0.43, Float(row) * 0.075 - 0.1),
            to: SCNVector3(x * 0.76, 0.57 - abs(x) * 0.25, Float(row) * 0.04 - 0.19),
            radius: 0.04, tip: 0.003, material: hair)
        }
      }
      let scar = Self.fabric(UIColor(red: 0.38, green: 0.20, blue: 0.15, alpha: 1))
      tube(
        head, from: SCNVector3(0.12, 0.28, 0.171),
        to: SCNVector3(0.13, 0.18, 0.161), radius: 0.006, material: scar)
    } else if styleIndex == 1 {
      for side: Float in [-1, 1] {
        for index in 0..<4 {
          let z = Float(index) * 0.065 - 0.16
          tube(
            head, from: SCNVector3(side * 0.17, 0.43, z),
            to: SCNVector3(side * 0.22, 0.08 + Float(index) * 0.02, z),
            radius: 0.068, tip: 0.027, material: hair)
        }
      }
      for index in 0..<5 {
        tube(
          head, from: SCNVector3(Float(index) * 0.055 - 0.10, 0.43, 0.10),
          to: SCNVector3(Float(index) * 0.050 - 0.17, 0.30, 0.19),
          radius: 0.037, tip: 0.008, material: hair)
      }
      tube(
        head, from: SCNVector3(-0.20, 0.38, 0.03),
        to: SCNVector3(-0.23, 0.08, 0.06), radius: 0.013, material: accent)
    } else if styleIndex == 2 {
      for index in 0..<6 {
        tube(
          head, from: SCNVector3(0, 0.43, Float(index) * 0.043 - 0.15),
          to: SCNVector3(0, 0.56, Float(index) * 0.035 - 0.17),
          radius: 0.065, tip: 0.033, material: hair)
      }
    } else {
      oval(
        head, size: SCNVector3(0.105, 0.12, 0.095),
        at: SCNVector3(0, 0.54, -0.12), material: hair)
      tube(
        head, from: SCNVector3(0, 0.48, -0.14),
        to: SCNVector3(0.05, 0.02, -0.30), radius: 0.06, tip: 0.02, material: hair)
      band(head, y: 0.354, width: 0.19, depth: 0.193, height: 0.039, material: accent)
      for side: Float in [-1, 1] {
        tube(
          head, from: SCNVector3(side * 0.15, 0.36, -0.10),
          to: SCNVector3(side * 0.16, 0.19, -0.05), radius: 0.028, material: hair)
      }
    }
  }

  private func buildLimbs() {
    let arms = [leftArm, rightArm]
    let elbows = [leftElbow, rightElbow]
    let legs = [leftLeg, rightLeg]
    let knees = [leftKnee, rightKnee]
    let muscle: Float = styleIndex == 2 ? 1.24 : styleIndex == 1 ? 0.87 : 1
    for index in 0..<2 {
      let side: Float = index == 0 ? -1 : 1
      let arm = arms[index]
      torso.addChildNode(arm)
      arm.position = SCNVector3(side * 0.355 * muscle, 0.57, 0)
      contour(
        arm,
        rings: [
          (-0.46, 0.082, 0.086, 0), (-0.34, 0.109, 0.102, 0),
          (-0.20, 0.148, 0.123, 0.004), (-0.055, 0.166, 0.154, 0),
          (0.045, 0.102, 0.108, 0), (0.08, 0.008, 0.008, 0),
        ], material: styleIndex == 3 ? ivory : skin, width: muscle)
      arm.addChildNode(elbows[index])
      elbows[index].position.y = -0.44
      contour(
        elbows[index],
        rings: [
          (-0.39, 0.069, 0.068, 0), (-0.30, 0.083, 0.077, 0.006),
          (-0.12, 0.119, 0.112, 0.016), (0.02, 0.09, 0.085, 0),
        ], material: skin, width: muscle)
      if styleIndex == 1 {
        band(arm, y: -0.20, width: 0.154, depth: 0.134, height: 0.25, material: accent)
      }
      if styleIndex == 3 {
        band(arm, y: -0.32, width: 0.128, depth: 0.12, height: 0.11, material: accent)
      }
      for wrap in 0..<5 {
        band(
          elbows[index], y: -0.27 - Float(wrap) * 0.027,
          width: 0.090, depth: 0.086, height: 0.021,
          material: styleIndex == 2 ? accent : ivory)
      }
      buildHand(on: elbows[index])
      let leg = legs[index]
      hips.addChildNode(leg)
      leg.position = SCNVector3(side * 0.18, -0.025, 0)
      contour(
        leg,
        rings: [
          (-0.57, 0.112, 0.113, 0), (-0.45, 0.137, 0.13, 0),
          (-0.20, 0.18, 0.185, 0), (-0.04, 0.182, 0.172, 0),
          (0.07, 0.135, 0.14, 0),
        ], material: styleIndex == 3 ? ivory : cloth, width: muscle)
      leg.addChildNode(knees[index])
      knees[index].position.y = -0.54
      contour(
        knees[index],
        rings: [
          (-0.48, 0.083, 0.088, 0), (-0.35, 0.108, 0.109, -0.014),
          (-0.18, 0.132, 0.135, -0.019), (-0.03, 0.118, 0.12, 0),
          (0.055, 0.11, 0.11, 0),
        ], material: styleIndex == 3 ? ivory : cloth, width: muscle)
      tube(
        leg, from: SCNVector3(side * 0.169 * muscle, -0.02, 0.02),
        to: SCNVector3(side * 0.12 * muscle, -0.51, 0.025),
        radius: styleIndex == 0 ? 0.034 : 0.02, material: accent)
      if styleIndex == 0 {
        for flame in 0..<3 {
          tube(
            leg, from: SCNVector3(side * 0.16, -0.35, 0.08),
            to: SCNVector3(side * 0.16, -0.08 - Float(flame) * 0.08, 0.10),
            radius: 0.027, tip: 0.001, material: accent)
        }
      }
      if styleIndex == 2 {
        plate(
          leg, size: SCNVector3(0.11, 0.24, 0.18),
          at: SCNVector3(side * 0.21, -0.25, 0), material: accent)
      }
      buildBoot(on: knees[index], side: side)
    }
  }

  private func buildHand(on elbow: SCNNode) {
    let glove = styleIndex == 3 ? ivory : accent
    oval(
      elbow, size: SCNVector3(0.102, 0.115, 0.07),
      at: SCNVector3(0, -0.427, 0.015), material: glove)
    for finger in 0..<4 {
      let x = Float(finger) * 0.041 - 0.0615
      tube(
        elbow, from: SCNVector3(x, -0.46, 0.047),
        to: SCNVector3(x, -0.50, 0.043),
        radius: 0.025, material: styleIndex == 3 ? skin : glove)
      oval(
        elbow, size: SCNVector3(0.021, 0.025, 0.026),
        at: SCNVector3(x, -0.47, 0.075), material: styleIndex == 1 ? skin : glove)
    }
    tube(
      elbow, from: SCNVector3(-0.09, -0.405, 0.045),
      to: SCNVector3(-0.076, -0.475, 0.082), radius: 0.028, material: skin)
    plate(
      elbow, size: SCNVector3(0.118, 0.07, 0.018),
      at: SCNVector3(0, -0.415, -0.059), material: cloth)
  }

  private func buildBoot(on knee: SCNNode, side: Float) {
    let footwear = styleIndex == 3 ? cloth : styleIndex == 1 ? accent : cloth
    band(
      knee, y: -0.32, width: 0.119, depth: 0.12, height: 0.32, material: footwear)
    plate(
      knee, size: SCNVector3(0.245, 0.155, 0.41),
      at: SCNVector3(0, -0.495, 0.087), material: footwear)
    plate(
      knee, size: SCNVector3(0.252, 0.05, 0.425),
      at: SCNVector3(0, -0.566, 0.087), material: cloth)
    if styleIndex == 3 {
      for wrap in 0..<5 {
        band(
          knee, y: -0.21 - Float(wrap) * 0.045,
          width: 0.12, depth: 0.126, height: 0.029, material: ivory)
      }
    } else {
      for row in 0..<4 {
        for direction: Float in [-1, 1] {
          tube(
            knee, from: SCNVector3(-0.061, -0.23 - Float(row) * 0.054, 0.126),
            to: SCNVector3(0.061, -0.23 - Float(row) * 0.054 + direction * 0.039, 0.126),
            radius: 0.008, material: ivory)
        }
      }
      plate(
        knee, size: SCNVector3(0.11, 0.15, 0.035),
        at: SCNVector3(side * 0.03, 0, 0.12),
        material: styleIndex == 2 ? accent : cloth)
    }
  }

  private func buildCostume() {
    let costume = styleIndex == 3 ? ivory : accent
    band(hips, y: 0.22, width: 0.273, depth: 0.18, height: 0.105, material: costume)
    plate(
      hips, size: SCNVector3(0.095, 0.09, 0.036),
      at: SCNVector3(0, 0.22, 0.193), material: metal)
    if styleIndex == 0 || styleIndex == 1 || styleIndex == 2 {
      for side: Float in [-1, 1] {
        let jacket = SCNNode()
        torso.addChildNode(jacket)
        jacket.position = SCNVector3(side * 0.29, 0, 0)
        contour(
          jacket,
          rings: [
            (-0.03, 0.105, 0.15, 0), (0.20, 0.11, 0.20, 0),
            (0.48, 0.14, 0.22, 0), (0.63, 0.11, 0.18, 0),
            (0.67, 0.045, 0.09, 0),
          ], material: styleIndex == 2 ? cloth : accent)
        tube(
          torso, from: SCNVector3(side * 0.20, -0.02, 0.185),
          to: SCNVector3(side * 0.18, 0.63, 0.19),
          radius: 0.015, material: ivory)
        let lapel = plate(
          torso, size: SCNVector3(0.10, 0.33, 0.025),
          at: SCNVector3(side * 0.185, 0.45, 0.216),
          material: styleIndex == 2 ? accent : cloth)
        lapel.eulerAngles.z = side * -0.23
        for stud in 0..<3 {
          oval(
            torso, size: SCNVector3(0.014, 0.014, 0.012),
            at: SCNVector3(side * 0.27, Float(stud) * 0.13 + 0.08, 0.212),
            material: metal)
        }
      }
      plate(
        torso, size: SCNVector3(0.46, 0.59, 0.045),
        at: SCNVector3(0, 0.29, -0.19), material: styleIndex == 2 ? cloth : accent)
      emblem(on: torso, at: SCNVector3(0, 0.34, -0.22), facingBack: true)
    } else {
      contour(
        torso,
        rings: [
          (-0.08, 0.29, 0.19, 0), (0.15, 0.29, 0.20, 0),
          (0.42, 0.36, 0.225, 0), (0.58, 0.37, 0.22, 0),
          (0.65, 0.24, 0.17, 0),
        ], material: ivory)
      for side: Float in [-1, 1] {
        let lapel = plate(
          torso, size: SCNVector3(0.11, 0.64, 0.045),
          at: SCNVector3(side * 0.085, 0.37, 0.225), material: accent)
        lapel.eulerAngles.z = -side * 0.33
      }
      band(hips, y: 0.22, width: 0.29, depth: 0.20, height: 0.13, material: accent)
      hips.addChildNode(tails)
      for side: Float in [-1, 1] {
        let tail = plate(
          tails, size: SCNVector3(0.08, 0.55, 0.028),
          at: SCNVector3(side * 0.08, -0.075, 0.21), material: accent)
        tail.eulerAngles.z = side * 0.15
      }
      emblem(on: torso, at: SCNVector3(-0.23, 0.44, 0.226))
    }
    if styleIndex == 2 {
      for side: Float in [-1, 1] {
        plate(
          torso, size: SCNVector3(0.21, 0.075, 0.32),
          at: SCNVector3(side * 0.37, 0.645, 0), material: accent)
        for scar in 0..<2 {
          tube(
            torso, from: SCNVector3(side * 0.07, 0.38 + Float(scar) * 0.05, 0.22),
            to: SCNVector3(side * 0.20, 0.32 + Float(scar) * 0.05, 0.23),
            radius: 0.006, material: ivory)
        }
      }
    }
  }

  private func emblem(on parent: SCNNode, at position: SCNVector3, facingBack: Bool = false) {
    let node = SCNNode()
    node.position = position
    if facingBack { node.eulerAngles.y = .pi }
    parent.addChildNode(node)
    for side: Float in [-1, 1] {
      tube(
        node, from: SCNVector3(side * 0.08, -0.10, 0),
        to: SCNVector3(0, 0.11, 0), radius: 0.017, material: ivory)
    }
    tube(
      node, from: SCNVector3(-0.045, -0.02, 0),
      to: SCNVector3(0.075, -0.02, 0), radius: 0.018, material: ivory)
  }

  private func contour(
    _ parent: SCNNode, rings: [(Float, Float, Float, Float)], material: SCNMaterial,
    width: Float = 1, segments: Int = 24
  ) {
    var vertices: [SCNVector3] = []
    var normals: [SCNVector3] = []
    var indices: [Int32] = []
    for (row, ring) in rings.enumerated() {
      let before = rings[max(0, row - 1)]
      let after = rings[min(rings.count - 1, row + 1)]
      let dy = after.0 - before.0
      let dw = (after.1 - before.1) * width
      let dd = after.2 - before.2
      for index in 0..<segments {
        let angle = Float(index) * .pi * 2 / Float(segments)
        let s = sin(angle)
        let c = cos(angle)
        vertices.append(SCNVector3(ring.1 * width * s, ring.0, ring.2 * c + ring.3))
        let nx = ring.2 * dy * s
        let ny = -ring.2 * dw * s * s - ring.1 * width * dd * c * c
        let nz = ring.1 * width * dy * c
        let length = max(0.00001, sqrt(nx * nx + ny * ny + nz * nz))
        normals.append(SCNVector3(nx / length, ny / length, nz / length))
        if row < rings.count - 1 {
          let a = Int32(row * segments + index)
          let b = Int32(row * segments + (index + 1) % segments)
          let next = Int32(segments)
          indices.append(contentsOf: [a, b, a + next, b, b + next, a + next])
        }
      }
    }
    let geometry = SCNGeometry(
      sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals)],
      elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
    geometry.firstMaterial = material
    parent.addChildNode(SCNNode(geometry: geometry))
  }

  private func band(
    _ parent: SCNNode, y: Float, width: Float, depth: Float, height: Float, material: SCNMaterial
  ) {
    contour(
      parent,
      rings: [
        (y - height / 2, width * 0.97, depth * 0.97, 0),
        (y - height * 0.42, width, depth, 0),
        (y + height * 0.42, width, depth, 0),
        (y + height / 2, width * 0.97, depth * 0.97, 0),
      ], material: material)
  }

  private func tube(
    _ parent: SCNNode, from start: SCNVector3, to end: SCNVector3,
    radius: CGFloat, tip: CGFloat? = nil, material: SCNMaterial
  ) {
    let dx = end.x - start.x
    let dy = end.y - start.y
    let dz = end.z - start.z
    let length = sqrt(dx * dx + dy * dy + dz * dz)
    let geometry = SCNCone(
      topRadius: tip ?? radius, bottomRadius: radius, height: CGFloat(length))
    geometry.radialSegmentCount = 10
    geometry.firstMaterial = material
    let node = SCNNode(geometry: geometry)
    node.position = SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2, (start.z + end.z) / 2)
    node.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: simd_normalize(SIMD3(dx, dy, dz)))
    parent.addChildNode(node)
  }

  private func oval(
    _ parent: SCNNode, size: SCNVector3, at position: SCNVector3, material: SCNMaterial
  ) {
    let sphere = SCNSphere(radius: 1)
    sphere.segmentCount = 16
    let node = SCNNode(geometry: sphere)
    node.scale = size
    node.position = position
    sphere.firstMaterial = material
    parent.addChildNode(node)
  }

  @discardableResult
  private func plate(
    _ parent: SCNNode, size: SCNVector3, at position: SCNVector3, material: SCNMaterial
  ) -> SCNNode {
    let node = SCNNode(
      geometry: SCNBox(
        width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z),
        chamferRadius: CGFloat(min(size.x, min(size.y, size.z))) * 0.28))
    node.position = position
    node.geometry?.firstMaterial = material
    parent.addChildNode(node)
    return node
  }

  func pose(time: Double, state: FighterState?, preview: Bool = false, phase: String = "fight") {
    let breathe = Float(sin(time * 3)) * 0.012
    hips.position.y = 1.22 + breathe
    torso.position.z = 0
    torso.eulerAngles = SCNVector3(0.06, -0.23, 0)
    head.eulerAngles = SCNVector3(-0.035, 0.15, -0.025)
    tails.eulerAngles = SCNVector3(sin(time * 3) * 0.06, 0, sin(time * 2) * 0.06)
    leftArm.eulerAngles = SCNVector3(-0.62, 0.05, -0.17)
    rightArm.eulerAngles = SCNVector3(-0.50, -0.12, 0.12)
    leftElbow.eulerAngles = SCNVector3(-1.70, 0.10, -0.13)
    rightElbow.eulerAngles = SCNVector3(-1.95, -0.12, 0.17)
    leftLeg.eulerAngles = SCNVector3(-0.22, 0.05, -0.11)
    rightLeg.eulerAngles = SCNVector3(0.19, -0.05, 0.11)
    leftKnee.eulerAngles.x = 0.24
    rightKnee.eulerAngles.x = 0.25
    if styleIndex == 1 {
      leftArm.eulerAngles.x = -0.75
      rightArm.eulerAngles.x = -0.70
      hips.position.y += Float(abs(sin(time * 4))) * 0.025
    } else if styleIndex == 2 {
      leftArm.eulerAngles.z = -0.34
      rightArm.eulerAngles.z = 0.29
      leftElbow.eulerAngles.x = -1.30
      rightElbow.eulerAngles.x = -1.45
      hips.position.y -= 0.05
    } else if styleIndex == 3 {
      leftArm.eulerAngles.x = -1.12
      leftElbow.eulerAngles.x = -0.50
      rightArm.eulerAngles.x = -0.37
      rightElbow.eulerAngles.x = -1.46
      torso.eulerAngles.y = -0.4
    }
    if preview {
      root.eulerAngles.y = -0.35 + Float(sin(time * 0.4) * 0.12)
      head.eulerAngles.y = 0.12
      return
    }
    guard let state else { return }
    let target = SCNVector3(state.x, state.y, state.z)
    root.position.x += (target.x - root.position.x) * 0.22
    root.position.y += (target.y - root.position.y) * 0.35
    root.position.z += (target.z - root.position.z) * 0.22
    root.eulerAngles.y = state.facing > 0 ? .pi / 2 : -.pi / 2
    root.eulerAngles.z = 0
    if phase == "result" || phase == "roundEnd" {
      if state.health[state.active] <= 0 {
        hips.position.y = 0.3
        torso.eulerAngles.x = -1.0
        head.eulerAngles.x = 0.35
        leftLeg.eulerAngles.x = -1.4
        rightLeg.eulerAngles.x = -1.2
      } else {
        rightArm.eulerAngles.x = -.pi
        rightElbow.eulerAngles.x = -0.3
        torso.eulerAngles.y = Float(sin(time)) * 0.15
      }
      return
    }
    if abs(state.vx) + abs(state.vz) > 0.1 && state.attack.isEmpty && state.stun == 0 {
      let walk = Float(sin(time * 12))
      leftLeg.eulerAngles.x += walk * 0.3
      rightLeg.eulerAngles.x -= walk * 0.3
      hips.position.y += abs(walk) * 0.045
      torso.eulerAngles.z = walk * 0.025
    }
    if state.guardHeld {
      leftArm.eulerAngles = SCNVector3(-0.85, 0.18, -0.06)
      rightArm.eulerAngles = SCNVector3(-0.90, -0.18, 0.06)
      leftElbow.eulerAngles.x = -2.0
      rightElbow.eulerAngles.x = -2.0
      head.eulerAngles.x = 0.15
      hips.position.y -= 0.06
    }
    if state.stun > 0 {
      torso.eulerAngles.x = -0.25
      torso.eulerAngles.z = 0.10
      head.eulerAngles.x = -0.30
    }
    if state.y > 0.05 {
      torso.eulerAngles.x = -0.85
      leftArm.eulerAngles.z = -0.9
      rightArm.eulerAngles.z = 0.9
      leftElbow.eulerAngles.x = -0.45
      rightElbow.eulerAngles.x = -0.35
      leftLeg.eulerAngles.x = -0.6
      rightKnee.eulerAngles.x = 0.9
      tails.eulerAngles.x = -0.6
    }
    let age = Float(state.age) + Float((time * 60).truncatingRemainder(dividingBy: 3))
    let start: Float = state.attack == "punch" ? 9 : state.attack == "cross" ? 12 : 18
    let duration: Float =
      state.attack == "punch"
      ? 25 : state.attack == "cross" ? 32 : state.attack == "launch" ? 36 : 43
    let strike = max(0, min(1, age / start))
    let retract = max(0, 1 - max(0, age - start) / (duration - start))
    let power = strike * retract
    if state.attack == "punch" || state.attack == "cross" {
      let arm = state.attack == "punch" ? leftArm : rightArm
      let elbow = state.attack == "punch" ? leftElbow : rightElbow
      arm.eulerAngles.x = -0.5 - 1.15 * power
      elbow.eulerAngles.x = -1.55 + 1.45 * power
      elbow.eulerAngles.z *= 1 - power
      torso.eulerAngles.y = (state.attack == "cross" ? -0.65 : 0.42) * power
      torso.position.z = 0.12 * power
      rightLeg.eulerAngles.x += 0.10 * power
      head.eulerAngles.x = 0.10 * power
    } else if state.attack == "kick" || state.attack == "finisher" {
      rightLeg.eulerAngles.x = -1.70 * power
      rightLeg.eulerAngles.y = -0.17 * power
      rightKnee.eulerAngles.x = 0.25 + sin(strike * .pi) * 1.1 * retract
      torso.eulerAngles.x = -0.36 * power
      torso.eulerAngles.y = -0.65 * power
      leftArm.eulerAngles.z = -0.65 * power
      rightArm.eulerAngles.z = 0.5 * power
      tails.eulerAngles.x = -0.5 * power
    } else if state.attack == "launch" {
      hips.position.y -= sin(strike * .pi) * 0.26 * retract
      rightArm.eulerAngles.x = -0.5 - 2.15 * power
      rightElbow.eulerAngles.x = -1.2 + power * 0.8
      torso.eulerAngles.y = -0.6 * power
      torso.eulerAngles.x = -0.14 * power
      leftKnee.eulerAngles.x += sin(strike * .pi) * 0.32 * retract
    }
  }
}
