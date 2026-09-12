import SwiftUI

private let cream = Color(red: 0.98, green: 0.94, blue: 0.81)
private let honey = Color(red: 0.92, green: 0.73, blue: 0.40)
private let ink = Color(red: 0.10, green: 0.23, blue: 0.20)

struct GameView: View {
  @ObservedObject var model: GameModel

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        NativeScene(model: model).ignoresSafeArea()
        if model.screen == .home {
          home(compact: geometry.size.height < 370)
        } else if model.screen == .playing {
          gameplay
        } else if model.screen == .chapters {
          chapterSelect
        } else {
          Color(red: 0.04, green: 0.13, blue: 0.12).opacity(0.77).ignoresSafeArea()
          overlay
        }
      }
      .foregroundStyle(cream)
      .font(.custom("AvenirNext-Medium", size: 15))
    }
  }

  private func home(compact: Bool) -> some View {
    ZStack(alignment: .leading) {
      LinearGradient(
        colors: [ink.opacity(0.91), ink.opacity(0.65), .clear],
        startPoint: .leading, endPoint: .trailing
      ).ignoresSafeArea()
      VStack(alignment: .leading, spacing: compact ? 9 : 14) {
        HStack(spacing: 8) {
          Image(systemName: "leaf.fill").foregroundStyle(honey)
          Text("A TINY WOODLAND ODYSSEY").tracking(3).font(.system(size: 10, weight: .semibold))
        }
        VStack(alignment: .leading, spacing: -6) {
          Text("Buttonwood").font(.custom("Georgia-Bold", size: compact ? 46 : 58))
          Text("Adventure").font(.custom("Georgia", size: compact ? 36 : 45)).foregroundStyle(honey)
        }
        Text("Small boots. Great big wonder.")
          .font(.custom("AvenirNext-Regular", size: 15)).foregroundStyle(cream.opacity(0.75))
          .padding(.bottom, compact ? 1 : 8)
        HStack(spacing: 13) {
          primary(
            model.records.isEmpty ? "Begin adventure" : "Continue journey", icon: "arrow.right"
          ) {
            model.start(model.unlocked)
          }.accessibilityIdentifier("begin")
          Button {
            model.screen = .chapters
          } label: {
            Image(systemName: "map").font(.system(size: 21))
              .frame(width: 51, height: 51)
              .background(cream.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
              .overlay(RoundedRectangle(cornerRadius: 16).stroke(cream.opacity(0.25)))
          }.accessibilityLabel("Choose chapter")
        }
        HStack(spacing: 20) {
          Button {
            model.showHelp()
          } label: {
            Label("How to wander", systemImage: "questionmark.circle")
              .font(.system(size: 12, weight: .medium)).frame(height: 38)
          }
          Text("3 handcrafted chapters").font(.system(size: 11)).foregroundStyle(
            cream.opacity(0.48))
        }
      }
      .padding(.leading, 26)
      VStack {
        HStack {
          Spacer()
          soundButton
        }
        Spacer()
        HStack {
          Spacer()
          Text("MADE FOR A LITTLE ESCAPE").tracking(2.5)
            .font(.system(size: 9, weight: .medium)).foregroundStyle(cream.opacity(0.6))
        }
      }.padding(.vertical, 20).padding(.trailing, 22)
    }
  }

  private var gameplay: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        HStack(spacing: 13) {
          Image(systemName: "leaf.fill").foregroundStyle(honey)
          VStack(alignment: .leading, spacing: 3) {
            Text("CHAPTER 0\(model.snapshot.levelIndex + 1)")
              .tracking(2).font(.system(size: 8, weight: .semibold)).foregroundStyle(honey)
            Text(model.snapshot.level.name).font(.custom("Georgia-Bold", size: 14))
          }
          Rectangle().fill(cream.opacity(0.16)).frame(width: 1, height: 25)
          HStack(spacing: 5) {
            ForEach(0..<3) { index in
              Image(systemName: index < model.snapshot.lives ? "heart.fill" : "heart")
                .font(.system(size: 12))
                .foregroundStyle(
                  index < model.snapshot.lives
                    ? Color(red: 0.9, green: 0.56, blue: 0.43) : cream.opacity(0.3))
            }
          }.accessibilityLabel("\(model.snapshot.lives) lives")
        }
        .padding(.horizontal, 15).padding(.vertical, 10)
        .background(ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 17))
        Spacer(minLength: 5)
        HStack(spacing: 16) {
          Label("\(model.snapshot.coinCount)", systemImage: "circle.dotted.circle.fill")
            .foregroundStyle(honey)
          Text(model.snapshot.score.formatted()).monospacedDigit()
          Text(time(model.snapshot.time)).foregroundStyle(cream.opacity(0.65)).monospacedDigit()
        }
        .font(.system(size: 14, weight: .semibold))
        .padding(.horizontal, 16).frame(height: 51)
        .background(ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 17))
        Button {
          model.pause()
        } label: {
          Image(systemName: "pause.fill").font(.system(size: 16))
            .frame(width: 51, height: 51)
            .background(ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 17))
        }.accessibilityLabel("Pause").accessibilityIdentifier("pause")
      }
      .padding(.top, 10)
      .accessibilityElement(children: .contain)
      if !model.toast.isEmpty {
        Text(model.toast)
          .font(.system(size: 12, weight: .medium))
          .padding(.horizontal, 16).padding(.vertical, 8)
          .background(ink.opacity(0.88), in: Capsule()).padding(.top, 10)
          .transition(.opacity)
      }
      Spacer()
      HStack(alignment: .bottom) {
        HStack(spacing: 13) {
          HoldControl(symbol: "arrow.left", label: "Run left", tint: cream) {
            model.move($0 ? -1 : 0)
          }
          HoldControl(symbol: "arrow.right", label: "Run right", tint: cream) {
            model.move($0 ? 1 : 0)
          }
        }
        Spacer()
        VStack(spacing: 4) {
          if model.snapshot.shield {
            Label("ACORN GUARD", systemImage: "shield.fill")
              .font(.system(size: 9, weight: .bold)).foregroundStyle(honey)
          }
          Text("HOLD TO JUMP HIGHER").tracking(1.5)
            .font(.system(size: 8, weight: .bold)).foregroundStyle(cream.opacity(0.65))
        }.padding(.bottom, 12)
        Spacer()
        HoldControl(symbol: "arrow.up", label: "Jump", tint: honey, size: 76) {
          model.jump($0)
        }.accessibilityIdentifier("jump")
      }
      .padding(.bottom, 12)
    }
    .padding(.horizontal, 20)
  }

  private var chapterSelect: some View {
    ZStack {
      ink.opacity(0.91).ignoresSafeArea()
      VStack(spacing: 17) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            eyebrow("THE WOODLAND ATLAS")
            Text("Pick a path").font(.custom("Georgia-Bold", size: 30))
          }
          Spacer()
          Button {
            model.home()
          } label: {
            Image(systemName: "xmark").frame(width: 44, height: 44)
          }.accessibilityLabel("Close atlas")
        }
        HStack(spacing: 16) {
          ForEach(0..<3) { index in
            chapterCard(index)
          }
        }
        Text("A star for coming home. A star for half the buttons. A star for all three hearts.")
          .font(.system(size: 11)).foregroundStyle(cream.opacity(0.6))
      }.padding(.horizontal, 32)
    }
  }

  private func chapterCard(_ index: Int) -> some View {
    let level = Level.all[index]
    let record = model.records[String(index)]
    let unlocked = index <= model.unlocked
    return Button {
      model.start(index)
    } label: {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("0\(index + 1)").font(.custom("Georgia", size: 38)).foregroundStyle(honey)
          Spacer()
          Image(systemName: unlocked ? ["leaf", "gearshape.2", "sparkles"][index] : "lock")
            .font(.system(size: 27, weight: .light)).foregroundStyle(honey)
        }
        Text(level.name).font(.custom("Georgia-Bold", size: 18))
        Text(level.subtitle).font(.system(size: 11)).foregroundStyle(cream.opacity(0.65))
          .frame(height: 28, alignment: .topLeading)
        HStack(spacing: 4) {
          ForEach(0..<3) { star in
            Image(systemName: star < (record?.stars ?? 0) ? "star.fill" : "star")
              .foregroundStyle(honey).font(.system(size: 13))
          }
          Spacer()
          Text(record == nil ? (unlocked ? "EXPLORE →" : "LOCKED") : "\(record?.score ?? 0) BEST")
            .font(.system(size: 9, weight: .bold)).tracking(1)
        }
      }
      .padding(19).frame(maxWidth: .infinity)
      .background(cream.opacity(unlocked ? 0.08 : 0.025), in: RoundedRectangle(cornerRadius: 22))
      .overlay(RoundedRectangle(cornerRadius: 22).stroke(honey.opacity(unlocked ? 0.3 : 0.1)))
    }
    .buttonStyle(.plain)
    .disabled(!unlocked)
    .accessibilityLabel("\(level.name), \(unlocked ? "play chapter" : "locked")")
  }

  @ViewBuilder private var overlay: some View {
    switch model.screen {
    case .paused:
      VStack(spacing: 14) {
        eyebrow("TAKE A BREATHER")
        Text("The forest can wait.").font(.custom("Georgia-Bold", size: 34))
        Text("Your adventure is right where you left it.")
          .foregroundStyle(cream.opacity(0.65)).font(.system(size: 13))
        primary("Keep wandering", icon: "play.fill") { model.resume() }.padding(.top, 5)
        HStack(spacing: 22) {
          Button("How to play") { model.showHelp() }.frame(height: 44)
          soundButton
          Button("Back to title") { model.home() }.frame(height: 44)
        }.font(.system(size: 12, weight: .medium))
      }
    case .help:
      VStack(spacing: 17) {
        eyebrow("FIELD NOTES")
        Text("A little know-how.").font(.custom("Georgia-Bold", size: 32))
        HStack(alignment: .top, spacing: 26) {
          instruction(
            "arrow.left.and.right", title: "Find your feet",
            text: "Hold the arrows to run.\nTap jump for a hop; hold for height.")
          instruction(
            "leaf", title: "Brave the beetles",
            text: "Land on a beetle to bounce.\nAcorns protect you from one hit.")
          instruction(
            "sparkles", title: "Follow the light",
            text: "Light a lantern to save your place.\nReach the brass door to finish.")
        }.padding(.vertical, 4)
        Text("Keyboard: ← → to run · Space to jump · Esc to pause")
          .font(.system(size: 10)).foregroundStyle(cream.opacity(0.55))
        primary("Got it", icon: "checkmark") { model.dismissHelp() }
      }.padding(20)
    case .hurt, .lost:
      VStack(spacing: 13) {
        eyebrow(model.screen == .hurt ? "A LITTLE TUMBLE" : "EVERY EXPLORER STARTS AGAIN")
        Text(model.screen == .hurt ? "Dust off your boots." : "A new trail awaits.")
          .font(.custom("Georgia-Bold", size: 34))
        Text(
          model.screen == .hurt
            ? "\(model.snapshot.lives) hearts left · \(model.snapshot.checkpointActive ? "Your lantern is waiting." : "Try the trail again.")"
            : "You gathered \(model.snapshot.coinCount) buttons. Let’s go a little further."
        )
        .font(.system(size: 13)).foregroundStyle(cream.opacity(0.7))
        primary(model.screen == .hurt ? "Try again" : "Replay chapter", icon: "arrow.clockwise") {
          if model.screen == .hurt {
            model.retryCheckpoint()
          } else {
            model.start(model.snapshot.levelIndex)
          }
        }.padding(.top, 8)
        Button("Back to title") { model.home() }.font(.system(size: 12)).frame(height: 44)
      }
    case .won:
      result
    default: EmptyView()
    }
  }

  private var result: some View {
    VStack(spacing: 11) {
      eyebrow(model.lastWasBest ? "A NEW PERSONAL BEST" : "CHAPTER COMPLETE")
      Text(model.snapshot.levelIndex == 2 ? "You brought the light home." : "Wonder, well earned.")
        .font(.custom("Georgia-Bold", size: 33))
      HStack(spacing: 12) {
        ForEach(0..<3) { star in
          Image(systemName: star < model.snapshot.stars ? "star.fill" : "star")
            .font(.system(size: 26)).foregroundStyle(honey)
        }
      }.padding(.vertical, 3)
      HStack(spacing: 0) {
        metric("SCORE", value: model.snapshot.score.formatted())
        metric("BUTTONS", value: "\(model.snapshot.coinCount)/\(model.snapshot.level.coins.count)")
        metric("TRAIL TIME", value: time(model.snapshot.time))
      }
      .padding(.vertical, 10).frame(width: 440)
      .background(cream.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
      Text("Finish · collect half the buttons · keep all three hearts")
        .font(.system(size: 10)).foregroundStyle(cream.opacity(0.5))
      HStack(spacing: 15) {
        Button("Replay") { model.start(model.snapshot.levelIndex) }
          .font(.system(size: 13)).frame(width: 70, height: 48)
        primary(
          model.snapshot.levelIndex < 2 ? "Next chapter" : "Woodland atlas", icon: "arrow.right"
        ) {
          if model.snapshot.levelIndex < 2 {
            model.start(model.snapshot.levelIndex + 1)
          } else {
            model.screen = .chapters
          }
        }
        ShareLink(
          item:
            "I scored \(model.snapshot.score) with \(model.snapshot.coinCount) buttons on \(model.snapshot.level.name) in Buttonwood Adventure!"
        ) {
          Image(systemName: "square.and.arrow.up").frame(width: 48, height: 48)
        }.accessibilityLabel("Share your result")
        Button {
          model.home()
        } label: {
          Image(systemName: "house").frame(width: 44, height: 48)
        }.accessibilityLabel("Back to title")
      }.padding(.top, 3)
    }
  }

  private func metric(_ title: String, value: String) -> some View {
    VStack(spacing: 4) {
      Text(title).tracking(1.5).font(.system(size: 8, weight: .bold)).foregroundStyle(honey)
      Text(value).font(.custom("Georgia", size: 24)).monospacedDigit()
    }.frame(maxWidth: .infinity)
  }

  private func instruction(_ icon: String, title: String, text: String) -> some View {
    VStack(spacing: 9) {
      Image(systemName: icon).font(.system(size: 26, weight: .light)).foregroundStyle(honey)
      Text(title).font(.custom("Georgia-Bold", size: 17))
      Text(text).font(.system(size: 11)).multilineTextAlignment(.center)
        .foregroundStyle(cream.opacity(0.7)).lineSpacing(5)
    }.frame(maxWidth: 230)
  }

  private var soundButton: some View {
    Button {
      model.toggleSound()
    } label: {
      Image(systemName: model.sound ? "speaker.wave.2" : "speaker.slash")
        .font(.system(size: 17))
        .frame(width: 44, height: 44)
        .background(ink.opacity(0.48), in: Circle())
    }.accessibilityLabel(model.sound ? "Mute sound" : "Enable sound")
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).tracking(3).font(.system(size: 10, weight: .semibold)).foregroundStyle(honey)
  }

  private func primary(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 20) {
        Text(text).font(.custom("AvenirNext-DemiBold", size: 14))
        Image(systemName: icon).font(.system(size: 13, weight: .semibold))
      }
      .foregroundStyle(ink).padding(.horizontal, 23).frame(height: 51)
      .background(honey, in: RoundedRectangle(cornerRadius: 16))
      .overlay(RoundedRectangle(cornerRadius: 16).stroke(cream.opacity(0.35)))
      .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
    }.buttonStyle(.plain)
  }

  private func time(_ seconds: Double) -> String {
    String(format: "%01d:%02d", Int(seconds) / 60, Int(seconds) % 60)
  }
}

private struct HoldControl: View {
  let symbol: String
  let label: String
  let tint: Color
  var size: CGFloat = 66
  let action: (Bool) -> Void
  @State private var held = false

  var body: some View {
    Image(systemName: symbol)
      .font(.system(size: 25, weight: .medium))
      .foregroundStyle(tint)
      .frame(width: size, height: size)
      .background(held ? tint.opacity(0.3) : ink.opacity(0.82), in: Circle())
      .overlay(Circle().stroke(tint.opacity(held ? 0.8 : 0.38), lineWidth: 1.5))
      .overlay(Circle().stroke(tint.opacity(0.1), lineWidth: 1).padding(5))
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            if !held {
              held = true
              action(true)
            }
          }
          .onEnded { _ in
            held = false
            action(false)
          }
      )
      .onDisappear {
        held = false
        action(false)
      }
      .accessibilityElement()
      .accessibilityLabel(label)
      .accessibilityAddTraits(.isButton)
      .accessibilityAction {
        action(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { action(false) }
      }
  }
}
