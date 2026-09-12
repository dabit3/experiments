import SpriteKit
import SwiftUI

@main
struct LanternfallApp: App {
  var body: some Scene {
    WindowGroup { LanternfallView().preferredColorScheme(.dark) }
  }
}

enum Palette {
  static let ink = Color(red: 0.025, green: 0.065, blue: 0.09)
  static let panel = Color(red: 0.055, green: 0.13, blue: 0.16)
  static let gold = Color(red: 1, green: 0.8, blue: 0.43)
  static let mint = Color(red: 0.47, green: 0.9, blue: 0.8)
  static let cream = Color(red: 0.97, green: 0.94, blue: 0.83)
  static let muted = Color(red: 0.55, green: 0.68, blue: 0.69)
}

struct LanternfallView: View {
  @StateObject private var store = GameStore()
  @Environment(\.scenePhase) private var scenePhase
  @State private var showingGuide = false
  var body: some View {
    ZStack {
      Palette.ink.ignoresSafeArea()
      if store.screen == "title" {
        title
      } else {
        gameplay
        if store.game.phase == .choosing { upgrades }
        if store.game.phase == .paused { pause }
        if store.game.phase == .victory || store.game.phase == .defeat { results }
      }
      if showingGuide { guide }
    }
    .foregroundStyle(Palette.cream)
    .onChange(of: scenePhase) { _, phase in
      if phase != .active { store.game.pause() }
    }
    .statusBarHidden()
  }

