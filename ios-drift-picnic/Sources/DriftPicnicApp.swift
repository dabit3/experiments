import SceneKit
import SwiftUI

@main
struct DriftPicnicApp: App {
  var body: some Scene {
    WindowGroup { PicnicView() }
  }
}

let forest = Color(uiColor: Palette.green)
let deepForest = Color(uiColor: Palette.deepGreen)
let butter = Color(uiColor: Palette.butter)
let butterDeep = Color(red: 0.96, green: 0.78, blue: 0.36)
let cream = Color(uiColor: Palette.cream)
let creamDeep = Color(red: 0.96, green: 0.91, blue: 0.76)
let strawberry = Color(uiColor: Palette.pink)

func raceTime(_ seconds: Double) -> String {
  guard seconds > 0 else { return "—:—" }
  return String(format: "%d:%05.2f", Int(seconds) / 60, seconds.truncatingRemainder(dividingBy: 60))
}

func serif(_ size: CGFloat) -> Font { .custom("Georgia-BoldItalic", size: size) }

func eyebrow(_ text: String, size: CGFloat = 9) -> some View {
  Text(text).font(.system(size: size, weight: .bold)).tracking(size * 0.22)
}

struct PicnicCard: ViewModifier {
  var radius: CGFloat = 22
  var tint: Color = cream
  func body(content: Content) -> some View {
    content
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(
            LinearGradient(colors: [tint, tint.opacity(0.94)], startPoint: .top, endPoint: .bottom)
          )
          .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
              .strokeBorder(
                LinearGradient(
                  colors: [.white.opacity(0.85), .white.opacity(0.15)], startPoint: .top,
                  endPoint: .bottom), lineWidth: 1.2)
          }
          .shadow(color: deepForest.opacity(0.28), radius: 14, y: 8)
      }
  }
}

extension View {
  func picnicCard(_ radius: CGFloat = 22, tint: Color = cream) -> some View {
    modifier(PicnicCard(radius: radius, tint: tint))
  }
}

struct GinghamPattern: View {
  var color: Color
  var body: some View {
    Canvas { context, size in
      let step: CGFloat = 26
      var x: CGFloat = 0
      while x < size.width {
        context.fill(
          Path(CGRect(x: x, y: 0, width: step / 2, height: size.height)), with: .color(color))
        x += step
      }
      var y: CGFloat = 0
      while y < size.height {
        context.fill(
          Path(CGRect(x: 0, y: y, width: size.width, height: step / 2)), with: .color(color))
        y += step
      }
    }
    .allowsHitTesting(false)
  }
}

struct PrimaryButtonStyle: ButtonStyle {
  var height: CGFloat = 54
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 17, weight: .heavy))
      .frame(maxWidth: .infinity).frame(height: height)
      .foregroundStyle(deepForest)
      .background {
        RoundedRectangle(cornerRadius: height * 0.34, style: .continuous)
          .fill(LinearGradient(colors: [butter, butterDeep], startPoint: .top, endPoint: .bottom))
          .overlay {
            RoundedRectangle(cornerRadius: height * 0.34, style: .continuous)
              .strokeBorder(.white.opacity(0.55), lineWidth: 1.2)
          }
          .shadow(color: butterDeep.opacity(configuration.isPressed ? 0.1 : 0.45), radius: 12, y: 6)
      }
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.spring(duration: 0.25), value: configuration.isPressed)
  }
}

struct GlassCircleStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 16, weight: .bold))
      .frame(width: 46, height: 46)
      .foregroundStyle(forest)
      .background {
        Circle().fill(cream.opacity(0.94))
          .overlay { Circle().strokeBorder(.white.opacity(0.8), lineWidth: 1.2) }
          .shadow(color: deepForest.opacity(0.3), radius: 8, y: 4)
      }
      .scaleEffect(configuration.isPressed ? 0.92 : 1)
  }
}

