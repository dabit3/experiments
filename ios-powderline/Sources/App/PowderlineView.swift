import SwiftUI
import UIKit

struct PowderlineView: View {
  @StateObject private var store = RideStore()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private let cream = Palette.cream
  private let ink = Palette.ink

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        AlpineCanvas(
          engine: store.engine, time: store.sceneryTime,
          isHome: store.screen == .home, reduceMotion: reduceMotion,
          impactTime: store.impactTime
        )
        switch store.screen {
        case .home:
          home.transition(.opacity)
        case .riding:
          rideHUD(size: geometry.size)
        case .paused:
          pause.transition(.opacity)
        case .results:
          results.transition(.opacity.combined(with: .offset(y: 24)))
        }
        if store.showGuide { guide.transition(.move(edge: .bottom).combined(with: .opacity)) }
      }
      .animation(reduceMotion ? nil : .easeOut(duration: 0.34), value: store.screen)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: store.showGuide)
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

  // MARK: Home

  private var home: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center) {
        HStack(spacing: 8) {
          GlyphView(glyph: .peaks, size: 15, weight: 1.3)
          Text("EXPEDITION NO. 01")
            .font(.system(size: 9, weight: .semibold))
            .tracking(2.2)
        }
        .foregroundStyle(cream.opacity(0.78))
        Spacer()
        soundButton
      }
      .padding(.bottom, 44)

      Wordmark()
      Text("Leave everything behind.")
        .font(.system(size: 16, weight: .regular, design: .serif))
        .italic()
        .foregroundStyle(cream.opacity(0.86))
        .padding(.top, 10)

      Spacer(minLength: 110)

      VStack(spacing: 12) {
        if store.records.rides > 0 {
          HStack(spacing: 0) {
            recordColumn("BEST DISTANCE", value: "\(store.records.bestDistance) m")
            divider
            recordColumn("BEST SCORE", value: store.records.bestScore.formatted())
            divider
            recordColumn("BACKFLIPS", value: store.records.totalFlips.formatted())
          }
          .padding(.vertical, 13)
          .padding(.horizontal, 8)
          .background(ink.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
          .overlay(RoundedRectangle(cornerRadius: 18).stroke(cream.opacity(0.14), lineWidth: 1))
          .padding(.bottom, 6)
        } else {
          Text("A fresh trail. A quieter mind.")
            .font(.system(size: 14, design: .serif))
            .italic()
            .foregroundStyle(ink.opacity(0.8))
            .padding(.bottom, 8)
        }

        primaryButton("Begin the descent") { store.start(.expedition) }

        HStack(spacing: 10) {
          secondaryButton("Zen practice", glyph: .leaf) { store.start(.practice) }
          secondaryButton("How to ride", glyph: .tap) { store.showGuide = true }
        }
      }
      .padding(.horizontal, 4)
    }
    .padding(.horizontal, 26)
    .padding(.top, 4)
    .padding(.bottom, 6)
  }

  private var divider: some View {
    Rectangle().fill(cream.opacity(0.16)).frame(width: 1, height: 30)
  }

  private func recordColumn(_ label: String, value: String) -> some View {
    VStack(spacing: 5) {
      Text(value)
        .font(.system(size: 19, weight: .light, design: .rounded))
        .monospacedDigit()
        .minimumScaleFactor(0.7)
        .lineLimit(1)
      Text(label)
        .font(.system(size: 7, weight: .semibold))
        .tracking(1.6)
        .foregroundStyle(Palette.amber)
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: Ride HUD

  private func rideHUD(size: CGSize) -> some View {
    ZStack {
      TouchSurface(onPress: store.press, onRelease: store.release)
        .accessibilityLabel("Snowboard. Tap to jump. Hold to backflip.")
        .accessibilityIdentifier("rideSurface")
        .padding(.top, 150)
        .padding(.bottom, 110)

      VStack(spacing: 0) {
        HStack(alignment: .top, spacing: 16) {
          VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
              Text("\(store.engine.distance)")
                .font(.system(size: 46, weight: .light, design: .rounded))
                .contentTransition(.numericText())
              Text("m")
                .font(.system(size: 17, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(cream.opacity(0.7))
            }
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Distance \(store.engine.distance) meters")
            eyebrow(store.engine.mode == .practice ? "ZEN PRACTICE" : "DISTANCE")
              .foregroundStyle(Palette.amber)
          }
          Spacer(minLength: 0)
          VStack(alignment: .trailing, spacing: 6) {
            Text(store.engine.score.formatted())
              .font(.system(size: 27, weight: .light, design: .rounded))
              .monospacedDigit()
              .padding(.top, 8)
              .accessibilityLabel("Score \(store.engine.score)")
            HStack(spacing: 5) {
              GlyphView(glyph: .gem, size: 9, weight: 1.2)
              Text("\(store.engine.coins)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(Palette.amber)
            eyebrow(store.engine.mode == .practice ? "PRACTICE SCORE" : "SCORE")
              .foregroundStyle(cream.opacity(0.6))
          }
          iconButton(.pause, label: "Pause", action: store.pause)
            .disabled(store.impactTime > 0)
        }
        .padding(.horizontal, 26)
        .padding(.top, 8)

        flowMeter
          .padding(.horizontal, 26)
          .padding(.top, 14)

        trailRadar(width: size.width - 52)
          .padding(.horizontal, 26)
          .padding(.top, 10)

        Spacer()
        if store.impactTime > 0 {
          Text(store.engine.crashReason)
            .font(.system(size: 22, weight: .medium, design: .serif))
            .padding(.horizontal, 22)
            .padding(.vertical, 13)
            .background(Palette.inkDeep.opacity(0.88), in: Capsule())
            .overlay(Capsule().stroke(Palette.coral.opacity(0.7), lineWidth: 1))
            .padding(.bottom, size.height * 0.26)
            .allowsHitTesting(false)
        } else if store.toastTime > 0 {
          VStack(spacing: 6) {
            Text(store.toast)
              .font(.system(size: 21, weight: .semibold, design: .serif))
              .tracking(1.5)
            Text(store.toastDetail)
              .font(.system(size: 11, weight: .semibold, design: .monospaced))
              .foregroundStyle(Palette.amber)
          }
          .foregroundStyle(cream)
          .padding(.horizontal, 22)
          .padding(.vertical, 13)
          .background(Palette.inkDeep.opacity(0.86), in: RoundedRectangle(cornerRadius: 14))
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(cream.opacity(0.16)))
          .padding(.bottom, size.height * 0.26)
          .allowsHitTesting(false)
          .accessibilityElement(children: .combine)
        } else if store.engine.elapsed < 4.5 && !store.hasJumped {
          VStack(spacing: 8) {
            Text("Find your flow.")
              .font(.system(size: 27, weight: .regular, design: .serif))
              .italic()
            Text("TAP TO JUMP · HOLD FOR A BACKFLIP")
              .font(.system(size: 9, weight: .semibold))
              .tracking(2)
              .foregroundStyle(cream.opacity(0.8))
          }
          .shadow(color: Palette.inkDeep.opacity(0.5), radius: 10, y: 4)
          .padding(.bottom, size.height * 0.26)
          .allowsHitTesting(false)
        }
        Spacer().frame(height: 100)
      }

      VStack {
        Spacer()
        VStack(spacing: 9) {
          Group {
            if !store.engine.grounded {
              HStack(spacing: 7) {
                GlyphView(glyph: .rotate, size: 11, weight: 1.4)
                Text(landingHint)
              }
              .font(.system(size: 10, weight: .semibold))
              .tracking(1)
            } else {
              Text(
                store.engine.mode == .practice
                  ? "GENTLE PACE · FALLS ARE FORGIVEN" : "FIND AIR · CHASE THE HORIZON"
              )
              .font(.system(size: 8, weight: .semibold))
              .tracking(2)
            }
          }
          .foregroundStyle(cream)
          .frame(height: 22)
          .padding(.horizontal, 12)
          .background(Palette.inkDeep.opacity(0.82), in: Capsule())
          .overlay(Capsule().stroke(cream.opacity(0.18), lineWidth: 1))
          HoldControl(onPress: store.press, onRelease: store.release)
            .frame(height: 56)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 10)
      }
    }
  }

  private var flowMeter: some View {
    HStack(spacing: 10) {
      HStack(spacing: 4) {
        ForEach(0..<5, id: \.self) { index in
          RoundedRectangle(cornerRadius: 1.5)
            .fill(index < store.engine.combo ? Palette.amber : cream.opacity(0.22))
            .frame(width: 18, height: 3)
        }
      }
      .overlay(alignment: .leading) {
        if store.engine.combo > 0 {
          RoundedRectangle(cornerRadius: 1.5)
            .fill(cream)
            .frame(width: 106 * store.engine.comboTime / 5.5, height: 1)
            .offset(y: 4)
        }
      }
      Text(store.engine.combo > 0 ? "FLOW \(store.engine.combo)×" : "FLOW")
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .tracking(1.4)
        .foregroundStyle(store.engine.combo > 0 ? Palette.amber : cream.opacity(0.5))
        .contentTransition(.numericText())
        .accessibilityLabel("\(store.engine.combo) times combo")
      Spacer()
      HStack(spacing: 6) {
        Circle().fill(Palette.amber).frame(width: 4, height: 4)
        Text(daylight)
          .font(.system(size: 8, weight: .medium, design: .monospaced))
          .tracking(1.6)
      }
      .foregroundStyle(cream.opacity(0.6))
    }
  }

  /// A thin route line: the rider tick sits left and the next hazard marker
  /// slides in from the right as it approaches.
  private func trailRadar(width: CGFloat) -> some View {
    let hazard = store.engine.nextHazard
    let ahead = hazard.x - store.engine.x
    let span = 520.0
    return ZStack(alignment: .leading) {
      Line().stroke(cream.opacity(0.28), style: StrokeStyle(lineWidth: 1, dash: [2, 5]))
        .frame(height: 1)
      Circle().fill(cream).frame(width: 5, height: 5)
      if ahead < span {
        let fraction = max(0, ahead / span)
        VStack(spacing: 3) {
          GlyphView(glyph: hazard.kind == .rock ? .rock : .flag, size: 13, weight: 1.5)
          Text(hazard.kind == .rock ? "ROCK" : "RAVINE")
            .font(.system(size: 8.5, weight: .bold))
            .tracking(1.6)
        }
        .foregroundStyle(ahead < 180 ? Palette.coral : Palette.amber)
        .shadow(color: Palette.inkDeep.opacity(0.7), radius: 3)
        .frame(width: 52)
        .offset(x: min(width - 22, 8 + fraction * (width - 30)) - 22, y: 13)
        .accessibilityIdentifier("hazardWarning")
        .accessibilityLabel(hazard.kind == .rock ? "Rock ahead" : "Ravine ahead")
      }
    }
    .frame(height: 30, alignment: .top)
  }

  // MARK: Pause

  private var pause: some View {
    ZStack {
      Palette.inkDeep.opacity(0.74).ignoresSafeArea()
      VStack(spacing: 22) {
        HStack {
          eyebrow("TAKE A BREATH")
          Spacer()
          soundButton
        }
        Spacer()
        GlyphView(glyph: .snowflake, size: 34, weight: 1.2)
          .foregroundStyle(Palette.amber)
          .padding(.bottom, 4)
        Text("The mountain\ncan wait.")
          .font(.system(size: 44, weight: .semibold, design: .serif))
          .multilineTextAlignment(.center)
        Text("\(store.engine.distance) m into the quiet.")
          .font(.system(size: 15, design: .serif))
          .italic()
          .foregroundStyle(cream.opacity(0.72))
        Spacer()
        primaryButton("Keep riding", glyph: .play, light: true, action: store.resume)
        Button(action: store.finish) {
          Text(store.engine.mode == .practice ? "Finish practice" : "End this ride")
            .font(.system(size: 14, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        Button {
          store.showGuide = true
        } label: {
          Text("TOUCH CONTROLS").font(.system(size: 9, weight: .semibold)).tracking(2)
            .frame(minHeight: 44)
        }
        .foregroundStyle(cream.opacity(0.6))
      }
      .padding(.horizontal, 36)
      .padding(.vertical, 16)
    }
  }

  // MARK: Results

  private var results: some View {
    ZStack {
      Palette.inkDeep.opacity(0.78).ignoresSafeArea()
      VStack(spacing: 14) {
        HStack {
          eyebrow(
            store.engine.mode == .practice ? "ZEN PRACTICE · COMPLETE" : "ALPINE JOURNAL · ENTRY")
          Spacer()
          iconButton(.close, label: "Back to title", action: store.home)
        }
        Spacer(minLength: 4)
        Text(
          store.engine.mode == .practice
            ? "A little closer\nto the flow." : "Beautiful,\nwhile it lasted."
        )
        .font(.system(size: 36, weight: .semibold, design: .serif))
        .multilineTextAlignment(.center)
        .lineSpacing(-1)
        Text(
          store.engine.crashReason.isEmpty
            ? "Every descent is a new beginning."
            : store.engine.crashReason + ". There’s always another trail."
        )
        .font(.system(size: 13, design: .serif))
        .italic()
        .multilineTextAlignment(.center)
        .foregroundStyle(cream.opacity(0.74))
        .fixedSize(horizontal: false, vertical: true)

        journalCard
          .padding(.top, 6)

        Spacer(minLength: 2)
        primaryButton("Ride again", light: true) { store.start(store.engine.mode) }
        HStack {
          Button(action: store.home) {
            Text("Back to the lodge").frame(maxWidth: .infinity, minHeight: 44)
          }
          ShareLink(item: shareText) {
            HStack(spacing: 7) {
              GlyphView(glyph: .share, size: 12, weight: 1.3)
              Text("Share ride")
            }
            .frame(maxWidth: .infinity, minHeight: 44)
          }
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(cream.opacity(0.72))
      }
      .padding(.horizontal, 28)
      .padding(.top, 4)
      .padding(.bottom, 8)
    }
  }

  private var journalCard: some View {
    VStack(spacing: 0) {
      RidgeBand()
        .frame(height: 46)
        .overlay(alignment: .topLeading) {
          eyebrow(store.engine.mode == .practice ? "PRACTICE SESSION" : "THIS DESCENT")
            .foregroundStyle(cream)
            .padding(.leading, 22)
            .padding(.top, 16)
        }
        .overlay(alignment: .topTrailing) {
          if store.newBest {
            StampBadge(title: "NEW BEST").padding(.trailing, 22).padding(.top, 10)
          }
        }
      VStack(spacing: 16) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(store.engine.score.formatted())
            .font(.system(size: 58, weight: .light, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.6)
            .lineLimit(1)
          Text("points")
            .font(.system(size: 15, design: .serif))
            .italic()
            .foregroundStyle(ink.opacity(0.6))
          Spacer(minLength: 0)
          if store.engine.bestCombo > 1 {
            VStack(alignment: .trailing, spacing: 3) {
              Text("\(store.engine.bestCombo)×")
                .font(.system(size: 22, weight: .light, design: .rounded))
              Text("BEST FLOW").font(.system(size: 7, weight: .semibold)).tracking(1.4)
                .foregroundStyle(Palette.coral)
            }
          }
        }
        .padding(.horizontal, 22)
        Perforation()
        HStack(spacing: 0) {
          resultStat("\(store.engine.distance) m", label: "DISTANCE", glyph: .peaks)
          resultStat("\(store.engine.flips)", label: "BACKFLIPS", glyph: .rotate)
          resultStat("\(store.engine.coins)", label: "COINS", glyph: .gem)
        }
        .padding(.horizontal, 14)
        Text(
          store.engine.mode == .practice
            ? "Practice is separate from expedition records."
            : "Personal best  \(store.records.bestScore.formatted()) pts  ·  \(store.records.bestDistance) m"
        )
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(ink.opacity(0.6))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 22)
      }
      .padding(.top, 14)
      .padding(.bottom, 20)
    }
    .foregroundStyle(ink)
    .background(cream, in: RoundedRectangle(cornerRadius: 22))
    .clipShape(RoundedRectangle(cornerRadius: 22))
    .shadow(color: Palette.inkDeep.opacity(0.35), radius: 24, y: 12)
  }

  // MARK: Guide

  private var guide: some View {
    ZStack {
      Palette.inkDeep.ignoresSafeArea()
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          eyebrow("A FIELD GUIDE")
          Spacer()
          iconButton(.close, label: "Close guide") { store.showGuide = false }
        }
        Text("One touch.\nAn open mountain.")
          .font(.system(size: 36, weight: .semibold, design: .serif))
          .padding(.bottom, 4)
        guideRow(
          "01", title: "Tap for air",
          detail: "Tap anywhere on the snow or the bottom control to jump rocks and ravines.",
          glyph: .tap)
        guideRow(
          "02", title: "Hold. Flip. Let go.",
          detail:
            "Hold for about 1.2 seconds. Release as the board comes around and the cue reads LEVEL.",
          glyph: .rotate)
        guideRow(
          "03", title: "Find your flow",
          detail:
            "Land backflips within 5.5 seconds of each other to build flow up to 5×. Gems add 25 points.",
          glyph: .flow)
        guideRow(
          "04", title: "Take the quiet trail",
          detail:
            "Zen practice rides at a gentler pace and rescues every fall. Its progress stays separate.",
          glyph: .leaf)
        Spacer(minLength: 0)
        primaryButton("I’m ready", light: true) { store.showGuide = false }
      }
      .padding(.horizontal, 30)
      .padding(.vertical, 12)
    }
  }

  // MARK: Shared pieces

  private var soundButton: some View {
    iconButton(
      store.soundEnabled ? .sound : .muted,
      label: store.soundEnabled ? "Sound on. Mute." : "Sound off. Unmute.",
      action: store.toggleSound)
  }

  private func iconButton(_ glyph: Glyph, label: String, action: @escaping () -> Void) -> some View
  {
    Button(action: action) {
      GlyphView(glyph: glyph, size: 16, weight: 1.5)
        .frame(width: 44, height: 44)
        .background(Palette.inkDeep.opacity(0.32), in: Circle())
        .overlay(Circle().stroke(cream.opacity(0.28), lineWidth: 1))
    }
    .buttonStyle(PressStyle())
    .accessibilityLabel(label)
  }

  private var daylight: String {
    if store.engine.x > 19000 { return "APRICOT HOUR" }
    if store.engine.x > 9500 { return "HIGH COUNTRY" }
    return "FIRST LIGHT"
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
    Text(text).font(.system(size: 8, weight: .semibold)).tracking(2)
  }

  private func resultStat(_ value: String, label: String, glyph: Glyph) -> some View {
    VStack(spacing: 6) {
      GlyphView(glyph: glyph, size: 13, weight: 1.3).foregroundStyle(Palette.coral)
      Text(value).font(.system(size: 22, weight: .light, design: .rounded)).monospacedDigit()
      Text(label).font(.system(size: 7, weight: .semibold)).tracking(1.4)
        .foregroundStyle(ink.opacity(0.6))
    }
    .frame(maxWidth: .infinity)
  }

  private func primaryButton(
    _ title: String, glyph: Glyph = .arrow, light: Bool = false, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack {
        Spacer()
        Text(title).font(.system(size: 17, weight: .semibold, design: .serif))
        Spacer()
        GlyphView(glyph: glyph, size: 14, weight: 1.6)
      }
      .padding(.horizontal, 24)
      .frame(height: 58)
      .foregroundStyle(light ? ink : cream)
      .background(
        LinearGradient(
          colors: light ? [cream, Palette.paper] : [Color(hex: 0x1D3550), Palette.inkDeep],
          startPoint: .top, endPoint: .bottom),
        in: Capsule()
      )
      .overlay(
        Capsule().stroke(
          (light ? Color.white : cream).opacity(light ? 0.9 : 0.18), lineWidth: 1)
      )
      .shadow(color: Palette.inkDeep.opacity(light ? 0.3 : 0.4), radius: 14, y: 8)
    }
    .buttonStyle(PressStyle())
  }

  private func secondaryButton(_ title: String, glyph: Glyph, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      HStack(spacing: 8) {
        GlyphView(glyph: glyph, size: 13, weight: 1.4)
        Text(title).font(.system(size: 14, weight: .medium, design: .serif))
      }
      .frame(maxWidth: .infinity, minHeight: 46)
      .foregroundStyle(ink)
      .background(cream.opacity(0.55), in: Capsule())
      .overlay(Capsule().stroke(ink.opacity(0.35), lineWidth: 1))
    }
    .buttonStyle(PressStyle())
  }

  private func guideRow(_ index: String, title: String, detail: String, glyph: Glyph) -> some View {
    HStack(alignment: .top, spacing: 16) {
      ZStack {
        Circle().stroke(Palette.amber.opacity(0.5), lineWidth: 1)
        GlyphView(glyph: glyph, size: 19, weight: 1.4).foregroundStyle(Palette.amber)
      }
      .frame(width: 44, height: 44)
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(index).font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(Palette.amber)
          Text(title).font(.system(size: 19, weight: .semibold, design: .serif))
        }
        Text(detail).font(.system(size: 12)).lineSpacing(4)
          .foregroundStyle(cream.opacity(0.66))
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
      Capsule().fill(Palette.inkDeep.opacity(0.84))
      Capsule().stroke(Palette.cream.opacity(0.26), lineWidth: 1)
      Capsule()
        .trim(from: 0.02, to: 0.48)
        .stroke(Palette.amber.opacity(0.8), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        .padding(3)
      HStack(spacing: 12) {
        GlyphView(glyph: .tap, size: 15, weight: 1.4)
        Text("TAP TO JUMP").tracking(1.6)
        Rectangle().fill(Palette.cream.opacity(0.3)).frame(width: 1, height: 12)
        Text("HOLD TO FLIP").tracking(1.6)
        GlyphView(glyph: .rotate, size: 13, weight: 1.4)
      }
      .font(.system(size: 9, weight: .bold))
      .foregroundStyle(Palette.cream)
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
