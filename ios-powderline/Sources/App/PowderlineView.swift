import SwiftUI
import UIKit

struct PowderlineView: View {
  @StateObject private var store = RideStore()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let cream = Color(hex: 0xF5EEDD)
  private let ink = Color(hex: 0x1B3C50)

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        AlpineCanvas(
          engine: store.engine, time: store.sceneryTime,
          isHome: store.screen == .home, reduceMotion: reduceMotion
        )
        switch store.screen {
        case .home:
          home
        case .riding:
          rideHUD(size: geometry.size)
        case .paused:
          pause
        case .results:
          results
        }
        if store.showGuide { guide }
      }
      .foregroundStyle(cream)
    }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { store.background() }
    }
    .onChange(of: reduceMotion, initial: true) { _, value in
      store.reduceMotion = value
    }
    .dynamicTypeSize(.xSmall ... .xxxLarge)
  }

  private var home: some View {
    VStack(spacing: 0) {
      HStack {
        Label("ALPINE JOURNAL / 01", systemImage: "mountain.2")
          .font(.system(size: 9, weight: .medium, design: .monospaced))
          .tracking(1.3)
        Spacer()
        soundButton
      }
      .padding(.bottom, 31)
      VStack(spacing: 14) {
        MountainMark()
          .stroke(
            cream.opacity(0.82),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
          )
          .frame(width: 58, height: 28)
          .padding(.bottom, 4)
        Text("POWDERLINE")
          .font(.system(size: 43, weight: .light, design: .serif))
          .tracking(2.1)
          .minimumScaleFactor(0.7)
          .lineLimit(1)
        Text("Leave everything behind.")
          .font(.system(size: 15, weight: .regular, design: .serif))
          .italic()
          .foregroundStyle(cream.opacity(0.82))
        HStack(spacing: 8) {
          Rectangle().frame(width: 20, height: 0.5)
          Text("AN ENDLESS ALPINE ODYSSEY")
            .font(.system(size: 8, weight: .medium))
            .tracking(2.1)
          Rectangle().frame(width: 20, height: 0.5)
        }
        .foregroundStyle(cream.opacity(0.55))
        .padding(.top, 5)
      }
      Spacer(minLength: 125)
      VStack(spacing: 13) {
        if store.records.rides > 0 {
          HStack(spacing: 25) {
            miniRecord("BEST DISTANCE", value: "\(store.records.bestDistance)m")
            miniRecord("BEST SCORE", value: store.records.bestScore.formatted())
          }
          .foregroundStyle(ink)
          .padding(.bottom, 6)
        } else {
          Text("A fresh trail. A quieter mind.")
            .font(.system(size: 13, design: .serif))
            .italic()
            .foregroundStyle(ink.opacity(0.80))
            .padding(.bottom, 6)
        }
        primaryButton("Begin the descent", icon: "arrow.right") { store.start(.expedition) }
        Button {
          store.start(.practice)
        } label: {
          HStack(spacing: 9) {
            Image(systemName: "leaf")
            Text("Zen practice")
            Text("·").opacity(0.5)
            Text("No stakes").opacity(0.6)
          }
          .font(.system(size: 13, weight: .medium))
          .frame(maxWidth: .infinity, minHeight: 44)
          .background(ink.opacity(0.06), in: Capsule())
          .overlay(Capsule().stroke(ink.opacity(0.12), lineWidth: 1))
        }
        .foregroundStyle(ink)
        Button {
          store.showGuide = true
        } label: {
          Text("HOW TO RIDE")
            .font(.system(size: 9, weight: .semibold))
            .tracking(2)
            .frame(minWidth: 120, minHeight: 44)
        }
        .foregroundStyle(ink.opacity(0.75))
      }
      .padding(.horizontal, 12)
    }
    .padding(.horizontal, 25)
    .padding(.top, 2)
    .padding(.bottom, 4)
  }

  private func rideHUD(size: CGSize) -> some View {
    ZStack {
      TouchSurface(onPress: store.press, onRelease: store.release)
        .accessibilityLabel("Snowboard. Tap to jump. Hold to backflip.")
        .accessibilityIdentifier("rideSurface")
        .padding(.top, 125)
        .padding(.bottom, 110)
      VStack(spacing: 0) {
        HStack(alignment: .top, spacing: 20) {
          VStack(alignment: .leading, spacing: 1) {
            eyebrow(store.engine.mode == .practice ? "ZEN PRACTICE" : "DISTANCE")
            HStack(alignment: .firstTextBaseline, spacing: 3) {
              Text("\(store.engine.distance)")
                .font(.system(size: 42, weight: .light, design: .rounded))
                .contentTransition(.numericText())
              Text("m").font(.system(size: 15, weight: .light))
            }
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Distance \(store.engine.distance) meters")
          }
          Spacer(minLength: 0)
          VStack(alignment: .trailing, spacing: 5) {
            eyebrow(store.engine.mode == .practice ? "PRACTICE SCORE" : "SCORE")
            Text(store.engine.score.formatted())
              .font(.system(size: 25, weight: .light, design: .rounded))
              .monospacedDigit()
              .accessibilityLabel("Score \(store.engine.score)")
            Label("\(store.engine.coins)", systemImage: "circle.inset.filled")
              .font(.system(size: 11, weight: .medium, design: .monospaced))
              .foregroundStyle(Color(hex: 0xFFD89E))
          }
          Button(action: store.pause) {
            Image(systemName: "pause")
              .font(.system(size: 15, weight: .medium))
              .frame(width: 44, height: 44)
              .background(.white.opacity(0.09), in: Circle())
              .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 0.7))
          }
          .accessibilityLabel("Pause")
        }
        .padding(.horizontal, 27)
        .padding(.top, 12)
        HStack {
          Circle().fill(Color(hex: 0xE6B98D)).frame(width: 4, height: 4)
          Text(daylight)
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .tracking(1.8)
          Spacer()
          if store.engine.combo > 0 {
            Text("\(store.engine.combo)× FLOW")
              .font(.system(size: 9, weight: .semibold))
              .tracking(1.5)
          }
        }
        .foregroundStyle(cream.opacity(0.65))
        .padding(.horizontal, 29)
        .padding(.top, 20)
        if store.engine.nextHazard.x - store.engine.x < 305 {
          HStack(spacing: 7) {
            Image(systemName: store.engine.nextHazard.kind == .rock ? "triangle" : "flag")
            Text(store.engine.nextHazard.kind == .rock ? "ROCK AHEAD" : "RAVINE AHEAD")
          }
          .font(.system(size: 9, weight: .semibold))
          .tracking(1.6)
          .padding(.horizontal, 13)
          .padding(.vertical, 9)
          .background(ink.opacity(0.38), in: Capsule())
          .padding(.top, 27)
          .accessibilityIdentifier("hazardWarning")
        }
        Spacer()
        if store.toastTime > 0 {
          VStack(spacing: 7) {
            Text(store.toast)
              .font(.system(size: 19, weight: .medium, design: .serif))
              .tracking(2)
            Text(store.toastDetail)
              .font(.system(size: 10, weight: .medium, design: .monospaced))
          }
          .foregroundStyle(cream)
          .shadow(color: ink.opacity(0.5), radius: 12)
          .padding(.bottom, size.height * 0.26)
          .allowsHitTesting(false)
          .accessibilityElement(children: .combine)
        } else if store.engine.elapsed < 4.5 {
          VStack(spacing: 8) {
            Text("Find your flow.")
              .font(.system(size: 25, weight: .light, design: .serif))
            Text("Tap to jump. Hold for a backflip.")
              .font(.system(size: 12))
          }
          .padding(.bottom, size.height * 0.26)
          .allowsHitTesting(false)
        }
        Spacer().frame(height: 100)
      }
      VStack {
        Spacer()
        VStack(spacing: 10) {
          if !store.engine.grounded {
            HStack(spacing: 7) {
              Image(systemName: "arrow.counterclockwise")
              Text(landingHint)
            }
            .font(.system(size: 10, weight: .semibold))
            .tracking(1)
            .foregroundStyle(ink)
            .frame(height: 20)
          } else {
            Text(
              store.engine.mode == .practice
                ? "GENTLE PACE · FALLS ARE FORGIVEN" : "FIND AIR. CHASE THE HORIZON."
            )
            .font(.system(size: 8, weight: .medium))
            .tracking(1.8)
            .foregroundStyle(ink.opacity(0.65))
            .frame(height: 20)
          }
          HoldControl(onPress: store.press, onRelease: store.release)
            .frame(height: 56)
        }
        .padding(.horizontal, 31)
        .padding(.bottom, 10)
      }
    }
  }

  private var pause: some View {
    ZStack {
      ink.opacity(0.68).ignoresSafeArea()
      VStack(spacing: 23) {
        HStack {
          eyebrow("TAKE A BREATH")
          Spacer()
          soundButton
        }
        Spacer()
        Image(systemName: "snowflake")
          .font(.system(size: 25, weight: .ultraLight))
          .padding(.bottom, 5)
        Text("The mountain\ncan wait.")
          .font(.system(size: 44, weight: .light, design: .serif))
          .multilineTextAlignment(.center)
        Text("\(store.engine.distance)m into the quiet.")
          .font(.system(size: 14, design: .serif))
          .italic()
          .foregroundStyle(cream.opacity(0.7))
        Spacer()
        primaryButton("Keep riding", icon: "play.fill", light: true, action: store.resume)
        Button(action: store.finish) {
          Text(store.engine.mode == .practice ? "Finish practice" : "End this ride")
            .font(.system(size: 14))
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        Button {
          store.showGuide = true
        } label: {
          Text("Touch controls").font(.system(size: 12)).frame(minHeight: 44)
        }
        .foregroundStyle(cream.opacity(0.6))
      }
      .padding(.horizontal, 37)
      .padding(.vertical, 18)
    }
  }

  private var results: some View {
    ZStack {
      ink.opacity(0.69).ignoresSafeArea()
      VStack(spacing: 17) {
        HStack {
          eyebrow(
            store.engine.mode == .practice ? "ZEN PRACTICE / COMPLETE" : "YOUR ALPINE JOURNAL")
          Spacer()
          Button(action: store.home) {
            Image(systemName: "xmark").font(.system(size: 15)).frame(width: 44, height: 44)
          }
          .accessibilityLabel("Back to title")
        }
        Spacer(minLength: 5)
        Text(
          store.engine.mode == .practice
            ? "A little closer\nto the flow." : "Beautiful,\nwhile it lasted."
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.center)
        .lineSpacing(-2)
        Text(
          store.engine.crashReason.isEmpty
            ? "Every descent is a new beginning."
            : store.engine.crashReason + ". There’s always another trail."
        )
        .font(.system(size: 12, design: .serif))
        .italic()
        .multilineTextAlignment(.center)
        .foregroundStyle(cream.opacity(0.74))
        .fixedSize(horizontal: false, vertical: true)
        VStack(spacing: 19) {
          HStack {
            eyebrow(
              store.newBest
                ? "A NEW PERSONAL BEST"
                : store.engine.mode == .practice ? "PRACTICE SESSION" : "THIS DESCENT")
            Spacer()
            Image(systemName: store.newBest ? "sparkle" : "mountain.2")
              .font(.system(size: 16, weight: .light))
          }
          .foregroundStyle(ink.opacity(0.7))
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(store.engine.score.formatted())
              .font(.system(size: 57, weight: .light, design: .rounded))
              .minimumScaleFactor(0.7)
              .lineLimit(1)
            Text("points")
              .font(.system(size: 14, design: .serif))
              .italic()
              .foregroundStyle(ink.opacity(0.64))
            Spacer(minLength: 0)
          }
          Rectangle().fill(ink.opacity(0.16)).frame(height: 0.5)
          HStack {
            resultStat("\(store.engine.distance)m", label: "DISTANCE")
            Spacer()
            resultStat("\(store.engine.flips)", label: "BACKFLIPS")
            Spacer()
            resultStat("\(store.engine.coins)", label: "COINS")
          }
          if store.engine.bestCombo > 1 {
            Text("BEST FLOW  \(store.engine.bestCombo)×")
              .font(.system(size: 10, weight: .medium, design: .monospaced))
              .tracking(1.5)
          }
          Text(
            store.engine.mode == .practice
              ? "Practice is separate from expedition records."
              : "Personal best  \(store.records.bestScore.formatted()) pts  ·  \(store.records.bestDistance)m"
          )
          .font(.system(size: 10))
          .foregroundStyle(ink.opacity(0.62))
          .multilineTextAlignment(.center)
        }
        .foregroundStyle(ink)
        .padding(24)
        .background(cream, in: RoundedRectangle(cornerRadius: 24))
        .padding(.top, 8)
        Spacer(minLength: 3)
        primaryButton("Ride again", icon: "arrow.right", light: true) {
          store.start(store.engine.mode)
        }
        HStack {
          Button(action: store.home) {
            Text("Back to the lodge").frame(maxWidth: .infinity, minHeight: 44)
          }
          ShareLink(item: shareText) {
            Label("Share ride", systemImage: "square.and.arrow.up")
              .frame(maxWidth: .infinity, minHeight: 44)
          }
        }
        .font(.system(size: 12))
        .foregroundStyle(cream.opacity(0.7))
      }
      .padding(.horizontal, 29)
      .padding(.top, 6)
      .padding(.bottom, 8)
    }
  }

  private var guide: some View {
    ZStack {
      ink.opacity(0.98).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 22) {
        HStack {
          eyebrow("A FIELD GUIDE")
          Spacer()
          Button {
            store.showGuide = false
          } label: {
            Image(systemName: "xmark").frame(width: 44, height: 44)
          }.accessibilityLabel("Close guide")
        }
        Text("One touch.\nAn open mountain.")
          .font(.system(size: 35, weight: .light, design: .serif))
          .padding(.bottom, 5)
        guideRow(
          "01", title: "Tap for air",
          detail: "Tap anywhere on the snow or the bottom control to jump over rocks and ravines.",
          icon: "hand.tap")
        guideRow(
          "02", title: "Hold. Flip. Let go.",
          detail:
            "Keep holding for a backflip. Release when your board comes around, then land upright.",
          icon: "arrow.counterclockwise")
        guideRow(
          "03", title: "Find your flow",
          detail:
            "Land backflips close together to build a combo up to 5×. Gold coins add 25 points.",
          icon: "sparkles")
        guideRow(
          "04", title: "Take the quiet trail",
          detail:
            "Zen practice rides at a gentler pace and rescues every fall. Its progress stays separate.",
          icon: "leaf")
        Spacer(minLength: 0)
        primaryButton("I’m ready", icon: "arrow.right", light: true) { store.showGuide = false }
      }
      .padding(.horizontal, 31)
      .padding(.vertical, 12)
    }
  }

  private var soundButton: some View {
    Button(action: store.toggleSound) {
      Image(systemName: store.soundEnabled ? "speaker.wave.2" : "speaker.slash")
        .font(.system(size: 15, weight: .regular))
        .frame(width: 44, height: 44)
        .background(.white.opacity(0.06), in: Circle())
    }
    .accessibilityLabel(store.soundEnabled ? "Sound on. Mute." : "Sound off. Unmute.")
  }

  private var daylight: String {
    if store.engine.x > 19000 { return "APRICOT HOUR / 17:42" }
    if store.engine.x > 9500 { return "HIGH COUNTRY / 12:08" }
    return "FIRST LIGHT / 06:14"
  }

  private var landingHint: String {
    let safe = RideEngine.isSafeLanding(
      rotation: store.engine.rotation, slope: RideEngine.slope(at: store.engine.x))
    return safe ? "BOARD LEVEL · RELEASE TO LAND" : "KEEP ROTATING · FIND LEVEL"
  }

  private var shareText: String {
    let mode = store.engine.mode == .practice ? "Zen practice" : "Expedition"
    return
      "Powderline · \(mode)\n\(store.engine.distance)m through the mountains. \(store.engine.score) points, \(store.engine.flips) backflips, \(store.engine.coins) coins.\nLeave everything behind."
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 8, weight: .semibold)).tracking(1.8)
  }

  private func miniRecord(_ label: String, value: String) -> some View {
    VStack(spacing: 4) {
      Text(value).font(.system(size: 20, weight: .light, design: .rounded))
      Text(label).font(.system(size: 7, weight: .semibold)).tracking(1.5)
    }
  }

  private func resultStat(_ value: String, label: String) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(value).font(.system(size: 23, weight: .light, design: .rounded))
      Text(label).font(.system(size: 7, weight: .medium)).tracking(1.0)
    }
  }

  private func primaryButton(
    _ title: String, icon: String, light: Bool = false, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Spacer()
        Text(title).font(.system(size: 16, weight: .medium, design: .serif))
        Spacer()
        Image(systemName: icon).font(.system(size: 13, weight: .medium))
      }
      .padding(.horizontal, 24)
      .frame(height: 57)
      .foregroundStyle(light ? ink : cream)
      .background(light ? cream : ink, in: Capsule())
    }
    .buttonStyle(.plain)
  }

  private func guideRow(_ index: String, title: String, detail: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: 15) {
      Image(systemName: icon)
        .font(.system(size: 21, weight: .light))
        .frame(width: 37, height: 42)
        .foregroundStyle(Color(hex: 0xEDBE98))
      VStack(alignment: .leading, spacing: 7) {
        Text(title).font(.system(size: 19, weight: .regular, design: .serif))
        Text(detail).font(.system(size: 12)).lineSpacing(4)
          .foregroundStyle(cream.opacity(0.65))
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct HoldControl: View {
  let onPress: () -> Void
  let onRelease: () -> Void

  var body: some View {
    ZStack {
      Capsule().fill(Color(hex: 0x1B3C50).opacity(0.10))
      Capsule().stroke(Color(hex: 0x1B3C50).opacity(0.17), lineWidth: 1)
      HStack(spacing: 11) {
        Image(systemName: "hand.tap").font(.system(size: 16))
        Text("TAP TO JUMP").tracking(1.2)
        Text("·").opacity(0.4)
        Text("HOLD TO FLIP").tracking(1.2)
      }
      .font(.system(size: 9, weight: .semibold))
      .foregroundStyle(Color(hex: 0x1B3C50))
      .allowsHitTesting(false)
      TouchSurface(onPress: onPress, onRelease: onRelease)
        .accessibilityLabel("Jump. Hold to backflip.")
        .accessibilityIdentifier("jumpControl")
    }
  }
}

struct TouchSurface: UIViewRepresentable {
  let onPress: () -> Void
  let onRelease: () -> Void

  func makeUIView(context: Context) -> SnowTouchView {
    let view = SnowTouchView()
    view.isAccessibilityElement = true
    view.accessibilityTraits = .button
    view.onPress = onPress
    view.onRelease = onRelease
    return view
  }

  func updateUIView(_ uiView: SnowTouchView, context: Context) {
    uiView.onPress = onPress
    uiView.onRelease = onRelease
  }
}

final class SnowTouchView: UIView {
  var onPress: (() -> Void)?
  var onRelease: (() -> Void)?
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { onPress?() }
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { onRelease?() }
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { onRelease?() }
  override func accessibilityActivate() -> Bool {
    onPress?()
    onRelease?()
    return true
  }
}

struct MountainMark: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.addLines([
      CGPoint(x: rect.minX, y: rect.maxY),
      CGPoint(x: rect.width * 0.34, y: rect.minY),
      CGPoint(x: rect.width * 0.58, y: rect.maxY),
    ])
    path.move(to: CGPoint(x: rect.width * 0.45, y: rect.height * 0.47))
    path.addLine(to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.13))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    return path
  }
}