  private var title: some View {
    GeometryReader { geometry in
      ZStack {
        GardenBackdrop()
        VStack(spacing: 0) {
          HStack {
            eyebrow("A MIDNIGHT SURVIVAL")
            Spacer()
            soundButton
          }
          .padding(.top, 10)
          Spacer(minLength: 10)
          VStack(spacing: 8) {
            Text("Lanternfall")
              .font(
                .system(size: min(57, geometry.size.width * 0.14), weight: .regular, design: .serif)
              )
              .tracking(-2)
              .foregroundStyle(Palette.cream)
            HStack(spacing: 10) {
              Rectangle().fill(Palette.gold.opacity(0.3)).frame(width: 27, height: 1)
              Text("KEEP THE LIGHT ALIVE").font(.system(size: 10, weight: .semibold)).tracking(3)
              Rectangle().fill(Palette.gold.opacity(0.3)).frame(width: 27, height: 1)
            }
            .foregroundStyle(Palette.gold)
          }
          ZStack {
            Circle().fill(Palette.gold.opacity(0.025)).frame(width: 230, height: 230)
            Circle().stroke(Palette.gold.opacity(0.16), lineWidth: 1).frame(width: 206, height: 206)
            Circle().stroke(Palette.mint.opacity(0.10), lineWidth: 1).frame(width: 260, height: 260)
            Image(uiImage: UIImage(cgImage: GardenArt.texture("keeper").cgImage()))
              .resizable().interpolation(.high)
              .frame(width: 170, height: 170)
              .shadow(color: Palette.gold.opacity(0.22), radius: 30, x: 30)
            Image(systemName: "sparkle").font(.system(size: 17)).foregroundStyle(Palette.gold)
              .offset(x: -99, y: -44)
            Image(systemName: "diamond.fill").font(.system(size: 10)).foregroundStyle(Palette.mint)
              .offset(x: 98, y: 58)
          }
          .frame(height: min(280, geometry.size.height * 0.33))
          VStack(spacing: 8) {
            Text("One keeper. Five minutes until dawn.")
              .font(.system(size: 17, weight: .regular, design: .serif))
            Text("Gather light. Grow stronger.\nFace what waits in the garden.")
              .font(.system(size: 13)).foregroundStyle(Palette.muted)
              .multilineTextAlignment(.center).lineSpacing(4)
          }
          Spacer(minLength: 18)
          HStack(spacing: 0) {
            record(value: clock(store.bestSeconds), label: "BEST SURVIVAL")
            Rectangle().fill(Palette.muted.opacity(0.25)).frame(width: 1, height: 28)
            record(value: "\(store.bestKills)", label: "MOST BANISHED")
            Rectangle().fill(Palette.muted.opacity(0.25)).frame(width: 1, height: 28)
            record(value: "\(store.victories)", label: "DAWNS SEEN")
          }
          .padding(.vertical, 20)
          primary("Enter the garden", icon: "arrow.right") { store.start() }
          Button {
            showingGuide = true
          } label: {
            Label("How to keep the light", systemImage: "hand.draw")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(Palette.muted).frame(height: 49)
          }
          .accessibilityIdentifier("howToPlay")
        }
        .padding(.horizontal, 27)
        .padding(.bottom, 5)
      }
    }
  }
  private var gameplay: some View {
    ZStack {
      SpriteView(scene: store.scene, options: [.ignoresSiblingOrder])
        .ignoresSafeArea()
      VStack {
        LinearGradient(
          colors: [Palette.ink.opacity(0.85), .clear], startPoint: .top, endPoint: .bottom
        )
        .frame(height: 175)
        Spacer()
        LinearGradient(
          colors: [.clear, Palette.ink.opacity(0.82)], startPoint: .top, endPoint: .bottom
        )
        .frame(height: 140)
      }
      .ignoresSafeArea().allowsHitTesting(false)
      VStack(spacing: 12) {
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 5) {
            eyebrow(store.game.elapsed < 240 ? "UNTIL DAWN" : "THE FINAL HOUR")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text(store.game.timeText).font(.system(size: 28, weight: .light, design: .rounded))
                .monospacedDigit()
              Text("/ 05:00").font(.system(size: 12)).foregroundStyle(Palette.muted)
            }
          }
          Spacer()
          VStack(alignment: .trailing, spacing: 6) {
            Text("\(store.game.kills)").font(.system(size: 24, weight: .medium, design: .rounded))
              .monospacedDigit()
            eyebrow("BANISHED")
          }
          Button {
            store.game.pause()
          } label: {
            Image(systemName: "pause.fill").font(.system(size: 16)).frame(width: 46, height: 46)
              .background(Palette.panel.opacity(0.8), in: Circle())
              .overlay(Circle().stroke(Palette.muted.opacity(0.2)))
          }
          .accessibilityLabel("Pause")
          .padding(.leading, 8)
        }
        HStack(spacing: 10) {
          Image(systemName: "heart.fill").font(.system(size: 11)).foregroundStyle(
            Color(red: 0.94, green: 0.57, blue: 0.49))
          meter(
            store.game.health / store.game.maxHealth,
            color: Color(red: 0.94, green: 0.57, blue: 0.49), height: 5)
          Text("\(Int(store.game.health))").font(.system(size: 11, weight: .semibold))
            .monospacedDigit().frame(minWidth: 24)
        }
        HStack(spacing: 10) {
          Text("LV \(store.game.level)").font(.system(size: 10, weight: .bold)).foregroundStyle(
            Palette.mint)
          meter(store.game.experience / store.game.neededExperience, color: Palette.mint, height: 3)
          Image(systemName: "diamond.fill").font(.system(size: 8)).foregroundStyle(Palette.mint)
        }
        if let boss = store.game.enemies.first(where: { $0.kind == .boss }) {
          VStack(spacing: 5) {
            HStack {
              Text("THE HOLLOW GARDENER").font(.system(size: 9, weight: .bold)).tracking(2)
              Spacer()
              Image(systemName: "location.north.fill")
                .rotationEffect(
                  .radians(
                    .pi / 2
                      - atan2(
                        boss.position.y - store.game.player.y, boss.position.x - store.game.player.x
                      )))
            }
            .foregroundStyle(Palette.gold)
            meter(boss.health / boss.maxHealth, color: Palette.gold, height: 4)
          }
          .padding(12).background(Palette.ink.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
        } else if store.game.elapsed < 8 {
          Text("Drag the stick to move. Your lantern attacks.")
            .font(.system(size: 12)).foregroundStyle(Palette.cream.opacity(0.8))
            .padding(.top, 10)
        }
        if store.game.elapsed >= 43 && store.game.elapsed < 55 {
          Label(
            "Thorn blooms! Leave the rose-colored rings.", systemImage: "exclamationmark.circle"
          )
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.7))
          .padding(10).background(Palette.ink.opacity(0.7), in: Capsule())
        } else if store.game.experience >= store.game.neededExperience && store.game.nextGiftIn > 0
        {
          Text("A new gift blooms in \(Int(ceil(store.game.nextGiftIn)))s")
            .font(.system(size: 11)).foregroundStyle(Palette.mint)
        }
        Spacer()
        if store.game.elapsed < 16 {
          Text("Collect turquoise gems to grow your light")
            .font(.system(size: 11)).foregroundStyle(Palette.mint)
        }
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 9) {
            eyebrow("YOUR LIGHT")
            HStack(spacing: 8) {
              weapon("sparkles", rank: 1 + store.game.rank(.lantern), color: Palette.gold)
              if store.game.rank(.orbit) > 0 {
                weapon(
                  "moonphase.waning.crescent", rank: store.game.rank(.orbit), color: Palette.mint)
              }
              if store.game.rank(.nova) > 0 {
                weapon("sun.max", rank: store.game.rank(.nova), color: Palette.gold)
              }
            }
            Text(store.game.stage).font(.system(size: 10, design: .serif)).foregroundStyle(
              Palette.muted)
          }
          Spacer(minLength: 8)
          Joystick { movement in store.game.movement = movement }
        }
        .padding(.bottom, 6)
      }
      .padding(.horizontal, 23).padding(.top, 10)
    }
  }
  private var upgrades: some View {
    overlay {
      VStack(alignment: .leading, spacing: 18) {
        HStack {
          eyebrow("LIGHT GATHERED")
          Spacer()
          Text("LEVEL \(store.game.level)").font(.system(size: 10, weight: .bold)).tracking(1)
            .foregroundStyle(Palette.mint)
        }
        VStack(alignment: .leading, spacing: 7) {
          Text("Let it bloom.").font(.system(size: 37, design: .serif))
          Text("Choose a gift. The garden can wait.").font(.system(size: 13)).foregroundStyle(
            Palette.muted)
        }
        ForEach(store.game.choices) { upgrade in
          Button {
            store.choose(upgrade)
          } label: {
            HStack(spacing: 15) {
              Image(systemName: upgrade.symbol).font(.system(size: 25, weight: .light))
                .foregroundStyle(
                  upgrade == .orbit || upgrade == .magnet ? Palette.mint : Palette.gold
                )
                .frame(width: 46, height: 56)
              VStack(alignment: .leading, spacing: 6) {
                HStack {
                  Text(upgrade.title).font(.system(size: 18, design: .serif))
                  Spacer()
                  Text("RANK \(store.game.rank(upgrade) + 1)")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.gold)
                }
                Text(upgrade.detail(after: store.game.rank(upgrade))).font(.system(size: 12))
                  .foregroundStyle(Palette.muted)
                  .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
              }
              Image(systemName: "chevron.right").font(.system(size: 10)).foregroundStyle(
                Palette.gold.opacity(0.6))
            }
            .padding(17)
            .background(
              LinearGradient(
                colors: [Palette.panel, Palette.ink], startPoint: .topLeading,
                endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 17)
            )
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(Palette.gold.opacity(0.22)))
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("upgrade-\(upgrade.rawValue)")
        }
        Label("Time is paused while you choose", systemImage: "pause.circle")
          .font(.system(size: 11)).foregroundStyle(Palette.muted)
          .frame(maxWidth: .infinity).padding(.top, 3)
      }
    }
  }
  private var pause: some View {
    overlay {
      VStack(spacing: 22) {
        Image(systemName: "moon.stars").font(.system(size: 38, weight: .ultraLight))
          .foregroundStyle(Palette.gold)
        eyebrow("A MOMENT OF STILLNESS")
        Text("The light can wait.").font(.system(size: 33, design: .serif))
        Text("Your run is paused at \(store.game.timeText).")
          .font(.system(size: 14)).foregroundStyle(Palette.muted)
        primary("Return to the garden", icon: "play.fill") { store.game.resume() }
        HStack(spacing: 16) {
          Button {
            store.toggleSound()
          } label: {
            Label(
              store.sound ? "Sound on" : "Sound off",
              systemImage: store.sound ? "speaker.wave.2" : "speaker.slash")
          }
          Spacer()
          Button("How to play") { showingGuide = true }
        }
        .font(.system(size: 13)).foregroundStyle(Palette.muted).frame(height: 44)
        Button("End this run") {
          store.game.defeatCause = .ended
          store.game.phase = .defeat
          store.finish()
        }
        .font(.system(size: 13)).foregroundStyle(Palette.muted).frame(height: 44)
      }
    }
  }
  private var results: some View {
    overlay {
      VStack(spacing: 20) {
        ZStack {
          Circle().stroke(Palette.gold.opacity(0.18)).frame(width: 92, height: 92)
          Image(systemName: store.game.phase == .victory ? "sun.max" : "sparkle")
            .font(.system(size: 44, weight: .ultraLight)).foregroundStyle(Palette.gold)
        }
        eyebrow(
          store.game.phase == .victory ? "THE GARDEN REMEMBERS" : "EVERY LIGHT LEAVES A TRACE")
        VStack(spacing: 10) {
          Text(store.game.phase == .victory ? "You brought the dawn." : "An ember remains.")
            .font(.system(size: 34, design: .serif)).multilineTextAlignment(.center)
          Text(
            store.game.phase == .victory
              ? "The Hollow Gardener falls. The flowers open."
              : store.game.defeatCause?.advice ?? "The garden is patient. Return a little brighter."
          )
          .font(.system(size: 13)).foregroundStyle(Palette.muted)
          .multilineTextAlignment(.center).lineSpacing(4)
        }
        HStack(spacing: 0) {
          record(value: store.game.timeText, label: "SURVIVED")
          record(value: "\(store.game.kills)", label: "BANISHED")
          record(value: "\(store.game.level)", label: "LEVEL")
        }
        .padding(.vertical, 20)
        .background(Palette.panel, in: RoundedRectangle(cornerRadius: 18))
        HStack {
          Image(systemName: "laurel.leading").foregroundStyle(Palette.gold)
          Text("LOCAL BEST  \(clock(store.bestSeconds))  ·  \(store.bestKills) banished")
            .font(.system(size: 10, weight: .medium)).tracking(0.6)
          Image(systemName: "laurel.trailing").foregroundStyle(Palette.gold)
        }
        primary("Light another lantern", icon: "arrow.clockwise") { store.start() }
        HStack {
          Button("Back to garden gate") { store.screen = "title" }
          Spacer()
          ShareLink(
            item:
              "I kept the light alive for \(store.game.timeText) and banished \(store.game.kills) shades in Lanternfall."
          ) {
            Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44)
          }
        }
        .font(.system(size: 12)).foregroundStyle(Palette.muted)
      }
    }
  }
  private var guide: some View {
    overlay {
      VStack(alignment: .leading, spacing: 24) {
        eyebrow("THE KEEPER'S FIELD NOTES")
        Text("A little light\n goes a long way.").font(.system(size: 35, design: .serif))
        guideRow(
          "hand.draw", title: "Wander with one thumb",
          text:
            "Drag the lower-right stick to move. Let go to stop. Your lantern targets nearby enemies."
        )
        guideRow(
          "diamond", title: "Gather what glimmers",
          text:
            "Turquoise gems grant levels. Choose one of three gifts each time. Rose gems restore health."
        )
        guideRow(
          "sun.max", title: "Earn your dawn",
          text:
            "Survive five minutes and defeat the Hollow Gardener, who arrives in the final minute.")
        Text(
          "Leave rose-colored thorn rings before they bloom.\nCircle back for gems. Pause whenever you need."
        )
        .font(.system(size: 12)).foregroundStyle(Palette.gold).lineSpacing(4)
        primary("I’ll keep the light", icon: "checkmark") { showingGuide = false }
      }
    }
  }
  private func overlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Palette.ink.opacity(0.95).ignoresSafeArea()
      GardenBackdrop().opacity(0.5).allowsHitTesting(false)
      ScrollView {
        content().padding(25).frame(maxWidth: 480)
          .frame(maxWidth: .infinity)
      }
      .scrollBounceBehavior(.basedOnSize)
      .defaultScrollAnchor(.center)
    }
  }
  private var soundButton: some View {
    Button {
      store.toggleSound()
    } label: {
      Image(systemName: store.sound ? "speaker.wave.2" : "speaker.slash")
        .font(.system(size: 15)).foregroundStyle(Palette.muted)
        .frame(width: 44, height: 44)
    }
    .accessibilityLabel(store.sound ? "Mute sound" : "Enable sound")
  }
  private func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Spacer()
        Text(title).font(.system(size: 16, weight: .semibold))
        Spacer()
        Image(systemName: icon).font(.system(size: 15, weight: .medium))
      }
      .foregroundStyle(Palette.ink)
      .padding(.horizontal, 22).frame(height: 58)
      .background(
        LinearGradient(
          colors: [Color(red: 1, green: 0.87, blue: 0.58), Palette.gold], startPoint: .topLeading,
          endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 17)
      )
      .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.white.opacity(0.15)))
    }
    .buttonStyle(.plain)
  }
  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 9, weight: .semibold)).tracking(1.7).foregroundStyle(
      Palette.muted)
  }
  private func record(value: String, label: String) -> some View {
    VStack(spacing: 7) {
      Text(value).font(.system(size: 24, weight: .light, design: .rounded)).monospacedDigit()
      Text(label).font(.system(size: 8, weight: .semibold)).tracking(1).foregroundStyle(
        Palette.muted)
    }
    .frame(maxWidth: .infinity)
  }
  private func meter(_ value: Double, color: Color, height: Double) -> some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Capsule().fill(color.opacity(0.15))
        Capsule().fill(color).frame(width: proxy.size.width * min(1, max(0, value)))
      }
    }
    .frame(height: height)
  }
  private func weapon(_ symbol: String, rank: Int, color: Color) -> some View {
    HStack(spacing: 4) {
      Image(systemName: symbol).font(.system(size: 16))
      Text("\(rank)").font(.system(size: 10, weight: .bold))
    }
    .foregroundStyle(color).padding(9).background(
      Palette.panel, in: RoundedRectangle(cornerRadius: 10))
  }
  private func guideRow(_ symbol: String, title: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
      Image(systemName: symbol).font(.system(size: 25, weight: .light)).foregroundStyle(
        Palette.gold
      ).frame(width: 32)
      VStack(alignment: .leading, spacing: 7) {
        Text(title).font(.system(size: 18, design: .serif))
        Text(text).font(.system(size: 13)).foregroundStyle(Palette.muted).lineSpacing(4)
      }
    }
  }
  private func clock(_ seconds: Double) -> String {
    String(format: "%02d:%02d", Int(seconds) / 60, Int(seconds) % 60)
  }
}

