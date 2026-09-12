import SpriteKit
import SwiftUI

enum Palette {
  static let background = Color(red: 0.035, green: 0.025, blue: 0.075)
  static let panel = Color(red: 0.075, green: 0.055, blue: 0.14)
  static let coral = Color(red: 1, green: 0.36, blue: 0.43)
  static let cyan = Color(red: 0.35, green: 0.95, blue: 0.94)
  static let muted = Color(red: 0.63, green: 0.59, blue: 0.73)
  static let white = Color(red: 0.96, green: 0.95, blue: 1)
}

struct RootView: View {
  @ObservedObject var model: GameModel
  var body: some View {
    ZStack {
      Palette.background.ignoresSafeArea()
      if model.screenIsGame {
        PlayView(model: model)
      } else {
        HomeView(model: model)
      }
    }
    .foregroundStyle(Palette.white)
  }
}

struct HomeView: View {
  @ObservedObject var model: GameModel

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 22) {
        HStack {
          HStack(spacing: 8) {
            Image(systemName: "waveform.path").foregroundStyle(Palette.cyan)
            Text("PULSEBOUND").font(.system(size: 12, weight: .heavy)).tracking(3)
          }
          Spacer()
          SoundButton(model: model)
        }
        .padding(.top, 8)

        ZStack(alignment: .leading) {
          HeroArt().frame(height: 185)
          VStack(alignment: .leading, spacing: 9) {
            Eyebrow(text: "ONE TOUCH. PURE FLOW.", color: Palette.coral)
            Text("Find your\nfrequency.")
              .font(.system(size: 43, weight: .heavy, design: .rounded))
              .tracking(-1.9).lineSpacing(-4)
            Text("Three tracks. One perfect run.")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Palette.muted)
          }
        }

        VStack(spacing: 10) {
          HStack {
            Eyebrow(text: "SELECT A FREQUENCY")
            Spacer()
            Text("01 — 03").font(.system(size: 10, weight: .medium, design: .monospaced))
              .foregroundStyle(Palette.muted)
          }.padding(.bottom, 3)
          ForEach(Stage.all) { stage in
            StageCard(stage: stage, model: model)
          }
        }

        VStack(spacing: 16) {
          HStack(spacing: 6) {
            modeButton("Normal", detail: "One clean run", practice: false)
            modeButton("Practice", detail: "Save checkpoints", practice: true)
          }
          PrimaryButton(
            title: "Play \(model.stage.title)", icon: "arrow.up.right",
            action: model.enter)
          Text("Tap to jump  ·  Follow the beat  ·  Find your flow")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Palette.muted)
        }
      }
      .padding(.horizontal, 24).padding(.bottom, 20)
    }
  }

  private func modeButton(_ title: String, detail: String, practice: Bool) -> some View {
    Button {
      model.practice = practice
    } label: {
      HStack(spacing: 8) {
        Image(systemName: practice ? "flag.checkered" : "bolt.fill")
          .font(.system(size: 13))
        VStack(alignment: .leading, spacing: 3) {
          Text(title).font(.system(size: 12, weight: .bold))
          Text(detail).font(.system(size: 10))
            .foregroundStyle(Palette.muted)
        }
        Spacer(minLength: 0)
        if model.practice == practice {
          Circle().fill(Palette.cyan).frame(width: 5, height: 5)
        }
      }.padding(12).frame(maxWidth: .infinity, minHeight: 34)
        .background(model.practice == practice ? Palette.panel : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay(
          RoundedRectangle(cornerRadius: 13)
            .stroke(model.practice == practice ? Palette.cyan.opacity(0.38) : .white.opacity(0.08))
        )
    }.buttonStyle(.plain).accessibilityIdentifier(practice ? "mode.practice" : "mode.normal")
      .accessibilityAddTraits(model.practice == practice ? .isSelected : [])
  }
}

struct StageCard: View {
  let stage: Stage
  @ObservedObject var model: GameModel
  var selected: Bool { model.selection == stage.id }

