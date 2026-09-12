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
      .font(TypeStyle.body(15))
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
        Eyebrow(text: "Last light club", color: Ink.gold)
        Spacer()
        Button {
          panel = .settings
        } label: {
          Image(systemName: "slider.horizontal.3").frame(width: 48, height: 48)
            .background(Ink.night.opacity(0.4), in: Circle())
            .overlay(Circle().strokeBorder(Ink.cream.opacity(0.18), lineWidth: 0.7))
        }
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settings")
      }
      .padding(.bottom, 12)
      VStack(spacing: 0) {
        AnglerSeal().frame(width: 46, height: 46).foregroundStyle(Ink.gold)
          .padding(.bottom, 12)
        Text("DUSK").font(TypeStyle.display(76)).tracking(9).padding(.leading, 9)
          .padding(.bottom, -12)
        Text("ANGLER").font(TypeStyle.display(35)).tracking(13).padding(.leading, 13)
        Text("STILL WATER. WILD HEART.")
          .font(TypeStyle.label(9)).tracking(2.6).padding(.top, 15)
          .foregroundStyle(Ink.cream.opacity(0.8))
      }
      .shadow(color: Ink.night.opacity(0.45), radius: 12, y: 3)
      .frame(maxWidth: .infinity)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Dusk Angler. Still water, wild heart.")
      Spacer(minLength: 24)
      VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 2) {
            Eyebrow(text: "Your evening begins at", color: Ink.gold)
            Text(store.lake.name).font(TypeStyle.display(31))
          }
          Spacer()
          AnglerSeal().frame(width: 38, height: 38).foregroundStyle(Ink.gold.opacity(0.65))
        }
        PrimaryAction(title: "Begin fishing") {
          if store.progress.tutorialSeen { store.begin() } else { showTutorial = true }
        }
        .accessibilityLabel("Cast at \(store.lake.name)")
        .accessibilityIdentifier("Cast at \(store.lake.name)")
      }
      .modifier(InstrumentSurface())
      HStack(spacing: 16) {
        navButton("Field journal", symbol: "book.closed", panel: .journal)
        Spacer()
        navButton("Other waters", symbol: "map", panel: .waters)
      }
      .padding(.top, 12)
      HStack {
        Text("\(store.progress.total) \(store.progress.total == 1 ? "CATCH" : "CATCHES")")
        Spacer()
        Text(
          store.progress.best == 0
            ? "MAKE YOUR FIRST MEMORY" : "PERSONAL BEST  \(store.progress.best)")
      }
      .font(TypeStyle.label(8)).tracking(1.3)
      .foregroundStyle(Ink.cream.opacity(0.6))
      .padding(.top, 8)
      .padding(.bottom, 14)
    }
    .padding(.horizontal, 26)
  }

  private func navButton(_ title: String, symbol: String, panel item: Panel) -> some View {
    Button {
      panel = item
    } label: {
      Label(title, systemImage: symbol)
        .font(TypeStyle.body(13))
        .frame(minHeight: 44)
    }
    .accessibilityIdentifier(title)
  }

  private func gameplay(height: CGFloat) -> some View {
    ZStack(alignment: .top) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Eyebrow(text: store.lake.name)
          Text(store.phase == .duel ? store.duel.species.name : "Find your fish")
            .font(TypeStyle.display(25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Ink.night.opacity(0.82), in: RoundedRectangle(cornerRadius: 12))
        Spacer()
        Button {
          store.pause()
        } label: {
          Image(systemName: "pause").frame(width: 48, height: 48)
            .background(Ink.night.opacity(0.7), in: Circle())
            .overlay(Circle().strokeBorder(Ink.gold.opacity(0.4), lineWidth: 0.7))
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
        duelStage.frame(height: height * 0.22).offset(y: height * 0.30)
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
                  .frame(width: 88, height: 48)
                  .shadow(color: Ink.gold.opacity(0.7), radius: 10)
                if store.lake.species[index].rare {
                  Image(systemName: "sparkle").font(TypeStyle.body(14)).offset(x: 35, y: -18)
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
          Circle().trim(from: 0.04, to: 0.96)
            .stroke(Ink.gold, style: StrokeStyle(lineWidth: 1, dash: [22, 8]))
            .frame(width: 102, height: 76)
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
      VStack(spacing: 8) {
        ZStack {
          Ellipse().stroke(Ink.cream.opacity(0.24), lineWidth: 1)
            .frame(width: 270, height: 75).offset(y: 48)
          Ellipse().stroke(Ink.cream.opacity(0.14), lineWidth: 1)
            .frame(width: 320, height: 105).offset(y: 48)
          FishArt(species: store.duel.species)
            .frame(width: 265, height: 150)
            .shadow(color: Ink.gold.opacity(0.24), radius: 20)
            .rotationEffect(
              .degrees(
                reduceMotion
                  ? 0
                  : sin(store.duel.elapsed * (store.duel.surging ? 9 : 2))
                    * (store.duel.surging ? 10 : 3))
            )
            .offset(y: reduceMotion ? 0 : sin(store.duel.elapsed * 2) * 6)
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder private var controlDeck: some View {
    if store.phase == .aiming {
      VStack(spacing: 12) {
        HStack(spacing: 12) {
          FishArt(species: store.activeSpecies).frame(width: 76, height: 45)
          VStack(alignment: .leading, spacing: 2) {
            Eyebrow(
              text: store.activeSpecies.rare ? "Rare sighting" : "In your sights", color: Ink.gold)
            Text(store.activeSpecies.name).font(TypeStyle.display(24))
              .lineLimit(1).minimumScaleFactor(0.8)
          }
          Spacer(minLength: 0)
        }
        Text("Tap a silhouette to choose your cast.")
          .font(TypeStyle.body(12)).foregroundStyle(Ink.cream.opacity(0.7))
          .frame(maxWidth: .infinity, alignment: .leading)
        if store.progress.bait >= 2 {
          Toggle(isOn: $store.useBait) {
            Text("Glow bait  ·  2 of \(store.progress.bait)").font(TypeStyle.body(12))
          }
          .tint(Ink.gold)
          .accessibilityIdentifier("glow-bait")
        }
        PrimaryAction(title: "Cast the line", icon: "arrow.up.right", action: store.cast)
      }
      .modifier(InstrumentSurface())
    } else if store.phase == .waiting || store.phase == .bite {
      VStack(alignment: .leading, spacing: 10) {
        Eyebrow(
          text: store.phase == .bite ? "Take your moment" : "Line in the water", color: Ink.gold)
        Text(store.phase == .bite ? "Set the hook." : "Watch the float…")
          .font(TypeStyle.display(32))
        Text(
          store.phase == .bite
            ? "Tap now, while the fish is biting." : "A bite is a heartbeat away."
        )
        .font(TypeStyle.body(12)).foregroundStyle(Ink.cream.opacity(0.7))
        PrimaryAction(
          title: store.phase == .bite ? "HOOK" : "Wait for the bite", icon: "arrow.up",
          action: store.hook
        )
        .accessibilityIdentifier("hook")
      }
      .modifier(InstrumentSurface())
    } else if store.phase == .duel {
      VStack(spacing: 7) {
        HStack {
          Eyebrow(text: "Bring it home", color: Ink.gold)
          Spacer()
          Text("\(Int(store.duel.landed * 100))%").font(TypeStyle.label(13)).monospacedDigit()
        }
        GeometryReader { g in
          ZStack(alignment: .leading) {
            Capsule().fill(Ink.cream.opacity(0.15))
            Capsule().fill(Ink.gold).frame(width: g.size.width * store.duel.landed)
          }
        }
        .frame(height: 3)
        HStack(spacing: 6) {
          ReelControl(
            holding: $store.holding, tension: store.duel.tension,
            elapsed: store.duel.elapsed)
          VStack(alignment: .leading, spacing: 6) {
            Text(store.duel.surging ? "RELEASE" : store.duel.warning ? "EASE OFF" : "REEL IN")
              .font(TypeStyle.display(23))
              .foregroundStyle(store.duel.surging || store.duel.warning ? Ink.gold : Ink.mint)
            Text(
              store.duel.surging
                ? "Fish surging" : store.duel.warning ? "Surge ahead" : "Steady water"
            )
            .font(TypeStyle.body(11)).foregroundStyle(Ink.cream.opacity(0.7))
            Rectangle().fill(Ink.gold.opacity(0.25)).frame(height: 1).padding(.vertical, 4)
            Text("\(Int(store.duel.tension * 100))%").font(TypeStyle.display(30)).monospacedDigit()
              .foregroundStyle(store.duel.tension > 0.8 ? Ink.coral : Ink.cream)
            Text("TENSION").font(TypeStyle.label(8)).tracking(1.5)
            Text(
              store.duel.tension > 0.8 ? "Danger" : store.duel.tension < 0.1 ? "Slack" : "Balanced"
            )
            .font(TypeStyle.body(11))
            .foregroundStyle(store.duel.tension > 0.8 ? Ink.coral : Ink.mint)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        Text(
          store.duel.slack > 1
            ? "Too much slack. Reel now." : "Hold the reel. Release before a surge."
        )
        .font(TypeStyle.body(11)).foregroundStyle(
          store.duel.slack > 1 ? Ink.gold : Ink.cream.opacity(0.8))
      }
      .modifier(InstrumentSurface())
    }
  }

  private var failure: some View {
    VStack(spacing: 24) {
      Spacer()
      AnglerSeal().frame(width: 72, height: 72).foregroundStyle(Ink.gold)
      Eyebrow(text: "The lake keeps its secrets")
      Text(store.failure.components(separatedBy: "|").first ?? "Gone")
        .font(TypeStyle.display(41)).multilineTextAlignment(.center)
      Text(store.failure.components(separatedBy: "|").last ?? "")
        .font(TypeStyle.body(16)).lineSpacing(5).multilineTextAlignment(.center)
        .foregroundStyle(Ink.cream.opacity(0.85))
      Spacer()
      PrimaryAction(title: "Cast again", icon: "arrow.counterclockwise", action: store.begin)
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
        AnglerSeal().frame(width: 60, height: 60).foregroundStyle(Ink.gold)
        Eyebrow(text: "A moment of stillness")
        Text("The lake can wait.").font(TypeStyle.display(34))
        PrimaryAction(title: "Resume", icon: "play") { store.paused = false }
        PrimaryAction(
          title: "Start a fresh cast", icon: "arrow.counterclockwise", dark: true,
          action: store.begin)
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
      VStack(alignment: .leading, spacing: 22) {
        HStack {
          Eyebrow(text: "The angler’s field guide", color: Ink.gold)
          Spacer()
          AnglerSeal().frame(width: 44, height: 44).foregroundStyle(Ink.gold)
        }
        Text("INSTINCT.\nTHEN PATIENCE.")
          .font(TypeStyle.display(39)).lineSpacing(-4)
        tutorialRow("01", title: "Find your fish", text: "Tap a silhouette in the lake, then cast.")
        tutorialRow("02", title: "Meet the moment", text: "When the float dips, tap HOOK.")
        tutorialRow(
          "03", title: "Feel the line",
          text: "Hold to reel. Release before a surge. Too tight snaps; too slack loses the fish.")
        PrimaryAction(title: "Let’s fish", icon: "arrow.up.right") {
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
      Text(number).font(TypeStyle.display(24)).foregroundStyle(Ink.gold)
        .frame(width: 38, height: 38)
        .overlay(Circle().strokeBorder(Ink.gold.opacity(0.4), lineWidth: 0.7))
      VStack(alignment: .leading, spacing: 6) {
        Text(title).font(TypeStyle.display(20))
        Text(text).font(TypeStyle.body(14)).lineSpacing(4).foregroundStyle(Ink.cream.opacity(0.7))
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
          Text("Out of the deep.").font(TypeStyle.display(38))
          Spacer().frame(height: 70)
        }
      }
    }
  }
}