struct PicnicView: View {
  @StateObject private var game = GameController()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        if game.phase == .title {
          HStack(spacing: 0) {
            forest.frame(width: min(365, geometry.size.width * 0.43))
            NativeScene(game: game)
          }.ignoresSafeArea()
        } else {
          NativeScene(game: game).ignoresSafeArea()
        }
        if game.phase == .title {
          title(geometry.size)
        } else if game.phase == .results {
          results(geometry.size)
        } else {
          hud(geometry.size)
          if game.phase == .countdown { countdownView }
          if game.phase == .paused { pausePanel }
        }
        if game.showGuide { guide(geometry.size) }
      }
      .foregroundStyle(forest)
      .onAppear { game.reducedMotion = reduceMotion }
      .onChange(of: reduceMotion) { _, value in game.reducedMotion = value }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { game.pause() }
      }
    }
    .persistentSystemOverlays(.hidden)
  }

  private var countdownView: some View {
    VStack(spacing: 2) {
      Text(game.countdown == 0 ? "Go!" : "\(game.countdown)")
        .font(serif(game.countdown == 0 ? 92 : 120))
        .foregroundStyle(game.countdown == 0 ? butter : cream)
        .id(game.countdown)
        .transition(.scale(scale: 1.5).combined(with: .opacity))
      eyebrow("A LITTLE RACE. A LOVELY DAY.", size: 11).foregroundStyle(cream)
    }
    .shadow(color: deepForest.opacity(0.7), radius: 16, y: 6)
    .animation(reduceMotion ? nil : .spring(duration: 0.45), value: game.countdown)
    .allowsHitTesting(false)
  }

  private func title(_ size: CGSize) -> some View {
    let compact = size.height < 420
    return HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: compact ? 6 : 10) {
        HStack(spacing: 9) {
          ZStack {
            Circle().strokeBorder(butter, lineWidth: 1.4)
            Text("DP").font(serif(12)).foregroundStyle(butter)
          }.frame(width: 30, height: 30)
          VStack(alignment: .leading, spacing: 2) {
            eyebrow("THE LITTLE RACING CLUB").foregroundStyle(cream.opacity(0.75))
            eyebrow("EST. ON A SUNNY SATURDAY", size: 7).foregroundStyle(cream.opacity(0.45))
          }
        }
        VStack(alignment: .leading, spacing: compact ? -12 : -14) {
          Text("Drift").foregroundStyle(cream)
          Text("Picnic").foregroundStyle(butter)
        }
        .font(serif(compact ? 56 : 70))
        .shadow(color: deepForest.opacity(0.6), radius: 0, x: 0, y: 3)
        .padding(.top, compact ? 0 : 4)
        HStack(spacing: 8) {
          Rectangle().fill(butter).frame(width: 22, height: 1.5)
          Text("Small wheels. Sweeter victories.")
            .font(.system(size: 13, weight: .medium, design: .serif)).italic()
            .foregroundStyle(cream.opacity(0.85))
        }
        Spacer(minLength: 0)
        modePicker
        Button(action: game.begin) {
          HStack {
            Text("Let’s race")
            Spacer()
            Image(systemName: "arrow.right")
              .font(.system(size: 14, weight: .bold))
              .frame(width: 30, height: 30)
              .background(deepForest.opacity(0.12), in: Circle())
          }.padding(.horizontal, 12)
        }
        .buttonStyle(PrimaryButtonStyle(height: compact ? 50 : 56))
        .accessibilityIdentifier("startRace")
        HStack {
          eyebrow("3 LAPS  ·  \(game.mode == .picnic ? "4 FRIENDS" : "JUST YOU")")
            .foregroundStyle(cream.opacity(0.6))
          Spacer()
          Button {
            game.showGuide = true
          } label: {
            HStack(spacing: 5) {
              Image(systemName: "book.closed.fill").font(.system(size: 9))
              Text("How to play").font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 11).frame(height: 30)
            .background(cream.opacity(0.1), in: Capsule())
            .overlay { Capsule().strokeBorder(cream.opacity(0.25), lineWidth: 1) }
          }.foregroundStyle(cream)
        }
      }
      .padding(.horizontal, 26).padding(.vertical, compact ? 12 : 20)
      .frame(width: min(365, size.width * 0.43))
      .background {
        ZStack {
          LinearGradient(
            colors: [Color(red: 0.11, green: 0.33, blue: 0.26), deepForest],
            startPoint: .top, endPoint: .bottom)
          GinghamPattern(color: .white.opacity(0.03))
          Circle().fill(butter.opacity(0.10)).frame(width: 360, height: 360)
            .blur(radius: 60).offset(x: -120, y: -170)
        }.ignoresSafeArea()
      }
      .overlay(alignment: .trailing) {
        Rectangle().fill(butter).frame(width: 2).ignoresSafeArea()
      }
      .shadow(color: deepForest.opacity(0.5), radius: 30, x: 12)
      .zIndex(1)
      Spacer(minLength: 0)
      VStack {
        HStack {
          Spacer()
          Button(action: game.toggleSound) {
            Image(systemName: game.sound ? "speaker.wave.2.fill" : "speaker.slash.fill")
          }
          .buttonStyle(GlassCircleStyle())
          .accessibilityLabel(game.sound ? "Mute sound" : "Enable sound")
        }
        Spacer()
        courseCard(compact)
      }.padding(compact ? 14 : 20)
    }
  }

  private var modePicker: some View {
    HStack(spacing: 4) {
      ForEach([RaceMode.picnic, RaceMode.trial], id: \.self) { mode in
        Button {
          withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) { game.mode = mode }
        } label: {
          HStack(spacing: 6) {
            Image(systemName: mode == .picnic ? "flag.checkered" : "stopwatch")
            Text(mode.rawValue)
          }
          .font(.system(size: 12, weight: .bold))
          .frame(maxWidth: .infinity).frame(height: 38)
          .foregroundStyle(game.mode == mode ? deepForest : cream)
          .background {
            if game.mode == mode {
              RoundedRectangle(cornerRadius: 12, style: .continuous).fill(cream)
                .shadow(color: deepForest.opacity(0.35), radius: 6, y: 3)
                .matchedGeometryEffect(id: "mode", in: modeNamespace)
            }
          }
        }
        .accessibilityAddTraits(game.mode == mode ? .isSelected : [])
      }
    }
    .padding(4)
    .background(
      deepForest.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .strokeBorder(cream.opacity(0.14), lineWidth: 1)
    }
  }

  @Namespace private var modeNamespace

  private func courseCard(_ compact: Bool) -> some View {
    HStack(spacing: 14) {
      MiniMap(circuit: game.race.circuit, drivers: [], onCard: true)
        .frame(width: 74, height: 54)
        .padding(6)
        .background(
          forest.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text("01").font(serif(20)).foregroundStyle(strawberry)
          Text("Strawberry Circuit").font(.system(size: 16, weight: .heavy))
        }
        eyebrow("A SUN-SOAKED TABLETOP CLASSIC", size: 8).foregroundStyle(forest.opacity(0.7))
        HStack(spacing: 14) {
          statChip("stopwatch", raceTime(game.bestLap), "BEST LAP")
          if game.mode == .picnic {
            statChip("trophy.fill", "\(game.wins)", "WINS")
            statChip("flag.checkered", raceTime(game.bestCup), "BEST CUP")
          } else {
            statChip("hourglass", raceTime(game.bestTrial), "BEST TRIAL")
          }
        }.padding(.top, 2)
      }
    }
    .padding(compact ? 12 : 16).picnicCard(22)
    .frame(maxWidth: 360)
  }

  private func statChip(_ icon: String, _ value: String, _ label: String) -> some View {
    HStack(spacing: 6) {
      Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(strawberry)
      VStack(alignment: .leading, spacing: 1) {
        Text(value).font(.system(size: 12, weight: .heavy)).monospacedDigit()
        eyebrow(label, size: 6.5).foregroundStyle(forest.opacity(0.55))
      }
    }
  }

  private var ready: Bool { game.race.player.driftCharge >= 0.65 }

  private func hud(_ size: CGSize) -> some View {
    let compact = size.height < 370
    return VStack {
      HStack(alignment: .top, spacing: 12) {
        positionBadge
        Spacer()
        HStack(spacing: 16) {
          VStack(spacing: 5) {
            eyebrow("LAP", size: 8).foregroundStyle(cream.opacity(0.65))
            HStack(spacing: 4) {
              ForEach(0..<3, id: \.self) { lap in
                Capsule()
                  .fill(
                    lap < game.race.player.tracker.laps
                      ? butter : cream.opacity(lap == game.race.player.tracker.laps ? 0.9 : 0.25)
                  )
                  .frame(width: lap == min(2, game.race.player.tracker.laps) ? 18 : 9, height: 5)
              }
            }
            Text("\(min(3, game.race.player.tracker.laps + 1)) / 3").font(
              .system(size: 15, weight: .heavy)
            ).monospacedDigit()
          }
          Rectangle().fill(cream.opacity(0.2)).frame(width: 1, height: 36)
          VStack(spacing: 4) {
            eyebrow("RACE TIME", size: 8).foregroundStyle(cream.opacity(0.65))
            Text(raceTime(game.race.elapsed)).font(.system(size: 22, weight: .heavy))
              .monospacedDigit()
          }
        }
        .padding(.horizontal, 22).padding(.vertical, 9)
        .foregroundStyle(cream)
        .background {
          Capsule().fill(deepForest.opacity(0.88))
            .overlay { Capsule().strokeBorder(butter.opacity(0.35), lineWidth: 1) }
            .shadow(color: deepForest.opacity(0.35), radius: 10, y: 5)
        }
        Spacer()
        HStack(spacing: 8) {
          Button(action: game.toggleSound) {
            Image(systemName: game.sound ? "speaker.wave.2.fill" : "speaker.slash.fill")
          }
          .buttonStyle(GlassCircleStyle())
          .accessibilityLabel(game.sound ? "Mute sound" : "Enable sound")
          Button(action: game.pause) { Image(systemName: "pause.fill") }
            .buttonStyle(GlassCircleStyle())
            .accessibilityLabel("Pause race").accessibilityIdentifier("pauseRace")
        }
      }
      ZStack {
        if game.race.feedbackRemaining > 0 && game.phase == .racing {
          Text(game.race.feedback)
            .font(.system(size: 11, weight: .heavy)).tracking(1.4)
            .foregroundStyle(deepForest)
            .padding(.horizontal, 18).padding(.vertical, 8)
            .background {
              Capsule().fill(
                LinearGradient(colors: [butter, butterDeep], startPoint: .top, endPoint: .bottom)
              )
              .shadow(color: deepForest.opacity(0.3), radius: 8, y: 4)
            }
            .transition(.scale(scale: 0.8).combined(with: .opacity))
            .accessibilityIdentifier("raceFeedback")
        }
      }
      .frame(height: 36).padding(.top, 6)
      .animation(
        reduceMotion ? nil : .spring(duration: 0.3), value: game.race.feedbackRemaining > 0)
      Spacer()
      HStack(alignment: .bottom, spacing: 12) {
        steeringButton(-1, icon: "arrow.turn.up.left", label: "Steer left")
        steeringButton(1, icon: "arrow.turn.up.right", label: "Steer right")
        speedometer.padding(.leading, 6)
        Spacer()
        MiniMap(circuit: game.race.circuit, drivers: game.race.drivers, onCard: false)
          .frame(width: 104, height: 68)
          .padding(.horizontal, 10).padding(.vertical, 6)
          .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(deepForest.opacity(0.55))
              .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(
                  cream.opacity(0.25), lineWidth: 1)
              }
          }
          .padding(.trailing, 4)
        itemButton
        driftButton
      }
    }
    .padding(.horizontal, 18).padding(.vertical, compact ? 10 : 16)
  }

  private var positionBadge: some View {
    VStack(spacing: 0) {
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(game.mode == .trial ? "TT" : "\(game.race.position)")
          .font(serif(game.mode == .trial ? 30 : 44))
          .contentTransition(.numericText())
        if game.mode == .picnic {
          Text("/4").font(.system(size: 13, weight: .heavy)).foregroundStyle(
            deepForest.opacity(0.6))
        }
      }
      eyebrow(
        game.mode == .trial
          ? "TIME TRIAL" : ["", "LEADING", "SECOND", "THIRD", "FOURTH"][game.race.position], size: 7
      )
      .foregroundStyle(deepForest.opacity(0.7))
      .padding(.bottom, 6)
    }
    .foregroundStyle(deepForest)
    .frame(width: 84)
    .padding(.top, 2)
    .picnicCard(20, tint: butter)
    .animation(reduceMotion ? nil : .spring(duration: 0.35), value: game.race.position)
  }

  private var speedometer: some View {
    let boosting = game.race.player.boost > 0
    return VStack(alignment: .leading, spacing: 1) {
      Text("\(Int(game.race.player.speed * 3.6))")
        .font(.system(size: 30, weight: .black)).monospacedDigit()
        .foregroundStyle(boosting ? butter : cream)
      eyebrow(boosting ? "BOOST" : "KM/H", size: 8).foregroundStyle(cream.opacity(0.8))
    }
    .shadow(color: deepForest.opacity(0.9), radius: 5, y: 2)
    .frame(width: 62, alignment: .leading)
  }

  private var itemButton: some View {
    let has = game.race.hasItem
    return Button(action: game.item) {
      VStack(spacing: 4) {
        Image(systemName: has ? "cup.and.saucer.fill" : "sparkle")
          .font(.system(size: 22, weight: .bold))
          .frame(height: 28)
        eyebrow(has ? "LEMONADE" : "FIND A CUP", size: 7.5)
      }
      .frame(width: 82, height: 80)
      .foregroundStyle(has ? deepForest : forest.opacity(0.55))
      .background {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(
            has
              ? LinearGradient(colors: [butter, butterDeep], startPoint: .top, endPoint: .bottom)
              : LinearGradient(
                colors: [cream.opacity(0.7), cream.opacity(0.6)], startPoint: .top,
                endPoint: .bottom)
          )
          .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .strokeBorder(.white.opacity(has ? 0.8 : 0.4), lineWidth: 1.2)
          }
          .shadow(color: has ? butterDeep.opacity(0.5) : .clear, radius: 12, y: 4)
      }
    }
    .disabled(!has)
    .animation(reduceMotion ? nil : .spring(duration: 0.3), value: has)
    .accessibilityLabel(has ? "Use lemonade boost" : "No item collected")
    .accessibilityIdentifier("useItem")
  }

  private var driftButton: some View {
    let drifting = game.race.drifting
    let charge = min(1, game.race.player.driftCharge / 0.65)
    return Button(action: game.drift) {
      VStack(spacing: 5) {
        ZStack {
          Circle().stroke((ready ? butter : forest).opacity(0.2), lineWidth: 4)
          Circle().trim(from: 0, to: charge)
            .stroke(ready ? butter : forest, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .rotationEffect(.degrees(-90))
          Image(systemName: ready ? "bolt.fill" : (drifting ? "wind" : "skew"))
            .font(.system(size: 19, weight: .bold))
        }.frame(width: 44, height: 44)
        eyebrow(ready ? "BOOST READY" : (drifting ? "CHARGING" : "DRIFT"), size: 8)
      }
      .frame(width: 96, height: 92)
      .foregroundStyle(ready ? butter : deepForest)
      .background {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .fill(
            ready
              ? LinearGradient(colors: [forest, deepForest], startPoint: .top, endPoint: .bottom)
              : (drifting
                ? LinearGradient(colors: [butter, butterDeep], startPoint: .top, endPoint: .bottom)
                : LinearGradient(colors: [cream, creamDeep], startPoint: .top, endPoint: .bottom))
          )
          .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
              .strokeBorder(ready ? butter : .white.opacity(0.7), lineWidth: ready ? 2.5 : 1.2)
          }
          .shadow(color: ready ? butter.opacity(0.55) : deepForest.opacity(0.25), radius: 12, y: 5)
      }
    }
    .animation(reduceMotion ? nil : .spring(duration: 0.3), value: ready)
    .accessibilityLabel(drifting ? "Release drift boost" : "Start drift")
    .accessibilityIdentifier("drift")
  }

  private func steeringButton(_ direction: Double, icon: String, label: String) -> some View {
    let held = game.race.steering == direction
    return Image(systemName: icon)
      .font(.system(size: 28, weight: .bold))
      .foregroundStyle(deepForest)
      .frame(width: 80, height: 80)
      .background {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
          .fill(
            held
              ? LinearGradient(colors: [butter, butterDeep], startPoint: .top, endPoint: .bottom)
              : LinearGradient(
                colors: [cream.opacity(0.96), creamDeep.opacity(0.92)], startPoint: .top,
                endPoint: .bottom)
          )
          .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
              .strokeBorder(.white.opacity(0.75), lineWidth: 1.2)
          }
          .shadow(color: deepForest.opacity(held ? 0.1 : 0.3), radius: 10, y: held ? 2 : 6)
      }
      .scaleEffect(held ? 0.95 : 1)
      .animation(reduceMotion ? nil : .spring(duration: 0.2), value: held)
      .contentShape(RoundedRectangle(cornerRadius: 26))
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in game.steer(direction) }
          .onEnded { _ in game.steer(0) }
      )
      .accessibilityElement()
      .accessibilityLabel(label)
      .accessibilityAddTraits(.isButton)
      .accessibilityAction {
        game.steer(direction)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { game.steer(0) }
      }
  }

  private func metric(_ label: String, _ value: String, large: Bool = true) -> some View {
    VStack(spacing: 3) {
      eyebrow(label, size: 8).foregroundStyle(forest.opacity(0.65))
      Text(value).font(.system(size: large ? 22 : 16, weight: .heavy)).monospacedDigit()
    }
  }

  private func guide(_ size: CGSize) -> some View {
    ZStack {
      deepForest.opacity(0.82).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 16) {
        HStack(alignment: .top) {
          VStack(alignment: .leading, spacing: 4) {
            eyebrow("HOW TO PLAY").foregroundStyle(strawberry)
            Text("A quick pit stop.").font(serif(30))
            Text("Three little tricks for a sweet first race.")
              .font(.system(size: 13, design: .serif)).italic().foregroundStyle(forest.opacity(0.8))
          }
          Spacer()
          Button {
            game.showGuide = false
          } label: {
            Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).frame(
              width: 40, height: 40
            )
            .background(forest.opacity(0.08), in: Circle())
          }.accessibilityLabel("Close instructions")
        }
        HStack(alignment: .top, spacing: 14) {
          tip(
            "01", "Steer your way",
            "Hold the arrows to steer. Cut close to the inside curb for a faster racing line.",
            "arrow.left.and.right")
          tip(
            "02", "Drift, then dash",
            "Tap DRIFT into a bend. Tap again when BOOST READY lights up for a burst.", "bolt.fill")
          tip(
            "03", "Sip. Zip. Repeat.",
            "Drive through a lemonade. Tap its button to boost past your friends.",
            "cup.and.saucer.fill")
        }
        Button(action: game.start) {
          HStack {
            Text("Got it. Let’s picnic!")
            Image(systemName: "arrow.right")
          }
        }.buttonStyle(PrimaryButtonStyle(height: 50)).accessibilityIdentifier("confirmGuide")
      }
      .padding(24).frame(maxWidth: min(size.width - 40, 720))
      .picnicCard(30)
      .overlay(alignment: .top) {
        HStack(spacing: 0) {
          ForEach(0..<16, id: \.self) { i in
            Triangle().fill([butter, strawberry, forest, Color(uiColor: Palette.blue)][i % 4])
              .frame(width: 14, height: 10)
          }
        }.offset(y: -1)
      }
    }
  }

  private func tip(_ number: String, _ title: String, _ text: String, _ icon: String) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      HStack {
        Image(systemName: icon).font(.system(size: 17, weight: .bold)).foregroundStyle(deepForest)
          .frame(width: 40, height: 40)
          .background(
            LinearGradient(colors: [butter, butterDeep], startPoint: .top, endPoint: .bottom),
            in: Circle())
        Spacer()
        Text(number).font(serif(18)).foregroundStyle(strawberry.opacity(0.8))
      }
      Text(title).font(.system(size: 14, weight: .heavy))
      Text(text).font(.system(size: 11)).lineSpacing(3).foregroundStyle(forest.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(forest.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private var pausePanel: some View {
    ZStack {
      deepForest.opacity(0.7).ignoresSafeArea()
      VStack(spacing: 12) {
        Image(systemName: "sun.haze.fill").font(.system(size: 28)).foregroundStyle(butter)
        Text("Take a breather.").font(serif(30))
        Text("Your picnic will be right here.")
          .font(.system(size: 13, design: .serif)).italic().opacity(0.8)
        eyebrow("PAUSED AT  \(raceTime(game.race.elapsed))", size: 10).monospacedDigit()
          .padding(.horizontal, 12).padding(.vertical, 6)
          .background(cream.opacity(0.1), in: Capsule())
        Button("Back to the race", action: game.resume).buttonStyle(PrimaryButtonStyle(height: 50))
          .accessibilityIdentifier("resumeRace").padding(.top, 4)
        HStack(spacing: 10) {
          Button("Restart", action: game.start)
          Button("Leave race", action: game.home)
        }
        .buttonStyle(GhostButtonStyle())
      }
      .foregroundStyle(cream).padding(26)
      .frame(width: 340)
      .background {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
          .fill(LinearGradient(colors: [forest, deepForest], startPoint: .top, endPoint: .bottom))
          .overlay {
            GinghamPattern(color: .white.opacity(0.03)).clipShape(
              RoundedRectangle(cornerRadius: 30, style: .continuous))
          }
          .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous).strokeBorder(
              butter.opacity(0.4), lineWidth: 1.2)
          }
          .shadow(color: .black.opacity(0.35), radius: 30, y: 14)
      }
    }
  }

  private func results(_ size: CGSize) -> some View {
    let won = game.mode == .picnic && game.race.position == 1
    let personal = game.mode == .picnic ? game.bestCup : game.bestTrial
    let newBest = abs(personal - game.race.elapsed) < 0.001
    return ZStack {
      LinearGradient(
        colors: [forest.opacity(0.94), deepForest.opacity(0.97)], startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      GinghamPattern(color: .white.opacity(0.025)).ignoresSafeArea()
      if won && !reduceMotion { Confetti().ignoresSafeArea().allowsHitTesting(false) }
      HStack(spacing: 28) {
        VStack(alignment: .leading, spacing: 10) {
          eyebrow(game.mode == .trial ? "TIME TRIAL COMPLETE" : "STRAWBERRY CIRCUIT · CUP COMPLETE")
            .foregroundStyle(butter)
          Text(
            game.mode == .trial
              ? "Sweet time."
              : (won ? "Oh, sweet\nvictory!" : "A lovely\nlittle race.")
          )
          .font(serif(size.height < 390 ? 34 : 42))
          .lineSpacing(-6).foregroundStyle(cream)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(game.mode == .trial ? "3" : "\(game.race.position)")
              .font(serif(56))
            eyebrow(game.mode == .trial ? "LAPS COMPLETE" : "OF 4 RACERS", size: 10)
          }.foregroundStyle(butter)
          HStack(spacing: 8) {
            resultChip("bolt.fill", "\(game.race.driftBoosts) drifts")
            resultChip("cup.and.saucer.fill", "\(game.race.itemsCollected) lemonades")
          }
          HStack(spacing: 10) {
            Button("Race again", action: game.start).buttonStyle(PrimaryButtonStyle(height: 50))
              .accessibilityIdentifier("raceAgain")
            Button(action: game.home) {
              Image(systemName: "house.fill").frame(width: 50, height: 50)
                .background(
                  cream.opacity(0.12), in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                )
                .overlay {
                  RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(
                    cream.opacity(0.25), lineWidth: 1)
                }
            }.foregroundStyle(cream).accessibilityLabel("Back to title")
          }.padding(.top, 4)
        }.frame(maxWidth: 300, alignment: .leading)
        VStack(spacing: 12) {
          if game.mode == .picnic { podium }
          HStack {
            metric("RACE TIME", raceTime(game.race.elapsed))
            Spacer()
            Rectangle().fill(forest.opacity(0.15)).frame(width: 1, height: 34)
            Spacer()
            metric("BEST LAP", raceTime(game.race.player.lapTimes.min() ?? 0))
          }
          .padding(.horizontal, 22).padding(.vertical, 14).picnicCard(20)
          HStack {
            Label(
              newBest ? "New personal best" : "Personal best",
              systemImage: newBest ? "sparkles" : "rosette"
            )
            .foregroundStyle(newBest ? butter : cream)
            Spacer()
            Text(raceTime(personal)).monospacedDigit().fontWeight(.heavy).foregroundStyle(cream)
          }.font(.system(size: 12, weight: .semibold))
          eyebrow("SAVED ON THIS DEVICE", size: 7.5).foregroundStyle(cream.opacity(0.4))
        }.frame(maxWidth: 330)
      }.padding(24)
    }
  }

  private func resultChip(_ icon: String, _ text: String) -> some View {
    HStack(spacing: 5) {
      Image(systemName: icon).font(.system(size: 9, weight: .bold))
      Text(text).font(.system(size: 11, weight: .bold))
    }
    .foregroundStyle(cream)
    .padding(.horizontal, 10).padding(.vertical, 6)
    .background(cream.opacity(0.1), in: Capsule())
    .overlay { Capsule().strokeBorder(cream.opacity(0.2), lineWidth: 1) }
  }

  private var podium: some View {
    let sorted = game.race.drivers.indices.sorted {
      let a = game.race.drivers[$0]
      let b = game.race.drivers[$1]
      if let at = a.finishTime, let bt = b.finishTime { return at < bt }
      if a.finishTime != nil { return true }
      if b.finishTime != nil { return false }
      return a.tracker.progress > b.tracker.progress
    }
    let names = ["Clover", "Maple", "Mochi", "Pepper"]
    return HStack(alignment: .bottom, spacing: 6) {
      ForEach([1, 0, 2], id: \.self) { rank in
        let driver = sorted[rank]
        let height: CGFloat = rank == 0 ? 66 : (rank == 1 ? 48 : 38)
        VStack(spacing: 5) {
          CharacterBadge(driver: driver).frame(width: 40, height: 40)
            .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
          Text(names[driver] + (driver == 0 ? " · YOU" : ""))
            .font(.system(size: 9, weight: .heavy)).foregroundStyle(driver == 0 ? butter : cream)
          ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
              .fill(
                rank == 0
                  ? LinearGradient(
                    colors: [butter, butterDeep], startPoint: .top, endPoint: .bottom)
                  : LinearGradient(colors: [cream, creamDeep], startPoint: .top, endPoint: .bottom)
              )
              .overlay(alignment: .top) {
                Rectangle().fill(.white.opacity(0.7)).frame(height: 3)
              }
            Text("\(rank + 1)")
              .font(serif(rank == 0 ? 34 : 24))
              .foregroundStyle(deepForest).padding(.top, rank == 0 ? 10 : 6)
          }
          .frame(maxWidth: .infinity).frame(height: height)
          .shadow(color: .black.opacity(0.2), radius: 6, y: 4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(rank + 1). \(names[driver])\(driver == 0 ? ", you" : "")")
      }
    }
  }
}

