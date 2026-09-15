import SceneKit
import SwiftUI

@main
struct VoxelVanguardApp: App {
  var body: some Scene {
    WindowGroup {
      VanguardView()
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }
  }
}

struct WorldView: UIViewRepresentable {
  let world: DungeonScene
  func makeUIView(context: Context) -> SCNView {
    let view = SCNView()
    view.scene = world.scene
    view.pointOfView = world.camera
    view.isPlaying = true
    view.rendersContinuously = true
    view.preferredFramesPerSecond = 60
    view.antialiasingMode = .multisampling4X
    view.backgroundColor = .black
    return view
  }
  func updateUIView(_ view: SCNView, context: Context) {}
}

enum Palette {
  static let gold = Color(red: 0.96, green: 0.73, blue: 0.35)
  static let blue = Color(red: 0.36, green: 0.8, blue: 0.92)
  static let panel = Color(red: 0.055, green: 0.095, blue: 0.12)
  static let muted = Color(red: 0.58, green: 0.69, blue: 0.7)
}

struct VanguardView: View {
  @StateObject private var game = GameClient()
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        WorldView(world: game.world).ignoresSafeArea()
        LinearGradient(
          colors: [.black.opacity(0.65), .clear, .clear, .black.opacity(0.65)],
          startPoint: .top, endPoint: .bottom
        ).allowsHitTesting(false)
        ZStack {
          if game.state == nil {
            entry
          } else if game.state?.phase == "lobby" {
            lobby
          } else {
            hud
            if ["victory", "defeat"].contains(game.state?.phase ?? "") { result }
            if game.gearOpen { gearPicker }
            if game.state?.paused == true || !game.connected { pause }
          }
        }
        .frame(width: 900, height: 420)
        .scaleEffect(min(geometry.size.width / 900, geometry.size.height / 420))
        .frame(width: geometry.size.width, height: geometry.size.height)
      }
    }
  }

  private var entry: some View {
    HStack(spacing: 45) {
      VStack(alignment: .leading, spacing: 8) {
        Text("A COOPERATIVE DUNGEON EXPEDITION").font(
          .system(size: 10, weight: .heavy, design: .monospaced)
        )
        .tracking(2.3).foregroundStyle(Palette.gold)
        Text("VOXEL\nVANGUARD").font(.system(size: 44, weight: .black, design: .rounded))
          .tracking(1).lineSpacing(-6).shadow(color: .black, radius: 0, x: 3, y: 4)
        Rectangle().fill(Palette.gold).frame(width: 48, height: 3)
        Text("THE HOLLOWWOOD EXPEDITION").font(
          .system(size: 11, weight: .bold, design: .monospaced)
        )
        .foregroundStyle(Palette.gold).padding(.top, 4)
        Text("Two heroes. Three seals. One ancient Warden.\nGather your party. Restore the forest.")
          .font(.system(size: 12)).foregroundStyle(.white.opacity(0.8)).lineSpacing(5)
        HStack(spacing: 13) {
          Label("REAL NETWORK CO-OP", systemImage: "network")
          Label("GUEST PLAY", systemImage: "person.2.fill")
        }.font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(Palette.muted)
          .padding(.top, 30)
      }.frame(width: 395, alignment: .leading)
      VStack(alignment: .leading, spacing: 10) {
        Text("ASSEMBLE YOUR PARTY").font(.system(size: 17, weight: .black, design: .rounded))
        labeledField("HERO NAME", text: $game.name, hint: "Aster")
        labeledField("SERVER ADDRESS", text: $game.address, hint: "ws://192.168.1.20:8791")
        labeledField("ROOM CODE  ·  LEAVE BLANK TO CREATE", text: $game.room, hint: "GROVE")
        HStack(spacing: 9) {
          solidButton("CREATE ROOM", icon: "plus", color: Palette.gold) {
            game.connect(create: true)
          }
          solidButton("JOIN", icon: "arrow.right", color: Palette.blue) {
            game.connect(create: false)
          }
        }
        Text(game.error.isEmpty ? game.status : game.error)
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .foregroundStyle(game.error.isEmpty ? Palette.muted : .orange)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(22).frame(width: 334)
      .background(Palette.panel.opacity(0.96))
      .overlay(Rectangle().stroke(Palette.gold.opacity(0.5), lineWidth: 1))
    }
  }

  private func labeledField(_ title: String, text: Binding<String>, hint: String) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(title).font(.system(size: 8, weight: .bold, design: .monospaced))
        .tracking(1).foregroundStyle(Palette.muted)
      TextField(hint, text: text)
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .padding(10).background(.black.opacity(0.3))
        .overlay(Rectangle().stroke(.white.opacity(0.13)))
        .accessibilityLabel(title)
    }
  }

  private var lobby: some View {
    VStack(spacing: 12) {
      Text("THE HOLLOWWOOD").font(.system(size: 11, weight: .black, design: .monospaced))
        .tracking(3).foregroundStyle(Palette.gold)
      Text("YOUR PARTY IS GATHERING").font(.system(size: 27, weight: .black, design: .rounded))
      HStack(spacing: 12) {
        Image(systemName: "network").foregroundStyle(Palette.blue)
        Text("ROOM \(game.room)").font(.system(size: 24, weight: .black, design: .monospaced))
          .tracking(5)
      }
      HStack(spacing: 16) {
        ForEach(0..<2) { slot in
          let player = game.state?.players.first { $0.slot == slot }
          VStack(spacing: 7) {
            Image(systemName: slot == 0 ? "shield.lefthalf.filled" : "arrow.up.right")
              .font(.system(size: 26)).foregroundStyle(slot == 0 ? Palette.blue : Palette.gold)
            Text(player?.name ?? "Waiting for a friend").font(.system(size: 16, weight: .bold))
            Text(player == nil ? "JOIN WITH THE ROOM CODE" : player!.ready ? "READY" : "NOT READY")
              .font(.system(size: 9, weight: .bold, design: .monospaced))
              .foregroundStyle(player?.ready == true ? .green : Palette.muted)
            Text(player.map { String($0.id.prefix(8)) } ?? "—")
              .font(.system(size: 8, design: .monospaced)).foregroundStyle(Palette.muted)
          }.frame(width: 220, height: 104).background(Palette.panel.opacity(0.9))
            .overlay(Rectangle().stroke((slot == 0 ? Palette.blue : Palette.gold).opacity(0.4)))
        }
      }
      Text("Joystick to move  •  Strike, shoot & dodge  •  Hold revive beside a fallen hero")
        .font(.system(size: 11)).foregroundStyle(.white.opacity(0.8))
      HStack {
        solidButton(
          game.me?.ready == true ? "UNREADY" : "READY FOR EXPEDITION",
          icon: "play.fill", color: Palette.gold
        ) { game.ready() }
        .frame(width: 295)
        Button("Leave room") { game.leave() }.font(.system(size: 12)).foregroundStyle(Palette.muted)
      }
      if game.automation { driverBanner }
    }.padding(25).background(Palette.panel.opacity(0.8))
  }

  private var hud: some View {
    ZStack {
      VStack(spacing: 0) {
        HStack(alignment: .top, spacing: 12) {
          if let me = game.me { heroPanel(me, local: true) }
          Spacer(minLength: 0)
          VStack(spacing: 5) {
            Text(
              "HOLLOWWOOD  /  \(["MOSSGATE", "SUNDERED CRYPT", "WARDEN'S COURT"][min(2, (game.state?.stage ?? 1) - 1)])"
            )
            .font(.system(size: 9, weight: .black, design: .monospaced)).tracking(1.4)
            .foregroundStyle(Palette.gold)
            Text(game.state?.objective ?? "").font(.system(size: 11, weight: .bold))
            HStack(spacing: 6) {
              ForEach(1...3, id: \.self) { stage in
                Image(
                  systemName: (game.state?.completedStages ?? 0) >= stage
                    ? "diamond.fill" : "diamond"
                )
                .foregroundStyle((game.state?.stage ?? 1) >= stage ? Palette.gold : Palette.muted)
              }
              Text("\(game.state?.enemies.count ?? 0) FOES")
                .foregroundStyle(Palette.muted)
            }.font(.system(size: 9, weight: .bold, design: .monospaced))
          }.frame(width: 342).padding(.top, 6)
          Spacer(minLength: 0)
          if let ally = game.partner { heroPanel(ally, local: false) }
        }
        if let boss = game.state?.enemies.first(where: { $0.kind == "boss" }) {
          VStack(spacing: 3) {
            Text("THE HOLLOW WARDEN").font(.system(size: 9, weight: .heavy, design: .monospaced))
              .tracking(2)
            ZStack(alignment: .leading) {
              Rectangle().fill(.black.opacity(0.75))
              Rectangle().fill(
                LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
              )
              .frame(width: 330 * Double(boss.hp) / Double(boss.maxHP))
            }.frame(width: 330, height: 6).overlay(Rectangle().stroke(Palette.gold.opacity(0.6)))
          }.padding(8).background(Palette.panel.opacity(0.75)).padding(.top, 6)
        }
        Spacer()
        HStack(alignment: .bottom, spacing: 15) {
          VStack(spacing: 5) {
            Joystick { game.movement($0, $1) }
            Text("MOVE").font(.system(size: 9, weight: .black, design: .monospaced))
              .foregroundStyle(Palette.muted)
          }.frame(width: 132)
          VStack(spacing: 6) {
            if game.nearChest != nil {
              Button {
                game.gearOpen = true
              } label: {
                Label("CLAIM YOUR GEAR CARD", systemImage: "shippingbox.fill")
                  .font(.system(size: 10, weight: .black, design: .monospaced))
                  .foregroundStyle(Palette.panel).padding(8).frame(maxWidth: .infinity).background(
                    Palette.gold)
              }.accessibilityLabel("Claim gear")
            }
            HStack(spacing: 5) {
              gearCard("MELEE", item: game.me?.weapon ?? "iron", glyph: "sword", color: .red)
              gearCard("RANGE", item: game.me?.bow ?? "oak", glyph: "bow", color: .purple)
              gearCard(
                "ARMOR", item: game.me?.armor ?? "scout", glyph: "armor", color: Palette.blue)
              Button {
                game.perform("artifact")
              } label: {
                VStack(spacing: 3) {
                  Text("RELIC").font(.system(size: 8, weight: .black, design: .monospaced))
                  GearGlyph(kind: "relic", color: .purple).frame(width: 30, height: 30)
                  Text(game.me?.charge == 100 ? "READY!" : "\(game.me?.charge ?? 0)%")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                }.foregroundStyle(.white).frame(width: 58, height: 69)
                  .background(Palette.panel.opacity(0.9))
                  .overlay(
                    Rectangle().stroke(
                      game.me?.charge == 100 ? .purple : .purple.opacity(0.4), lineWidth: 2))
              }.accessibilityLabel("Activate thunder relic")
            }
            HStack(spacing: 4) {
              Image(systemName: "bolt.fill").foregroundStyle(.purple)
              ProgressView(value: Double(game.me?.charge ?? 0), total: 100).tint(.purple)
            }.frame(width: 244).font(.system(size: 8))
          }
          Spacer(minLength: 0)
          VStack(spacing: 6) {
            HStack(spacing: 7) {
              actionButton(
                "HEAL", icon: "cross.case.fill", action: "heal", color: .green, small: true,
                cooldown: max(0, ((game.me?.potion ?? 0) - (game.state?.tick ?? 0) + 19) / 20))
              actionButton(
                "REVIVE", icon: "heart.circle.fill", action: "revive", color: Palette.blue,
                small: true)
            }
            HStack(alignment: .bottom, spacing: 8) {
              actionButton(
                "DODGE", icon: "wind", action: "dodge", color: Palette.gold,
                cooldown: max(0, ((game.me?.dodge ?? 0) - (game.state?.tick ?? 0) + 19) / 20))
              actionButton("RANGE", icon: "scope", action: "ranged", color: .purple)
              actionButton(
                "MELEE", icon: "bolt.shield.fill", action: "melee", color: .orange, large: true)
            }
          }
        }
        HStack(spacing: 9) {
          Text(
            "● \(game.connected ? "LIVE" : "OFFLINE")  \(game.room)  ·  P\((game.me?.slot ?? 0) + 1)  ·  \(game.identity.prefix(6))"
          )
          .font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(Palette.muted)
          Button("Reconnect") { game.reconnect() }.font(.system(size: 9, weight: .bold))
            .foregroundStyle(Palette.blue)
          Spacer()
          if Launch.has("automation") {
            Button(game.automation ? "AUTO DRIVER: ON" : "AUTO DRIVER: OFF") { game.toggleDriver() }
              .font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(
                Palette.gold)
          }
          Button("Exit") { game.leave() }.font(.system(size: 9)).foregroundStyle(Palette.muted)
        }.padding(.top, 7)
      }.padding(.horizontal, 30).padding(.top, 12).padding(.bottom, 12)
      if let me = game.me, me.down {
        VStack(spacing: 8) {
          Text("HERO DOWN").font(.system(size: 23, weight: .black, design: .rounded))
            .foregroundStyle(.orange)
          Text("Your ally can hold REVIVE nearby").font(.system(size: 12, weight: .bold))
          ProgressView(value: me.revive).tint(.green).frame(width: 200)
        }.padding(20).background(Palette.panel.opacity(0.9))
      }
      if game.automation {
        VStack {
          Spacer()
          driverBanner
          Spacer().frame(height: 146)
        }
      }
    }
  }

  private var driverBanner: some View {
    Text("AUTOMATED INPUT  •  \(game.driverStep)")
      .font(.system(size: 8, weight: .bold, design: .monospaced))
      .foregroundStyle(Palette.gold).padding(.horizontal, 12).padding(.vertical, 5)
      .background(Palette.panel.opacity(0.9)).allowsHitTesting(false)
  }

  private func heroPanel(_ hero: Hero, local: Bool) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack {
        Text("P\(hero.slot + 1) \(hero.name.uppercased())")
          .font(.system(size: 11, weight: .black, design: .monospaced)).lineLimit(1)
        Spacer()
        Text(local ? "YOU" : "ALLY").font(.system(size: 7, weight: .heavy, design: .monospaced))
          .foregroundStyle(Palette.muted)
      }
      HStack(spacing: 3) {
        ForEach(0..<5) { index in
          PixelHeart().fill(
            Double(hero.hp) / Double(hero.maxHP) > Double(index) / 5
              ? Color(red: 0.97, green: 0.32, blue: 0.29) : .gray.opacity(0.3)
          )
          .frame(width: 16, height: 14)
        }
        Text("\(hero.hp)/\(hero.maxHP)").font(.system(size: 9, weight: .bold, design: .monospaced))
      }
      HStack(spacing: 10) {
        Text("◆ \(hero.gems)").foregroundStyle(.green)
        Text("SCORE \(hero.score)").foregroundStyle(.white)
      }.font(.system(size: 9, weight: .heavy, design: .monospaced))
    }.padding(9).frame(width: 190).background(Palette.panel.opacity(0.86))
      .overlay(alignment: .leading) {
        Rectangle().fill(hero.slot == 0 ? Palette.blue : Palette.gold).frame(width: 3)
      }
  }

  private func gearCard(_ label: String, item: String, glyph: String, color: Color) -> some View {
    Button {
      game.gearOpen = true
    } label: {
      VStack(spacing: 3) {
        Text(label).font(.system(size: 8, weight: .black, design: .monospaced)).foregroundStyle(
          color)
        GearGlyph(kind: glyph, color: color).frame(width: 30, height: 30)
        Text(item.uppercased()).font(.system(size: 7, weight: .heavy, design: .monospaced))
          .lineLimit(1)
      }.foregroundStyle(.white).frame(width: 58, height: 69)
        .background(Palette.panel.opacity(0.9))
        .overlay(Rectangle().stroke(color.opacity(0.65), lineWidth: 2))
    }.accessibilityLabel("Inspect \(label.lowercased()) card")
  }

  private func actionButton(
    _ label: String, icon: String, action: String, color: Color,
    small: Bool = false, large: Bool = false, cooldown: Int = 0
  ) -> some View {
    VStack(spacing: 3) {
      Image(systemName: icon).font(.system(size: small ? 14 : large ? 25 : 22, weight: .bold))
      Text(cooldown > 0 ? "\(cooldown)s" : label)
        .font(.system(size: small ? 8 : 9, weight: .black, design: .monospaced))
    }
    .foregroundStyle(cooldown > 0 ? color.opacity(0.5) : color)
    .frame(width: small ? 75 : large ? 72 : 60, height: small ? 36 : large ? 72 : 62)
    .background(Palette.panel.opacity(0.91))
    .overlay(
      RoundedRectangle(cornerRadius: 6).stroke(
        color.opacity(cooldown > 0 ? 0.25 : 0.8), lineWidth: 2)
    )
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in game.hold(action, down: true) }
        .onEnded { _ in game.hold(action, down: false) }
    )
    .accessibilityLabel(label.capitalized)
    .accessibilityAddTraits(.isButton)
    .accessibilityAction { game.perform(action) }
  }

  private var gearPicker: some View {
    VStack(spacing: 13) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("THE RELIQUARY").font(.system(size: 23, weight: .black, design: .rounded))
          Text(
            game.nearChest == nil
              ? "Find a cache after clearing a seal to claim a card."
              : "One card per hero, per cache. Choose your advantage."
          )
          .font(.system(size: 11)).foregroundStyle(Palette.muted)
        }
        Spacer()
        Button("CLOSE") { game.gearOpen = false }.font(.system(size: 11, weight: .bold))
          .foregroundStyle(Palette.gold)
      }
      HStack(spacing: 10) {
        choiceCard(
          "cleaver", title: "SUN CLEAVER", detail: "36 melee damage\nWide cleaving arcs",
          glyph: "sword", color: .orange)
        choiceCard(
          "storm", title: "STORM BLADE", detail: "24 melee damage\nFaster attacks", glyph: "sword",
          color: .purple)
        choiceCard(
          "ember", title: "EMBER BOW", detail: "38 arrow damage\nSearing projectiles", glyph: "bow",
          color: .red)
        choiceCard(
          "swift", title: "SWIFT BOW", detail: "Rapid arrow volley\nReduced cooldown", glyph: "bow",
          color: .green)
        choiceCard(
          "guardian", title: "WARDEN MAIL", detail: "+20 max health\n35% less damage",
          glyph: "armor", color: Palette.blue)
      }
      Text(
        "Equipped: \(game.me?.weapon ?? "iron")  /  \(game.me?.bow ?? "oak")  /  \(game.me?.armor ?? "scout")"
      )
      .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(Palette.muted)
    }.padding(23).frame(width: 755).background(Palette.panel)
      .overlay(Rectangle().stroke(Palette.gold, lineWidth: 2))
  }

  private func choiceCard(
    _ choice: String, title: String, detail: String, glyph: String, color: Color
  ) -> some View {
    Button {
      game.equip(choice)
    } label: {
      VStack(spacing: 10) {
        Text("RARE GEAR").font(.system(size: 8, weight: .black, design: .monospaced))
          .foregroundStyle(color)
        GearGlyph(kind: glyph, color: color).frame(width: 48, height: 48)
        Text(title).font(.system(size: 10, weight: .black, design: .monospaced))
        Text(detail).font(.system(size: 10)).multilineTextAlignment(.center).foregroundStyle(
          Palette.muted)
        Text(game.nearChest == nil ? "LOCKED" : "EQUIP")
          .font(.system(size: 10, weight: .black, design: .monospaced)).foregroundStyle(color)
      }.foregroundStyle(.white).frame(width: 128, height: 188)
        .background(color.opacity(0.07)).overlay(
          Rectangle().stroke(color.opacity(0.6), lineWidth: 2))
    }.disabled(game.nearChest == nil).accessibilityLabel("Equip \(title)")
  }

  private var result: some View {
    VStack(spacing: 12) {
      Text("EXPEDITION \(game.state?.round ?? 1)").font(
        .system(size: 10, weight: .bold, design: .monospaced)
      )
      .tracking(3).foregroundStyle(Palette.gold)
      Text(game.state?.phase == "victory" ? "HOLLOWWOOD RESTORED" : "THE VANGUARD FALLS")
        .font(.system(size: 31, weight: .black, design: .rounded))
      Text(
        game.state?.phase == "victory"
          ? "Three seals broken. The Warden defeated. Together."
          : "No hero is left behind. Regroup and try again."
      )
      .font(.system(size: 12)).foregroundStyle(Palette.muted)
      HStack(spacing: 18) {
        ForEach(game.state?.players ?? []) { hero in
          VStack(spacing: 6) {
            Text(hero.name.uppercased()).font(
              .system(size: 16, weight: .black, design: .monospaced)
            )
            .foregroundStyle(hero.slot == 0 ? Palette.blue : Palette.gold)
            Text("\(hero.score)").font(.system(size: 30, weight: .black, design: .rounded))
            Text("\(hero.kills) DEFEATED   ◆ \(hero.gems) GEMS")
              .font(.system(size: 9, weight: .bold, design: .monospaced))
            Text(
              "\(hero.stats.hits) hits  ·  \(hero.stats.equipment) cards  ·  \(hero.stats.revive) revives"
            )
            .font(.system(size: 9)).foregroundStyle(Palette.muted)
            Text(hero.ready ? "READY FOR REMATCH" : "AWAITING REMATCH")
              .font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundStyle(
                hero.ready ? .green : Palette.muted)
          }.frame(width: 242, height: 125).background(.black.opacity(0.2))
        }
      }
      HStack(spacing: 18) {
        solidButton(
          game.me?.ready == true ? "CANCEL READY" : "REMATCH", icon: "arrow.clockwise",
          color: Palette.gold
        ) { game.ready() }
        .frame(width: 240)
        Button("LEAVE EXPEDITION") { game.leave() }.font(.system(size: 10, weight: .bold))
          .foregroundStyle(Palette.muted)
      }
      if game.automation { driverBanner }
    }.padding(22).background(Palette.panel.opacity(0.97))
      .overlay(Rectangle().stroke(Palette.gold.opacity(0.7), lineWidth: 2))
  }

  private var pause: some View {
    VStack(spacing: 12) {
      Text(game.connected ? "WAITING FOR YOUR ALLY" : "CONNECTION INTERRUPTED")
        .font(.system(size: 20, weight: .black, design: .rounded))
      Text("The dungeon is paused. Your hero and loot are preserved.")
        .font(.system(size: 12)).foregroundStyle(Palette.muted)
      solidButton("RECONNECT", icon: "network", color: Palette.blue) { game.reconnect() }.frame(
        width: 235)
      Button("Leave expedition") { game.leave() }.font(.system(size: 12)).foregroundStyle(
        Palette.muted)
    }.padding(30).background(Palette.panel).overlay(Rectangle().stroke(Palette.blue))
  }

  private func solidButton(
    _ title: String, icon: String, color: Color, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 7) {
        Image(systemName: icon)
        Text(title)
      }.font(.system(size: 11, weight: .black, design: .monospaced))
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .foregroundStyle(Palette.panel).background(color)
    }
  }
}

