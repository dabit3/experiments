import SceneKit
import SwiftUI

@main
struct DriftPicnicApp: App {
  var body: some Scene {
    WindowGroup { PicnicView() }
  }
}

private let forest = Color(uiColor: Palette.green)
private let butter = Color(uiColor: Palette.butter)
private let cream = Color(uiColor: Palette.cream)

func raceTime(_ seconds: Double) -> String {
  guard seconds > 0 else { return "—:—" }
  return String(format: "%d:%05.2f", Int(seconds) / 60, seconds.truncatingRemainder(dividingBy: 60))
}

struct PicnicView: View {
  @StateObject private var game = GameController()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        NativeScene(game: game).ignoresSafeArea()
        if game.phase == .title {
          title(geometry.size)
        } else if game.phase == .results {
          results(geometry.size)
        } else {
          hud(geometry.size)
          if game.phase == .countdown {
            VStack(spacing: 0) {
              Text(game.countdown == 0 ? "GO!" : "\(game.countdown)")
                .font(.system(size: 96, weight: .black, design: .rounded))
              Text("A LITTLE RACE. A LOVELY DAY.")
                .font(.system(size: 11, weight: .heavy)).tracking(2)
            }
            .foregroundStyle(cream)
            .shadow(color: forest, radius: 12)
          }
          if game.phase == .paused { pausePanel }
        }
        if game.showGuide { guide(geometry.size) }
      }
      .foregroundStyle(forest)
      .fontDesign(.rounded)
      .onAppear { game.reducedMotion = reduceMotion }
      .onChange(of: reduceMotion) { _, value in game.reducedMotion = value }
      .onChange(of: scenePhase) { _, phase in
        if phase != .active { game.pause() }
      }
    }
    .persistentSystemOverlays(.hidden)
  }

  private func title(_ size: CGSize) -> some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 7) {
          Image(systemName: "sun.max.fill").foregroundStyle(butter)
          Text("THE LITTLE RACING CLUB").tracking(2.1)
        }
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(cream.opacity(0.7))
        VStack(alignment: .leading, spacing: -13) {
          Text("Drift").foregroundStyle(cream)
          Text("Picnic").foregroundStyle(butter)
        }
        .font(.system(size: size.height < 370 ? 59 : 71, weight: .black, design: .serif))
        .italic()
        Text("Small wheels. Sweeter victories.")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(cream.opacity(0.8))
          .padding(.top, 1)
        Spacer(minLength: 0)
        HStack(spacing: 7) {
          modeButton(.picnic, icon: "flag.checkered")
          modeButton(.trial, icon: "stopwatch")
        }
        Button(action: game.begin) {
          HStack {
            Text("Let’s race").font(.system(size: 18, weight: .heavy))
            Spacer()
            Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
          }
          .padding(.horizontal, 20).frame(height: 52)
          .background(butter, in: RoundedRectangle(cornerRadius: 17))
          .foregroundStyle(forest)
        }
        .accessibilityIdentifier("startRace")
        HStack {
          Text("3 LAPS  ·  \(game.mode == .picnic ? "4 FRIENDS" : "JUST YOU")")
            .font(.system(size: 9, weight: .heavy)).tracking(1.5)
          Spacer()
          Button {
            game.showGuide = true
          } label: {
            Text("How to play").font(.system(size: 11, weight: .bold)).underline()
          }.frame(minHeight: 32)
        }.foregroundStyle(cream.opacity(0.7))
      }
      .padding(.horizontal, 28).padding(.vertical, 20)
      .frame(width: min(365, size.width * 0.43))
      .background(forest)
      Spacer(minLength: 0)
      VStack {
        HStack {
          Spacer()
          soundButton
        }
        Spacer()
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("01").font(.system(size: 25, weight: .black, design: .serif)).italic()
            Rectangle().fill(forest.opacity(0.2)).frame(width: 1, height: 30)
            VStack(alignment: .leading, spacing: 3) {
              Text("Strawberry Circuit").font(.system(size: 17, weight: .heavy))
              Text("A SUN-SOAKED TABLETOP CLASSIC").font(.system(size: 8, weight: .bold)).tracking(
                1.3)
            }
          }
          HStack {
            Label("Best lap", systemImage: "stopwatch")
            Spacer()
            Text(raceTime(game.bestLap)).monospacedDigit().fontWeight(.heavy)
          }.font(.system(size: 11))
        }
        .padding(17).background(cream, in: RoundedRectangle(cornerRadius: 19))
        .frame(maxWidth: 310)
      }.padding(20)
    }
  }

  private func modeButton(_ mode: RaceMode, icon: String) -> some View {
    Button {
      game.mode = mode
    } label: {
      HStack(spacing: 6) {
        Image(systemName: icon)
        Text(mode.rawValue)
      }
      .font(.system(size: 11, weight: .bold))
      .frame(maxWidth: .infinity).frame(height: 40)
      .background(
        game.mode == mode ? cream : cream.opacity(0.1), in: RoundedRectangle(cornerRadius: 12)
      )
      .foregroundStyle(game.mode == mode ? forest : cream)
    }
    .accessibilityAddTraits(game.mode == mode ? .isSelected : [])
  }

  private var soundButton: some View {
    Button(action: game.toggleSound) {
      Image(systemName: game.sound ? "speaker.wave.2.fill" : "speaker.slash.fill")
        .font(.system(size: 16, weight: .bold))
        .frame(width: 44, height: 44).background(cream, in: Circle())
    }
    .accessibilityLabel(game.sound ? "Mute sound" : "Enable sound")
  }

  private func hud(_ size: CGSize) -> some View {
    VStack {
      HStack(alignment: .top) {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(game.mode == .trial ? "TT" : "\(game.race.position)")
            .font(.system(size: 43, weight: .black, design: .rounded))
          if game.mode == .picnic { Text("/ 4").font(.system(size: 15, weight: .heavy)) }
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
        .background(butter, in: RoundedRectangle(cornerRadius: 17))
        Spacer()
        HStack(spacing: 20) {
          metric("LAP", "\(min(3, game.race.player.tracker.laps + 1)) / 3")
          Rectangle().fill(cream.opacity(0.25)).frame(width: 1, height: 28)
          metric("RACE TIME", raceTime(game.race.elapsed))
        }
        .padding(.horizontal, 21).padding(.vertical, 11)
        .foregroundStyle(cream).background(forest.opacity(0.93), in: Capsule())
        Spacer()
        soundButton
        Button(action: game.pause) {
          Image(systemName: "pause.fill").font(.system(size: 16, weight: .bold))
            .frame(width: 44, height: 44).background(cream, in: Circle())
        }.accessibilityLabel("Pause race").accessibilityIdentifier("pauseRace")
      }
      Spacer()
      if game.race.feedbackRemaining > 0 && game.phase == .racing {
        Text(game.race.feedback)
          .font(.system(size: 12, weight: .heavy)).tracking(1.1)
          .padding(.horizontal, 20).padding(.vertical, 11)
          .background(butter, in: Capsule())
          .padding(.bottom, 8)
          .accessibilityIdentifier("raceFeedback")
      }
      HStack(alignment: .bottom) {
        HStack(spacing: 12) {
          steeringButton(-1, icon: "arrow.turn.up.left", label: "Steer left")
          steeringButton(1, icon: "arrow.turn.up.right", label: "Steer right")
        }
        VStack(alignment: .leading, spacing: 3) {
          Text("\(Int(game.race.player.speed * 3.6))")
            .font(.system(size: 26, weight: .black)).monospacedDigit()
          Text("KM/H").font(.system(size: 8, weight: .heavy)).tracking(1)
        }
        .foregroundStyle(cream).shadow(color: forest, radius: 4).padding(.leading, 7)
        Spacer()
        MiniMap(circuit: game.race.circuit, drivers: game.race.drivers)
          .frame(width: 115, height: 75).padding(.trailing, 8)
        Button(action: game.item) {
          VStack(spacing: 4) {
            Image(systemName: game.race.hasItem ? "cup.and.saucer.fill" : "sparkle")
              .font(.system(size: 24, weight: .bold))
            Text(game.race.hasItem ? "LEMONADE" : "FIND A CUP")
              .font(.system(size: 8, weight: .heavy)).tracking(0.6)
          }
          .frame(width: 88, height: 76)
          .background(
            game.race.hasItem ? butter : cream.opacity(0.75), in: RoundedRectangle(cornerRadius: 23)
          )
        }
        .disabled(!game.race.hasItem)
        .accessibilityLabel(game.race.hasItem ? "Use lemonade boost" : "No item collected")
        .accessibilityIdentifier("useItem")
        Button(action: game.drift) {
          VStack(spacing: 5) {
            Image(systemName: game.race.drifting ? "bolt.fill" : "skew")
              .font(.system(size: 25, weight: .bold))
            Text(game.race.drifting ? "RELEASE" : "DRIFT")
              .font(.system(size: 10, weight: .heavy)).tracking(1)
            Capsule().fill(forest.opacity(0.2)).frame(width: 53, height: 4)
              .overlay(alignment: .leading) {
                Capsule().fill(forest).frame(
                  width: 53 * min(1, game.race.player.driftCharge / 0.65), height: 4)
              }
          }
          .frame(width: 92, height: 88)
          .background(game.race.drifting ? butter : cream, in: RoundedRectangle(cornerRadius: 25))
        }
        .accessibilityLabel(game.race.drifting ? "Release drift boost" : "Start drift")
        .accessibilityIdentifier("drift")
      }
    }
    .padding(.horizontal, 18).padding(.vertical, size.height < 370 ? 10 : 17)
  }

  private func steeringButton(_ direction: Double, icon: String, label: String) -> some View {
    Image(systemName: icon)
      .font(.system(size: 27, weight: .bold))
      .frame(width: 76, height: 76)
      .background(
        game.race.steering == direction ? butter : cream.opacity(0.92),
        in: RoundedRectangle(cornerRadius: 24)
      )
      .contentShape(RoundedRectangle(cornerRadius: 24))
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

  private func metric(_ label: String, _ value: String) -> some View {
    VStack(spacing: 3) {
      Text(label).font(.system(size: 8, weight: .heavy)).tracking(1.8)
      Text(value).font(.system(size: 18, weight: .heavy)).monospacedDigit()
    }
  }

  private func guide(_ size: CGSize) -> some View {
    ZStack {
      forest.opacity(0.88).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 17) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("A quick pit stop.").font(.system(size: 32, weight: .black, design: .serif))
              .italic()
            Text("Three little tricks for a sweet first race.").font(.system(size: 13))
          }
          Spacer()
          Button {
            game.showGuide = false
          } label: {
            Image(systemName: "xmark").fontWeight(.bold).frame(width: 44, height: 44)
          }.accessibilityLabel("Close instructions")
        }
        HStack(alignment: .top, spacing: 22) {
          tip(
            "01", "Steer your way",
            "Hold the arrows to steer. We accelerate for you, with gentle corner assist.",
            "arrow.left.and.right")
          tip(
            "02", "Drift, then dash",
            "Tap DRIFT into a bend. When the bar fills, tap RELEASE for a burst.", "bolt.fill")
          tip(
            "03", "Sip. Zip. Repeat.",
            "Drive through a lemonade. Tap its button to boost past your friends.",
            "cup.and.saucer.fill")
        }
        Button(action: game.start) {
          HStack {
            Text("Got it. Let’s picnic!")
            Image(systemName: "arrow.right")
          }.font(.system(size: 15, weight: .heavy))
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(forest, in: RoundedRectangle(cornerRadius: 15)).foregroundStyle(cream)
        }.accessibilityIdentifier("confirmGuide")
      }
      .padding(25).frame(maxWidth: min(size.width - 40, 700))
      .background(cream, in: RoundedRectangle(cornerRadius: 27))
    }
  }

  private func tip(_ number: String, _ title: String, _ text: String, _ icon: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon).font(.system(size: 20, weight: .bold))
        Spacer()
        Text(number).font(.system(size: 11, weight: .heavy)).foregroundStyle(forest.opacity(0.5))
      }.frame(height: 25)
      Text(title).font(.system(size: 14, weight: .heavy))
      Text(text).font(.system(size: 11)).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }

  private var pausePanel: some View {
    ZStack {
      forest.opacity(0.75).ignoresSafeArea()
      VStack(spacing: 13) {
        Image(systemName: "sun.haze.fill").font(.system(size: 30)).foregroundStyle(butter)
        Text("Take a breather.").font(.system(size: 34, weight: .black, design: .serif)).italic()
        Text("Your picnic will be right here.").font(.system(size: 13)).opacity(0.8)
        Button("Back to the race", action: game.resume).buttonStyle(PicnicButtonStyle())
          .accessibilityIdentifier("resumeRace")
        HStack(spacing: 24) {
          Button("Restart", action: game.start)
          Button("Leave race", action: game.home)
        }.font(.system(size: 13, weight: .bold)).frame(height: 44)
      }
      .foregroundStyle(cream).padding(28)
      .frame(width: 340).background(forest, in: RoundedRectangle(cornerRadius: 28))
    }
  }

  private func results(_ size: CGSize) -> some View {
    ZStack {
      forest.opacity(0.93).ignoresSafeArea()
      HStack(spacing: 30) {
        VStack(alignment: .leading, spacing: 11) {
          Text(game.mode == .trial ? "TIME TRIAL COMPLETE" : "STRAWBERRY CIRCUIT · CUP COMPLETE")
            .font(.system(size: 9, weight: .heavy)).tracking(1.4).foregroundStyle(butter)
          Text(
            game.mode == .trial
              ? "Sweet time."
              : (game.race.position == 1 ? "Oh, sweet\nvictory!" : "A lovely\nlittle race.")
          )
          .font(.system(size: size.height < 370 ? 38 : 46, weight: .black, design: .serif))
          .italic().lineSpacing(-6).foregroundStyle(cream)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(game.mode == .trial ? "3" : "\(game.race.position)")
              .font(.system(size: 55, weight: .black))
            Text(game.mode == .trial ? "LAPS COMPLETE" : "OF 4 RACERS")
              .font(.system(size: 10, weight: .heavy)).tracking(1)
          }.foregroundStyle(butter)
          Text("\(game.race.driftBoosts) drift boosts  ·  \(game.race.itemsCollected) lemonades")
            .font(.system(size: 11, weight: .medium)).foregroundStyle(cream.opacity(0.8))
          HStack(spacing: 10) {
            Button("Race again", action: game.start).buttonStyle(PicnicButtonStyle())
              .accessibilityIdentifier("raceAgain")
            Button(action: game.home) {
              Image(systemName: "house.fill").frame(width: 48, height: 48)
                .background(cream.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
            }.foregroundStyle(cream).accessibilityLabel("Back to title")
          }
        }.frame(maxWidth: 305, alignment: .leading)
        VStack(spacing: 12) {
          if game.mode == .picnic { podium }
          HStack {
            metric("RACE TIME", raceTime(game.race.elapsed))
            Spacer()
            metric("BEST LAP", raceTime(game.race.player.lapTimes.min() ?? 0))
          }
          .padding(18).background(cream, in: RoundedRectangle(cornerRadius: 18))
          HStack {
            Label("Personal best", systemImage: "rosette")
            Spacer()
            Text(raceTime(game.mode == .picnic ? game.bestCup : game.bestTrial))
              .monospacedDigit().fontWeight(.heavy)
          }.font(.system(size: 12)).foregroundStyle(cream)
          Text("SAVED ON THIS DEVICE").font(.system(size: 8, weight: .bold))
            .tracking(1.8).foregroundStyle(cream.opacity(0.45))
        }.frame(maxWidth: 325)
      }.padding(24)
    }
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
    return HStack(alignment: .bottom, spacing: 8) {
      ForEach([1, 0, 2], id: \.self) { rank in
        VStack(spacing: 5) {
          Image(systemName: sorted[rank] == 0 ? "hare.fill" : "pawprint.fill")
            .font(.system(size: rank == 0 ? 28 : 23)).foregroundStyle(rank == 0 ? butter : cream)
          Text(names[sorted[rank]] + (sorted[rank] == 0 ? " · YOU" : ""))
            .font(.system(size: 9, weight: .heavy)).foregroundStyle(cream)
          Text("\(rank + 1)")
            .font(.system(size: rank == 0 ? 37 : 28, weight: .black, design: .serif))
            .frame(maxWidth: .infinity).frame(height: rank == 0 ? 64 : (rank == 1 ? 46 : 36))
            .background(
              rank == 0 ? butter : cream.opacity(0.85),
              in: UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))
        }
      }
    }
  }
}

struct PicnicButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 15, weight: .heavy))
      .frame(maxWidth: .infinity).frame(height: 48)
      .foregroundStyle(forest)
      .background(
        butter.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 15))
  }
}

struct MiniMap: View {
  let circuit: Circuit
  let drivers: [Driver]
  var body: some View {
    Canvas { context, size in
      func point(_ p: Point) -> CGPoint {
        CGPoint(x: (p.x + 68) / 136 * size.width, y: (p.z + 50) / 100 * size.height)
      }
      var path = Path()
      path.addLines(circuit.points.map(point))
      context.stroke(path, with: .color(forest.opacity(0.5)), lineWidth: 9)
      context.stroke(path, with: .color(cream.opacity(0.75)), lineWidth: 4)
      for index in drivers.indices.reversed() {
        let p = point(drivers[index].point)
        context.fill(
          Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)),
          with: .color(index == 0 ? butter : .pink))
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
    view.antialiasingMode = .multisampling4X
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
