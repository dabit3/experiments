import SwiftUI
import UIKit

@main
struct RooftopRaccoonApp: App {
  @State private var store = GameStore()
  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      RootView(store: store)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
          if phase != .active {
            if store.mission?.phase == .playing { store.paused = true }
            store.save()
          }
        }
    }
  }
}

struct RootView: View {
  @Bindable var store: GameStore

  var body: some View {
    ZStack {
      CityBackdrop()
      if let mission = store.mission {
        if mission.phase == .playing {
          PlayView(store: store, mission: mission)
        } else {
          ResultView(store: store, mission: mission)
        }
      } else {
        HomeView(store: store)
      }
      if store.showTutorial { TutorialView(store: store) }
      if store.paused && !store.showTutorial { PauseView(store: store) }
    }
    .tint(Palette.mint)
    .sheet(isPresented: $store.showSettings) {
      SettingsView(store: store)
        .presentationDetents([.medium])
    }
  }
}

struct Eyebrow: View {
  let text: String
  var color = Palette.mint
  var body: some View {
    Text(text)
      .font(.system(size: 10, weight: .heavy, design: .monospaced))
      .tracking(2.5)
      .foregroundStyle(color)
      .lineLimit(1)
      .minimumScaleFactor(0.75)
  }
}

struct PrimaryButton: View {
  let title: String
  var symbol = "arrow.right"
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .font(.system(size: 15, weight: .heavy, design: .rounded))
          .tracking(1)
        Spacer()
        Image(systemName: symbol).font(.system(size: 17, weight: .bold))
      }
      .foregroundStyle(Palette.ink)
      .padding(.horizontal, 23)
      .frame(height: 57)
      .background(Palette.mint, in: RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.22), lineWidth: 1))
    }
    .buttonStyle(.plain)
  }
}

struct RoundButton: View {
  let symbol: String
  let label: String
  let id: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 17, weight: .semibold))
        .frame(width: 46, height: 46)
        .foregroundStyle(Palette.cream)
        .background(.white.opacity(0.07), in: Circle())
        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityIdentifier(id)
  }
}

struct HomeView: View {
  @Bindable var store: GameStore
  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        HStack {
          HStack(spacing: 7) {
            Circle().fill(Palette.mint).frame(width: 5, height: 5)
            Eyebrow(text: "THE CITY IS ASLEEP")
          }
          Spacer()
          RoundButton(symbol: "slider.horizontal.3", label: "Settings", id: "settings") {
            store.showSettings = true
          }
        }
        .padding(.top, 8)
        VStack(spacing: 6) {
          Text("Rooftop\nRaccoon")
            .font(
              .system(size: min(geometry.size.width * 0.15, 63), weight: .black, design: .serif)
            )
            .tracking(-2.2)
            .lineSpacing(-7)
            .multilineTextAlignment(.center)
            .foregroundStyle(Palette.cream)
            .accessibilityAddTraits(.isHeader)
          Text("Small paws. Grand larceny.")
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Palette.muted)
        }
        .padding(.top, 7)
        HeroScene()
          .frame(maxHeight: .infinity)
          .layoutPriority(-1)
        VStack(spacing: 15) {
          HStack {
            Eyebrow(text: "CHOOSE YOUR NEIGHBORHOOD")
            Spacer()
            Text("\(store.progress.unlocked + 1) / 3")
              .font(.system(size: 11, weight: .medium, design: .monospaced))
              .foregroundStyle(Palette.muted)
          }
          HStack(spacing: 8) {
            ForEach(District.all) { district in
              let unlocked = district.id <= store.progress.unlocked
              Button {
                store.selected = district.id
              } label: {
                VStack(alignment: .leading, spacing: 8) {
                  HStack {
                    Text(String(format: "%02d", district.id + 1))
                      .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Spacer()
                    Image(
                      systemName: !unlocked
                        ? "lock.fill"
                        : store.progress.best[String(district.id)] != nil
                          ? "checkmark.seal.fill" : "moon.stars.fill"
                    )
                    .font(.system(size: 11))
                  }
                  Text(district.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 33, alignment: .topLeading)
                }
                .foregroundStyle(
                  !unlocked
                    ? Palette.muted.opacity(0.5)
                    : store.selected == district.id ? Palette.ink : Palette.cream
                )
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                  store.selected == district.id ? Palette.cream : .white.opacity(0.04),
                  in: RoundedRectangle(cornerRadius: 13)
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 13)
                    .stroke(.white.opacity(0.13), lineWidth: 1))
              }
              .disabled(!unlocked)
              .buttonStyle(.plain)
              .accessibilityLabel(
                "\(district.name), \(unlocked ? "district \(district.id + 1)" : "locked, escape previous district to unlock")"
              )
              .accessibilityIdentifier("district-\(district.id)")
              .accessibilityAddTraits(store.selected == district.id ? .isSelected : [])
            }
          }
          PrimaryButton(title: "LET'S GET SNACKS") { store.start() }
            .accessibilityIdentifier("start-heist")
          HStack(spacing: 5) {
            Image(systemName: "sparkle")
            Text(
              store.progress.best[String(store.selected)].map { "PERSONAL BEST  \($0) PTS" }
                ?? "COLLECT. OUTSMART. DISAPPEAR.")
          }
          .font(.system(size: 9, weight: .semibold, design: .monospaced))
          .tracking(1.4)
          .foregroundStyle(Palette.muted)
        }
        .padding(.bottom, 16)
      }
      .padding(.horizontal, 25)
    }
  }
}

