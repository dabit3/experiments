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
  let styleIndex: Int
  private let accent: SCNMaterial
  private let metal = FighterRig.material(UIColor(white: 0.18, alpha: 1), metallic: 0.8)
  private let leather = FighterRig.material(UIColor(white: 0.045, alpha: 1))

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

  init(style: Int) {
    styleIndex = style
    let design = FighterStyle.all[style]
    accent = Self.material(design.color, metallic: style == 2 ? 0.75 : 0.15)
    let skin = Self.material(design.skin)
    let silver = Self.material(UIColor(white: 0.75, alpha: 1), metallic: 0.65)
    root.addChildNode(hips)
    hips.position.y = 1.25
    hips.addChildNode(torso)
    torso.position.y = 0.25
    ellipsoid(
      torso, size: SCNVector3(style == 2 ? 0.53 : 0.43, 0.50, 0.25),
      at: SCNVector3(0, 0.26, 0), material: style == 0 ? skin : leather)
    ellipsoid(
      hips, size: SCNVector3(0.33, 0.23, 0.23), at: SCNVector3(0, 0.02, 0), material: leather)
    box(hips, size: SCNVector3(0.67, 0.11, 0.49), at: SCNVector3(0, 0.2, 0), material: accent)
    box(hips, size: SCNVector3(0.16, 0.13, 0.06), at: SCNVector3(0, 0.2, 0.27), material: silver)
    torso.addChildNode(head)
    head.position.y = 0.88
    ellipsoid(head, size: SCNVector3(0.22, 0.28, 0.22), at: SCNVector3(0, 0.12, 0), material: skin)
    ellipsoid(
      head, size: SCNVector3(0.18, 0.11, 0.18), at: SCNVector3(0, -0.07, 0.035), material: skin)
    box(head, size: SCNVector3(0.065, 0.10, 0.07), at: SCNVector3(0, 0.105, 0.215), material: skin)
    for side in [-1.0, 1.0] {
      box(
        head, size: SCNVector3(0.075, 0.024, 0.025),
        at: SCNVector3(side * 0.09, 0.19, 0.207), material: leather)
      box(
        head, size: SCNVector3(0.068, 0.017, 0.026),
        at: SCNVector3(side * 0.09, 0.15, 0.212), material: silver)
      ellipsoid(
        head, size: SCNVector3(0.04, 0.075, 0.06),
        at: SCNVector3(side * 0.22, 0.09, 0), material: skin)
    }
    box(
      head, size: SCNVector3(0.09, 0.017, 0.02), at: SCNVector3(0, -0.035, 0.198), material: leather
    )
    let shoulders = [leftArm, rightArm]
    let elbows = [leftElbow, rightElbow]
    let legs = [leftLeg, rightLeg]
    let knees = [leftKnee, rightKnee]
    for index in 0..<2 {
      let sign = index == 0 ? -1.0 : 1.0
      let arm = shoulders[index]
      torso.addChildNode(arm)
      arm.position = SCNVector3(sign * (style == 2 ? 0.48 : 0.40), 0.55, 0)
      ellipsoid(
        arm, size: SCNVector3(0.20, 0.23, 0.21), at: SCNVector3(0, -0.09, 0),
        material: style == 0 ? skin : accent)
      limb(arm, length: 0.43, radius: 0.125, material: skin)
      arm.addChildNode(elbows[index])
      elbows[index].position.y = -0.43
      limb(elbows[index], length: 0.40, radius: 0.105, material: style == 1 ? metal : skin)
      ellipsoid(
        elbows[index], size: SCNVector3(0.15, 0.16, 0.15),
        at: SCNVector3(0, -0.42, 0), material: accent)
      box(
        elbows[index], size: SCNVector3(0.20, 0.17, 0.04),
        at: SCNVector3(0, -0.38, 0.14), material: silver)
      let leg = legs[index]
      hips.addChildNode(leg)
      leg.position = SCNVector3(sign * 0.20, -0.03, 0)
      limb(
        leg, length: 0.56, radius: style == 2 ? 0.20 : 0.16,
        material: style == 3 ? accent : leather)
      leg.addChildNode(knees[index])
      knees[index].position.y = -0.56
      limb(knees[index], length: 0.53, radius: 0.13, material: leather)
      ellipsoid(
        knees[index], size: SCNVector3(0.17, 0.18, 0.16),
        at: SCNVector3(0, -0.02, 0.065), material: metal)
      box(
        knees[index], size: SCNVector3(0.13, 0.32, 0.07),
        at: SCNVector3(0, -0.28, 0.12), material: accent)
      ellipsoid(
        knees[index], size: SCNVector3(0.16, 0.12, 0.27),
        at: SCNVector3(0, -0.52, 0.1), material: leather)
    }
    if style == 0 {
      for side in [-1.0, 1.0] {
        box(
          torso, size: SCNVector3(0.16, 0.61, 0.11),
          at: SCNVector3(side * 0.30, 0.28, 0.20), material: accent)
        for rivet in 0..<4 {
          ellipsoid(
            torso, size: SCNVector3(0.025, 0.025, 0.025),
            at: SCNVector3(side * 0.27, Double(rivet) * 0.14, 0.27), material: silver)
        }
      }
      for index in 0..<7 {
        let spike = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.07, height: 0.24))
        spike.geometry?.firstMaterial = leather
        spike.position = SCNVector3(Double(index - 3) * 0.053, 0.4, -0.03)
        spike.eulerAngles.x = -0.25
        head.addChildNode(spike)
      }
    } else if style == 1 {
      ellipsoid(
        head, size: SCNVector3(0.235, 0.20, 0.235), at: SCNVector3(0, 0.28, -0.035),
        material: silver)
      box(
        head, size: SCNVector3(0.12, 0.39, 0.30), at: SCNVector3(-0.20, 0.12, -0.02),
        material: silver)
      box(
        head, size: SCNVector3(0.30, 0.045, 0.035), at: SCNVector3(0, 0.16, 0.23),
        material: Self.material(design.color, glow: 1))
      for side in [-1.0, 1.0] {
        let coat = box(
          hips, size: SCNVector3(0.21, 0.72, 0.16),
          at: SCNVector3(side * 0.32, -0.30, -0.16), material: accent)
        coat.eulerAngles.z = Float(side * 0.14)
      }
    } else if style == 2 {
      box(head, size: SCNVector3(0.41, 0.23, 0.23), at: SCNVector3(0, 0.03, 0.14), material: metal)
      box(
        head, size: SCNVector3(0.31, 0.055, 0.04), at: SCNVector3(0, 0.18, 0.24),
        material: Self.material(design.color, glow: 1))
      box(
        torso, size: SCNVector3(0.80, 0.47, 0.19), at: SCNVector3(0, 0.36, 0.22), material: accent)
      for index in -1...1 {
        box(
          torso, size: SCNVector3(0.09, 0.18, 0.05),
          at: SCNVector3(Double(index) * 0.16, 0.40, 0.34), material: metal)
      }
      root.scale = SCNVector3(1.09, 1.05, 1.09)
    } else {
      ellipsoid(
        head, size: SCNVector3(0.23, 0.16, 0.23), at: SCNVector3(0, 0.33, -0.04), material: leather)
      ellipsoid(
        head, size: SCNVector3(0.12, 0.13, 0.13), at: SCNVector3(0, 0.46, -0.1), material: leather)
      let sash = box(
        torso, size: SCNVector3(0.18, 0.85, 0.09), at: SCNVector3(0, 0.23, 0.26), material: accent)
      sash.eulerAngles.z = -0.48
      box(
        hips, size: SCNVector3(0.32, 0.65, 0.09), at: SCNVector3(0.1, -0.28, 0.27), material: accent
      )
    }
  }

  private func limb(_ parent: SCNNode, length: CGFloat, radius: CGFloat, material: SCNMaterial) {
    let node = SCNNode(geometry: SCNCapsule(capRadius: radius, height: length + radius))
    node.position.y = -Float(length / 2)
    node.geometry?.firstMaterial = material
    parent.addChildNode(node)
  }

  private func ellipsoid(
    _ parent: SCNNode, size: SCNVector3, at position: SCNVector3, material: SCNMaterial
  ) {
    let node = SCNNode(geometry: SCNSphere(radius: 1))
    node.scale = size
    node.position = position
    node.geometry?.firstMaterial = material
    parent.addChildNode(node)
  }

  @discardableResult
  private func box(
    _ parent: SCNNode, size: SCNVector3, at position: SCNVector3, material: SCNMaterial
  ) -> SCNNode {
    let node = SCNNode(
      geometry: SCNBox(
        width: CGFloat(size.x), height: CGFloat(size.y),
        length: CGFloat(size.z), chamferRadius: 0.035))
    node.position = position
    node.geometry?.firstMaterial = material
    parent.addChildNode(node)
    return node
  }

  func pose(time: Double, state: FighterState?, preview: Bool = false, phase: String = "fight") {
    let breathe = Float(sin(time * 3)) * 0.018
    hips.position.y = 1.22 + breathe
    torso.eulerAngles = SCNVector3(0.06, 0, 0)
    head.eulerAngles = SCNVector3(0, 0, 0)
    leftArm.eulerAngles = SCNVector3(-0.50, 0.05, -0.19)
    rightArm.eulerAngles = SCNVector3(-0.65, -0.12, 0.18)
    leftElbow.eulerAngles.x = -1.55
    rightElbow.eulerAngles.x = -1.35
    leftLeg.eulerAngles = SCNVector3(-0.16, 0, -0.1)
    rightLeg.eulerAngles = SCNVector3(0.12, 0, 0.1)
    leftKnee.eulerAngles.x = 0.22
    rightKnee.eulerAngles.x = 0.25
    if preview {
      root.eulerAngles.y = -0.4 + Float(sin(time * 0.4) * 0.08)
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
      hips.position.y += abs(walk) * 0.06
    }
    if state.guardHeld {
      leftArm.eulerAngles.x = -0.9
      rightArm.eulerAngles.x = -0.95
      leftElbow.eulerAngles.x = -1.9
      rightElbow.eulerAngles.x = -1.9
      hips.position.y -= 0.06
    }
    if state.stun > 0 {
      torso.eulerAngles.x = -0.25
      head.eulerAngles.x = -0.25
    }
    if state.y > 0.05 {
      torso.eulerAngles.x = -0.85
      leftArm.eulerAngles.z = -0.9
      rightArm.eulerAngles.z = 0.9
      leftLeg.eulerAngles.x = -0.6
      rightKnee.eulerAngles.x = 0.9
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
      torso.eulerAngles.y = (state.attack == "cross" ? -0.5 : 0.4) * power
      torso.position.z = 0.10 * power
    } else if state.attack == "kick" || state.attack == "finisher" {
      rightLeg.eulerAngles.x = -1.65 * power
      rightKnee.eulerAngles.x = 0.25 + sin(strike * .pi) * 0.9 * retract
      torso.eulerAngles.x = -0.30 * power
      torso.eulerAngles.y = -0.55 * power
      leftArm.eulerAngles.z = -0.65 * power
    } else if state.attack == "launch" {
      hips.position.y -= sin(strike * .pi) * 0.24 * retract
      rightArm.eulerAngles.x = -0.5 - 2.15 * power
      rightElbow.eulerAngles.x = -1.2 + power * 0.8
      torso.eulerAngles.y = -0.45 * power
    } else {
      torso.position.z = 0
    }
  }
}
