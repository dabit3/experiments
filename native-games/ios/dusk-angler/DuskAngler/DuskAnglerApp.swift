import SwiftUI

@main
struct DuskAnglerApp: App {
  var body: some Scene {
    WindowGroup { AnglerView() }
  }
}

struct AnglerView: View {
  @StateObject private var store = GameStore()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var panel: Panel?
  @State private var showTutorial = false
  private let clock = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

  enum Panel: String, Identifiable {
    case journal, waters, settings
    var id: String { rawValue }
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        LakeBackdrop(violet: store.lake == .violet)
        if store.phase == .home {
          home
        } else if store.phase == .caught, let record = store.latest {
          CatchView(record: record, total: store.progress.total, again: store.begin) {
            store.phase = .home
          }
        } else if store.phase == .failed {
          failure
        } else if store.phase == .landing {
          landing
        } else {
          gameplay(height: geometry.size.height)
        }
        if store.paused { pauseOverlay }
        if showTutorial { tutorial }
      }
      .foregroundStyle(Ink.cream)
      .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: store.phase)
    }
    .preferredColorScheme(.dark)
    .sheet(item: $panel) { item in
      FieldPanel(store: store, panel: item) {
        panel = nil
        showTutorial = true
      }
    }
    .onReceive(clock) { _ in store.tick(0.05) }
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { store.pause() }
    }
  }

  private var home: some View {
    VStack(spacing: 0) {
      HStack {
        Image(systemName: "sun.horizon").font(.system(size: 25, weight: .ultraLight))
        Spacer()
        Button {
          panel = .settings
        } label: {
          Image(systemName: "slider.horizontal.3").frame(width: 48, height: 48)
        }
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settings")
      }
      .padding(.bottom, 18)
      VStack(alignment: .leading, spacing: 12) {
        Eyebrow(text: "A quiet pursuit")
        Text("Dusk\nAngler")
          .font(.system(size: 72, weight: .regular, design: .serif))
          .tracking(-3)
          .lineSpacing(-9)
          .shadow(color: Ink.night.opacity(0.18), radius: 12, y: 3)
        Text("One more cast before the stars.")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Ink.cream.opacity(0.9))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      Spacer(minLength: 35)
      HStack(spacing: 12) {
        Rectangle().fill(Ink.cream.opacity(0.3)).frame(height: 1)
        Image(systemName: "sparkle").font(.system(size: 13))
        Rectangle().fill(Ink.cream.opacity(0.3)).frame(height: 1)
      }
      .padding(.bottom, 22)
      Eyebrow(text: store.lake.subtitle)
        .padding(.bottom, 12)
      CapsuleAction(title: "Cast at \(store.lake.name)") {
        if store.progress.tutorialSeen { store.begin() } else { showTutorial = true }
      }
      HStack {
        navButton("Field journal", symbol: "book.closed", panel: .journal)
        Spacer()
        navButton("Other waters", symbol: "map", panel: .waters)
      }
      .padding(.top, 18)
      HStack {
        Text("\(store.progress.total) CATCHES")
        Spacer()
        Text(store.progress.best == 0 ? "THE LAKE IS WAITING" : "BEST  \(store.progress.best)")
      }
      .font(.system(size: 9, weight: .medium, design: .monospaced))
      .tracking(2)
      .foregroundStyle(Ink.cream.opacity(0.6))
      .padding(.top, 24)
      .padding(.bottom, 16)
    }
    .padding(.horizontal, 30)
  }

  private func navButton(_ title: String, symbol: String, panel item: Panel) -> some View {
    Button {
      panel = item
    } label: {
      Label(title, systemImage: symbol)
        .font(.system(size: 13))
        .frame(minHeight: 44)
    }
    .accessibilityIdentifier(title)
  }

  private func gameplay(height: CGFloat) -> some View {
    ZStack(alignment: .top) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Eyebrow(text: store.lake.name)
          Text(store.phase == .duel ? store.duel.species.name : "Follow the ripples")
            .font(.system(size: 23, design: .serif))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Ink.night.opacity(0.72), in: RoundedRectangle(cornerRadius: 6))
        Spacer()
        Button {
          store.pause()
        } label: {
          Image(systemName: "pause").frame(width: 48, height: 48)
            .background(Ink.night.opacity(0.3), in: Circle())
        }
        .accessibilityLabel("Pause fishing")
        .accessibilityIdentifier("pause")
      }
      .padding(.horizontal, 24)
      .padding(.top, 8)
      .padding(.bottom, 24)
      .background(
        LinearGradient(
          colors: [Ink.night.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top))
      if store.phase == .duel {
        duelStage.frame(height: height * 0.26).offset(y: height * 0.36)
      } else {
        castingStage.frame(height: height * 0.28).offset(y: height * 0.39)
      }
      VStack {
        Spacer()
        controlDeck
          .padding(.horizontal, 24)
          .padding(.bottom, 16)
      }
    }
  }

  private var castingStage: some View {
    GeometryReader { geometry in
      ZStack {
        WaterSparkles(time: reduceMotion ? 0 : store.phaseTime)
        if store.phase == .aiming {
          Color.clear.contentShape(Rectangle())
            .onTapGesture { location in
              store.aim = CGPoint(
                x: location.x / geometry.size.width, y: location.y / geometry.size.height)
              if let index = Casting.target(x: store.aim.x, y: store.aim.y) {
                store.selected = index
              }
            }
          ForEach(0..<3, id: \.self) { index in
            Button {
              store.target(index)
            } label: {
              ZStack {
                Ellipse().stroke(Ink.cream.opacity(0.4), lineWidth: 1)
                  .frame(width: 86, height: 26).offset(y: 16)
                FishArt(species: store.lake.species[index], silhouette: true)
                  .frame(width: 83, height: 45)
                  .shadow(color: Ink.gold.opacity(0.7), radius: 10)
                if store.lake.species[index].rare {
                  Image(systemName: "sparkle").font(.system(size: 14)).offset(x: 35, y: -18)
                }
              }
              .frame(width: 100, height: 66)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .position(
              x: geometry.size.width * Casting.positions[index].0,
              y: geometry.size.height * Casting.positions[index].1
            )
            .accessibilityLabel("Aim at \(store.lake.species[index].name)")
            .accessibilityIdentifier("fish-\(index)")
          }
          Circle().stroke(Ink.gold, style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
            .frame(width: 100, height: 100)
            .overlay {
              Image(systemName: "plus").font(.system(size: 13, weight: .light)).foregroundStyle(
                Ink.gold)
            }
            .position(x: geometry.size.width * store.aim.x, y: geometry.size.height * store.aim.y)
            .allowsHitTesting(false)
        } else {
          let point = CGPoint(
            x: geometry.size.width * store.aim.x, y: geometry.size.height * store.aim.y)
          Path { p in
            p.move(to: CGPoint(x: geometry.size.width * 0.85, y: geometry.size.height + 160))
            p.addQuadCurve(
              to: point,
              control: CGPoint(x: geometry.size.width * 0.38, y: geometry.size.height * 0.45))
          }
          .stroke(Ink.cream.opacity(0.6), lineWidth: 1)
          ZStack {
            ForEach(0..<3) { index in
              Ellipse()
                .stroke(Ink.gold.opacity(0.6 - Double(index) * 0.15), lineWidth: 1.5)
                .frame(width: CGFloat(45 + index * 34), height: CGFloat(17 + index * 13))
            }
            Capsule().fill(Ink.coral).frame(width: 8, height: 16).offset(y: -10)
            Capsule().fill(Ink.cream).frame(width: 8, height: 10).offset(y: -19)
            if store.phase == .bite {
              Text("BITE!").font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(10).background(Ink.gold, in: Capsule())
                .foregroundStyle(Ink.night).offset(y: -60)
            }
          }
          .scaleEffect(store.phase == .bite && !reduceMotion ? 1.12 : 1)
          .position(point)
        }
      }
    }
  }

  private var duelStage: some View {
    ZStack {
      WaterSparkles(time: reduceMotion ? 0 : store.duel.elapsed)
      VStack(spacing: 14) {
        ZStack {
          Ellipse().stroke(Ink.cream.opacity(0.24), lineWidth: 1)
            .frame(width: 270, height: 75).offset(y: 48)
          Ellipse().stroke(Ink.cream.opacity(0.14), lineWidth: 1)
            .frame(width: 320, height: 105).offset(y: 48)
          FishArt(species: store.duel.species)
            .frame(width: 235, height: 130)
            .shadow(color: Ink.gold.opacity(0.35), radius: 30)
            .rotationEffect(
              .degrees(
                reduceMotion
                  ? 0
                  : sin(store.duel.elapsed * (store.duel.surging ? 9 : 2))
                    * (store.duel.surging ? 10 : 3))
            )
            .offset(y: reduceMotion ? 0 : sin(store.duel.elapsed * 2) * 6)
        }
        Text(
          store.duel.surging
            ? "Let it run." : store.duel.warning ? "Ease off in a moment." : "Bring it closer."
        )
        .font(.system(size: 22, design: .serif))
        .shadow(color: Ink.night, radius: 8)
      }
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder private var controlDeck: some View {
    if store.phase == .aiming {
      VStack(spacing: 16) {
        Text("01 / CAST").font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(
          3)
        Text(store.activeSpecies.name).font(.system(size: 28, design: .serif))
        Text("Tap a silhouette to aim your cast.")
          .font(.system(size: 13)).foregroundStyle(Ink.cream.opacity(0.75))
        if store.progress.bait >= 2 {
          Toggle(isOn: $store.useBait) {
            Text("Glow bait · 2 of \(store.progress.bait)").font(.system(size: 13))
          }
          .tint(Ink.gold)
          .accessibilityIdentifier("glow-bait")
        }
        CapsuleAction(title: "Cast the line", icon: "arrow.up.right", action: store.cast)
      }
    } else if store.phase == .waiting || store.phase == .bite {
      VStack(spacing: 18) {
        Eyebrow(text: "02 / THE MOMENT")
        Text(store.phase == .bite ? "Now. Set the hook." : "Watch the float…")
          .font(.system(size: 29, design: .serif))
        Text(
          store.phase == .bite
            ? "Tap before the golden ring disappears." : "A bite is only a heartbeat away."
        )
        .font(.system(size: 13)).foregroundStyle(Ink.cream.opacity(0.75))
        CapsuleAction(
          title: store.phase == .bite ? "HOOK" : "Wait for the bite", icon: "arrow.up",
          action: store.hook
        )
        .accessibilityIdentifier("hook")
      }
    } else if store.phase == .duel {
      VStack(spacing: 15) {
        HStack {
          Eyebrow(text: "03 / THE DUEL")
          Spacer()
          Text("\(Int(store.duel.landed * 100))% LANDED")
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
        GeometryReader { g in
          ZStack(alignment: .leading) {
            Capsule().fill(Ink.cream.opacity(0.15))
            Capsule().fill(Ink.cream).frame(width: g.size.width * store.duel.landed)
          }
        }
        .frame(height: 3)
        HStack {
          Image(systemName: store.duel.surging || store.duel.warning ? "wind" : "water.waves")
          Text(
            store.duel.surging
              ? "SURGE · RELEASE" : store.duel.warning ? "SURGE APPROACHING" : "STEADY · REEL IN"
          )
          .font(.system(size: 12, weight: .semibold, design: .monospaced))
          Spacer()
        }
        .foregroundStyle(store.duel.surging || store.duel.warning ? Ink.gold : Ink.mint)
        tensionMeter
        Text(
          store.duel.slack > 1
            ? "Too much slack — reel now"
            : store.holding ? "Reeling · watch your tension" : "Release to soften • hold to reel"
        )
        .font(.system(size: 14)).foregroundStyle(
          store.duel.slack > 1 ? Ink.gold : Ink.cream.opacity(0.8))
        Text(store.holding ? "REELING" : "HOLD TO REEL")
          .font(.system(size: 15, weight: .bold)).tracking(2)
          .frame(maxWidth: .infinity).frame(height: 66)
          .foregroundStyle(Ink.night)
          .background(store.holding ? Ink.gold : Ink.cream, in: Capsule())
          .contentShape(Capsule())
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { _ in store.holding = true }
              .onEnded { _ in store.holding = false }
          )
          .accessibilityLabel("Reel")
          .accessibilityValue(store.holding ? "Reeling" : "Released")
          .accessibilityHint("Double tap to toggle reeling. Release before a surge.")
          .accessibilityAddTraits(.isButton)
          .accessibilityIdentifier("reel")
          .accessibilityAction { store.holding.toggle() }
      }
    }
  }

  private var tensionMeter: some View {
    VStack(spacing: 8) {
      HStack {
        Text("LINE TENSION")
        Spacer()
        Text(store.duel.tension > 0.8 ? "DANGER" : store.duel.tension < 0.1 ? "SLACK" : "BALANCED")
          .foregroundStyle(store.duel.tension > 0.8 ? Ink.coral : Ink.mint)
      }
      .font(.system(size: 11, weight: .semibold, design: .monospaced)).tracking(1.5)
      GeometryReader { g in
        ZStack(alignment: .leading) {
          Capsule().fill(
            LinearGradient(
              stops: [
                .init(color: Ink.cream.opacity(0.25), location: 0),
                .init(color: Ink.mint, location: 0.15),
                .init(color: Ink.mint, location: 0.62),
                .init(color: Ink.gold, location: 0.78),
                .init(color: Ink.coral, location: 1),
              ], startPoint: .leading, endPoint: .trailing))
          Capsule().fill(.white).frame(width: 5, height: 24)
            .offset(x: max(0, (g.size.width - 5) * store.duel.tension))
        }
      }
      .frame(height: 14)
      .accessibilityLabel("Line tension")
      .accessibilityValue("\(Int(store.duel.tension * 100)) percent")
    }
  }

  private var failure: some View {
    VStack(spacing: 24) {
      Spacer()
      Image(systemName: "water.waves").font(.system(size: 50, weight: .ultraLight))
      Eyebrow(text: "The lake keeps its secrets")
      Text(store.failure.components(separatedBy: "|").first ?? "Gone")
        .font(.system(size: 41, design: .serif)).multilineTextAlignment(.center)
      Text(store.failure.components(separatedBy: "|").last ?? "")
        .font(.system(size: 16)).lineSpacing(5).multilineTextAlignment(.center)
        .foregroundStyle(Ink.cream.opacity(0.85))
      Spacer()
      CapsuleAction(title: "Cast again", icon: "arrow.counterclockwise", action: store.begin)
      Button("Back to the shore") { store.phase = .home }
        .frame(minHeight: 44).accessibilityIdentifier("home")
    }
    .padding(30)
    .background(Ink.night.opacity(0.5))
  }

  private var pauseOverlay: some View {
    ZStack {
      Ink.night.ignoresSafeArea()
      VStack(spacing: 24) {
        Eyebrow(text: "A moment of stillness")
        Text("The lake can wait.").font(.system(size: 34, design: .serif))
        CapsuleAction(title: "Resume", icon: "play") { store.paused = false }
        CapsuleAction(
          title: "Start a fresh cast", icon: "arrow.counterclockwise", action: store.begin)
        Button("Back to the shore") {
          store.paused = false
          store.phase = .home
        }
        .frame(minHeight: 44).accessibilityIdentifier("pause-home")
      }
      .padding(30)
    }
  }

  private var tutorial: some View {
    ZStack {
      Ink.night.ignoresSafeArea()
      VStack(alignment: .leading, spacing: 26) {
        Eyebrow(text: "Your first evening")
        Text("A little patience.\nA little instinct.")
          .font(.system(size: 36, design: .serif))
        tutorialRow("01", title: "Find your fish", text: "Tap a silhouette in the lake, then cast.")
        tutorialRow("02", title: "Meet the moment", text: "When the float dips, tap HOOK.")
        tutorialRow(
          "03", title: "Feel the line",
          text: "Hold to reel. Release before a surge. Too tight snaps; too slack loses the fish.")
        CapsuleAction(title: "Let’s fish", icon: "arrow.up.right") {
          store.progress.tutorialSeen = true
          store.save()
          showTutorial = false
          store.begin()
        }
      }
      .padding(30)
    }
  }

  private func tutorialRow(_ number: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 18) {
      Text(number).font(.system(size: 12, design: .monospaced)).foregroundStyle(Ink.gold).padding(
        .top, 4)
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(.system(size: 20, design: .serif))
        Text(text).font(.system(size: 14)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.7))
      }
    }
  }

  private var landing: some View {
    GeometryReader { geometry in
      let leap = reduceMotion ? 0.5 : sin(min(1, store.phaseTime / 1.3) * .pi)
      ZStack {
        WaterSparkles(time: reduceMotion ? 0 : store.phaseTime * 8)
          .frame(height: 260).offset(y: geometry.size.height * 0.2)
        Ellipse().stroke(Ink.gold.opacity(0.8), lineWidth: 2)
          .frame(width: 120 + store.phaseTime * 110, height: 40 + store.phaseTime * 30)
          .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.66)
        FishArt(species: store.duel.species)
          .frame(width: 290, height: 170)
          .rotationEffect(.degrees(-25 * leap))
          .shadow(color: Ink.gold.opacity(0.6), radius: 24)
          .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.64 - leap * 150)
        VStack {
          Spacer()
          Eyebrow(text: store.duel.species.rare ? "A rare moment" : "Yours for a moment")
          Text("Out of the deep.").font(.system(size: 38, design: .serif))
          Spacer().frame(height: 70)
        }
      }
    }
  }
}