struct BoardGeometry {
  let size: CGSize
  var roofWidth: CGFloat { size.width / 3 - 19 }
  func center(_ id: Int) -> CGPoint {
    CGPoint(
      x: (CGFloat(id % 3) + 0.5) * size.width / 3 - 3,
      y: 58 + CGFloat(id / 3) * (size.height - 116) / 3)
  }
}

struct BoardView: View {
  @Bindable var store: GameStore
  let mission: Mission
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      let board = BoardGeometry(size: geometry.size)
      ZStack(alignment: .topLeading) {
        Canvas { context, size in
          let pen = Pen(context: context)
          for roof in mission.district.roofs {
            let origin = board.center(roof.id)
            for next in [roof.column < 2 ? roof.id + 1 : -1, roof.row < 3 ? roof.id + 3 : -1]
            where next >= 0 {
              let end = board.center(next)
              pen.line([origin, end], Palette.ink.opacity(0.8), width: 11)
              pen.line([origin, end], Palette.cream.opacity(0.35), width: 5)
              pen.line([origin, end], Palette.ink.opacity(0.6), width: 1)
            }
          }
          for roof in mission.district.roofs {
            let center = board.center(roof.id)
            Illustration.roof(
              context, center: center, width: board.roofWidth, garden: roof.garden, id: roof.id)
            if !roof.garden {
              let danger = roof.danger(on: mission.beat + 1)
              let ring = CGRect(
                x: center.x - board.roofWidth / 2 + 4, y: center.y - 24, width: board.roofWidth - 4,
                height: 22)
              context.stroke(
                Path(roundedRect: ring, cornerRadius: 4),
                with: .color(danger ? Palette.coral : Palette.cream.opacity(0.6)),
                style: StrokeStyle(lineWidth: 2, dash: danger ? [4, 3] : []))
              if danger {
                let cone = Path { path in
                  path.move(to: CGPoint(x: center.x + 25, y: center.y - 38))
                  path.addLine(to: CGPoint(x: center.x - 30, y: center.y - 3))
                  path.addLine(to: CGPoint(x: center.x + 27, y: center.y - 3))
                  path.closeSubpath()
                }
                context.fill(cone, with: .color(Palette.cream.opacity(0.15)))
              }
            }
            if roof.snack && !mission.collected.contains(roof.id) {
              var c = context
              c.translateBy(x: center.x - 12, y: center.y - 20)
              c.scaleBy(x: 0.62, y: 0.62)
              Illustration.snack(c, kind: roof.id)
            }
            if roof.id == 2 {
              Illustration.tower(context, x: center.x - 13, y: center.y - 49, scale: 0.6)
            }
            if case .cat = roof.watcher {
              let p = Pen(context: context)
              let x = center.x + board.roofWidth / 2 - 16
              let y = center.y - 24
              p.oval(CGRect(x: x - 6, y: y - 4, width: 22, height: 11), Palette.cream)
              p.shape(
                [
                  CGPoint(x: x + 4, y: y), CGPoint(x: x + 5, y: y - 11),
                  CGPoint(x: x + 9, y: y - 7), CGPoint(x: x + 14, y: y - 11),
                  CGPoint(x: x + 16, y: y),
                ], Palette.cream)
              p.line(
                [
                  CGPoint(x: x - 8, y: y + 4), CGPoint(x: x - 12, y: y),
                  CGPoint(x: x - 10, y: y - 3),
                ], Palette.cream, width: 3)
            }
          }
        }
        ForEach(mission.district.roofs) { roof in
          let point = board.center(roof.id)
          let danger = roof.danger(on: mission.beat + 1)
          Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.68)) {
              store.act(roof.id)
            }
          } label: {
            Color.clear.contentShape(Rectangle())
          }
          .frame(width: board.roofWidth + 10, height: 73)
          .position(x: point.x, y: point.y)
          .accessibilityLabel(
            "Roof \(roof.id + 1), \(roof.id == 2 ? "escape tower" : roof.watcher.name), \(danger ? "danger next beat" : "safe next beat")\(roof.snack && !mission.collected.contains(roof.id) ? ", snack" : "")\(mission.position == roof.id ? ", current roof" : "")"
          )
          .accessibilityHint(
            mission.isNeighbor(roof.id)
              ? "Move here, uses one beat" : "Move to a connected neighbor first"
          )
          .accessibilityIdentifier("roof-\(roof.id)")
          .overlay(alignment: .bottom) { EmptyView() }
          if roof.id != mission.position {
            Text(roof.id == 2 ? "EXIT" : roof.garden ? "HIDE" : danger ? "WATCHED" : "CLEAR")
              .font(.system(size: 8, weight: .heavy, design: .monospaced))
              .tracking(0.8)
              .foregroundStyle(roof.garden ? Palette.mint : danger ? Palette.coral : Palette.cream)
              .padding(.horizontal, 5)
              .padding(.vertical, 3)
              .background(Palette.ink.opacity(0.88), in: Capsule())
              .position(x: point.x, y: point.y + 43)
              .allowsHitTesting(false)
              .accessibilityHidden(true)
          }
        }
        RaccoonArt(snacks: min(mission.loot, 3))
          .frame(width: 62, height: 62)
          .position(x: board.center(mission.position).x, y: board.center(mission.position).y - 30)
          .shadow(color: Palette.ink.opacity(0.4), radius: 8, y: 5)
          .allowsHitTesting(false)
        Text("YOU")
          .font(.system(size: 8, weight: .heavy, design: .monospaced))
          .tracking(1.2)
          .foregroundStyle(Palette.ink)
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Palette.mint, in: Capsule())
          .position(x: board.center(mission.position).x, y: board.center(mission.position).y + 43)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      .contentShape(Rectangle())
      .simultaneousGesture(
        DragGesture(minimumDistance: 24)
          .onEnded { value in
            let dx = value.translation.width
            let dy = value.translation.height
            let direction: Direction =
              abs(dx) > abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up)
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.68)) {
              store.move(direction)
            }
          })
    }
  }
}

