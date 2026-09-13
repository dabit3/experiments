import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class GameModel: ObservableObject {
  @Published var room: Room?
  @Published var connection = "OFFLINE"
  @Published var error = ""
  @Published var name = "Guest"
  @Published var address = "ws://127.0.0.1:43116"
  @Published var code = ""
  @Published var selectedSong = "refraction"
  @Published var difficulty = "ADVANCED"
  @Published var showSettings = false
  @Published var showGuide = false
  @Published var frame = 0
  @Published var latency = 0.0
  @Published var syncSamples = 0
  @Published var calibration = 0.0
  @Published var volume = 0.8
  @Published var haptics = true
  @Published var flashes: [Int: (label: String, at: Double)] = [:]

  let songs = Song.load()
  let playerID: String
  let options = LaunchOptions()
  let automated: Bool
  private var token = ""
  private var socket: URLSessionWebSocketTask?
  private var connectionTask: Task<Void, Never>?
  private var pulse: AnyCancellable?
  private var clockOffset = Date().timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime
  private var samples: [(rtt: Double, offset: Double, time: Double)] = []
  private var pingAt = 0.0
  private var retryAt = 0.0
  private var seq = 0
  private var scheduledRound = -1
  private var audio: AVAudioPlayer?
  private var previewing = false
  private var effects: [AVAudioPlayer] = []
  private var effectIndex = 0
  private var outbox: [String] = []
  private var flushing: Task<Void, Never>?
  private var driverNotes: Set<Int> = []
  private var readySentRound = -1
  private var resultAt = 0.0
  private var lastPhase = ""
  private var wantsConnection = false
  private var connectMode = "join"
  private var autoRematches = 0
  private let impact = UIImpactFeedbackGenerator(style: .light)

  init() {
    let storedID = UserDefaults.standard.string(forKey: "playerID") ?? UUID().uuidString
    playerID = storedID
    UserDefaults.standard.set(storedID, forKey: "playerID")
    automated = options.has("--autoplay")
    name = options.value("--name") ?? UserDefaults.standard.string(forKey: "name") ?? "Guest"
    address =
      options.value("--server") ?? UserDefaults.standard.string(forKey: "server")
      ?? "ws://127.0.0.1:43116"
    code = options.value("--room") ?? ""
    selectedSong = options.value("--song") ?? "refraction"
    difficulty = options.value("--difficulty") ?? "ADVANCED"
    calibration = UserDefaults.standard.double(forKey: "calibration")
    autoRematches = Int(options.value("--rematches") ?? "0") ?? 0
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch { self.error = "Audio unavailable: \(error.localizedDescription)" }
    if let url = Bundle.main.url(forResource: "tap", withExtension: "wav") {
      effects = (0..<8).compactMap { _ in try? AVAudioPlayer(contentsOf: url) }
      for effect in effects {
        effect.volume = 0.18
        effect.prepareToPlay()
      }
    }
    pulse = Timer.publish(every: 1.0 / 60, on: .main, in: .common).autoconnect()
      .sink { [weak self] _ in self?.tick() }
    if options.has("--create") || options.has("--join") {
      Task { @MainActor [weak self] in
        try? await Task.sleep(nanoseconds: 800_000_000)
        guard let self else { return }
        self.connect(create: self.options.has("--create"))
      }
    }
  }

  var uptime: Double { ProcessInfo.processInfo.systemUptime }
  var serverNow: Double { uptime + clockOffset }
  var song: Song? { songs.first { $0.id == (room?.songID ?? selectedSong) } }
  var notes: [Note] { song?.charts[room?.difficulty ?? difficulty] ?? [] }
  var me: Peer? { room?.players.first { $0.id == playerID } }
  var rival: Peer? { room?.players.first { $0.id != playerID } }
  var finalMe: Peer? { room?.results.first { $0.id == playerID } }
  var finalRival: Peer? { room?.results.first { $0.id != playerID } }
  var playing: Bool { room?.phase == "playing" }
  var host: Bool { room?.hostID == playerID }
  var songTime: Double { serverNow - (room?.startAt ?? serverNow) }
  var progress: Double { max(0, min(1, songTime / (song?.duration ?? 1))) }
  var isPreviewing: Bool { previewing }

  func connect(create: Bool) {
    error = ""
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
      error = "Enter your guest name."
      return
    }
    guard let url = URL(string: address), ["ws", "wss"].contains(url.scheme ?? ""),
      url.host != nil
    else {
      error = "Use a ws:// or wss:// server address."
      return
    }
    if !create && code.count < 4 {
      error = "Enter the room code."
      return
    }
    UserDefaults.standard.set(name, forKey: "name")
    UserDefaults.standard.set(address, forKey: "server")
    connectionTask?.cancel()
    flushing?.cancel()
    flushing = nil
    outbox = []
    socket?.cancel(with: .goingAway, reason: nil)
    wantsConnection = true
    connectMode = create ? "create" : "join"
    connection = "CONNECTING"
    samples = []
    syncSamples = 0
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    var join = ClientMessage(type: connectMode)
    join.name = name
    join.playerID = playerID
    join.code = create && !automated ? nil : code.uppercased()
    if !create && token.isEmpty
      && UserDefaults.standard.string(forKey: "resumeRoom") == code.uppercased()
      && UserDefaults.standard.string(forKey: "resumeServer") == address
    {
      token = UserDefaults.standard.string(forKey: "resumeToken") ?? ""
    }
    join.token = token
    send(join)
    connectionTask = Task { [weak self] in
      do {
        while !Task.isCancelled {
          let message = try await task.receive()
          guard let self, self.socket === task else { return }
          let data: Data
          switch message {
          case .data(let payload): data = payload
          case .string(let string): data = Data(string.utf8)
          @unknown default: continue
          }
          self.receive(data)
        }
      } catch {
        guard let self, self.socket === task, !Task.isCancelled, self.wantsConnection else {
          return
        }
        self.connection = "RECONNECTING"
        self.error = "Connection interrupted. Retrying…"
        self.retryAt = self.uptime + 2
        self.audio?.stop()
        self.scheduledRound = -1
      }
    }
  }

  func send(_ message: ClientMessage) {
    guard let data = try? JSONEncoder().encode(message),
      let string = String(data: data, encoding: .utf8)
    else { return }
    outbox.append(string)
    guard flushing == nil else { return }
    flushing = Task { [weak self] in
      guard let self else { return }
      while !self.outbox.isEmpty && !Task.isCancelled {
        let next = self.outbox.removeFirst()
        guard let socket = self.socket else { break }
        do { try await socket.send(.string(next)) } catch { break }
      }
      self.flushing = nil
    }
  }

  private func receive(_ data: Data) {
    guard let message = try? JSONDecoder().decode(ServerMessage.self, from: data) else { return }
    switch message.type {
    case "welcome":
      let created = connectMode == "create"
      seq = max(seq, message.lastSequence ?? 0)
      token = message.token ?? token
      code = message.code ?? code
      UserDefaults.standard.set(token, forKey: "resumeToken")
      UserDefaults.standard.set(code, forKey: "resumeRoom")
      UserDefaults.standard.set(address, forKey: "resumeServer")
      connection = "LINKED"
      connectMode = "join"
      error = ""
      print("PRISM joined id=\(playerID) room=\(code) automated=\(automated)")
      if created {
        var selection = ClientMessage(type: "select")
        selection.songID = selectedSong
        selection.difficulty = difficulty
        send(selection)
      }
    case "error":
      error = message.message ?? "Server error"
      if room == nil {
        wantsConnection = false
        connection = "OFFLINE"
        socket?.cancel(with: .normalClosure, reason: nil)
      }
    case "pong":
      guard let sent = message.sent, let remote = message.serverTime else { return }
      let current = uptime
      samples.append((current - sent, remote - (sent + current) / 2, current))
      samples = samples.filter { current - $0.time < 15 }
      if let best = samples.min(by: { $0.rtt < $1.rtt }) {
        clockOffset = best.offset
        latency = best.rtt * 1000
      }
      syncSamples = samples.count
    case "state":
      guard let incoming = message.room else { return }
      let previousJudged = me?.judged ?? [:]
      room = incoming
      if incoming.phase == "playing", let current = me {
        for note in notes
        where current.judged[String(note.id)] == "MISS"
          && previousJudged[String(note.id)] == nil
        {
          flashes[note.cell] = ("MISS", uptime)
        }
      }
      selectedSong = incoming.songID
      difficulty = incoming.difficulty
      if incoming.phase == "results" && lastPhase != "results" {
        audio?.stop()
        resultAt = uptime
        print(
          "PRISM result round=\(incoming.round) scores=\(incoming.players.map { "\($0.id):\($0.score)" }.joined(separator: ","))"
        )
      }
      if incoming.phase != lastPhase { lastPhase = incoming.phase }
    case "judgment":
      if let judgment = try? JSONDecoder().decode(Judgment.self, from: data) {
        flashes[judgment.cell] = (judgment.label, uptime)
      }
    default: break
    }
  }

  func select() {
    previewing = false
    audio?.stop()
    guard room != nil || options.has("--create") else { return }
    var message = ClientMessage(type: "select")
    message.songID = selectedSong
    message.difficulty = difficulty
    send(message)
  }

  func ready() {
    guard syncSamples >= 3, connection == "LINKED" else { return }
    var message = ClientMessage(type: "ready")
    message.ready = !(me?.ready ?? false)
    send(message)
  }

  func leave() {
    let previousSocket = socket
    wantsConnection = false
    connectionTask?.cancel()
    flushing?.cancel()
    flushing = nil
    outbox = []
    Task {
      try? await previousSocket?.send(.string("{\"type\":\"leave\"}"))
      previousSocket?.cancel(with: .normalClosure, reason: nil)
    }
    socket = nil
    room = nil
    token = ""
    UserDefaults.standard.removeObject(forKey: "resumeToken")
    UserDefaults.standard.removeObject(forKey: "resumeRoom")
    connection = "OFFLINE"
    audio?.stop()
    previewing = false
    scheduledRound = -1
    readySentRound = -1
    error = ""
  }

  func saveSettings() {
    UserDefaults.standard.set(calibration, forKey: "calibration")
    audio?.volume = Float(volume)
    showSettings = false
  }

  func preview() {
    if previewing {
      audio?.stop()
      previewing = false
    } else if let song,
      let url = Bundle.main.url(forResource: song.id, withExtension: "wav")
    {
      do {
        audio = try AVAudioPlayer(contentsOf: url)
        audio?.volume = Float(volume)
        audio?.currentTime = 8 * 60 / Double(song.bpm)
        audio?.play()
        previewing = true
      } catch { self.error = "Could not load song audio." }
    }
    frame += 1
  }

  func panelInput(cell: Int, timestamp: Double, source: String = "touch") {
    flashes[cell] = ("TOUCH", uptime)
    if source == "touch" && haptics { impact.impactOccurred(intensity: 0.6) }
    guard playing, connection == "LINKED", let room, songTime >= 0 else { return }
    if !effects.isEmpty {
      let effect = effects[effectIndex % effects.count]
      effect.currentTime = 0
      effect.volume = Float(volume * 0.2)
      effect.play()
      effectIndex += 1
    }
    seq += 1
    var message = ClientMessage(type: "tap")
    message.cell = cell
    message.seq = seq
    message.round = room.round
    message.at = timestamp + clockOffset - calibration / 1000
    message.source = source
    send(message)
    if source == "touch" {
      print("PRISM touch cell=\(cell) seq=\(seq) songTime=\(songTime)")
    }
  }

  private func scheduleAudio() {
    guard let room, let song,
      let url = Bundle.main.url(forResource: song.id, withExtension: "wav")
    else {
      error = "Song assets are missing."
      return
    }
    do {
      audio?.stop()
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = Float(volume)
      player.prepareToPlay()
      let delay = room.startAt - serverNow
      if delay > 0 {
        player.play(atTime: player.deviceCurrentTime + delay)
      } else {
        player.currentTime = min(song.duration, -delay + 0.05)
        player.play(atTime: player.deviceCurrentTime + 0.05)
      }
      audio = player
      previewing = false
      scheduledRound = room.round
      driverNotes = Set(notes.filter { $0.time < songTime - 0.14 }.map(\.id))
      print(
        "PRISM audio round=\(room.round) serverStart=\(room.startAt) delay=\(delay) rttMs=\(latency)"
      )
    } catch { self.error = "Audio playback failed: \(error.localizedDescription)" }
  }

  private func tick() {
    frame &+= 1
    let current = uptime
    if wantsConnection && connection == "RECONNECTING" && current >= retryAt {
      connect(create: connectMode == "create")
    }
    if socket != nil && current - pingAt > 0.5 {
      pingAt = current
      var ping = ClientMessage(type: "ping")
      ping.sent = current
      send(ping)
    }
    flashes = flashes.filter { current - $0.value.at < 0.45 }
    guard let room else { return }
    if playing && syncSamples >= 3 && scheduledRound != room.round { scheduleAudio() }
    guard automated else { return }
    if (room.phase == "lobby" || room.phase == "results") && room.players.count == 2
      && syncSamples >= 5 && readySentRound != room.round
      && (room.phase == "lobby" || (room.round <= autoRematches && current - resultAt > 7))
    {
      readySentRound = room.round
      ready()
      print("PRISM driver ready room=\(room.code) round=\(room.round)")
    }
    if playing && scheduledRound == room.round {
      let delay = Double(options.value("--tap-delay") ?? "0.008") ?? 0.008
      let skip = Int(options.value("--skip-every") ?? "0") ?? 0
      for note in notes where !driverNotes.contains(note.id) && songTime >= note.time + delay {
        driverNotes.insert(note.id)
        if skip > 0 && (note.id + 1) % skip == 0 { continue }
        if songTime - note.time < 0.14 {
          panelInput(cell: note.cell, timestamp: current, source: "driver")
        }
      }
    }
  }
}
