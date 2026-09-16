import AudioToolbox
import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

struct MatchView: View {
  @EnvironmentObject private var session: Session
  @EnvironmentObject private var profile: Profile
  @Environment(\.scenePhase) private var scenePhase
  @ObservedObject var match: MatchReplica
  let catalogue: Catalogue
  @StateObject private var controls = Controls()
  @State private var fullMap = false
  @StateObject private var terrain: TerrainImage
  init(match: MatchReplica, catalogue: Catalogue) {
    self.match = match
    self.catalogue = catalogue
    _terrain = StateObject(wrappedValue: TerrainImage(match.island))
  }
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        GameCanvas(
          match: match, catalogue: catalogue, terrain: terrain,
          reducedMotion: profile.data.reducedMotion, aim: controls.aim)
        #if os(macOS)
          DesktopInput(controls: controls).id(controls.menu)
        #endif
        VStack(spacing: 8) {
          if geometry.size.height < 500 { compactTopHUD } else { topHUD }
          if let me = match.me {
            if me.s == .inBus {
              Button("DROP FROM BUS · \(Int(match.state?.bus?.rem ?? 0))s") {
                controls.queue(.jump)
              }
              .buttonStyle(FortButtonStyle(primary: true))
            } else if me.s == .dropping {
              Text(me.alt > 0.35 ? "FREEFALL · STEER TO YOUR LANDING" : "GLIDING").hudPanel()
            } else if me.s == .eliminated {
              HStack {
                Text("SPECTATING \(match.target?.n ?? "SURVIVORS")")
                Button("Next") { controls.queue(.spectateNext) }
              }.hudPanel()
            }
            if let storm = match.state?.storm, !storm.contains(me.x, me.y), me.s == .alive {
              Text("IN THE STORM · \(Int(storm.dps)) DAMAGE / SECOND").foregroundStyle(
                Color.fortWarning
              ).hudPanel()
            }
          }
          Spacer(minLength: 0)
          #if os(iOS)
            touchHUD(compact: geometry.size.height < 500)
          #endif
          bottomHUD
        }.padding(12)
        if session.connection != .connected {
          VStack(spacing: 12) {
            ProgressView()
            Text("Connection lost · attempting to resume")
            Button("Reconnect now") {
              controls.reset()
              session.connect()
            }.buttonStyle(FortButtonStyle())
            Button("Leave match") { session.leave() }.buttonStyle(FortButtonStyle())
          }.padding(24).background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        if controls.menu { menu }
      }
      .task(id: geometry.size) { await inputLoop(size: geometry.size) }
      .onChange(of: geometry.size) { _, _ in controls.pointer = nil }
      .onChange(of: match.me?.hp) { old, new in
        if let old, let new, new < old { feedback() }
      }
    }.foregroundStyle(.white).background(Color.fortBackground)
      .onDisappear { controls.reset() }
      .onChange(of: scenePhase) { _, phase in if phase != .active { controls.reset() } }
      .sheet(isPresented: $fullMap) {
        VStack {
          HStack {
            Text("ISLAND MAP").font(.custom("Rajdhani-Bold", size: 28))
            Spacer()
            Button("Close") { fullMap = false }
          }
          IslandMap(match: match, terrain: terrain, detailed: true).aspectRatio(
            1, contentMode: .fit)
          Text("White: next storm eye · Purple: current eye · Teal: your squad").font(
            .custom("Rajdhani-Medium", size: 16))
        }.padding(20).frame(idealWidth: 750, idealHeight: 800).background(Color.fortBackground)
          .foregroundStyle(.white)
      }
  }
  private var compactTopHUD: some View {
    HStack {
      Button {
        controls.menu = true
        controls.reset()
      } label: {
        Image(systemName: "line.3.horizontal")
      }.hudPanel()
      Text(compass).hudPanel()
      Spacer(minLength: 0)
      Text("\(match.state?.alive ?? match.players.count) ALIVE").hudPanel()
      if let storm = match.state?.storm {
        Text("STORM \(storm.ph + 1) · \(Int(ceil(storm.rem)))s").hudPanel()
      }
      Button {
        fullMap = true
        controls.reset()
      } label: {
        IslandMap(match: match, terrain: terrain, detailed: false).frame(width: 58, height: 58)
      }.buttonStyle(.plain).accessibilityLabel("Open island map")
    }.font(.custom("Rajdhani-Bold", size: 13))
  }
  private var topHUD: some View {
    HStack(alignment: .top, spacing: 8) {
      VStack(alignment: .leading, spacing: 6) {
        Button {
          controls.menu = true
          controls.reset()
        } label: {
          Label("Menu", systemImage: "line.3.horizontal")
        }.hudPanel()
        Text(compass).font(.custom("Rajdhani-Bold", size: 18)).hudPanel()
        ForEach(Array(match.feed.prefix(3).enumerated()), id: \.offset) { _, item in
          Text(item).font(.custom("Rajdhani-Medium", size: 12)).lineLimit(1).hudPanel()
        }
      }
      Spacer(minLength: 0)
      VStack(alignment: .trailing, spacing: 4) {
        Button {
          fullMap = true
          controls.reset()
        } label: {
          IslandMap(match: match, terrain: terrain, detailed: false).frame(width: 112, height: 112)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.5)))
        }.buttonStyle(.plain).accessibilityLabel("Open island map")
        Text("\(match.state?.alive ?? match.players.count) ALIVE · \(match.me?.k ?? 0) ELIMS")
          .font(.custom("Rajdhani-Bold", size: 13)).hudPanel()
        if let storm = match.state?.storm {
          Text(
            "STORM \(storm.ph + 1) · \(storm.sh ? "SHRINKING" : "WAIT") \(Int(ceil(storm.rem)))s"
          )
          .font(.custom("Rajdhani-Bold", size: 12)).hudPanel()
        }
      }
    }
  }
  private var compass: String {
    let angle = ((controls.aim * 180 / .pi + 90).truncatingRemainder(dividingBy: 360) + 360)
      .truncatingRemainder(dividingBy: 360)
    let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    return "\(directions[Int((angle + 22.5) / 45) % 8])  \(Int(angle))°"
  }
  private var bottomHUD: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let me = match.me {
        HStack(spacing: 10) {
          VStack(alignment: .leading, spacing: 3) {
            Text("SHIELD \(me.sh)    HEALTH \(me.hp)").font(.custom("Rajdhani-Bold", size: 13))
            ProgressView(value: Double(me.sh), total: 100).tint(.fortShield)
            ProgressView(value: Double(me.hp), total: 100).tint(.fortHealth)
          }.frame(maxWidth: 250).hudPanel()
          Spacer(minLength: 2)
          Button {
            controls.material()
          } label: {
            VStack(alignment: .trailing, spacing: 2) {
              ForEach(BuildingMaterial.allCases, id: \.self) { material in
                Text("\(material.rawValue.uppercased()) \(me.mats?[safe: material.index] ?? 0)")
                  .foregroundStyle((me.bmat ?? .wood) == material ? Color.fortTeal : .white)
              }
            }.font(.custom("Rajdhani-Bold", size: 12))
          }.hudPanel()
        }
        if me.rl || me.us {
          Text(
            me.rl
              ? "RELOADING \(String(format: "%.1f", me.rlt ?? 0))s"
              : "USING \(me.selectedItem?.label ?? "ITEM") \(String(format: "%.1f", me.ust ?? 0))s"
          )
          .font(.custom("Rajdhani-Bold", size: 14)).hudPanel()
        }
        HStack(spacing: 4) {
          ForEach(0..<6) { slot in
            let item = me.inv?[safe: slot] ?? nil
            Button {
              controls.queue(.select, slot: slot)
            } label: {
              VStack(spacing: 3) {
                Image(
                  systemName: slot == 0
                    ? "hammer.fill"
                    : item?.t == .weapon
                      ? "scope" : item?.t == .consumable ? "cross.case.fill" : "square.dashed"
                )
                .font(.system(size: 18))
                Text(slot == 0 ? "PICK" : item?.label.uppercased() ?? "EMPTY")
                  .font(.custom("Rajdhani-Bold", size: 10)).lineLimit(1).minimumScaleFactor(0.6)
                Text(
                  item?.t == .weapon
                    ? "\(item?.l ?? 0) / \(me.ammo?[item?.w?.ammo ?? ""] ?? 0)"
                    : item.map { "×\($0.n)" } ?? "\(slot + 1)"
                )
                .font(.custom("Rajdhani-Medium", size: 11))
              }.frame(maxWidth: .infinity).frame(height: 60).padding(3)
                .background(
                  Color.fortBackground.opacity(0.88), in: RoundedRectangle(cornerRadius: 7)
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 7).stroke(
                    me.slot == slot
                      ? Color.fortTeal : Color(rgb: (item?.r ?? .common).rgb).opacity(0.6),
                    lineWidth: me.slot == slot ? 3 : 1))
            }.buttonStyle(.plain).accessibilityLabel(
              "Slot \(slot + 1), \(item?.label ?? (slot == 0 ? "Pickaxe" : "Empty"))")
          }
        }.frame(maxWidth: 560).frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
  }
  private func touchHUD(compact: Bool) -> some View {
    HStack(alignment: .bottom, spacing: 10) {
      if compact { moveStick(diameter: 70) }
      VStack(spacing: 8) {
        touchActions
        if !compact {
          HStack {
            moveStick(diameter: 96)
            Spacer()
            aimStick(diameter: 96)
          }.padding(.horizontal, 12).padding(.bottom, 18)
        }
      }
      if compact { aimStick(diameter: 70) }
    }.padding(.bottom, compact ? 18 : 0)
  }
  private func moveStick(diameter: Double) -> some View {
    TouchStick(label: "MOVE", diameter: diameter) { controls.move = $0 }
  }
  private func aimStick(diameter: Double) -> some View {
    TouchStick(label: match.me?.bm == true ? "AIM / BUILD" : "AIM / FIRE", diameter: diameter) {
      vector in
      controls.pointer = nil
      if hypot(vector.dx, vector.dy) > 0.1 { controls.aim = atan2(vector.dy, vector.dx) }
      controls.fire = hypot(vector.dx, vector.dy) > 0.35
    }
  }
  private var touchActions: some View {
    VStack(spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          touchButton("Interact", "hand.tap") { controls.queue(.interact) }
          touchButton("Jump", "arrow.up") { controls.queue(.jump) }
          touchButton(controls.sprint ? "Walking" : "Sprint", "figure.run") {
            controls.sprint.toggle()
          }
          touchButton(match.me?.bm == true ? "Combat" : "Build", "square.stack.3d.up") {
            controls.toggleBuild()
          }
          touchButton("Reload", "arrow.clockwise") { controls.queue(.reload) }
          touchButton("Use", "cross.case") { controls.queue(.use, slot: match.me?.slot) }
          touchButton("Drop item", "arrow.down.square") {
            controls.queue(.drop, slot: match.me?.slot)
          }
          touchButton("Emote", "sparkles") { controls.queue(.emote) }
          touchButton("Thank", "hand.wave") { controls.queue(.thank) }
        }
      }
      if match.me?.bm == true {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 6) {
            ForEach(Piece.allCases, id: \.self) { piece in
              Button(piece.rawValue.capitalized) { controls.piece(piece) }.hudPanel()
            }
            Menu("Edit") {
              ForEach(PieceEdit.allCases, id: \.self) { edit in
                Button(edit.rawValue.capitalized) { controls.queue(.edit, value: edit.rawValue) }
              }
              Button("Rotate ramp") { controls.queue(.edit, value: "none") }
            }.hudPanel()
            Button("Place") { controls.queue(.place) }.hudPanel()
          }.font(.custom("Rajdhani-Bold", size: 14))
        }
      }
    }
  }
  private func touchButton(_ label: String, _ icon: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      VStack(spacing: 2) {
        Image(systemName: icon)
        Text(label).font(.custom("Rajdhani-Bold", size: 11))
      }
      .frame(minWidth: 46, minHeight: 38)
    }.hudPanel()
  }
  private var menu: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 15) {
        Text("MATCH MENU").font(.custom("Rajdhani-Bold", size: 30))
        Text("Room \(match.start.code) · \(session.latency) ms")
        Button("Resume match") { controls.menu = false }.buttonStyle(FortButtonStyle(primary: true))
        Text("SQUAD").font(.custom("Rajdhani-Bold", size: 17))
        ForEach(match.players.values.filter { $0.t == match.me?.t }.sorted { $0.id < $1.id }) {
          player in
          Text("\(player.n) · \(player.s.rawValue) · \(player.hp) HP / \(player.sh) SH")
        }
        Toggle(
          "Server autopilot",
          isOn: Binding(get: { session.autopilot }, set: { session.setAutopilot($0) }))
        Toggle("Reduce motion", isOn: $profile.data.reducedMotion)
        Toggle("Sound", isOn: $profile.data.sound)
        if session.options["TEST"] != nil {
          Toggle(
            "Pause server simulation",
            isOn: Binding(
              get: { session.testPaused },
              set: {
                session.testPaused = $0
                session.control($0 ? "pause" : "resume")
              }))
          Button("Step 100 ticks") { session.control("step", count: 100) }.buttonStyle(
            FortButtonStyle())
        }
        Button("Leave match") {
          controls.reset()
          session.leave()
        }.buttonStyle(FortButtonStyle())
      }.padding(24).frame(maxWidth: 420).background(
        Color.fortBackground.opacity(0.97), in: RoundedRectangle(cornerRadius: 18))
    }.frame(maxWidth: 460).padding(20)
  }
  private func inputLoop(size: CGSize) async {
    while !Task.isCancelled {
      let step = match.start.rules.dt
      try? await Task.sleep(for: .seconds(step))
      if Task.isCancelled { return }
      controls.player = match.me
      if let pointer = controls.pointer, let me = match.me {
        let world = Camera(match: match, size: size).world(pointer)
        controls.aim = atan2(world.y - me.y, world.x - me.x)
      }
      guard session.connection == .connected, !session.autopilot else {
        _ = controls.drain()
        continue
      }
      let active = scenePhase == .active && !controls.menu && !fullMap
      if let frame = match.input(
        mx: active ? controls.move.dx : 0, my: active ? controls.move.dy : 0,
        aim: controls.aim, fire: active && controls.fire, sprint: active && controls.sprint,
        actions: active ? controls.drain() : [])
      {
        var message = ClientMessage(.input)
        message.f = frame
        await session.sendAwaited(message)
      }
    }
  }
  private func feedback() {
    #if os(iOS)
      if profile.data.haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    #endif
    if profile.data.sound {
      #if os(macOS)
        NSSound(named: "Pop")?.play()
      #else
        AudioServicesPlaySystemSound(1104)
      #endif
    }
  }
}
extension View {
  fileprivate func hudPanel() -> some View {
    padding(.horizontal, 9).padding(.vertical, 6)
      .background(Color.fortBackground.opacity(0.82), in: RoundedRectangle(cornerRadius: 7))
  }
}
struct IslandMap: View {
  @ObservedObject var match: MatchReplica
  let terrain: TerrainImage
  let detailed: Bool
  var body: some View {
    Canvas { context, size in
      let side = min(size.width, size.height)
      let scale = side / match.start.rules.mapSize
      if let image = terrain.image {
        context.draw(
          Image(decorative: image, scale: 1), in: CGRect(x: 0, y: 0, width: side, height: side))
      }
      if let storm = match.state?.storm {
        let current = CGRect(
          x: (storm.cx - storm.r) * scale, y: (storm.cy - storm.r) * scale,
          width: storm.r * 2 * scale, height: storm.r * 2 * scale)
        var path = Path(CGRect(origin: .zero, size: size))
        path.addEllipse(in: current)
        context.fill(path, with: .color(.fortStorm.opacity(0.45)), style: FillStyle(eoFill: true))
        context.stroke(Path(ellipseIn: current), with: .color(.fortStorm), lineWidth: 2)
        let target = CGRect(
          x: (storm.tx - storm.tr) * scale, y: (storm.ty - storm.tr) * scale,
          width: storm.tr * 2 * scale, height: storm.tr * 2 * scale)
        context.stroke(Path(ellipseIn: target), with: .color(.white), lineWidth: 1)
      }
      if let bus = match.state?.bus {
        context.line(
          [
            CGPoint(x: bus.x0 * scale, y: bus.y0 * scale),
            CGPoint(x: bus.x1 * scale, y: bus.y1 * scale),
          ], .white, width: 1)
        context.ellipse(bus.x * scale, bus.y * scale, 7, 7, .fortEmber)
      }
      for player in match.players.values where player.id == match.localID || player.t == match.me?.t
      {
        if player.s != .eliminated {
          context.ellipse(
            player.x * scale, player.y * scale, detailed ? 8 : 4, detailed ? 8 : 4,
            player.id == match.localID ? .white : .fortTeal)
        }
      }
      if detailed {
        for poi in match.island.pois {
          context.label(
            poi.name.uppercased(), poi.x * scale, poi.y * scale, size: max(9, side / 42))
        }
      }
    }.clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityLabel(
      "Island, storm eye and squad positions")
  }
}