struct PlayView: View {
  @Bindable var store: GameStore
  let mission: Mission
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 6) {
          Eyebrow(text: "HEIST \(String(format: "%02d", mission.district.id + 1))  /  BLUE HOUR")
          Text(mission.district.name)
            .font(.system(size: 25, weight: .bold, design: .serif))
            .foregroundStyle(Palette.cream)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        }
        Spacer()
        RoundButton(symbol: "pause.fill", label: "Pause game", id: "pause") {
          store.paused = true
        }
      }
      .padding(.top, 8)
      HStack {
        HStack(spacing: 6) {
          Image(systemName: "takeoutbag.and.cup.and.straw.fill").foregroundStyle(Palette.cream)
          Text("\(mission.loot) / \(mission.district.requiredLoot)")
            .contentTransition(.numericText())
            .foregroundStyle(mission.canEscape ? Palette.mint : Palette.cream)
          Text("SNACKS").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(
            Palette.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mission.loot) snacks, \(mission.district.requiredLoot) required")
        Spacer()
        HStack(spacing: 5) {
          ForEach(0..<3) { index in
            Image(systemName: index < mission.alarm ? "eye.fill" : "eye.slash")
              .foregroundStyle(index < mission.alarm ? Palette.coral : Palette.muted.opacity(0.6))
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mission.alarm) of 3 sightings")
      }
      .font(.system(size: 16, weight: .bold, design: .rounded))
      .padding(.top, 21)
      .padding(.bottom, 12)
      Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
      HStack(spacing: 6) {
        Eyebrow(text: "NEXT BEAT", color: Palette.muted)
        Circle().stroke(Palette.mint, lineWidth: 1.5).frame(width: 5, height: 5)
        Text("hidden")
        Circle().stroke(Palette.coral, style: StrokeStyle(lineWidth: 1.5, dash: [2])).frame(
          width: 5, height: 5)
        Text("watched")
        Spacer()
        Text("\(mission.remaining) beats left")
          .foregroundStyle(mission.remaining <= 4 ? Palette.coral : Palette.cream)
      }
      .font(.system(size: 9, weight: .medium, design: .monospaced))
      .foregroundStyle(Palette.muted)
      .padding(.top, 13)
      BoardView(store: store, mission: mission)
        .frame(maxHeight: .infinity)
        .layoutPriority(1)
      VStack(spacing: 12) {
        HStack(alignment: .top, spacing: 9) {
          Image(systemName: mission.canEscape ? "flag.checkered" : "sparkle")
            .foregroundStyle(Palette.mint)
            .font(.system(size: 14))
          Text(mission.message)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Palette.cream)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
            .accessibilityIdentifier("game-guidance")
        }
        .padding(.horizontal, 4)
        HStack(spacing: 8) {
          ForEach([Direction.left, .up, .down, .right], id: \.self) { direction in
            Button {
              withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.68)) {
                store.move(direction)
              }
            } label: {
              Image(systemName: direction.symbol)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Palette.cream)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .disabled(mission.neighbor(direction) == nil)
            .opacity(mission.neighbor(direction) == nil ? 0.28 : 1)
            .accessibilityLabel("Move \(direction.rawValue)")
            .accessibilityIdentifier("move-\(direction.rawValue)")
          }
          Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { store.act(nil) }
          } label: {
            VStack(spacing: 3) {
              Image(systemName: "moon.zzz.fill").font(.system(size: 16))
              Text("WAIT").font(.system(size: 9, weight: .heavy, design: .monospaced))
            }
            .foregroundStyle(Palette.mint)
            .frame(width: 67, height: 48)
            .background(Palette.mint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.mint.opacity(0.35)))
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Wait one beat")
          .accessibilityHint(
            "Stay on this roof while the watchers change. Gardens are always safe."
          )
          .accessibilityIdentifier("wait")
        }
        Text("EVERY MOVE IS ONE BEAT. TAKE YOUR TIME.")
          .font(.system(size: 8, weight: .medium, design: .monospaced))
          .tracking(1.2)
          .foregroundStyle(Palette.muted)
      }
      .padding(.bottom, 15)
    }
    .padding(.horizontal, 23)
  }
}