  var body: some View {
    Button {
      model.selection = stage.id
    } label: {
      HStack(spacing: 15) {
        ZStack {
          RoundedRectangle(cornerRadius: 11)
            .fill((selected ? Palette.coral : Palette.muted).opacity(0.12))
          Text(String(format: "%02d", stage.id + 1))
            .font(.system(size: 22, weight: .light, design: .rounded))
            .foregroundStyle(selected ? Palette.coral : Palette.muted)
        }.frame(width: 48, height: 48)
        VStack(alignment: .leading, spacing: 5) {
          Text(stage.title).font(.system(size: 17, weight: .bold, design: .rounded))
          HStack(spacing: 5) {
            Text(stage.id == 0 ? "INTRO" : stage.id == 1 ? "FLOW" : "EXPERT")
              .foregroundStyle(selected ? Palette.coral : Palette.muted)
            Text("·  \(Int(stage.bpm)) BPM  ·  \(stage.duration) SEC")
              .foregroundStyle(Palette.muted)
          }.font(.system(size: 10, weight: .semibold)).tracking(0.2)
        }
        Spacer(minLength: 0)
        VStack(alignment: .trailing, spacing: 5) {
          if model.clears[stage.id] {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.cyan)
          } else {
            Text("\(Int(model.bests[stage.id]))%")
              .font(.system(size: 13, weight: .bold, design: .monospaced))
          }
          Text("BEST").font(.system(size: 9, weight: .bold)).tracking(1)
            .foregroundStyle(Palette.muted)
        }
      }
      .padding(13)
      .background(
        LinearGradient(
          colors: selected
            ? [Palette.coral.opacity(0.12), Palette.panel] : [Palette.panel, Palette.panel],
          startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .clipShape(RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(selected ? Palette.coral.opacity(0.65) : .white.opacity(0.06), lineWidth: 1)
      )
    }.buttonStyle(.plain).accessibilityIdentifier("stage.\(stage.id)")
      .accessibilityLabel("\(stage.title), \(Int(model.bests[stage.id])) percent best")
  }
}

struct HeroArt: View {
  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width * 0.88, y: size.height * 0.52)
      for index in (0..<6).reversed() {
        let radius = CGFloat(28 + index * 19)
        var shape = Path()
        shape.move(to: CGPoint(x: center.x, y: center.y - radius))
        shape.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        shape.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        shape.addLine(to: CGPoint(x: center.x - radius, y: center.y))
        shape.closeSubpath()
        context.stroke(
          shape,
          with: .color(
            (index == 0 ? Palette.cyan : Palette.coral).opacity(
              index == 0 ? 0.9 : 0.24 - Double(index) * 0.035)),
          lineWidth: index == 0 ? 3 : 1)
      }
      let core = Path(
        roundedRect: CGRect(x: center.x - 13, y: center.y - 13, width: 26, height: 26),
        cornerRadius: 5)
      context.fill(core, with: .color(Palette.cyan))
      let inset = Path(
        roundedRect: CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10),
        cornerRadius: 2)
      context.fill(inset, with: .color(Palette.background))
      for index in 0..<22 {
        let x = CGFloat(index) * size.width / 22
        let height = CGFloat(3 + (index * 17) % 20)
        let bar = Path(
          roundedRect: CGRect(x: x, y: size.height - height, width: 2, height: height),
          cornerRadius: 1)
        context.fill(bar, with: .color(Palette.coral.opacity(0.15)))
      }
    }.accessibilityHidden(true)
  }
}

struct PlayView: View {
  @ObservedObject var model: GameModel
  @State private var scene: GameScene?
  @State private var padPressed = false