struct GhostButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 13, weight: .bold))
      .frame(maxWidth: .infinity).frame(height: 42)
      .foregroundStyle(cream)
      .background(cream.opacity(configuration.isPressed ? 0.2 : 0.1), in: Capsule())
      .overlay { Capsule().strokeBorder(cream.opacity(0.25), lineWidth: 1) }
  }
}

struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

struct Confetti: View {
  private let start = Date()
  var body: some View {
    TimelineView(.animation) { timeline in
      let t = timeline.date.timeIntervalSince(start)
      Canvas { context, size in
        let colors = [
          butter, strawberry, cream, Color(uiColor: Palette.blue), Color(uiColor: Palette.lilac),
        ]
        for i in 0..<48 {
          let seed = Double(i)
          let speed = 55 + (seed * 37).truncatingRemainder(dividingBy: 40)
          let x =
            (seed * 97.3).truncatingRemainder(dividingBy: size.width)
            + sin(t * 1.6 + seed) * 22
          let y = (t * speed + seed * 61).truncatingRemainder(dividingBy: size.height + 40) - 20
          let fade = max(0, 1 - t / 7)
          var piece = context
          piece.translateBy(x: x, y: y)
          piece.rotate(by: .radians(t * 3 + seed))
          piece.opacity = fade
          piece.fill(
            Path(roundedRect: CGRect(x: -4, y: -2.5, width: 8, height: 5), cornerRadius: 1),
            with: .color(colors[i % colors.count]))
        }
      }
    }
  }
}