struct TutorialView: View {
  @Bindable var store: GameStore
  private let titles = ["A very small heist.", "Read the rooftops.", "Leave no crumbs."]
  private let details = [
    "Swipe, tap a neighboring roof, or use the arrows. Each move takes one beat. The city waits for you.",
    "Mint gardens hide you. WATCHED marks roofs that will spot you on your next move. Wait in a garden to change the beat.",
    "Grab the required snacks, then reach the striped water tower. Three sightings or running out of beats ends the heist.",
  ]

  var body: some View {
    ZStack {
      Palette.ink.opacity(0.90).ignoresSafeArea()
      VStack(spacing: 22) {
        HStack {
          Eyebrow(text: "FIELD NOTES  /  \(store.tutorialPage + 1) OF 3")
          Spacer()
          Button("Skip") { store.finishTutorial() }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Palette.muted)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("skip-tutorial")
        }
        RaccoonArt(snacks: store.tutorialPage + 1)
          .frame(width: 165, height: 165)
        VStack(spacing: 12) {
          Text(titles[store.tutorialPage])
            .font(.system(size: 31, weight: .bold, design: .serif))
            .foregroundStyle(Palette.cream)
          Text(details[store.tutorialPage])
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(Palette.muted)
            .lineSpacing(5)
            .multilineTextAlignment(.center)
        }
        HStack(spacing: 6) {
          ForEach(0..<3) { index in
            Capsule().fill(index == store.tutorialPage ? Palette.mint : .white.opacity(0.15))
              .frame(width: index == store.tutorialPage ? 24 : 6, height: 5)
          }
        }
        PrimaryButton(title: store.tutorialPage == 2 ? "I'M IN. LET'S GO." : "GOT IT") {
          if store.tutorialPage == 2 { store.finishTutorial() } else { store.tutorialPage += 1 }
        }
        .accessibilityIdentifier("tutorial-next")
      }
      .padding(30)
      .frame(maxWidth: 430)
    }
    .accessibilityAddTraits(.isModal)
  }
}