  var body: some View {
    ZStack {
      VStack(spacing: 14) {
        HStack {
          IconButton(icon: "arrow.left", label: "Back to tracks", action: model.home)
          Spacer()
          Eyebrow(text: model.practice ? "PRACTICE SESSION" : "NORMAL SESSION", color: Palette.cyan)
          Spacer()
          IconButton(icon: "pause.fill", label: "Pause") { model.pause() }
            .disabled(model.engine.phase != .running)
        }
        .padding(.horizontal, 24)
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 7) {
            Eyebrow(
              text: "TRACK 0\(model.selection + 1) / \(Int(model.stage.bpm)) BPM",
              color: Palette.coral)
            Text(model.stage.title)
              .font(.system(size: 27, weight: .heavy, design: .rounded)).tracking(-0.7)
          }
          Spacer()
          ProgressRing(value: model.engine.progress, size: 62, lineWidth: 3)
        }.padding(.horizontal, 26)

        HStack {
          Text(String(format: "ATTEMPT %02d", max(1, model.attempts)))
          Spacer()
          Text("\(model.practice ? "PRACTICE" : "LOCAL") BEST  \(Int(model.best))%")
        }.font(.system(size: 11, weight: .semibold, design: .monospaced))
          .tracking(0.2).foregroundStyle(Palette.muted).padding(.horizontal, 26)

        ZStack {
          if let scene {
            GameCanvas(scene: scene)
              .background(Palette.background)
          }
          if model.engine.phase == .ready {
            VStack(spacing: 12) {
              Image(systemName: "hand.tap.fill")
                .font(.system(size: 25)).foregroundStyle(Palette.cyan)
              Text("The first beat is yours.")
                .font(.system(size: 20, weight: .bold, design: .rounded))
              Text(
                "Tap below to start. Tap again to jump.\nClear coral spikes. Land on the cyan line."
              )
              .font(.system(size: 11)).foregroundStyle(Palette.muted)
              .multilineTextAlignment(.center).lineSpacing(4)
            }
            .padding(24).background(Palette.background.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 21))
            .padding(.bottom, 55)
            .allowsHitTesting(false)
          }
          if model.checkpointNotice {
            Text("◆  CHECKPOINT SAVED")
              .font(.system(size: 11, weight: .bold, design: .monospaced))
              .foregroundStyle(Palette.cyan).padding(12)
              .background(Palette.background.opacity(0.9), in: Capsule())
              .frame(maxHeight: .infinity, alignment: .top).padding(.top, 14)
              .allowsHitTesting(false)
          }
          if model.resumeCount > 0 {
            VStack(spacing: 5) {
              Text("\(model.resumeCount)")
                .font(.system(size: 44, weight: .light, design: .rounded))
              Eyebrow(text: "FIND THE BEAT", color: Palette.cyan)
            }
            .frame(width: 140, height: 96)
            .background(Palette.background, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
              RoundedRectangle(cornerRadius: 22).stroke(Palette.cyan.opacity(0.5), lineWidth: 1)
            )
            .frame(maxHeight: .infinity, alignment: .top).padding(.top, 16)
            .allowsHitTesting(false)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        HStack(spacing: 7) {
          Circle().fill(Palette.cyan).frame(width: 4, height: 4)
          Text(
            model.practice
              ? "Checkpoints save automatically. Retry from your last flag."
              : "A clean run. No checkpoints. Every beat counts."
          )
          .font(.system(size: 11)).foregroundStyle(Palette.muted)
        }.padding(.horizontal, 24)
        ZStack {
          VStack(spacing: 7) {
            HStack(spacing: 10) {
              Image(systemName: model.engine.phase == .ready ? "play.fill" : "arrow.up")
              Text(model.engine.phase == .ready ? "LET’S GO" : "TAP TO JUMP")
                .tracking(2)
            }.font(.system(size: 16, weight: .heavy, design: .rounded))
            Text(
              model.engine.phase == .ready
                ? "Your rhythm starts here" : "Light touch. Perfect timing."
            )
            .font(.system(size: 11)).foregroundStyle(Palette.cyan.opacity(0.8))
          }
          .frame(maxWidth: .infinity).frame(height: 112)
          .background(Palette.cyan.opacity(padPressed ? 0.2 : 0.085))
          .clipShape(RoundedRectangle(cornerRadius: 22))
          .overlay(RoundedRectangle(cornerRadius: 22).stroke(Palette.cyan.opacity(0.45)))
          .accessibilityHidden(true)
          TouchPad(
            label: model.engine.phase == .ready ? "Let's go" : "Tap to jump",
            value:
              "phase \(String(describing: model.engine.phase)), progress \(Int(model.engine.progress)), grounded \(model.engine.grounded), next \(Int(model.engine.nextHazardDistance ?? 9999))",
            action: model.tap, pressed: { padPressed = $0 }
          )
        }
        .frame(height: 112)
        .foregroundStyle(Palette.cyan)
        .padding(.horizontal, 24).padding(.bottom, 24)
      }.padding(.top, 6)
        .accessibilityHidden(
          model.resultReady || (model.engine.phase == .paused && model.resumeCount == 0)
        )

      if model.engine.phase == .paused && model.resumeCount == 0 { PauseOverlay(model: model) }
      if model.resultReady {
        ResultOverlay(model: model)
      }
    }
    .onAppear { scene = GameScene(model: model) }
    .onDisappear { scene = nil }
  }
}