struct CharacterBadge: View {
  let driver: Int
  private var fur: Color {
    [
      cream, Color(red: 0.77, green: 0.49, blue: 0.32), Color(red: 0.46, green: 0.46, blue: 0.5),
      Color(white: 0.94),
    ][driver]
  }
  private var helmet: Color {
    [forest, cream, butter, Color(uiColor: Palette.blue)][driver]
  }
  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      ZStack {
        if driver == 0 {
          ForEach([-1.0, 1.0], id: \.self) { side in
            Capsule().fill(fur)
              .frame(width: width * 0.24, height: width * 0.5)
              .rotationEffect(.degrees(side * 12))
              .offset(x: width * side * 0.22, y: -width * 0.3)
          }
        } else if driver == 2 {
          ForEach([-1.0, 1.0], id: \.self) { side in
            Triangle().fill(fur).rotationEffect(.degrees(180))
              .frame(width: width * 0.26, height: width * 0.26)
              .offset(x: width * side * 0.3, y: -width * 0.36)
          }
        } else {
          ForEach([-1.0, 1.0], id: \.self) { side in
            Circle().fill(fur).frame(width: width * 0.28)
              .offset(x: width * side * 0.34, y: -width * (driver == 1 ? 0.28 : 0.05))
          }
        }
        Ellipse().fill(fur).frame(width: width * 0.84, height: width * 0.72)
        Ellipse().fill(helmet).frame(width: width * 0.86, height: width * 0.4).offset(
          y: -width * 0.24
        )
        .mask(Rectangle().frame(height: width * 0.2).offset(y: -width * 0.32))
        HStack(spacing: width * 0.24) {
          Circle().fill(deepForest).frame(width: width * 0.09)
          Circle().fill(deepForest).frame(width: width * 0.09)
        }.offset(y: width * 0.02)
        Ellipse().fill(strawberry.opacity(0.8))
          .frame(width: width * 0.12, height: width * 0.07).offset(y: width * 0.16)
      }.frame(width: width, height: geometry.size.height)
    }
  }
}