struct PauseView: View {
  @Bindable var store: GameStore
  var body: some View {
    ZStack {
      Palette.ink.opacity(0.95).ignoresSafeArea()
      VStack(spacing: 22) {
        Eyebrow(text: "PAWS FOR A MOMENT")
        RaccoonArt(snacks: 0, happy: true).frame(width: 150, height: 150)
        Text("The city can wait.")
          .font(.system(size: 32, weight: .bold, design: .serif))
          .foregroundStyle(Palette.cream)
        PrimaryButton(title: "BACK TO MISCHIEF", symbol: "play.fill") { store.paused = false }
          .accessibilityIdentifier("resume")
        Button("Restart this heist") { store.start() }
          .accessibilityIdentifier("restart")
        Button("Field notes") {
          store.tutorialPage = 0
          store.showTutorial = true
          store.paused = false
        }
        .accessibilityIdentifier("show-tutorial")
        Button("Back to rooftops") { store.home() }
          .accessibilityIdentifier("home")
      }
      .font(.system(size: 15, weight: .semibold, design: .rounded))
      .buttonStyle(.borderless)
      .padding(30)
      .frame(maxWidth: 430)
    }
    .accessibilityAddTraits(.isModal)
  }
}

struct SettingsView: View {
  @Bindable var store: GameStore
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      Form {
        Section("Little details") {
          Toggle("Sound effects", isOn: $store.progress.sound)
            .accessibilityIdentifier("sound-toggle")
          Toggle("Haptic feedback", isOn: $store.progress.haptics)
            .accessibilityIdentifier("haptics-toggle")
        }
        Section {
          Text(
            "Your best scores and unlocked neighborhoods stay on this device. No accounts. Just snacks."
          )
          Text(
            "Every move advances one beat. WATCHED labels forecast the next beat; mint rooftops always hide you."
          )
        }
        .font(.system(size: 13))
      }
      .navigationTitle("After-hours settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            store.save()
            dismiss()
          }
          .accessibilityIdentifier("settings-done")
        }
      }
      .onDisappear { store.save() }
    }
  }
}

