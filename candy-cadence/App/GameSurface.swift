import SpriteKit
import SwiftUI
import UIKit

struct GameSurface: UIViewRepresentable {
  let client: GameClient

  func makeUIView(context: Context) -> CandyGameView {
    CandyGameView(client: client)
  }

  func updateUIView(_ uiView: CandyGameView, context: Context) {}
}

final class CandyGameView: UIView {
  private let skView = SKView()
  private let scene: CandyScene
  private var controls: [UIButton] = []
  private let client: GameClient

  init(client: GameClient) {
    self.client = client
    scene = CandyScene(client: client)
    super.init(frame: .zero)
    backgroundColor = CandyPalette.ink
    isMultipleTouchEnabled = true
    skView.isMultipleTouchEnabled = true
    skView.preferredFramesPerSecond = 60
    skView.ignoresSiblingOrder = false
    addSubview(skView)
    skView.presentScene(scene)
    let colors = ["white", "yellow", "green", "blue", "red", "blue", "green", "yellow", "white"]
    for lane in 0..<9 {
      let button = UIButton(type: .custom)
      button.tag = lane
      button.isExclusiveTouch = false
      button.accessibilityLabel = "Lane \(lane + 1), \(colors[lane])"
      button.accessibilityIdentifier = "lane-\(lane + 1)"
      button.addTarget(self, action: #selector(pressed(_:)), for: .touchDown)
      addSubview(button)
      controls.append(button)
    }
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  override func layoutSubviews() {
    super.layoutSubviews()
    skView.frame = bounds
    let scale = min(
      bounds.width / CandyScene.canvas.width, bounds.height / CandyScene.canvas.height)
    let offsetX = (bounds.width - CandyScene.canvas.width * scale) / 2
    let offsetY = (bounds.height - CandyScene.canvas.height * scale) / 2
    for (lane, button) in controls.enumerated() {
      let point = CandyScene.buttonPoint(lane)
      button.frame = CGRect(
        x: offsetX + (point.x - 36) * scale,
        y: offsetY + (CandyScene.canvas.height - point.y - 36) * scale,
        width: 72 * scale, height: 72 * scale
      )
    }
  }

  @objc private func pressed(_ sender: UIButton) {
    client.hit(sender.tag)
    scene.flash(sender.tag)
    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
  }
}
