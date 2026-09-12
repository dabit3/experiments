import SpriteKit
import SwiftUI
import UIKit

@main
struct ButtonwoodApp: App {
  @StateObject private var model = GameModel()
  @Environment(\.scenePhase) private var phase

  var body: some Scene {
    WindowGroup {
      GameView(model: model)
        .statusBarHidden()
        .preferredColorScheme(.dark)
        .onChange(of: phase) { _, phase in
          if phase != .active { model.pause() }
        }
    }
  }
}

struct NativeScene: UIViewRepresentable {
  let model: GameModel

  func makeUIView(context: Context) -> KeyboardSceneView {
    let view = KeyboardSceneView()
    view.model = model
    view.ignoresSiblingOrder = true
    view.isMultipleTouchEnabled = true
    view.presentScene(model.scene)
    view.becomeFirstResponder()
    return view
  }

  func updateUIView(_ view: KeyboardSceneView, context: Context) {}
}

final class KeyboardSceneView: SKView {
  weak var model: GameModel?
  override var canBecomeFirstResponder: Bool { true }

  override func layoutSubviews() {
    super.layoutSubviews()
    model?.scene.resize(bounds.size)
  }

  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      switch press.key?.keyCode {
      case .keyboardLeftArrow, .keyboardA: model?.move(-1)
      case .keyboardRightArrow, .keyboardD: model?.move(1)
      case .keyboardSpacebar, .keyboardUpArrow, .keyboardW: model?.jump(true)
      case .keyboardEscape: model?.pause()
      default: super.pressesBegan(presses, with: event)
      }
    }
  }

  override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      switch press.key?.keyCode {
      case .keyboardLeftArrow, .keyboardA, .keyboardRightArrow, .keyboardD: model?.move(0)
      case .keyboardSpacebar, .keyboardUpArrow, .keyboardW: model?.jump(false)
      default: super.pressesEnded(presses, with: event)
      }
    }
  }

  override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    model?.scene.game.clearInput()
  }
}