struct Joystick: View {
  let changed: (Double, Double) -> Void
  @State private var offset = CGSize.zero
  var body: some View {
    ZStack {
      Circle().fill(Palette.panel.opacity(0.65))
      Circle().stroke(.white.opacity(0.24), lineWidth: 2)
      Circle().stroke(.white.opacity(0.07), lineWidth: 15).padding(13)
      Image(systemName: "plus").font(.system(size: 36, weight: .ultraLight)).foregroundStyle(
        .white.opacity(0.15))
      Circle().fill(
        LinearGradient(
          colors: [Color(white: 0.42), Color(white: 0.17)],
          startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
      .frame(width: 40, height: 40).offset(offset)
    }.frame(width: 101, height: 101).contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0).onChanged { value in
          let dx = value.location.x - 50.5
          let dy = value.location.y - 50.5
          let distance = max(1, hypot(dx, dy) / 35)
          offset = CGSize(width: dx / distance, height: dy / distance)
          changed(Double(offset.width / 35), Double(offset.height / 35))
        }.onEnded { _ in
          offset = .zero
          changed(0, 0)
        }
      )
      .accessibilityLabel("Movement joystick")
  }
}

struct PixelHeart: Shape {
  func path(in rect: CGRect) -> Path {
    let points: [(CGFloat, CGFloat)] = [
      (0, 1), (1, 1), (1, 0), (3, 0), (3, 1), (4, 1),
      (4, 0), (6, 0), (6, 1), (7, 1), (7, 3), (6, 3), (6, 4),
      (5, 4), (5, 5), (4, 5), (4, 6), (3, 6), (3, 5), (2, 5),
      (2, 4), (1, 4), (1, 3), (0, 3),
    ]
    var path = Path()
    for (i, p) in points.enumerated() {
      let point = CGPoint(x: p.0 * rect.width / 7, y: p.1 * rect.height / 6)
      if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}

struct GearGlyph: View {
  let kind: String
  let color: Color
  var body: some View {
    Canvas { context, size in
      let unit = size.width / 12
      func pixel(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ fill: Color) {
        context.fill(
          Path(
            CGRect(
              x: CGFloat(x) * unit, y: CGFloat(y) * unit,
              width: CGFloat(w) * unit, height: CGFloat(h) * unit)), with: .color(fill))
      }
      if kind == "sword" {
        for i in 0..<7 { pixel(8 - i, 1 + i, 2, 2, .white.opacity(0.9)) }
        pixel(2, 7, 4, 1, color)
        pixel(3, 6, 1, 4, color)
        pixel(1, 9, 2, 2, Palette.gold)
      } else if kind == "bow" {
        for (x, y) in [(3, 1), (5, 2), (6, 3), (7, 4), (7, 5), (7, 6), (6, 7), (5, 8), (3, 9)] {
          pixel(x, y, 2, 2, Palette.gold)
        }
        pixel(3, 1, 1, 10, .white.opacity(0.7))
        pixel(1, 5, 10, 1, color)
        pixel(9, 4, 2, 3, .white)
      } else if kind == "armor" {
        pixel(3, 2, 6, 8, color)
        pixel(1, 2, 2, 4, .gray)
        pixel(9, 2, 2, 4, .gray)
        pixel(5, 1, 2, 3, Palette.panel)
        pixel(4, 4, 4, 3, .white.opacity(0.5))
        pixel(3, 9, 6, 1, Palette.gold)
      } else {
        pixel(3, 2, 6, 8, color)
        pixel(2, 3, 8, 6, color)
        pixel(5, 1, 2, 10, .white.opacity(0.7))
        pixel(1, 5, 10, 2, .white.opacity(0.7))
        pixel(4, 4, 4, 4, color)
        pixel(5, 5, 2, 2, .white)
      }
    }
  }
}