struct ResultView: View {
  @Bindable var store: GameStore
  let mission: Mission
  @State private var share: SharePayload?
  @State private var shareError = false
  var escaped: Bool { mission.phase == .escaped }

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        HStack {
          Eyebrow(
            text: escaped ? "CASE FILE  /  SUSPECT AT LARGE" : "CASE FILE  /  HEIST INTERRUPTED")
          Spacer()
          RoundButton(symbol: "xmark", label: "Return home", id: "result-home") { store.home() }
        }
        .padding(.top, 8)
        Text(escaped ? "A clean\ngetaway." : "One snack\ntoo far.")
          .font(.system(size: min(geometry.size.width * 0.14, 57), weight: .black, design: .serif))
          .tracking(-1.7)
          .lineSpacing(-5)
          .multilineTextAlignment(.center)
          .foregroundStyle(Palette.cream)
          .padding(.top, 10)
          .accessibilityIdentifier("result-title")
        HeroScene(celebration: escaped, snacks: max(1, mission.loot))
          .frame(maxHeight: .infinity)
          .layoutPriority(-1)
        VStack(spacing: 16) {
          Eyebrow(text: mission.rating, color: escaped ? Palette.mint : Palette.coral)
            .padding(.vertical, 9)
            .padding(.horizontal, 16)
            .overlay(Capsule().stroke((escaped ? Palette.mint : Palette.coral).opacity(0.4)))
          HStack(spacing: 0) {
            resultStat("\(mission.loot)", "SNACKS")
            Rectangle().fill(.white.opacity(0.17)).frame(width: 1, height: 32)
            resultStat(
              escaped ? "\(mission.score)" : "\(mission.beat)", escaped ? "POINTS" : "BEATS")
            Rectangle().fill(.white.opacity(0.17)).frame(width: 1, height: 32)
            resultStat("\(mission.alarm)", "SIGHTINGS")
          }
          Text(
            escaped
              ? mission.district.id < 2
                ? "\(District.all[mission.district.id + 1].name) is open for mischief."
                : "Every district conquered. Can you steal all seven?"
              : mission.message
          )
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center)
          .frame(minHeight: 30)
          if escaped {
            PrimaryButton(title: "SHARE WANTED POSTER", symbol: "square.and.arrow.up") {
              renderPoster()
            }
            .accessibilityIdentifier("share-result")
            HStack {
              Button("Play again") { store.start() }
                .accessibilityIdentifier("play-again")
                .frame(maxWidth: .infinity, minHeight: 44)
              if mission.district.id < 2 {
                Button {
                  store.selected = mission.district.id + 1
                  store.start()
                } label: {
                  HStack(spacing: 6) {
                    Text("Next district")
                    Image(systemName: "arrow.right")
                  }
                }
                .accessibilityIdentifier("next-district")
                .frame(maxWidth: .infinity, minHeight: 44)
              } else {
                Button("Rooftops") { store.home() }
                  .frame(maxWidth: .infinity, minHeight: 44)
              }
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
          } else {
            PrimaryButton(title: "ONE MORE HEIST", symbol: "arrow.counterclockwise") {
              store.start()
            }
            .accessibilityIdentifier("retry")
            Button("Back to rooftops") { store.home() }
              .font(.system(size: 14, weight: .bold, design: .rounded))
              .frame(minHeight: 44)
              .accessibilityIdentifier("failure-home")
          }
        }
        .padding(.bottom, 12)
      }
      .padding(.horizontal, 25)
    }
    .sheet(item: $share) { payload in ShareSheet(image: payload.image, text: payload.text) }
    .alert("Poster couldn't be drawn", isPresented: $shareError) {
      Button("Try again") { renderPoster() }
      Button("Cancel", role: .cancel) {}
    }
  }

  private func resultStat(_ value: String, _ label: String) -> some View {
    VStack(spacing: 4) {
      Text(value).font(.system(size: 29, weight: .bold, design: .serif)).foregroundStyle(
        Palette.cream)
      Text(label).font(.system(size: 8, weight: .heavy, design: .monospaced)).tracking(1.5)
        .foregroundStyle(Palette.muted)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }

  @MainActor private func renderPoster() {
    let renderer = ImageRenderer(content: WantedPoster(mission: mission))
    renderer.scale = 2
    if let image = renderer.uiImage {
      share = SharePayload(
        image: image,
        text:
          "Wanted for grand snack larceny. \(mission.loot) snacks • \(mission.score) points • \(mission.rating). Rooftop Raccoon — \(mission.district.name)."
      )
    } else {
      shareError = true
    }
  }
}

struct WantedPoster: View {
  let mission: Mission
  var body: some View {
    VStack(spacing: 15) {
      Eyebrow(text: "SAFFRON CITY NIGHT WATCH", color: Palette.ink)
      Text("WANTED")
        .font(.system(size: 66, weight: .black, design: .serif))
        .tracking(6)
      Text("FOR GRAND SNACK LARCENY")
        .font(.system(size: 12, weight: .heavy, design: .monospaced))
        .tracking(2)
      ZStack {
        Circle().fill(Palette.sky).frame(width: 280, height: 280)
        RaccoonArt(snacks: mission.loot, happy: true).frame(width: 250, height: 250)
      }
      Text("“THE ROOFTOP RACCOON”")
        .font(.system(size: 23, weight: .black, design: .serif))
      Text("\(mission.loot) STOLEN SNACKS  /  \(mission.score) POINTS")
        .font(.system(size: 12, weight: .heavy, design: .monospaced))
        .tracking(1)
      Text(mission.rating)
        .font(.system(size: 18, weight: .bold, design: .rounded))
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .overlay(Rectangle().stroke(Palette.brick, lineWidth: 2))
        .rotationEffect(.degrees(-3))
        .foregroundStyle(Palette.brick)
      Spacer(minLength: 0)
      Text("LAST SEEN IN \(mission.district.name.uppercased())")
        .font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.3)
      Text("ROOFTOP RACCOON  ·  SMALL PAWS. GRAND LARCENY.")
        .font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1)
    }
    .foregroundStyle(Palette.ink)
    .padding(28)
    .frame(width: 440, height: 690)
    .background(Palette.cream)
    .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 2).padding(12))
    .environment(\.colorScheme, .light)
  }
}

struct SharePayload: Identifiable {
  let id = UUID()
  let image: UIImage
  let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
  let image: UIImage
  let text: String
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