struct Joystick: View {
  var changed: (V2) -> Void
  @State private var offset: CGSize = .zero
  var body: some View {
    ZStack {
      Circle().fill(Palette.panel.opacity(0.58))
      Circle().stroke(Palette.muted.opacity(0.22), lineWidth: 1)
      Circle().stroke(Palette.muted.opacity(0.08), lineWidth: 1).padding(15)
      Image(systemName: "plus").font(.system(size: 40, weight: .ultraLight)).foregroundStyle(
        Palette.muted.opacity(0.14))
      Circle().fill(Palette.mint.opacity(0.16)).frame(width: 46, height: 46)
        .overlay(Circle().stroke(Palette.mint.opacity(0.55)))
        .overlay(Circle().fill(Palette.mint.opacity(0.6)).frame(width: 5, height: 5))
        .offset(offset)
    }
    .frame(width: 116, height: 116)
    .contentShape(Circle())
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          let vector = V2(x: value.location.x - 58, y: 58 - value.location.y)
          let clamped = vector.normalized * min(38, vector.length)
          offset = CGSize(width: clamped.x, height: -clamped.y)
          changed(clamped * (1 / 38))
        }
        .onEnded { _ in
          offset = .zero
          changed(.zero)
        }
    )
    .accessibilityLabel("Movement stick")
    .accessibilityHint("Drag in the direction you want to move")
    .onDisappear {
      offset = .zero
      changed(.zero)
    }
  }
}

