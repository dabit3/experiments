import SwiftUI

private let cream = Palette.cream
private let honey = Palette.honey
private let ink = Palette.ink

struct GameView: View {
  @ObservedObject var model: GameModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        NativeScene(model: model).ignoresSafeArea()
        Vignette()
        if model.screen == .home {
          home(compact: geometry.size.height < 370)
        } else if model.screen == .playing {
          gameplay
        } else if model.screen == .chapters {
          chapterSelect
        } else {
          Color(red: 0.03, green: 0.10, blue: 0.10).opacity(0.78).ignoresSafeArea()
          overlay
            .transition(.scale(scale: 0.96).combined(with: .opacity))
        }
      }
      .foregroundStyle(cream)
      .font(Type.body(15))
      .animation(reduceMotion ? nil : .spring(duration: 0.35), value: model.screen)
    }
  }

  // MARK: Title

  private func home(compact: Bool) -> some View {
    ZStack(alignment: .leading) {
      LinearGradient(
        colors: [ink.opacity(0.94), ink.opacity(0.72), .clear],
        startPoint: .leading, endPoint: .trailing
      ).ignoresSafeArea()
      VStack(alignment: .leading, spacing: compact ? 8 : 13) {
        HStack(spacing: 10) {
          Flourish(width: 54)
          Text("A TINY WOODLAND ODYSSEY").tracking(3.2).font(Type.label(10)).foregroundStyle(honey)
        }
        VStack(alignment: .leading, spacing: compact ? -8 : -10) {
          Text("Buttonwood")
            .font(Type.display(compact ? 48 : 60))
            .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
          Text("Adventure")
            .font(Type.italic(compact ? 38 : 48))
            .foregroundStyle(
              LinearGradient(
                colors: [Color(red: 0.99, green: 0.86, blue: 0.58), honey], startPoint: .top,
                endPoint: .bottom)
            )
            .padding(.leading, 2)
        }
        Text("Small boots. Great big wonder.")
          .font(Type.italic(17)).foregroundStyle(cream.opacity(0.78))
          .padding(.bottom, compact ? 1 : 6)
        HStack(spacing: 12) {
          primary(
            model.records.isEmpty ? "Begin adventure" : "Continue journey", icon: "arrow.right"
          ) {
            model.start(model.unlocked)
          }.accessibilityIdentifier("begin")
          Button {
            model.screen = .chapters
          } label: {
            Image(systemName: "map").font(.system(size: 20, weight: .medium))
              .frame(width: 51, height: 51)
          }.buttonStyle(GhostButtonStyle()).accessibilityLabel("Choose chapter")
        }
        HStack(spacing: 18) {
          Button {
            model.showHelp()
          } label: {
            Label("How to wander", systemImage: "questionmark.circle")
              .font(Type.label(12)).frame(height: 38)
          }
          HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
              Circle().fill(index <= model.unlocked ? honey : cream.opacity(0.25))
                .frame(width: 5, height: 5)
            }
            Text("3 handcrafted chapters").font(Type.body(11)).foregroundStyle(cream.opacity(0.55))
          }
        }
      }
      .padding(.leading, 28)
      VStack {
        HStack {
          Spacer()
          soundButton
        }
        Spacer()
        HStack {
          Spacer()
          if let best = model.records.values.map(\.score).max() {
            HStack(spacing: 8) {
              ButtonIcon(size: 12)
              Text("BEST \(best.formatted())").tracking(2)
            }
            .font(Type.label(9))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .plaque(radius: 12, fill: 0.7)
          } else {
            Text("MADE FOR A LITTLE ESCAPE").tracking(2.5)
              .font(Type.label(9)).foregroundStyle(cream.opacity(0.65))
          }
        }
      }.padding(.vertical, 20).padding(.trailing, 22)
    }
  }

  // MARK: Gameplay

  private var gameplay: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: 10) {
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 2) {
            Text("CHAPTER 0\(model.snapshot.levelIndex + 1)")
              .tracking(2.2).font(Type.label(8)).foregroundStyle(honey)
            Text(model.snapshot.level.name).font(Type.display(14))
          }
          Rectangle().fill(Palette.brass.opacity(0.35)).frame(width: 1, height: 24)
          HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
              HeartShape()
                .fill(index < model.snapshot.lives ? Palette.coral : cream.opacity(0.18))
                .overlay(
                  HeartShape().stroke(
                    index < model.snapshot.lives ? cream.opacity(0.5) : cream.opacity(0.3),
                    lineWidth: 0.8)
                )
                .frame(width: 14, height: 13)
                .scaleEffect(index < model.snapshot.lives ? 1 : 0.85)
            }
          }
          .animation(.spring(duration: 0.4), value: model.snapshot.lives)
          .accessibilityLabel("\(model.snapshot.lives) lives")
        }
        .padding(.horizontal, 15).frame(height: 50)
        .plaque(radius: 16, rivets: true)
        Spacer(minLength: 4)
        HStack(spacing: 12) {
          HStack(spacing: 6) {
            ButtonIcon(size: 14)
            Text("\(model.snapshot.coinCount)").font(Type.label(14)).foregroundStyle(honey)
          }
          Rectangle().fill(Palette.brass.opacity(0.35)).frame(width: 1, height: 24)
          VStack(alignment: .trailing, spacing: 1) {
            Text("SCORE").tracking(2).font(Type.label(7)).foregroundStyle(honey.opacity(0.8))
            Text(model.snapshot.score.formatted())
              .font(Type.label(14))
              .contentTransition(.numericText())
              .animation(.snappy, value: model.snapshot.score)
          }
          Rectangle().fill(Palette.brass.opacity(0.35)).frame(width: 1, height: 24)
          VStack(alignment: .trailing, spacing: 1) {
            Text("TIME").tracking(2).font(Type.label(7)).foregroundStyle(honey.opacity(0.8))
            Text(time(model.snapshot.time)).font(Type.label(14)).foregroundStyle(cream.opacity(0.7))
          }
        }
        .monospacedDigit()
        .padding(.horizontal, 16).frame(height: 50)
        .plaque(radius: 16, rivets: true)
        Button {
          model.pause()
        } label: {
          Image(systemName: "pause.fill").font(.system(size: 15, weight: .semibold))
            .frame(width: 50, height: 50)
            .plaque(radius: 16)
        }.accessibilityLabel("Pause").accessibilityIdentifier("pause")
      }
      .padding(.top, 10)
      .accessibilityElement(children: .contain)
      if !model.toast.isEmpty {
        HStack(spacing: 9) {
          Flourish(width: 34)
          Text(model.toast).font(Type.body(12))
          Flourish(width: 34)
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
        .plaque(radius: 20, fill: 0.86)
        .padding(.top, 10)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
      Spacer()
      HStack(alignment: .bottom) {
        HStack(spacing: 12) {
          HoldControl(symbol: "chevron.left", label: "Run left", tint: cream) {
            model.move($0 ? -1 : 0)
          }
          HoldControl(symbol: "chevron.right", label: "Run right", tint: cream) {
            model.move($0 ? 1 : 0)
          }
        }
        Spacer()
        VStack(spacing: 3) {
          if model.snapshot.shield {
            Label("ACORN GUARD", systemImage: "shield.fill")
              .font(Type.label(9)).foregroundStyle(honey).tracking(1)
          }
          Text("HOLD JUMP FOR HEIGHT").tracking(1.4)
            .font(Type.label(10)).foregroundStyle(cream.opacity(0.9))
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .plaque(radius: 20, fill: 0.8)
        .padding(.bottom, 16)
        Spacer()
        HoldControl(symbol: "chevron.up", label: "Jump", tint: honey, size: 78) {
          model.jump($0)
        }.accessibilityIdentifier("jump")
      }
      .padding(.bottom, 12)
    }
    .padding(.horizontal, 20)
  }

  // MARK: Chapters

  private var chapterSelect: some View {
    ZStack {
      ink.opacity(0.92).ignoresSafeArea()
      VStack(spacing: 15) {
        HStack {
          VStack(alignment: .leading, spacing: 3) {
            eyebrow("THE WOODLAND ATLAS")
            Text("Pick a path").font(Type.display(30))
          }
          Spacer()
          Button {
            model.home()
          } label: {
            Image(systemName: "xmark").frame(width: 44, height: 44)
          }.buttonStyle(GhostButtonStyle()).accessibilityLabel("Close atlas")
        }
        HStack(spacing: 14) {
          ForEach(0..<3, id: \.self) { index in
            chapterCard(index)
          }
        }
        HStack(spacing: 10) {
          Flourish(width: 60)
          Text("A star for coming home · a star for half the buttons · a star for all three hearts")
            .font(Type.italic(12)).foregroundStyle(cream.opacity(0.65))
          Flourish(width: 60)
        }
      }.padding(.horizontal, 32)
    }
  }

  private func chapterCard(_ index: Int) -> some View {
    let level = Level.all[index]
    let record = model.records[String(index)]
    let unlocked = index <= model.unlocked
    let tints: [Color] = [
      Palette.moss, Color(red: 0.36, green: 0.58, blue: 0.60),
      Color(red: 0.32, green: 0.42, blue: 0.62),
    ]
    return Button {
      model.start(index)
    } label: {
      VStack(alignment: .leading, spacing: 9) {
        HStack(alignment: .top) {
          Text("0\(index + 1)").font(Type.display(36))
            .foregroundStyle(
              LinearGradient(colors: [cream, honey], startPoint: .top, endPoint: .bottom))
          Spacer()
          ZStack {
            Circle().fill(tints[index].opacity(unlocked ? 0.35 : 0.12)).frame(width: 40, height: 40)
            Image(
              systemName: unlocked
                ? ["leaf.fill", "gearshape.2.fill", "moon.stars.fill"][index] : "lock.fill"
            )
            .font(.system(size: 17)).foregroundStyle(unlocked ? cream : cream.opacity(0.4))
          }
        }
        Text(level.name).font(Type.display(18))
        Text(level.subtitle).font(Type.italic(13)).foregroundStyle(cream.opacity(0.68))
          .frame(height: 30, alignment: .topLeading)
        Rectangle().fill(Palette.brass.opacity(0.3)).frame(height: 1)
        HStack(spacing: 2) {
          ForEach(0..<3, id: \.self) { star in
            StarBadge(earned: star < (record?.stars ?? 0), size: 13)
          }
          Spacer()
          Text(record == nil ? (unlocked ? "EXPLORE →" : "LOCKED") : "\(record?.score ?? 0) BEST")
            .font(Type.label(9)).tracking(1).foregroundStyle(unlocked ? honey : cream.opacity(0.4))
        }
      }
      .padding(18).frame(maxWidth: .infinity)
      .plaque(radius: 22, rivets: true, fill: unlocked ? 0.9 : 0.55)
      .opacity(unlocked ? 1 : 0.7)
    }
    .buttonStyle(.plain)
    .disabled(!unlocked)
    .accessibilityLabel("\(level.name), \(unlocked ? "play chapter" : "locked")")
  }

  // MARK: Overlays

  @ViewBuilder private var overlay: some View {
    switch model.screen {
    case .paused:
      card {
        eyebrow("TAKE A BREATHER")
        Text("The forest can wait.").font(Type.display(32))
        Flourish()
        Text("Your adventure is right where you left it.")
          .foregroundStyle(cream.opacity(0.68)).font(Type.italic(15))
        primary("Keep wandering", icon: "play.fill") { model.resume() }.padding(.top, 4)
        HStack(spacing: 22) {
          Button("How to play") { model.showHelp() }.frame(height: 44)
          soundButton
          Button("Back to title") { model.home() }.frame(height: 44)
        }.font(Type.label(12))
      }
    case .help:
      card(spacing: 14) {
        eyebrow("FIELD NOTES")
        Text("A little know-how.").font(Type.display(30))
        Flourish()
        HStack(alignment: .top, spacing: 22) {
          instruction(
            "arrow.left.and.right", title: "Find your feet",
            text: "Hold the arrows to run.\nTap jump for a hop; hold for height.")
          instruction(
            "ladybug.fill", title: "Brave the beetles",
            text: "Land on a beetle to bounce.\nAcorns protect you from one hit.")
          instruction(
            "lamp.floor.fill", title: "Follow the light",
            text: "Light a lantern to save your place.\nReach the brass door to finish.")
        }.padding(.vertical, 2)
        Text("Keyboard: ← → to run · Space to jump · Esc to pause")
          .font(Type.body(10)).foregroundStyle(cream.opacity(0.5))
        primary("Got it", icon: "checkmark") { model.dismissHelp() }
      }
    case .hurt, .lost:
      card {
        eyebrow(model.screen == .hurt ? "A LITTLE TUMBLE" : "EVERY EXPLORER STARTS AGAIN")
        Text(model.screen == .hurt ? "Dust off your boots." : "A new trail awaits.")
          .font(Type.display(32))
        Flourish()
        if model.screen == .hurt {
          HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
              HeartShape()
                .fill(index < model.snapshot.lives ? Palette.coral : cream.opacity(0.15))
                .frame(width: 18, height: 17)
            }
          }
        }
        Text(
          model.screen == .hurt
            ? "\(model.snapshot.lives) \(model.snapshot.lives == 1 ? "heart" : "hearts") left · \(model.snapshot.checkpointActive ? "Your lantern is waiting." : "Try the trail again.")"
            : "You gathered \(model.snapshot.coinCount) buttons. Let’s go a little further."
        )
        .font(Type.italic(15)).foregroundStyle(cream.opacity(0.72))
        primary(model.screen == .hurt ? "Try again" : "Replay chapter", icon: "arrow.clockwise") {
          if model.screen == .hurt {
            model.retryCheckpoint()
          } else {
            model.start(model.snapshot.levelIndex)
          }
        }.padding(.top, 6)
        Button("Back to title") { model.home() }.font(Type.label(12)).frame(height: 44)
      }
    case .won:
      result
    default: EmptyView()
    }
  }

  private var result: some View {
    card(spacing: 9) {
      eyebrow(model.lastWasBest ? "A NEW PERSONAL BEST" : "CHAPTER COMPLETE")
      Text(model.snapshot.levelIndex == 2 ? "You brought the light home." : "Wonder, well earned.")
        .font(Type.display(28))
      Text(
        "CHAPTER 0\(model.snapshot.levelIndex + 1)  ·  \(model.snapshot.level.name.uppercased())"
      )
      .tracking(1.8).font(Type.label(9)).foregroundStyle(cream.opacity(0.7))
      HStack(spacing: 0) {
        ForEach(0..<3, id: \.self) { star in
          VStack(spacing: 0) {
            StarBadge(earned: model.snapshot.starGoals[star], size: 26)
            Text(["Trail complete", "Half the buttons", "All three hearts"][star])
              .font(Type.body(10))
              .foregroundStyle(cream.opacity(model.snapshot.starGoals[star] ? 0.95 : 0.5))
          }.frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
              "\(["Trail complete", "Half the buttons", "All three hearts"][star]): \(model.snapshot.starGoals[star] ? "earned" : "not earned")"
            )
        }
      }.frame(width: 440)
      HStack(spacing: 0) {
        metric("SCORE", value: model.snapshot.score.formatted())
        Rectangle().fill(Palette.brass.opacity(0.3)).frame(width: 1, height: 34)
        metric("BUTTONS", value: "\(model.snapshot.coinCount)/\(model.snapshot.level.coins.count)")
        Rectangle().fill(Palette.brass.opacity(0.3)).frame(width: 1, height: 34)
        metric("TRAIL TIME", value: time(model.snapshot.time))
      }
      .padding(.vertical, 10).frame(width: 440)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cream.opacity(0.06))
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(
              Palette.brass.opacity(0.3))))
      HStack(spacing: 12) {
        Button("Replay") { model.start(model.snapshot.levelIndex) }
          .font(Type.label(13)).frame(width: 78, height: 48).buttonStyle(GhostButtonStyle())
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
        }.buttonStyle(GhostButtonStyle()).accessibilityLabel("Share your result")
        Button {
          model.home()
        } label: {
          Image(systemName: "house").frame(width: 48, height: 48)
        }.buttonStyle(GhostButtonStyle()).accessibilityLabel("Back to title")
      }.padding(.top, 2)
    }
  }

  // MARK: Pieces

  private func card<Content: View>(
    spacing: CGFloat = 12, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(spacing: spacing, content: content)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 30).padding(.vertical, 20)
      .plaque(radius: 28, rivets: true)
  }

  private func metric(_ title: String, value: String) -> some View {
    VStack(spacing: 3) {
      Text(title).tracking(1.6).font(Type.label(8)).foregroundStyle(honey)
      Text(value).font(Type.display(23)).monospacedDigit()
    }.frame(maxWidth: .infinity)
  }

  private func instruction(_ icon: String, title: String, text: String) -> some View {
    VStack(spacing: 8) {
      ZStack {
        Circle().fill(honey.opacity(0.14)).frame(width: 44, height: 44)
        Circle().stroke(Palette.brass.opacity(0.5), lineWidth: 1).frame(width: 44, height: 44)
        Image(systemName: icon).font(.system(size: 19, weight: .medium)).foregroundStyle(honey)
      }
      Text(title).font(Type.display(15)).frame(height: 22)
      Text(text).font(Type.body(11)).multilineTextAlignment(.center)
        .foregroundStyle(cream.opacity(0.7)).lineSpacing(4)
    }.frame(maxWidth: 220)
  }

  private var soundButton: some View {
    Button {
      model.toggleSound()
    } label: {
      Image(systemName: model.sound ? "speaker.wave.2" : "speaker.slash")
        .font(.system(size: 16))
        .frame(width: 44, height: 44)
        .background(ink.opacity(0.55), in: Circle())
        .overlay(Circle().stroke(Palette.brass.opacity(0.45), lineWidth: 1))
    }.accessibilityLabel(model.sound ? "Mute sound" : "Enable sound")
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).tracking(3).font(Type.label(10)).foregroundStyle(honey)
  }

  private func primary(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 18) {
        Text(text).font(Type.label(14))
        Image(systemName: icon).font(.system(size: 12, weight: .bold))
      }
      .padding(.horizontal, 22).frame(height: 51)
    }.buttonStyle(BrassButtonStyle())
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
    ZStack {
      Circle().fill(
        RadialGradient(
          colors: [Palette.pine.opacity(held ? 0.95 : 0.8), ink.opacity(0.9)],
          center: .init(x: 0.4, y: 0.3),
          startRadius: 2, endRadius: size * 0.7))
      Circle().stroke(
        LinearGradient(
          colors: [Palette.honey.opacity(0.9), Palette.brass.opacity(0.45)], startPoint: .top,
          endPoint: .bottom), lineWidth: held ? 3 : 2)
      Circle().stroke(tint.opacity(0.14), lineWidth: 1).padding(6)
      if held {
        Circle().fill(tint.opacity(0.22)).padding(6)
      }
      Image(systemName: symbol)
        .font(.system(size: size * 0.36, weight: .bold))
        .foregroundStyle(tint)
        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
    }
    .frame(width: size, height: size)
    .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
    .scaleEffect(held ? 0.94 : 1)
    .animation(.spring(duration: 0.18), value: held)
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
