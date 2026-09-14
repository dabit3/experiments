import SwiftUI
import UIKit

struct PowderlineView: View {
  @StateObject private var store = RideStore()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var blink = false
  @State private var comboPop = false
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
    .onChange(of: store.engine.combo) { _, value in
      guard value > 0 && !reduceMotion else { return }
      comboPop = true
      withAnimation(.spring(duration: 0.5, bounce: 0.55)) { comboPop = false }
    }
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) {
        blink = true
      }
    }
    .dynamicTypeSize(.xSmall ... .xxxLarge)
  }

  // MARK: Home (attract mode)

  private var home: some View {
    VStack(spacing: 0) {
      HStack(alignment: .center, spacing: 10) {
        marquee(
          label: "HI-SCORE",
          value: store.records.rides > 0 ? store.records.bestScore.formatted() : "000000")
        marquee(
          label: "BEST", value: store.records.rides > 0 ? "\(store.records.bestDistance) M" : "0 M")
        Spacer(minLength: 0)
        soundButton
      }
      .padding(.bottom, 26)

      ZStack {
        if !reduceMotion {
          Starburst()
            .fill(
              AngularGradient(
                colors: [Palette.amber.opacity(0.32), .clear, Palette.coral.opacity(0.24), .clear],
                center: .center)
            )
            .frame(width: 300, height: 300)
            .rotationEffect(.degrees(store.sceneryTime * 9))
            .blendMode(.screen)
            .allowsHitTesting(false)
        }
        Wordmark()
      }
      .frame(height: 190)
      .clipped()

      HStack(spacing: 8) {
        Rectangle().fill(Palette.mist).frame(width: 26, height: 3)
        Text("ONE-TOUCH SNOWBOARD ARCADE")
          .font(.system(size: 11, weight: .black, design: .rounded))
          .tracking(2.4)
          .foregroundStyle(Palette.mist)
        Rectangle().fill(Palette.mist).frame(width: 26, height: 3)
      }
      .padding(.top, 6)
      .shadow(color: Palette.inkDeep, radius: 0, y: 2)

      Spacer(minLength: 70)

      VStack(spacing: 14) {
        if store.records.rides > 0 {
          HStack(spacing: 8) {
            recordTile("RUNS", value: store.records.rides.formatted(), tint: Palette.mist)
            recordTile("FLIPS", value: store.records.totalFlips.formatted(), tint: Palette.coral)
            recordTile("COINS", value: store.records.totalCoins.formatted(), tint: Palette.amber)
          }
        } else {
          Text("INSERT COURAGE · FREE PLAY")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .tracking(2.4)
            .foregroundStyle(Palette.amber)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(ink, in: Capsule())
            .overlay(Capsule().stroke(Palette.amber, lineWidth: 2))
        }

        Button {
          store.start(.expedition)
        } label: {
          HStack(spacing: 10) {
            GlyphView(glyph: .play, size: 14, weight: 3)
            Text("TAP TO START")
          }
          .frame(maxWidth: .infinity)
          .opacity(reduceMotion ? 1 : (blink ? 1 : 0.62))
        }
        .buttonStyle(ArcadeButtonStyle(height: 66))
        .accessibilityLabel("Start expedition")

        HStack(spacing: 10) {
          Button {
            store.start(.practice)
          } label: {
            HStack(spacing: 8) {
              GlyphView(glyph: .leaf, size: 13, weight: 2.2)
              Text("ZEN MODE")
            }
          }
          .buttonStyle(ChipButtonStyle(tint: Palette.lime))
          Button {
            store.showGuide = true
          } label: {
            HStack(spacing: 8) {
              GlyphView(glyph: .tap, size: 13, weight: 2.2)
              Text("HOW TO PLAY")
            }
          }
          .buttonStyle(ChipButtonStyle())
        }
      }
    }
    .padding(.horizontal, 24)
    .padding(.top, 4)
    .padding(.bottom, 8)
  }

  private func marquee(label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(label)
        .font(.system(size: 8, weight: .black, design: .rounded))
        .tracking(1.8)
        .foregroundStyle(Palette.coral)
      Text(value)
        .font(.system(size: 15, weight: .black, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(Palette.amber)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 10))
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.violet, lineWidth: 2))
    .accessibilityElement(children: .combine)
  }

  private func recordTile(_ label: String, value: String, tint: Color) -> some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.system(size: 22, weight: .black, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(tint)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
      Text(label)
        .font(.system(size: 8, weight: .black, design: .rounded))
        .tracking(1.6)
        .foregroundStyle(cream.opacity(0.7))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.6), lineWidth: 2))
    .accessibilityElement(children: .combine)
  }

  // MARK: Riding HUD

  private func rideHUD(size: CGSize) -> some View {
    ZStack {
      TouchSurface(onPress: store.press, onRelease: store.release)
        .accessibilityLabel("Snowboard. Tap to jump. Hold to backflip.")
        .accessibilityIdentifier("rideSurface")
        .padding(.top, 150)
        .padding(.bottom, 110)

      if !reduceMotion && store.toastTime > 1.7 {
        RadialGradient(
          colors: [.clear, Palette.coral.opacity((store.toastTime - 1.7) * 1.6)],
          center: .center, startRadius: size.width * 0.3, endRadius: size.width * 0.8
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
      }

      VStack(spacing: 0) {
        HStack(alignment: .top, spacing: 12) {
          VStack(alignment: .leading, spacing: 2) {
            hudLabel(
              store.engine.mode == .practice ? "ZEN · DISTANCE" : "DISTANCE", tint: Palette.mist)
            ArcadeText(
              text: "\(store.engine.distance) M", size: 30, fill: [cream, Palette.mist],
              depth: 3)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Distance \(store.engine.distance) meters")

          Spacer(minLength: 0)

          VStack(alignment: .trailing, spacing: 2) {
            hudLabel(
              store.engine.mode == .practice ? "PRACTICE SCORE" : "SCORE", tint: Palette.amber)
            ArcadeText(
              text: store.engine.score.formatted(), size: 34,
              fill: [Color(hex: 0xFFF3B8), Palette.amber, Palette.orange], depth: 4
            )
            .contentTransition(.numericText())
            .accessibilityLabel("Score \(store.engine.score)")
            coinCounter
          }

          iconButton(.pause, label: "Pause", action: store.pause)
            .disabled(store.impactTime > 0)
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)

        HStack(alignment: .top, spacing: 12) {
          comboBadge
          Spacer()
          stageTag
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)

        hazardTicker(width: size.width - 44)
          .padding(.horizontal, 22)
          .padding(.top, 8)

        Spacer()
        if store.impactTime > 0 {
          VStack(spacing: 4) {
            ArcadeText(
              text: "WIPEOUT!", size: 46, fill: [cream, Palette.coral, Color(hex: 0xC8177A)],
              depth: 6)
            Text(store.engine.crashReason.uppercased())
              .font(.system(size: 12, weight: .black, design: .rounded))
              .tracking(1.8)
              .foregroundStyle(cream)
              .padding(.horizontal, 12)
              .padding(.vertical, 5)
              .background(ink, in: Capsule())
          }
          .padding(.bottom, size.height * 0.26)
          .allowsHitTesting(false)
        } else if store.toastTime > 0 {
          scorePop
            .id(store.toastCount)
            .transition(.scale(scale: 0.4).combined(with: .opacity))
            .padding(.bottom, size.height * 0.26)
            .allowsHitTesting(false)
        } else if store.engine.elapsed < 4.5 && !store.hasJumped {
          VStack(spacing: 8) {
            ArcadeText(
              text: "GO!", size: 54, fill: [cream, Palette.lime, Color(hex: 0x3FB93A)], depth: 6)
            Text("TAP TO JUMP · HOLD TO FLIP")
              .font(.system(size: 11, weight: .black, design: .rounded))
              .tracking(2)
              .foregroundStyle(cream)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(ink, in: Capsule())
          }
          .padding(.bottom, size.height * 0.26)
          .allowsHitTesting(false)
        }
        Spacer().frame(height: 100)
      }
      .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.4), value: store.toastCount)

      VStack {
        Spacer()
        VStack(spacing: 8) {
          Group {
            if !store.engine.grounded {
              HStack(spacing: 7) {
                GlyphView(glyph: .rotate, size: 11, weight: 2.2)
                Text(landingHint)
              }
              .foregroundStyle(landingSafe ? Palette.lime : Palette.amber)
            } else {
              Text(
                store.engine.mode == .practice
                  ? "ZEN MODE · FALLS ARE FORGIVEN" : "FIND AIR · CHAIN FLIPS · CHASE THE RECORD"
              )
              .foregroundStyle(Palette.mist)
            }
          }
          .font(.system(size: 10, weight: .black, design: .rounded))
          .tracking(1.4)
          .frame(height: 24)
          .padding(.horizontal, 14)
          .background(Palette.inkDeep.opacity(0.9), in: Capsule())
          .overlay(Capsule().stroke(cream.opacity(0.2), lineWidth: 1))
          HoldControl(onPress: store.press, onRelease: store.release)
            .frame(height: 60)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 10)
      }
    }
  }

  private var coinCounter: some View {
    HStack(spacing: 5) {
      GlyphView(glyph: .gem, size: 10, weight: 2)
      Text("\(store.engine.coins)")
        .font(.system(size: 13, weight: .black, design: .rounded))
        .monospacedDigit()
        .contentTransition(.numericText())
      if store.coinPopTime > 0 {
        Text("+25")
          .font(.system(size: 11, weight: .black, design: .rounded))
          .foregroundStyle(Palette.lime)
          .scaleEffect(reduceMotion ? 1 : 0.8 + store.coinPopTime * 0.6)
          .opacity(min(1, store.coinPopTime * 3))
      }
    }
    .foregroundStyle(Palette.amber)
    .padding(.horizontal, 9)
    .padding(.vertical, 4)
    .background(ink.opacity(0.9), in: Capsule())
    .overlay(Capsule().stroke(Palette.amber.opacity(0.6), lineWidth: 1.5))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(store.engine.coins) coins")
  }

  private var comboBadge: some View {
    let combo = store.engine.combo
    let fraction = combo > 0 ? min(1, store.engine.comboTime / 5.5) : 0
    return HStack(spacing: 10) {
      ZStack {
        Circle().fill(combo > 0 ? Palette.coral : ink.opacity(0.9))
        Circle().stroke(combo > 0 ? cream : cream.opacity(0.3), lineWidth: 2.5)
        Circle()
          .trim(from: 0, to: fraction)
          .stroke(Palette.amber, style: StrokeStyle(lineWidth: 4, lineCap: .round))
          .rotationEffect(.degrees(-90))
          .padding(-5)
        ArcadeText(
          text: "×\(max(1, combo))", size: 22,
          fill: combo > 0 ? [cream, Palette.amber] : [cream.opacity(0.5), cream.opacity(0.5)],
          depth: 2)
      }
      .frame(width: 54, height: 54)
      .scaleEffect(comboPop ? 1.3 : 1)
      VStack(alignment: .leading, spacing: 3) {
        Text(combo > 0 ? "COMBO" : "NO COMBO")
          .font(.system(size: 10, weight: .black, design: .rounded))
          .tracking(1.8)
          .foregroundStyle(combo > 0 ? Palette.coral : cream.opacity(0.6))
        HStack(spacing: 3) {
          ForEach(0..<5, id: \.self) { index in
            RoundedRectangle(cornerRadius: 2)
              .fill(index < combo ? Palette.amber : ink.opacity(0.8))
              .overlay(
                RoundedRectangle(cornerRadius: 2).stroke(
                  index < combo ? Palette.ink : cream.opacity(0.3), lineWidth: 1.5)
              )
              .frame(width: 14, height: 9)
          }
        }
      }
    }
    .padding(.horizontal, 6)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(combo) times combo")
  }

  private var stageTag: some View {
    VStack(alignment: .trailing, spacing: 3) {
      Text("STAGE \(stage)")
        .font(.system(size: 13, weight: .black, design: .rounded))
        .tracking(1.2)
        .foregroundStyle(Palette.amber)
      Text(daylight)
        .font(.system(size: 8, weight: .black, design: .rounded))
        .tracking(1.8)
        .foregroundStyle(cream.opacity(0.75))
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(Palette.violet, lineWidth: 2)
    )
    .accessibilityElement(children: .combine)
  }

  private var scorePop: some View {
    VStack(spacing: 2) {
      ArcadeText(
        text: store.toast, size: 40, fill: [cream, Palette.coral, Color(hex: 0xC8177A)], depth: 6)
      if store.toastPoints > 0 {
        ArcadeText(
          text: "+\(store.toastPoints.formatted())", size: 50,
          fill: [Color(hex: 0xFFF3B8), Palette.amber, Palette.orange], depth: 6)
      }
      if !store.toastDetail.isEmpty {
        Text(store.toastDetail)
          .font(.system(size: 12, weight: .black, design: .rounded))
          .tracking(2)
          .foregroundStyle(ink)
          .padding(.horizontal, 12)
          .padding(.vertical, 5)
          .background(Palette.amber, in: Capsule())
          .overlay(Capsule().stroke(ink, lineWidth: 2))
      }
    }
    .rotationEffect(.degrees(-4))
    .accessibilityElement(children: .combine)
  }

  /// Hazard ticker: a track with the rider pinned left and the next hazard
  /// sliding in from the right; it turns pink and flashes when danger is close.
  private func hazardTicker(width: CGFloat) -> some View {
    let hazard = store.engine.nextHazard
    let ahead = hazard.x - store.engine.x
    let span = 520.0
    let close = ahead < 180
    return ZStack(alignment: .leading) {
      Capsule().fill(ink.opacity(0.85)).frame(height: 8)
      Capsule().stroke(cream.opacity(0.25), lineWidth: 1).frame(height: 8)
      Circle().fill(Palette.mist).frame(width: 10, height: 10)
        .overlay(Circle().stroke(ink, lineWidth: 2))
        .offset(x: 6)
      if ahead < span {
        let fraction = max(0, ahead / span)
        HStack(spacing: 4) {
          GlyphView(glyph: .bolt, size: 12, weight: 2)
            .opacity(close && !reduceMotion ? (blink ? 1 : 0.3) : 1)
          Text(hazard.kind == .rock ? "ROCK" : "RAVINE")
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(1.4)
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(close ? Palette.coral : Palette.amber, in: Capsule())
        .overlay(Capsule().stroke(ink, lineWidth: 2))
        .frame(width: 84)
        .offset(x: min(width - 84, 14 + fraction * (width - 98)), y: -4)
        .accessibilityIdentifier("hazardWarning")
        .accessibilityLabel(hazard.kind == .rock ? "Rock ahead" : "Ravine ahead")
      }
    }
    .frame(height: 26, alignment: .top)
  }

  // MARK: Pause

  private var pause: some View {
    ZStack {
      Palette.inkDeep.opacity(0.8).ignoresSafeArea()
      Stripes(spacing: 34).stroke(Palette.violet.opacity(0.18), lineWidth: 10).ignoresSafeArea()
      VStack(spacing: 22) {
        HStack {
          hudLabel("GAME PAUSED", tint: Palette.mist)
          Spacer()
          soundButton
        }
        Spacer()
        ArcadeText(
          text: "PAUSED", size: 64, fill: [cream, Palette.mist, Color(hex: 0x1FA6D4)], depth: 8)
        HStack(spacing: 8) {
          statChip("\(store.engine.distance) M", tint: Palette.mist)
          statChip("\(store.engine.score.formatted()) PTS", tint: Palette.amber)
        }
        Spacer()
        Button(action: store.resume) {
          HStack(spacing: 10) {
            GlyphView(glyph: .play, size: 14, weight: 3)
            Text("RESUME")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(
          ArcadeButtonStyle(
            face: [Color(hex: 0xD3FFB0), Palette.lime, Color(hex: 0x3FB93A)],
            plinth: Color(hex: 0x1D6A1E)))
        HStack(spacing: 10) {
          Button(action: store.finish) {
            Text(store.engine.mode == .practice ? "END SESSION" : "END RUN")
          }
          .buttonStyle(ChipButtonStyle(tint: Palette.coral))
          Button {
            store.showGuide = true
          } label: {
            Text("CONTROLS")
          }
          .buttonStyle(ChipButtonStyle())
        }
      }
      .padding(.horizontal, 32)
      .padding(.vertical, 16)
    }
  }

  // MARK: Results

  private var results: some View {
    ZStack {
      Palette.inkDeep.opacity(0.84).ignoresSafeArea()
      Stripes(spacing: 34).stroke(Palette.violet.opacity(0.18), lineWidth: 10).ignoresSafeArea()
      VStack(spacing: 12) {
        HStack {
          hudLabel(
            store.engine.mode == .practice ? "ZEN SESSION OVER" : "GAME OVER", tint: Palette.mist)
          Spacer()
          iconButton(.close, label: "Back to title", action: store.home)
        }
        Spacer(minLength: 0)
        ZStack {
          if !reduceMotion {
            Starburst(rays: 14)
              .fill(
                AngularGradient(
                  colors: [Palette.amber.opacity(0.4), .clear, Palette.coral.opacity(0.3), .clear],
                  center: .center)
              )
              .frame(width: 240, height: 240)
              .rotationEffect(.degrees(store.sceneryTime * 12))
              .blendMode(.screen)
          }
          VStack(spacing: -4) {
            ArcadeText(
              text: store.engine.crashReason.isEmpty ? "RUN COMPLETE" : "WIPEOUT!", size: 46,
              fill: [cream, Palette.coral, Color(hex: 0xC8177A)], depth: 7)
            rankBadge
          }
        }
        .frame(height: 210)
        if store.newBest {
          StampBadge(title: "NEW HI-SCORE!", color: Palette.amber)
            .opacity(reduceMotion ? 1 : (blink ? 1 : 0.7))
            .padding(.top, -8)
        }
        scoreBoard
        Spacer(minLength: 0)
        Text(
          store.engine.crashReason.isEmpty
            ? "CLEAN RUN · PRESS PLAY AGAIN"
            : "\(store.engine.crashReason.uppercased()) · TRY AGAIN?"
        )
        .font(.system(size: 11, weight: .black, design: .rounded))
        .tracking(2)
        .foregroundStyle(Palette.lime)
        .opacity(reduceMotion ? 1 : (blink ? 1 : 0.35))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.bottom, 4)
        Button {
          store.start(store.engine.mode)
        } label: {
          HStack(spacing: 10) {
            GlyphView(glyph: .rotate, size: 15, weight: 3)
            Text("PLAY AGAIN")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(ArcadeButtonStyle())
        HStack(spacing: 10) {
          Button(action: store.home) {
            Text("TITLE")
          }
          .buttonStyle(ChipButtonStyle())
          ShareLink(item: shareText) {
            HStack(spacing: 7) {
              GlyphView(glyph: .share, size: 12, weight: 2.2)
              Text("SHARE")
            }
          }
          .buttonStyle(ChipButtonStyle(tint: Palette.amber))
        }
      }
      .padding(.horizontal, 26)
      .padding(.top, 4)
      .padding(.bottom, 8)
    }
  }

  private var rankBadge: some View {
    HStack(spacing: 10) {
      Text("RANK")
        .font(.system(size: 12, weight: .black, design: .rounded))
        .tracking(2.4)
        .foregroundStyle(cream)
      ArcadeText(text: rank, size: 58, fill: [cream, Palette.amber, Palette.orange], depth: 6)
        .frame(width: 66)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 6)
    .background(ink, in: RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.amber, lineWidth: 2.5))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Rank \(rank)")
  }

  private var scoreBoard: some View {
    VStack(spacing: 10) {
      VStack(spacing: 0) {
        hudLabel(
          store.engine.mode == .practice ? "PRACTICE SCORE" : "FINAL SCORE", tint: Palette.coral)
        ArcadeText(
          text: store.engine.score.formatted(), size: 60,
          fill: [Color(hex: 0xFFF3B8), Palette.amber, Palette.orange], depth: 7)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background(ink, in: RoundedRectangle(cornerRadius: 18))
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.amber.opacity(0.7), lineWidth: 2))
      HStack(spacing: 8) {
        resultStat(
          "\(store.engine.distance) M", label: "DISTANCE", glyph: .peaks, tint: Palette.mist)
        resultStat("\(store.engine.flips)", label: "BACKFLIPS", glyph: .rotate, tint: Palette.coral)
        resultStat("\(store.engine.coins)", label: "COINS", glyph: .gem, tint: Palette.amber)
        resultStat(
          "×\(store.engine.bestCombo)", label: "TOP COMBO", glyph: .bolt, tint: Palette.lime)
      }
      Text(
        store.engine.mode == .practice
          ? "ZEN MODE SCORES STAY OFF THE HI-SCORE BOARD"
          : "HI-SCORE \(store.records.bestScore.formatted())  ·  BEST \(store.records.bestDistance) M"
      )
      .font(.system(size: 9, weight: .black, design: .rounded))
      .tracking(1.6)
      .foregroundStyle(cream.opacity(0.7))
      .multilineTextAlignment(.center)
      .lineLimit(1)
      .minimumScaleFactor(0.7)
    }
  }

  // MARK: Guide

  private var guide: some View {
    ZStack {
      Palette.inkDeep.ignoresSafeArea()
      Stripes(spacing: 34).stroke(Palette.violet.opacity(0.18), lineWidth: 10).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          hudLabel("CONTROLS", tint: Palette.mist)
          Spacer()
          iconButton(.close, label: "Close guide") { store.showGuide = false }
        }
        ArcadeText(
          text: "HOW TO PLAY", size: 42, fill: [cream, Palette.mist, Color(hex: 0x1FA6D4)], depth: 6
        )
        .padding(.bottom, 2)
        guideRow(
          1, title: "TAP TO JUMP", tint: Palette.mist,
          detail: "Tap anywhere on the snow or the big button to clear rocks and ravines.",
          glyph: .tap)
        guideRow(
          2, title: "HOLD TO FLIP", tint: Palette.coral,
          detail: "Hold about 1.2 seconds in the air. Let go when the cue reads LEVEL to land it.",
          glyph: .rotate)
        guideRow(
          3, title: "CHAIN COMBOS", tint: Palette.amber,
          detail: "Land flips within 5.5 seconds of each other to multiply trick points up to ×5.",
          glyph: .bolt)
        guideRow(
          4, title: "ZEN MODE", tint: Palette.lime,
          detail:
            "A gentler pace that forgives every fall. Its score stays off the hi-score board.",
          glyph: .leaf)
        Spacer(minLength: 0)
        Button {
          store.showGuide = false
        } label: {
          Text("LET'S RIDE").frame(maxWidth: .infinity)
        }
        .buttonStyle(ArcadeButtonStyle())
      }
      .padding(.horizontal, 28)
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
      GlyphView(glyph: glyph, size: 16, weight: 2.4)
        .foregroundStyle(cream)
        .frame(width: 44, height: 44)
        .background(ink.opacity(0.9), in: Circle())
        .overlay(Circle().stroke(Palette.mist, lineWidth: 2))
    }
    .buttonStyle(PressStyle())
    .accessibilityLabel(label)
  }

  private func hudLabel(_ text: String, tint: Color) -> some View {
    Text(text)
      .font(.system(size: 9, weight: .black, design: .rounded))
      .tracking(2)
      .foregroundStyle(tint)
      .shadow(color: Palette.inkDeep, radius: 0, y: 1.5)
  }

  private func statChip(_ text: String, tint: Color) -> some View {
    Text(text)
      .font(.system(size: 15, weight: .black, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(tint)
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(ink, in: Capsule())
      .overlay(Capsule().stroke(tint.opacity(0.7), lineWidth: 2))
  }

  private var stage: Int {
    if store.engine.x > 19000 { return 3 }
    if store.engine.x > 9500 { return 2 }
    return 1
  }

  private var daylight: String {
    switch stage {
    case 3: return "APRICOT HOUR"
    case 2: return "HIGH COUNTRY"
    default: return "FIRST LIGHT"
    }
  }

  private var rank: String {
    let score = store.engine.score
    if score >= 50000 { return "S" }
    if score >= 20000 { return "A" }
    if score >= 8000 { return "B" }
    if score >= 2500 { return "C" }
    return "D"
  }

  private var landingSafe: Bool {
    RideEngine.isSafeLanding(
      rotation: store.engine.rotation, slope: RideEngine.slope(at: store.engine.x))
  }

  private var landingHint: String {
    landingSafe ? "LEVEL! RELEASE TO LAND" : "KEEP ROTATING · FIND LEVEL"
  }

  private var shareText: String {
    let mode = store.engine.mode == .practice ? "Zen mode" : "Arcade run"
    return
      "Powderline · \(mode) · Rank \(rank)\n\(store.engine.score) points over \(store.engine.distance)m with \(store.engine.flips) backflips and \(store.engine.coins) coins."
  }

  private func resultStat(_ value: String, label: String, glyph: Glyph, tint: Color) -> some View {
    VStack(spacing: 5) {
      GlyphView(glyph: glyph, size: 14, weight: 2.4).foregroundStyle(tint)
      Text(value)
        .font(.system(size: 21, weight: .black, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(tint)
      Text(label)
        .font(.system(size: 8, weight: .black, design: .rounded))
        .tracking(1.4)
        .foregroundStyle(cream.opacity(0.7))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background(ink, in: RoundedRectangle(cornerRadius: 14))
    .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.6), lineWidth: 2))
    .accessibilityElement(children: .combine)
  }

  private func guideRow(_ index: Int, title: String, tint: Color, detail: String, glyph: Glyph)
    -> some View
  {
    HStack(alignment: .top, spacing: 14) {
      ZStack {
        Circle().fill(tint)
        Circle().stroke(ink, lineWidth: 2.5)
        GlyphView(glyph: glyph, size: 20, weight: 2.4).foregroundStyle(ink)
      }
      .frame(width: 46, height: 46)
      VStack(alignment: .leading, spacing: 5) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text("\(index)")
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(tint)
          Text(title)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .tracking(1)
        }
        Text(detail).font(.system(size: 12, weight: .semibold)).lineSpacing(3)
          .foregroundStyle(cream.opacity(0.72))
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(12)
    .background(ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
    .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint.opacity(0.5), lineWidth: 2))
  }
}

struct HoldControl: View {
  let onPress: () -> Void
  let onRelease: () -> Void

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Color(hex: 0x0B4F63))
        .offset(y: 5)
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color(hex: 0xB8F6FF), Palette.mist, Color(hex: 0x1FA6D4)],
            startPoint: .top, endPoint: .bottom))
      RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.ink, lineWidth: 2.5)
      HStack(spacing: 12) {
        GlyphView(glyph: .tap, size: 17, weight: 2.6)
        Text("TAP = JUMP").tracking(1.4)
        Rectangle().fill(Palette.ink.opacity(0.5)).frame(width: 2, height: 16)
        Text("HOLD = FLIP").tracking(1.4)
        GlyphView(glyph: .rotate, size: 15, weight: 2.6)
      }
      .font(.system(size: 14, weight: .black, design: .rounded))
      .foregroundStyle(Palette.ink)
      .allowsHitTesting(false)
      TouchSurface(onPress: onPress, onRelease: onRelease)
        .accessibilityLabel("Jump. Hold to backflip.")
        .accessibilityIdentifier("jumpControl")
    }
    .padding(.bottom, 5)
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