struct PauseOverlay: View {
  @ObservedObject var model: GameModel
  var body: some View {
    ZStack {
      Palette.background.ignoresSafeArea()
      VStack(spacing: 22) {
        Image(systemName: "pause.circle").font(.system(size: 52, weight: .ultraLight))
          .foregroundStyle(Palette.cyan)
        VStack(spacing: 8) {
          Eyebrow(text: "TAKE A BREATH")
          Text("Between beats.")
            .font(.system(size: 34, weight: .heavy, design: .rounded)).tracking(-1)
          Text(
            "\(model.stage.title) · \(model.practice ? "Practice" : "Normal") · \(Int(model.engine.progress))%"
          )
          .font(.system(size: 13)).foregroundStyle(Palette.muted)
        }
        PrimaryButton(title: "Resume the flow", icon: "play.fill", action: model.resume)
        Button("Restart attempt", action: model.retry).buttonStyle(SecondaryButtonStyle())
          .background(Palette.panel, in: RoundedRectangle(cornerRadius: 14))
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1)))
        HStack {
          Button("Back to tracks", action: model.home)
            .font(.system(size: 13, weight: .semibold))
          Spacer()
          SoundButton(model: model)
        }.foregroundStyle(Palette.muted)
      }.padding(30)
    }
  }
}

struct ResultOverlay: View {
  @ObservedObject var model: GameModel
  private var cleared: Bool { model.engine.phase == .cleared }
  var body: some View {
    ZStack {
      Palette.background.ignoresSafeArea()
      VStack(spacing: 25) {
        HStack {
          Eyebrow(
            text: model.practice
              ? "PRACTICE / \(model.stage.title.uppercased())"
              : "NORMAL / \(model.stage.title.uppercased())")
          Spacer()
          SoundButton(model: model)
        }
        Spacer(minLength: 0)
        VStack(spacing: 11) {
          Eyebrow(
            text: cleared
              ? "FREQUENCY FOUND"
              : model.engine.progress >= 80 ? "SO CLOSE. GO AGAIN." : "FIND YOUR TIMING",
            color: cleared ? Palette.cyan : Palette.coral)
          Text(cleared ? "Pure resonance." : "One more beat.")
            .font(.system(size: 34, weight: .heavy, design: .rounded)).tracking(-1.2)
        }
        ProgressRing(value: model.engine.progress, size: 178, lineWidth: 7)
          .padding(.vertical, 8)
        Text(
          cleared
            ? (model.practice
              ? "Practice complete. Ready for a clean run?" : "Every jump. Every beat. All yours.")
            : model.engine.jumps == 0
              ? "Tap as a coral spike approaches your cube."
              : "Watch the next spike. Jump before it reaches you."
        )
        .font(.system(size: 13)).foregroundStyle(Palette.muted)
        .multilineTextAlignment(.center)
        HStack(spacing: 0) {
          stat("ATTEMPT", value: String(format: "%02d", model.attempts))
          Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: 28)
          stat(model.practice ? "PRACTICE BEST" : "LOCAL BEST", value: "\(Int(model.best))%")
          Rectangle().fill(.white.opacity(0.1)).frame(width: 1, height: 28)
          stat("JUMPS", value: "\(model.engine.jumps)")
        }.padding(.vertical, 19).background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
        if model.practice {
          Label(
            model.engine.checkpoint > 0
              ? "Retry from \(Int(model.engine.checkpoint / model.stage.length * 100))% checkpoint"
              : "Reach a flag to save a checkpoint",
            systemImage: "flag.checkered"
          )
          .font(.system(size: 11, weight: .medium)).foregroundStyle(Palette.cyan)
        }
        Spacer(minLength: 0)
        PrimaryButton(
          title: cleared ? "Play it again" : "Try again", icon: "arrow.clockwise",
          action: model.retry
        )
        .accessibilityIdentifier("retry")
        Button("Back to tracks", action: model.home).buttonStyle(SecondaryButtonStyle())
      }.padding(.horizontal, 28).padding(.vertical, 20)
    }
  }

  private func stat(_ name: String, value: String) -> some View {
    VStack(spacing: 8) {
      Text(value).font(.system(size: 21, weight: .semibold, design: .rounded))
      Text(name).font(.system(size: 10, weight: .bold)).tracking(0.2).foregroundStyle(Palette.muted)
    }.frame(maxWidth: .infinity)
  }
}

