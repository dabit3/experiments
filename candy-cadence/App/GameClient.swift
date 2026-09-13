import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class GameClient: ObservableObject {
  @Published var serverAddress =
    UserDefaults.standard.string(forKey: "server") ?? "ws://127.0.0.1:8789"
  @Published var guestName = "Mallow"
  @Published var roomCode = ""
  @Published var state: RoomState?
  @Published var status = "Pick a name. Make some noise."
  @Published var connected = false
  @Published var automated = false
  @Published var volume: Float = 0.7
  @Published var calibration = 0.0
  @Published var clockRTT = 0.0
  @Published var playerID = ""
  private var token = ""
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var pingTask: Task<Void, Never>?
  private var audio: AVAudioPlayer?
  private var tapAudio: [AVAudioPlayer] = []
  private var audioMatch = -1
  private var sequence = 0
  private var offset = 0.0
  private var bestRTT = Double.infinity
  private var syncSamples = 0
  private var driverNotes = Set<Int>()
  private var driverMatch = -1
  private var lastAudioSample = 0.0
  private var readySent = false
  private var generation = 0
  private var reconnectAttempts = 0
  private var intentionalClose = false
  private let telemetry: URL

  var me: Peer? { state?.players.first { $0.id == playerID } }
  var rival: Peer? { state?.players.first { $0.id != playerID } }
  var song: Song { Song.catalog.first { $0.id == state?.songID } ?? Song.catalog[0] }
  var now: Double { Date().timeIntervalSince1970 * 1000 + offset }
  var elapsed: Double { now - (state?.startAt ?? now) }
  var isHost: Bool { state?.hostID == playerID }

  init() {
    telemetry = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("telemetry.jsonl")
    try? AVAudioSession.sharedInstance().setCategory(
      .playback, mode: .default, options: [.mixWithOthers])
    try? AVAudioSession.sharedInstance().setActive(true)
    for lane in 0..<9 {
      if let url = Bundle.main.url(forResource: "tap\(lane)", withExtension: "wav"),
        let sound = try? AVAudioPlayer(contentsOf: url)
      {
        sound.prepareToPlay()
        tapAudio.append(sound)
      }
    }
    let args = ProcessInfo.processInfo.arguments
    func value(_ key: String) -> String? {
      guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
      return args[index + 1]
    }
    guestName = value("--name") ?? guestName
    serverAddress = value("--server") ?? serverAddress
    roomCode = value("--room") ?? ""
    automated = args.contains("--auto")
    if args.contains("--create") || !roomCode.isEmpty {
      Task { connect(create: args.contains("--create")) }
    }
  }

  func record(_ event: String, detail: String = "") {
    let line = "\(Date().timeIntervalSince1970)\t\(event)\t\(detail)\n"
    guard let data = line.data(using: .utf8) else { return }
    if !FileManager.default.fileExists(atPath: telemetry.path) {
      FileManager.default.createFile(atPath: telemetry.path, contents: nil)
    }
    if let file = try? FileHandle(forWritingTo: telemetry) {
      defer { try? file.close() }
      _ = try? file.seekToEnd()
      try? file.write(contentsOf: data)
    }
  }

  func connect(create: Bool, resume: Bool = false) {
    guard let url = URL(string: serverAddress), ["ws", "wss"].contains(url.scheme), url.host != nil
    else {
      status = "Enter a WebSocket address, like ws://192.168.1.20:8789"
      return
    }
    if !create && roomCode.trimmingCharacters(in: .whitespaces).isEmpty {
      status = "Enter your friend's six-character room code."
      return
    }
    UserDefaults.standard.set(serverAddress, forKey: "server")
    generation += 1
    let currentGeneration = generation
    receiveTask?.cancel()
    pingTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    intentionalClose = false
    if !resume {
      playerID = ""
      token = ""
      state = nil
      sequence = 0
      reconnectAttempts = 0
      driverMatch = -1
      driverNotes.removeAll()
    }
    bestRTT = .infinity
    syncSamples = 0
    status = resume ? "Reconnecting to your room…" : "Connecting to the candy club…"
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    send(
      Command(
        type: "hello", create: create, room: roomCode, name: guestName,
        playerID: resume ? playerID : nil, token: resume ? token : nil, automated: automated))
    receiveTask = Task { [weak self] in
      while !Task.isCancelled {
        do {
          let message = try await task.receive()
          let data: Data
          switch message {
          case .data(let payload): data = payload
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          self?.receive(data)
        } catch {
          guard let self, self.generation == currentGeneration, !self.intentionalClose else {
            return
          }
          self.connected = false
          self.status = "Connection lost. Reconnecting…"
          self.record("disconnect")
          self.reconnectAttempts += 1
          if !self.playerID.isEmpty && self.reconnectAttempts <= 6 {
            try? await Task.sleep(for: .seconds(1))
            if !Task.isCancelled { self.connect(create: false, resume: true) }
          } else {
            self.status = "Server unavailable. Check address and tap Reconnect."
          }
          return
        }
      }
    }
    pingTask = Task { [weak self] in
      for index in 0..<10000 {
        guard !Task.isCancelled, let self else { return }
        self.send(Command(type: "ping", sent: Date().timeIntervalSince1970 * 1000))
        try? await Task.sleep(for: .milliseconds(index < 12 ? 150 : 1500))
      }
    }
  }

  private func receive(_ data: Data) {
    guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
    switch envelope.type {
    case "welcome":
      playerID = envelope.playerID ?? ""
      token = envelope.token ?? ""
      roomCode = envelope.room ?? ""
      connected = true
      reconnectAttempts = 0
      status = "Connected • share room \(roomCode)"
      record("welcome", detail: "id=\(playerID) room=\(roomCode) automated=\(automated)")
    case "pong":
      guard let sent = envelope.sent, let server = envelope.serverTime else { return }
      let received = Date().timeIntervalSince1970 * 1000
      let rtt = received - sent
      syncSamples += 1
      if rtt < bestRTT {
        bestRTT = rtt
        offset = server - (sent + received) / 2
        clockRTT = rtt
      }
      autoReady()
    case "state":
      guard let next = try? JSONDecoder().decode(RoomState.self, from: data) else { return }
      if next.phase != state?.phase {
        record("phase", detail: "\(next.phase) match=\(next.match) start=\(next.startAt)")
      }
      state = next
      if next.phase == "lobby" {
        audio?.stop()
        audioMatch = -1
        if me?.ready == true { readySent = true }
        if next.players.allSatisfy({ !$0.ready }) { readySent = false }
        autoReady()
      }
      if next.phase == "playing" {
        prepareAudio()
      }
      if next.phase == "results" {
        audio?.stop()
        if let me, let rival {
          record(
            "result",
            detail:
              "match=\(next.match) self=\(me.score) rival=\(rival.score) judged=\(me.judged.count)")
        }
      }
    case "error":
      status = envelope.error ?? "Unable to complete that action."
      record("error", detail: status)
    default: break
    }
  }

  func send(_ command: Command) {
    guard let data = try? JSONEncoder().encode(command),
      let text = String(data: data, encoding: .utf8)
    else { return }
    socket?.send(.string(text)) { _ in }
  }

  private func autoReady() {
    guard automated, state?.phase == "lobby", state?.players.count == 2,
      syncSamples >= 4, !readySent
    else { return }
    readySent = true
    send(Command(type: "ready"))
  }

  func hit(_ lane: Int, origin: String = "touch") {
    guard state?.phase == "playing", elapsed >= 0, connected else { return }
    sequence += 1
    send(Command(type: "hit", lane: lane, sequence: sequence, time: now + calibration))
    if tapAudio.indices.contains(lane) {
      tapAudio[lane].currentTime = 0
      tapAudio[lane].volume = volume * 0.22
      tapAudio[lane].play()
    }
    record("input", detail: "source=\(origin) lane=\(lane) seq=\(sequence) time=\(now)")
  }

  private func prepareAudio() {
    guard let state, audioMatch != state.match else { return }
    audioMatch = state.match
    guard let url = Bundle.main.url(forResource: song.id, withExtension: "wav") else { return }
    audio = try? AVAudioPlayer(contentsOf: url)
    audio?.volume = volume
    audio?.prepareToPlay()
    guard let audio else { return }
    let delta = (state.startAt - now) / 1000
    if delta > 0 {
      audio.play(atTime: audio.deviceCurrentTime + delta)
    } else {
      audio.currentTime = -delta
      audio.play()
    }
    record(
      "audio_scheduled",
      detail: "match=\(state.match) start=\(state.startAt) delta=\(delta) rtt=\(clockRTT)")
  }

  func tick() {
    audio?.volume = volume
    let serverNow = now
    if let state, state.phase == "playing", serverNow >= state.startAt,
      let audio, serverNow - lastAudioSample >= 1000
    {
      lastAudioSample = serverNow
      record(
        "audio_clock",
        detail:
          "match=\(state.match) song=\(state.songID) server=\(serverNow) start=\(state.startAt) audio=\(audio.currentTime) playing=\(audio.isPlaying) volume=\(volume)"
      )
    }
    guard automated, let state, state.phase == "playing", elapsed >= 0 else { return }
    if driverMatch != state.match {
      driverMatch = state.match
      driverNotes.removeAll()
    }
    for note in song.notes where !driverNotes.contains(note.id) {
      let delay = isHost ? 8.0 : 62.0
      if elapsed >= note.at + delay {
        driverNotes.insert(note.id)
        if elapsed < note.at + 160 && (isHost || note.id % 17 != 0) {
          hit(note.lane, origin: "automated")
          NotificationCenter.default.post(name: .candyHit, object: note.lane)
        }
      }
    }
  }

  func reconnect() {
    connect(create: false, resume: !playerID.isEmpty)
  }

  func leave() {
    intentionalClose = true
    generation += 1
    receiveTask?.cancel()
    pingTask?.cancel()
    socket?.cancel(with: .normalClosure, reason: nil)
    audio?.stop()
    state = nil
    playerID = ""
    token = ""
    connected = false
    readySent = false
    status = "Pick a name. Make some noise."
  }

  func handleURL(_ url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
    let values = Dictionary(
      components.queryItems?.map { ($0.name, $0.value ?? "") } ?? [],
      uniquingKeysWith: { _, new in new })
    if url.host == "connect" {
      leave()
      serverAddress = values["server"] ?? serverAddress
      guestName = values["name"] ?? guestName
      roomCode = values["room"] ?? ""
      automated = values["auto"] == "1"
      connect(create: values["create"] == "1")
    } else if url.host == "ready" {
      send(Command(type: "ready"))
    } else if url.host == "rematch" {
      send(Command(type: "rematch"))
    } else if url.host == "reconnect" {
      reconnect()
    }
  }
}

extension Notification.Name {
  static let candyHit = Notification.Name("candyHit")
}
