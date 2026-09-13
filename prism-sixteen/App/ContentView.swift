import SwiftUI

private let mint = Color(red: 0.36, green: 1, blue: 0.88)
private let rose = Color(red: 1, green: 0.35, blue: 0.67)
private let muted = Color(red: 0.48, green: 0.59, blue: 0.63)

struct ContentView: View {
  @ObservedObject var model: GameModel

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color(red: 0.018, green: 0.032, blue: 0.052).ignoresSafeArea()
        RadialGradient(
          colors: [mint.opacity(0.07), .clear], center: .topLeading,
          startRadius: 5, endRadius: 450
        ).ignoresSafeArea()
        VStack(spacing: 0) {
          header
          if model.playing {
            match(height: geometry.size.height)
          } else {
            ScrollView {
              VStack(spacing: 22) {
                if model.room?.phase == "results" { results } else { selection }
                if model.room == nil { connectForm } else { lobby }
                if !model.error.isEmpty { errorMessage }
                footer
              }
              .padding(.horizontal, 22)
              .padding(.top, 14)
              .padding(.bottom, 24)
            }
          }
        }
      }
    }
    .sheet(isPresented: $model.showSettings) { settings }
    .sheet(isPresented: $model.showGuide) { guide }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 10) {
      Image(systemName: "square.grid.4x3.fill")
        .font(.system(size: 20)).foregroundStyle(mint)
      VStack(alignment: .leading, spacing: 1) {
        Text("PRISM").font(.system(size: 22, weight: .black, design: .rounded)).tracking(4)
        Text("S I X T E E N").font(.system(size: 8, weight: .bold)).foregroundStyle(muted)
      }
      Spacer()
      if let room = model.room {
        VStack(alignment: .trailing, spacing: 3) {
          Text(room.code).font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(mint)
          Text(model.connection == "LINKED" ? "● \(Int(model.latency)) ms LINK" : model.connection)
            .font(.system(size: 8, weight: .semibold, design: .monospaced)).foregroundStyle(muted)
        }
      } else {
        Button {
          model.showGuide = true
        } label: {
          Image(systemName: "questionmark.circle").font(.system(size: 20)).foregroundStyle(muted)
        }.accessibilityLabel("How to play").frame(width: 44, height: 44)
      }
      Button {
        model.showSettings = true
      } label: {
        Image(systemName: "slider.horizontal.3").font(.system(size: 18)).foregroundStyle(.white)
      }.accessibilityLabel("Settings").frame(width: 36, height: 44)
    }
    .padding(.horizontal, 22).padding(.vertical, 8)
    .background(.black.opacity(0.25))
    .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.09)).frame(height: 1) }
  }

  private var selection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        eyebrow("01 / SELECT A FREQUENCY")
        Spacer()
        Text("2 ORIGINAL TRACKS").font(.system(size: 8, weight: .bold, design: .monospaced))
          .foregroundStyle(muted)
      }
      if let song = model.song {
        ZStack(alignment: .bottomLeading) {
          cover(song.id)
            .frame(maxWidth: .infinity).frame(height: 252).clipped()
          LinearGradient(
            colors: [.clear, .black.opacity(0.88)],
            startPoint: .center, endPoint: .bottom)
          VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
              Text("ORIGINAL").font(.system(size: 8, weight: .heavy)).tracking(1)
                .padding(.horizontal, 6).padding(.vertical, 4).background(mint).foregroundStyle(
                  .black)
              Text("\(song.bpm) BPM").font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            Text(song.title).font(.system(size: 31, weight: .black, design: .rounded)).tracking(1)
            Text(song.tagline).font(.system(size: 12)).foregroundStyle(.white.opacity(0.65))
          }.padding(18)
          Button {
            model.preview()
          } label: {
            Image(systemName: model.isPreviewing ? "pause.fill" : "play.fill")
              .font(.system(size: 18)).foregroundStyle(.white)
              .frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
          }
          .accessibilityLabel(model.isPreviewing ? "Stop preview" : "Preview song")
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(14)
        }.clipShape(RoundedRectangle(cornerRadius: 8))
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.2), lineWidth: 1))
      }
      HStack(spacing: 9) {
        ForEach(model.songs) { song in
          Button {
            model.selectedSong = song.id
            model.select()
          } label: {
            HStack(spacing: 9) {
              cover(song.id).frame(width: 38, height: 38).clipped().cornerRadius(3)
              VStack(alignment: .leading, spacing: 3) {
                Text(song.title).font(.system(size: 10, weight: .heavy))
                Text("\(song.bpm) BPM · 0:\(Int(song.duration))")
                  .font(.system(size: 8, design: .monospaced)).foregroundStyle(muted)
              }
              Spacer(minLength: 0)
            }
            .padding(8)
            .background(model.selectedSong == song.id ? mint.opacity(0.09) : .white.opacity(0.035))
            .overlay(
              RoundedRectangle(cornerRadius: 6).stroke(
                model.selectedSong == song.id ? mint.opacity(0.65) : .white.opacity(0.08),
                lineWidth: 1))
          }.buttonStyle(.plain).disabled(model.room != nil && !model.host)
        }
      }
      difficultySelector
      densityBar
    }
  }

  private var difficultySelector: some View {
    HStack(spacing: 6) {
      ForEach(Array(["BASIC", "ADVANCED", "EXTREME"].enumerated()), id: \.element) { index, label in
        Button {
          model.difficulty = label
          model.select()
        } label: {
          HStack(spacing: 5) {
            Text("0\([3, 6, 9][index])").font(
              .system(size: 17, weight: .light, design: .monospaced))
            Text(label).font(.system(size: 8, weight: .black)).tracking(0.5)
          }
          .frame(maxWidth: .infinity).padding(.vertical, 12)
          .background(model.difficulty == label ? mint : .white.opacity(0.04))
          .foregroundStyle(model.difficulty == label ? Color.black : muted)
          .clipShape(RoundedRectangle(cornerRadius: 4))
        }.disabled(model.room != nil && !model.host)
      }
    }
  }

  private var densityBar: some View {
    VStack(spacing: 5) {
      GeometryReader { geometry in
        HStack(alignment: .bottom, spacing: 2) {
          ForEach(0..<48, id: \.self) { index in
            let total = model.song?.duration ?? 1
            let count = model.notes.filter {
              Int($0.time / total * 48) == index
            }.count
            Rectangle()
              .fill(
                Double(index) / 48 <= model.progress && model.playing ? mint : mint.opacity(0.3)
              )
              .frame(
                width: max(1, (geometry.size.width - 94) / 48),
                height: CGFloat(max(1, count)) * 2.2 + 2)
          }
        }.frame(maxHeight: .infinity, alignment: .bottom)
      }.frame(height: 22)
      HStack {
        Text("MUSIC BAR").tracking(1)
        Spacer()
        Text("\(model.notes.count) NOTES")
      }.font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundStyle(muted)
    }
  }

  private var connectForm: some View {
    VStack(alignment: .leading, spacing: 12) {
      eyebrow("02 / LINK UP")
      Text("One song. Two players.").font(.system(size: 22, weight: .semibold))
      TextField("Guest name", text: $model.name)
        .textContentType(.nickname).autocorrectionDisabled()
        .accessibilityIdentifier("guestName")
        .padding(14).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 6))
      HStack(spacing: 10) {
        TextField("ROOM CODE", text: $model.code)
          .textInputAutocapitalization(.characters).autocorrectionDisabled()
          .font(.system(size: 14, weight: .medium, design: .monospaced))
          .padding(14).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 6))
          .accessibilityIdentifier("roomCode")
        Button("JOIN") { model.connect(create: false) }
          .font(.system(size: 12, weight: .black)).foregroundStyle(mint)
          .padding(.horizontal, 24).frame(height: 46)
          .overlay(RoundedRectangle(cornerRadius: 6).stroke(mint.opacity(0.5)))
          .accessibilityIdentifier("joinRoom")
      }
      primary("CREATE A ROOM", icon: "arrow.up.right") { model.connect(create: true) }
        .accessibilityIdentifier("createRoom")
      Text("LOCAL NETWORK · NO ACCOUNT REQUIRED")
        .font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(
          muted
        )
        .frame(maxWidth: .infinity)
    }
  }

  private var lobby: some View {
    VStack(alignment: .leading, spacing: 13) {
      if model.room?.phase != "results" { eyebrow("02 / ROOM \(model.code)") }
      HStack(spacing: 12) {
        lobbyPeer(model.me, you: true)
        Text("×").foregroundStyle(muted)
        lobbyPeer(model.rival, you: false)
      }
      if model.automated {
        driverLabel
      }
      primary(
        model.me?.ready == true
          ? "READY · WAITING FOR RIVAL"
          : (model.room?.phase == "results" ? "REMATCH" : "READY TO SYNC"),
        icon: model.me?.ready == true ? "checkmark" : "bolt.fill"
      ) { model.ready() }
      .disabled(model.syncSamples < 3 || model.connection != "LINKED")
      .opacity(model.syncSamples < 3 ? 0.4 : 1)
      .accessibilityIdentifier("readyButton")
      HStack {
        Text(
          model.rival == nil
            ? "Share the code to connect player 2." : "The song begins when both players are ready."
        )
        .font(.system(size: 10)).foregroundStyle(muted)
        Spacer()
        Button("LEAVE") { model.leave() }
          .font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.6))
          .frame(minHeight: 44)
      }
    }
  }

  private func lobbyPeer(_ peer: Peer?, you: Bool) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Circle().fill(peer?.connected == true ? mint : muted).frame(width: 5, height: 5)
        Text(you ? "YOU" : "RIVAL").font(.system(size: 8, weight: .bold)).foregroundStyle(muted)
        Spacer()
      }
      Text(peer?.name ?? "Waiting…").font(.system(size: 17, weight: .semibold)).lineLimit(1)
      Text(
        peer?.ready == true
          ? "READY"
          : peer == nil ? "OPEN SLOT" : peer?.connected == true ? "CONNECTED" : "RECONNECTING"
      )
      .font(.system(size: 8, weight: .bold, design: .monospaced))
      .foregroundStyle(peer?.ready == true ? mint : muted)
    }.padding(13).frame(maxWidth: .infinity)
      .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 6))
      .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.08)))
  }

  private func match(height: CGFloat) -> some View {
    VStack(spacing: 12) {
      HStack(alignment: .top, spacing: 16) {
        scoreColumn(model.me, you: true)
        Rectangle().fill(.white.opacity(0.12)).frame(width: 1, height: 60)
        scoreColumn(model.rival, you: false)
      }.padding(.top, 12)
      HStack(spacing: 10) {
        cover(model.selectedSong).frame(width: 47, height: 47).clipped().cornerRadius(4)
        VStack(alignment: .leading, spacing: 4) {
          Text(model.song?.title ?? "").font(.system(size: 17, weight: .black, design: .rounded))
            .tracking(1)
          Text("\(model.difficulty)   /   \(model.song?.bpm ?? 128) BPM")
            .font(.system(size: 8, weight: .semibold, design: .monospaced)).foregroundStyle(muted)
        }
        Spacer()
        Text(timeRemaining).font(.system(size: 16, weight: .light, design: .monospaced))
          .foregroundStyle(mint)
      }
      densityBar
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 3) {
          Text("SHUTTER BONUS").font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(
            muted)
          HStack(spacing: 2) {
            ForEach(0..<16, id: \.self) { i in
              Rectangle().fill(
                Double(i) / 16 < (model.me?.shutter ?? 0) ? mint : .white.opacity(0.1)
              )
              .frame(width: 5, height: 13)
            }
          }
        }
        Spacer()
        if model.songTime < 0 {
          Text("START IN \(Int(ceil(-model.songTime)))")
            .font(.system(size: 22, weight: .black, design: .rounded)).foregroundStyle(mint)
        } else {
          HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("\(model.me?.combo ?? 0)")
              .font(.system(size: 32, weight: .light, design: .rounded)).monospacedDigit()
            Text("COMBO").font(.system(size: 8, weight: .bold)).foregroundStyle(muted)
          }
        }
      }.frame(height: 40)
      PanelBoard(model: model)
        .frame(maxWidth: min(height * 0.49, 430))
      HStack {
        Label("SINGLE", systemImage: "square").foregroundStyle(mint)
        Spacer()
        Text("TAP WHEN THE SQUARES ALIGN").foregroundStyle(muted)
        Spacer()
        Label("CHORD", systemImage: "square.on.square").foregroundStyle(rose)
      }.font(.system(size: 7, weight: .bold, design: .monospaced))
      if model.automated { driverLabel }
      if model.connection != "LINKED" || model.rival?.connected == false {
        Text("RECONNECTING · THE SHARED CLOCK CONTINUES").font(.system(size: 9)).foregroundStyle(
          .orange)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 20)
  }

  private var timeRemaining: String {
    let seconds = max(0, Int(ceil((model.song?.duration ?? 0) - max(0, model.songTime))))
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }

  private func scoreColumn(_ peer: Peer?, you: Bool) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(spacing: 5) {
        Circle().fill(you ? mint : rose).frame(width: 4, height: 4)
        Text("\(you ? "YOU" : "RIVAL") / \(peer?.name.uppercased() ?? "WAITING")")
          .font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(muted)
          .lineLimit(1)
      }
      Text(String(format: "%07d", peer?.score ?? 0))
        .font(.system(size: you ? 31 : 27, weight: .light, design: .rounded))
        .monospacedDigit().foregroundStyle(you ? .white : rose).minimumScaleFactor(0.6).lineLimit(1)
      HStack(spacing: 4) {
        Text(String(format: "%.2f%%", peer?.accuracy ?? 100))
        Text("ACCURACY").foregroundStyle(muted)
      }.font(.system(size: 8, weight: .medium, design: .monospaced)).foregroundStyle(
        you ? mint : rose)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }

  private var results: some View {
    VStack(spacing: 18) {
      eyebrow("SESSION COMPLETE / ROUND \(model.room?.round ?? 1)")
      HStack(spacing: 12) {
        cover(model.selectedSong).frame(width: 74, height: 74).clipped().cornerRadius(6)
        VStack(alignment: .leading, spacing: 5) {
          Text(model.song?.title ?? "").font(.system(size: 23, weight: .black, design: .rounded))
          Text("\(model.difficulty) · \(model.notes.count) NOTES")
            .font(.system(size: 9, design: .monospaced)).foregroundStyle(muted)
        }
        Spacer()
      }
      VStack(spacing: 5) {
        Text(outcome).font(.system(size: 12, weight: .black)).tracking(4).foregroundStyle(mint)
        Text(grade).font(.system(size: 76, weight: .ultraLight, design: .rounded)).foregroundStyle(
          mint)
        Text(String(format: "%07d", model.me?.score ?? 0))
          .font(.system(size: 42, weight: .light, design: .rounded)).monospacedDigit()
        Text("JUDGMENT + SHUTTER BONUS").font(.system(size: 8, weight: .bold)).tracking(1)
          .foregroundStyle(muted)
      }.frame(maxWidth: .infinity).padding(.vertical, 15)
        .background(mint.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(mint.opacity(0.2)))
      HStack {
        resultMetric("ACCURACY", String(format: "%.2f%%", model.me?.accuracy ?? 0))
        resultMetric("MAX COMBO", "\(model.me?.maxCombo ?? 0)")
        resultMetric("RIVAL SCORE", "\(model.rival?.score ?? 0)")
      }
      HStack(spacing: 5) {
        ForEach(
          Array(
            [
              ("PERFECT", model.me?.perfect ?? 0), ("GREAT", model.me?.great ?? 0),
              ("GOOD", model.me?.good ?? 0), ("MISS", model.me?.miss ?? 0),
            ].enumerated()), id: \.offset
        ) { _, pair in
          VStack(spacing: 6) {
            Text("\(pair.1)").font(.system(size: 22, weight: .light, design: .monospaced))
            Text(pair.0).font(.system(size: 7, weight: .bold)).foregroundStyle(muted)
          }.frame(maxWidth: .infinity).padding(.vertical, 12).background(.white.opacity(0.035))
        }
      }
    }
  }

  private var outcome: String {
    let mine = model.me?.score ?? 0
    let theirs = model.rival?.score ?? 0
    return mine == theirs ? "DRAW / IN HARMONY" : mine > theirs ? "YOU WIN" : "RIVAL WINS"
  }

  private var grade: String {
    let score = model.me?.score ?? 0
    if score == 1_000_000 { return "EXC" }
    if score >= 980_000 { return "SSS" }
    if score >= 950_000 { return "SS" }
    if score >= 900_000 { return "S" }
    if score >= 850_000 { return "A" }
    if score >= 700_000 { return "B" }
    return "C"
  }

  private func resultMetric(_ title: String, _ value: String) -> some View {
    VStack(spacing: 7) {
      Text(value).font(.system(size: 18, weight: .semibold, design: .rounded))
      Text(title).font(.system(size: 7, weight: .bold)).foregroundStyle(muted)
    }.frame(maxWidth: .infinity)
  }

  private var settings: some View {
    NavigationStack {
      Form {
        Section("Room server") {
          TextField("ws://host:43116", text: $model.address)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .disabled(model.room != nil)
          Text("Use the same LAN host on both iPhones. The default is for local simulators.")
        }
        Section("Sound & touch") {
          Slider(value: $model.volume, in: 0...1) { Text("Music volume") }
          Toggle("Haptic feedback", isOn: $model.haptics)
          Stepper(
            "Input offset: \(Int(model.calibration)) ms", value: $model.calibration, in: -200...200,
            step: 10)
          Text(
            "Positive offset compensates for late taps. Start at 0 ms; use wired audio for precise timing."
          )
        }
        Section {
          Button("How to play") {
            model.showSettings = false
            model.showGuide = true
          }
          if model.room != nil {
            Button("Leave room", role: .destructive) {
              model.showSettings = false
              model.leave()
            }
          }
        }
      }
      .navigationTitle("Fine tune")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) { Button("Done") { model.saveSettings() } }
      }
    }.tint(mint)
  }

  private var guide: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 24) {
        Text("Sixteen panels.\nOne perfect moment.")
          .font(.system(size: 32, weight: .bold, design: .rounded))
        Label(
          "Tap each panel when its expanding and contracting squares align.",
          systemImage: "square.dashed")
        Label(
          "Pink markers are chords. Tap every lit cell at the same time with separate fingers.",
          systemImage: "hand.tap")
        Label(
          "Perfect ±45 ms · Great ±90 ms · Good ±140 ms. Misses break your combo and close the shutter.",
          systemImage: "waveform")
        Label(
          "Create a room and share its code. Both players ready up to start the same song.",
          systemImage: "person.2")
        Text("900,000 judgment points + 100,000 shutter bonus. Highest final score wins.")
          .font(.system(size: 14)).foregroundStyle(muted)
        Spacer()
      }.padding(26).navigationTitle("How to play").navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Got it") { model.showGuide = false }
          }
        }
    }.tint(mint)
  }

  private var driverLabel: some View {
    HStack {
      Image(systemName: "cpu")
      Text("AUTOMATED INPUT DRIVER")
      Spacer()
      Text(model.playing ? "LIVE NETWORK TAPS" : "TEST SESSION")
    }.font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(0.6)
      .foregroundStyle(.orange).padding(9)
      .background(.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
  }

  private var errorMessage: some View {
    Text(model.error).font(.system(size: 12)).foregroundStyle(.orange)
      .frame(maxWidth: .infinity, alignment: .leading).padding(12)
      .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 5))
  }

  private var footer: some View {
    HStack {
      Text("16 PANELS / INFINITE CONNECTIONS")
      Spacer()
      Text("VOL. 01")
    }.font(.system(size: 7, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(
      muted.opacity(0.6))
  }

  private func eyebrow(_ text: String) -> some View {
    Text(text).font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.5)
      .foregroundStyle(mint)
  }

  private func cover(_ id: String) -> some View {
    Image("refraction").resizable().scaledToFill()
      .hueRotation(.degrees(id == "afterglow" ? 110 : 0))
  }

  private func primary(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(title).font(.system(size: 11, weight: .black)).tracking(1.3)
        Spacer()
        Image(systemName: icon).font(.system(size: 14, weight: .bold))
      }.foregroundStyle(.black).padding(18).background(mint, in: RoundedRectangle(cornerRadius: 5))
    }.buttonStyle(.plain)
  }
}