struct ProgressRing: View {
  let value: Double
  let size: CGFloat
  let lineWidth: CGFloat
  var body: some View {
    ZStack {
      Circle().stroke(.white.opacity(0.075), lineWidth: lineWidth)
      Circle().trim(from: 0, to: min(1, value / 100))
        .stroke(
          AngularGradient(
            colors: [Palette.cyan, Palette.cyan, Palette.coral], center: .center,
            startAngle: .degrees(0), endAngle: .degrees(360)),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
      Circle().stroke(.white.opacity(0.045), lineWidth: 1).padding(10)
      VStack(spacing: size > 100 ? 5 : 2) {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
          Text("\(Int(value))")
            .font(.system(size: size > 100 ? 59 : 23, weight: .light, design: .rounded))
            .tracking(-1.5)
          Text("%").font(.system(size: size > 100 ? 20 : 10, weight: .light))
            .foregroundStyle(Palette.muted)
        }
        if size > 100 {
          Text("COMPLETED")
            .font(.system(size: 10, weight: .bold))
            .tracking(2).foregroundStyle(Palette.muted)
        }
      }
    }.frame(width: size, height: size).accessibilityLabel("\(Int(value)) percent completed")
  }
}

struct Eyebrow: View {
  let text: String
  var color = Palette.muted
  var body: some View {
    Text(text).font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(color)
  }
}

struct SoundButton: View {
  @ObservedObject var model: GameModel
  var body: some View {
    IconButton(
      icon: model.sound ? "speaker.wave.2" : "speaker.slash",
      label: model.sound ? "Mute sound" : "Enable sound"
    ) {
      model.sound.toggle()
    }.accessibilityIdentifier("sound")
  }
}

struct IconButton: View {
  let icon: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: icon).font(.system(size: 15, weight: .medium))
        .frame(width: 44, height: 44)
        .background(.white.opacity(0.04), in: Circle())
    }.buttonStyle(.plain).accessibilityLabel(label)
  }
}

struct PrimaryButton: View {
  let title: String
  let icon: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
        Spacer()
        Image(systemName: icon).font(.system(size: 16, weight: .semibold))
      }.padding(.horizontal, 23).frame(height: 59)
        .foregroundStyle(Palette.background)
        .background(Palette.coral, in: RoundedRectangle(cornerRadius: 18))
    }.buttonStyle(JumpButtonStyle())
  }
}

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.font(.system(size: 13, weight: .semibold))
      .foregroundStyle(Palette.muted).frame(maxWidth: .infinity, minHeight: 44)
      .opacity(configuration.isPressed ? 0.6 : 1)
  }
}

struct JumpButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.opacity(configuration.isPressed ? 0.72 : 1)
  }
}
