import SwiftUI

struct LockerView: View {
  @EnvironmentObject private var profile: Profile
  @EnvironmentObject private var session: Session
  let catalogue: Catalogue
  @State private var slot: CosmeticSlot = .outfit
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Locker").font(.custom("Rajdhani-Bold", size: 34))
      Text("Original Lastfort cosmetics. Unlock more through the pass.").foregroundStyle(.secondary)
      Picker("Cosmetic category", selection: $slot) {
        ForEach(CosmeticSlot.allCases, id: \.self) {
          Text($0 == .pickaxe ? "Tool" : $0.rawValue.capitalized).tag($0)
        }
      }.pickerStyle(.segmented)
      if let equipped = catalogue.cosmetic(profile.data.loadout[slot]) {
        HStack {
          CosmeticArt(cosmetic: equipped).frame(width: 140, height: 170)
          VStack(alignment: .leading, spacing: 8) {
            Text("EQUIPPED").foregroundStyle(Color.fortTeal)
            Text(equipped.name).font(.custom("Rajdhani-Bold", size: 28))
            Text(equipped.rarity.rawValue.uppercased()).foregroundStyle(
              Color(rgb: equipped.rarity.rgb))
            Text(equipped.description).foregroundStyle(.secondary)
          }
        }
      }
      LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 140, maximum: 210), spacing: 14)], spacing: 14
      ) {
        ForEach(catalogue.cosmetics.filter { $0.slot == slot }) { cosmetic in
          let owned = profile.data.unlocked.contains(cosmetic.id)
          let selected = profile.data.loadout[slot] == cosmetic.id
          Button {
            profile.data.loadout[slot] = cosmetic.id
            session.updateIdentity()
          } label: {
            VStack(spacing: 7) {
              CosmeticArt(cosmetic: cosmetic).frame(height: 145)
              Text(cosmetic.name).font(.custom("Rajdhani-Bold", size: 19))
              Text(
                selected
                  ? "EQUIPPED"
                  : owned
                    ? "EQUIP"
                    : "TIER \(catalogue.tiers.first { $0.rewardId == cosmetic.id }?.tier ?? 0)"
              )
              .font(.custom("Rajdhani-SemiBold", size: 13)).foregroundStyle(
                Color(rgb: cosmetic.rarity.rgb))
            }.padding(12).frame(maxWidth: .infinity)
              .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
              .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(
                  selected ? Color.fortTeal : Color(rgb: cosmetic.rarity.rgb).opacity(0.3),
                  lineWidth: 2))
          }.buttonStyle(.plain).disabled(!owned || selected).opacity(owned ? 1 : 0.55)
        }
      }
    }
  }
}
struct PassView: View {
  @EnvironmentObject private var profile: Profile
  let catalogue: Catalogue
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Season pass").font(.custom("Rajdhani-Bold", size: 34))
      Text(
        "Earn XP from placement, eliminations, damage and survival. Claim rewards as you tier up."
      ).foregroundStyle(.secondary)
      HStack {
        Text("TIER \(min(11, profile.data.xp / 300))").font(.custom("Rajdhani-Bold", size: 36))
          .foregroundStyle(Color.fortTeal)
        Spacer()
        Text("\(profile.data.xp) XP").font(.custom("Rajdhani-Bold", size: 25))
      }
      ProgressView(value: min(Double(profile.data.xp), 3300), total: 3300).tint(.fortTeal)
      if catalogue.tiers.contains(where: {
        profile.data.xp >= $0.xpRequired && !profile.data.claimed.contains($0.tier)
      }) {
        Button("Claim available rewards") {
          for tier in catalogue.tiers { profile.data.claim(tier) }
        }.buttonStyle(FortButtonStyle(primary: true))
      }
      ScrollView(.horizontal) {
        HStack(spacing: 14) {
          ForEach(catalogue.tiers) { tier in
            if let reward = catalogue.cosmetic(tier.rewardId) {
              VStack(spacing: 8) {
                Text("TIER \(tier.tier)").font(.custom("Rajdhani-Bold", size: 22))
                CosmeticArt(cosmetic: reward).frame(width: 130, height: 140)
                Text(reward.name).font(.custom("Rajdhani-Bold", size: 19))
                Text("\(tier.xpRequired) XP").foregroundStyle(.secondary)
                Button(profile.data.claimed.contains(tier.tier) ? "Claimed" : "Claim") {
                  profile.data.claim(tier)
                }
                .buttonStyle(FortButtonStyle()).disabled(
                  profile.data.xp < tier.xpRequired || profile.data.claimed.contains(tier.tier))
              }.padding(14).frame(width: 185).background(
                .primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            }
          }
        }.padding(.vertical, 8)
      }
      Text("CAREER").font(.custom("Rajdhani-Bold", size: 24))
      let career = profile.data.career
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))]) {
        StatTile(label: "MATCHES", value: "\(career.matches)")
        StatTile(label: "VICTORIES", value: "\(career.wins)", color: .fortWarning)
        StatTile(label: "ELIMINATIONS", value: "\(career.kills)", color: .fortEmber)
        StatTile(label: "DAMAGE", value: "\(career.damage)")
        StatTile(label: "HARVESTED", value: "\(career.harvested)")
        StatTile(label: "BUILT", value: "\(career.built)")
        StatTile(
          label: "BEST PLACE", value: career.bestPlacement == 0 ? "—" : "#\(career.bestPlacement)")
      }
    }
  }
}
struct StatTile: View {
  let label, value: String
  var color: Color = .fortTeal
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label).font(.custom("Rajdhani-SemiBold", size: 13)).foregroundStyle(.secondary)
      Text(value).font(.custom("Rajdhani-Bold", size: 31)).foregroundStyle(color)
    }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(
      .primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
  }
}
struct SettingsView: View {
  @EnvironmentObject private var profile: Profile
  @EnvironmentObject private var session: Session
  @State private var server = ""
  @State private var name = ""
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("Settings").font(.custom("Rajdhani-Bold", size: 34))
      Text("PROFILE").font(.custom("Rajdhani-SemiBold", size: 16)).foregroundStyle(Color.fortTeal)
      TextField("Display name", text: $name).textFieldStyle(.roundedBorder)
      Button("Save name") {
        profile.data.name = String(name.trimmingCharacters(in: .whitespaces).prefix(24))
        session.updateIdentity()
      }
      .buttonStyle(FortButtonStyle()).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
      Divider()
      Text("APPEARANCE & FEEDBACK").font(.custom("Rajdhani-SemiBold", size: 16)).foregroundStyle(
        Color.fortTeal)
      Picker("Theme", selection: $profile.data.theme) {
        Text("System").tag("system")
        Text("Dark").tag("dark")
        Text("Light").tag("light")
      }.pickerStyle(.segmented)
      Toggle("Reduce motion", isOn: $profile.data.reducedMotion)
      Toggle("Sound feedback", isOn: $profile.data.sound)
      Toggle("Haptic feedback", isOn: $profile.data.haptics)
      Divider()
      Text("CONNECTION").font(.custom("Rajdhani-SemiBold", size: 16)).foregroundStyle(
        Color.fortTeal)
      TextField("WebSocket server URL", text: $server).textFieldStyle(.roundedBorder)
        #if os(iOS)
          .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
        #endif
      Text(
        "Local development: ws://your-mac-lan-address:8787/ws. Secure remote servers use wss://. Reconnect tokens are stored in this device’s Keychain per server."
      ).foregroundStyle(.secondary)
      ViewThatFits {
        HStack { serverButtons }
        VStack(alignment: .leading) { serverButtons }
      }
      Text("Status: \(session.connection.rawValue) · \(session.latency) ms").foregroundStyle(
        .secondary)
      if session.room != nil {
        Text(
          "Changing servers leaves the current connection. Your existing match can be resumed when you reconnect to that server."
        ).foregroundStyle(.secondary)
      }
    }.frame(maxWidth: 720, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
      .onAppear {
        server = profile.data.server
        name = profile.data.name
      }
  }
  @ViewBuilder private var serverButtons: some View {
    Button("Apply & reconnect") {
      profile.data.server = server.trimmingCharacters(in: .whitespaces)
      session.connect()
    }.buttonStyle(FortButtonStyle(primary: true))
    Button("Reset address") { server = "ws://localhost:8787/ws" }.buttonStyle(FortButtonStyle())
  }
}
struct ResultsView: View {
  @EnvironmentObject private var session: Session
  @EnvironmentObject private var profile: Profile
  let summary: MatchSummary
  let playerID: Int
  var body: some View {
    let row = summary.players.first { $0.id == playerID }
    let won = row?.team == summary.winnerTeam
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        Text(won ? "#1 VICTORY" : "PLACED #\(row?.placement ?? 0)")
          .font(.custom("Rajdhani-Bold", size: 54)).foregroundStyle(
            won ? Color.fortWarning : .white)
        Text(won ? "YOUR FORT WAS THE LAST ONE STANDING." : "ANOTHER DROP. ANOTHER CHANCE.")
          .font(.custom("Rajdhani-SemiBold", size: 18)).tracking(2)
        Text(
          "\(summary.mode.rawValue.uppercased()) · SEED \(summary.seed) · \(summary.endTick) TICKS"
        ).foregroundStyle(.secondary)
        if let row {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))]) {
            StatTile(label: "ELIMINATIONS", value: "\(row.kills)", color: .fortEmber)
            StatTile(label: "DAMAGE", value: "\(row.damage)")
            StatTile(label: "HARVESTED", value: "\(row.harvested)")
            StatTile(label: "BUILT", value: "\(row.built)")
            StatTile(label: "CHESTS", value: "\(row.chests)")
            StatTile(
              label: "SURVIVED",
              value: "\(row.survived / 60):\(String(format: "%02d", row.survived % 60))")
          }
          Text("+\(row.xp) XP").font(.custom("Rajdhani-Bold", size: 37)).foregroundStyle(
            Color.fortTeal)
          Text("TIER \(min(11, profile.data.xp / 300)) · \(profile.data.xp) TOTAL XP")
        }
        HStack {
          if session.isHost {
            Button("Play again · return to lobby") { session.returnToLobby() }.buttonStyle(
              FortButtonStyle(primary: true))
          } else {
            Text("Waiting for the host to return to the lobby.").foregroundStyle(.secondary)
          }
          Button("Leave") { session.leave() }.buttonStyle(FortButtonStyle())
        }
        Text("MATCH STANDINGS").font(.custom("Rajdhani-Bold", size: 24))
        ForEach(
          summary.players.sorted {
            $0.placement == $1.placement ? $0.id < $1.id : $0.placement < $1.placement
          }
        ) { player in
          HStack {
            Text("#\(player.placement)").frame(width: 40)
            VStack(alignment: .leading) {
              Text(player.name + (player.id == playerID ? " · You" : ""))
              Text("Team \(player.team + 1) · \(player.bot ? "BOT" : player.platform.uppercased())")
                .font(.custom("Rajdhani-Medium", size: 13)).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(player.kills) ELIMS · \(player.xp) XP")
          }.padding(12).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
      }.padding(24).frame(maxWidth: 1050).frame(maxWidth: .infinity)
    }.foregroundStyle(.white).background(
      LinearGradient(
        colors: [.fortSurface, .fortBackground], startPoint: .topLeading, endPoint: .bottomTrailing)
    )
  }
}