struct GardenBackdrop: View {
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        RadialGradient(
          colors: [Color(red: 0.09, green: 0.23, blue: 0.23), Palette.ink],
          center: UnitPoint(x: 0.65, y: 0.3), startRadius: 0, endRadius: proxy.size.height * 0.75)
        Canvas { context, size in
          var random = SeededRandom(state: 722)
          for _ in 0..<65 {
            let x = random.next() * size.width
            let y = random.next() * size.height
            let radius = random.next() > 0.85 ? 1.7 : 0.8
            context.fill(
              Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
              with: .color(Palette.gold.opacity(0.15 + random.next() * 0.35)))
          }
          for side in [0.0, 1.0] {
            for index in 0..<12 {
              let bottom = size.height * (0.48 + Double(index) * 0.055)
              var stem = Path()
              stem.move(to: CGPoint(x: side * size.width, y: bottom + 110))
              stem.addQuadCurve(
                to: CGPoint(
                  x: side == 0
                    ? 42 + Double(index % 3) * 13 : size.width - 42 - Double(index % 3) * 13,
                  y: bottom),
                control: CGPoint(x: side == 0 ? 7 : size.width - 7, y: bottom))
              context.stroke(stem, with: .color(Palette.mint.opacity(0.11)), lineWidth: 1)
              let leaf = Path(
                ellipseIn: CGRect(
                  x: side == 0 ? 18 : size.width - 43, y: bottom + 20, width: 25, height: 9))
              context.fill(leaf, with: .color(Palette.mint.opacity(0.07)))
            }
          }
        }
      }
    }
    .ignoresSafeArea()
  }
}