struct MiniMap: View {
  let circuit: Circuit
  let drivers: [Driver]
  var onCard: Bool
  var body: some View {
    Canvas { context, size in
      func point(_ p: Point) -> CGPoint {
        CGPoint(x: (p.x + 68) / 136 * size.width, y: (p.z + 50) / 100 * size.height)
      }
      var path = Path()
      path.addLines(circuit.points.map(point))
      path.closeSubpath()
      context.stroke(
        path, with: .color(onCard ? forest.opacity(0.9) : deepForest.opacity(0.7)), lineWidth: 8)
      context.stroke(path, with: .color(onCard ? creamDeep : cream.opacity(0.8)), lineWidth: 3.5)
      let start = point(circuit.points[0])
      context.fill(
        Path(
          roundedRect: CGRect(x: start.x - 2, y: start.y - 5, width: 4, height: 10), cornerRadius: 1
        ),
        with: .color(onCard ? strawberry : butter))
      for index in drivers.indices.reversed() {
        let p = point(drivers[index].point)
        let radius: CGFloat = index == 0 ? 4.5 : 3.2
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
          with: .color(index == 0 ? butter : strawberry))
        if index == 0 {
          context.stroke(
            Path(
              ellipseIn: CGRect(
                x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
            with: .color(.white), lineWidth: 1.5)
        }
      }
    }.accessibilityLabel("Circuit map")
  }
}

struct NativeScene: UIViewRepresentable {
  let game: GameController
  func makeUIView(context: Context) -> KeyboardSceneView {
    let view = KeyboardSceneView()
    view.scene = game.world.scene
    view.pointOfView = game.world.camera
    #if targetEnvironment(simulator)
      view.antialiasingMode = .multisampling2X
    #else
      view.antialiasingMode = .multisampling4X
    #endif
    view.preferredFramesPerSecond = 60
    view.isPlaying = true
    view.game = game
    view.becomeFirstResponder()
    return view
  }
  func updateUIView(_ uiView: KeyboardSceneView, context: Context) {}
}

final class KeyboardSceneView: SCNView {
  weak var game: GameController?
  override var canBecomeFirstResponder: Bool { true }
  override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      switch press.key?.keyCode {
      case .keyboardLeftArrow: game?.steer(-1)
      case .keyboardRightArrow: game?.steer(1)
      case .keyboardSpacebar: game?.drift()
      case .keyboardB: game?.item()
      case .keyboardP:
        if game?.phase == .paused { game?.resume() } else { game?.pause() }
      default: super.pressesBegan(presses, with: event)
      }
    }
  }
  override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
    for press in presses {
      if press.key?.keyCode == .keyboardLeftArrow || press.key?.keyCode == .keyboardRightArrow {
        game?.steer(0)
      }
    }
    super.pressesEnded(presses, with: event)
  }
}
