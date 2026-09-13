import Foundation
import SwiftUI
import UIKit

struct EvidenceEntry: Encodable {
  let event: String
  let wallTime: Double
  let id: String
  let room: String
  let epoch: Int
  let songTime: Double
  let audioTime: Double?
  let detail: String
  let peers: [Peer]
}

@MainActor
final class GameModel: ObservableObject {
  @Published var serverAddress = "ws://127.0.0.1:8769"
  @Published var guestName = "PHOTON"
  @Published var roomCode = ""
  @Published var phase = "offline"
  @Published var status = "LOCAL NETWORK / GUEST DUEL"
  @Published var peers: [Peer] = []
  @Published var connected = false
  @Published var driver = false
  @Published var showHelp = false
  @Published var epoch = 0
  @Published var rtt = 0.0
  let chart = Chart.load()
  let audio = SoundEngine()
  let id: String
  let token: String
  let automationAvailable: Bool
  var lasers = [0.5, 0.5]
  var buttons = Array(repeating: false, count: 6)
  var flashes = Array(repeating: -10.0, count: 6)
  var startAt = 0.0
  var offset = 0.0
  var localTime: Double { Date().timeIntervalSince1970 * 1000 }
  var songTime: Double { (localTime + offset - startAt) / 1000 }
  var me: Peer? { peers.first { $0.id == id } }
  var opponent: Peer? { peers.first { $0.id != id } }
  var driverVariant = 0
  var driverDelay = 0.0
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var pingTimer: Timer?
  private var reconnectTask: Task<Void, Never>?
  private var bestRTT = Double.infinity
  private var awaitingJoinedState = false
  private var seq = 0
  private var createRoom = false
  private var wantsConnection = false
  private var autoReady = false
  private var noteDown = Set<Int>()
  private var noteUp = Set<Int>()
  private var lastLaserSend = -1.0
  private var lastLogTime = -1.0
  private var lastPhase = ""
  private let logURL: URL

  init() {
    let defaults = UserDefaults.standard
    id = defaults.string(forKey: "guestID") ?? UUID().uuidString
    token = defaults.string(forKey: "guestToken") ?? UUID().uuidString
    defaults.set(id, forKey: "guestID")
    defaults.set(token, forKey: "guestToken")
    logURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("evidence.jsonl")
    let args = ProcessInfo.processInfo.arguments
    func value(_ flag: String) -> String? {
      guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
      return args[index + 1]
    }
    automationAvailable = args.contains("--autoplay")
    driver = automationAvailable
    autoReady = args.contains("--auto-ready")
    guestName = value("--name") ?? defaults.string(forKey: "guestName") ?? "PHOTON"
    serverAddress = value("--server") ?? defaults.string(forKey: "serverAddress") ?? serverAddress
    roomCode = value("--room") ?? ""
    driverVariant = Int(value("--variant") ?? "0") ?? 0
    driverDelay = Double(value("--driver-delay") ?? "0") ?? 0
    if args.contains("--connect") {
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(600))
        self.connect(create: args.contains("--create"))
      }
    }
    NotificationCenter.default.addObserver(
      forName: UIApplication.willResignActiveNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.releaseAll() }
    }
    NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil, queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        guard let self, self.phase == "playing" else { return }
        self.scheduleAudio()
      }
    }
  }

  func connect(create: Bool) {
    guard let url = URL(string: serverAddress),
      ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil,
      !guestName.trimmingCharacters(in: .whitespaces).isEmpty
    else {
      status = "Enter a guest name and a ws://host:port address."
      return
    }
    wantsConnection = true
    createRoom = create
    reconnectTask?.cancel()
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    connected = false
    status = "CONNECTING TO ROOM SERVER…"
    UserDefaults.standard.set(guestName, forKey: "guestName")
    UserDefaults.standard.set(serverAddress, forKey: "serverAddress")
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    var hello = WireMessage(type: "hello")
    hello.id = id
    hello.token = token
    hello.name = guestName
    hello.code = roomCode
    hello.create = create
    hello.chart = chart.id
    send(hello)
    receiveTask = Task { [weak self] in
      do {
        while !Task.isCancelled {
          let result = try await task.receive()
          let data: Data
          switch result {
          case .data(let bytes): data = bytes
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          guard let wire = try? JSONDecoder().decode(WireMessage.self, from: data) else { continue }
          self?.receive(wire)
        }
      } catch {
        guard !Task.isCancelled else { return }
        self?.connectionLost()
      }
    }
    pingTimer?.invalidate()
    bestRTT = .infinity
    ping()
    pingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.ping() }
    }
  }

  private func send(_ message: WireMessage) {
    guard let data = try? JSONEncoder().encode(message),
      let string = String(data: data, encoding: .utf8), let socket
    else { return }
    socket.send(.string(string)) { _ in }
  }

  private func ping() {
    var ping = WireMessage(type: "ping")
    ping.sent = localTime
    send(ping)
  }

  private func receive(_ message: WireMessage) {
    switch message.type {
    case "pong":
      guard let sent = message.sent, let serverNow = message.serverNow else { return }
      let roundTrip = localTime - sent
      rtt = roundTrip
      if roundTrip < bestRTT {
        bestRTT = roundTrip
        offset = serverNow - (sent + localTime) / 2
      }
    case "joined":
      awaitingJoinedState = true
      connected = true
      roomCode = message.code ?? roomCode
      seq = message.nextSeq ?? seq
      status = "CONNECTED / CLOCK SYNC"
      log("joined", detail: "distinct guest \(id)")
      if autoReady {
        Task { @MainActor in
          try? await Task.sleep(for: .seconds(2))
          if self.phase != "playing" && self.me?.ready != true { self.ready() }
        }
      }
    case "state":
      peers = message.players ?? []
      let nextEpoch = message.epoch ?? epoch
      let nextPhase = message.phase ?? phase
      if bestRTT == .infinity, let serverNow = message.serverNow {
        offset = serverNow - localTime
      }
      startAt = message.startAt ?? 0
      if nextEpoch != epoch {
        epoch = nextEpoch
        if !awaitingJoinedState { seq = 0 }
        buttons = Array(repeating: false, count: 6)
        noteDown.removeAll()
        noteUp.removeAll()
        lasers = [0.5, 0.5]
        lastLogTime = -1
        lastLaserSend = -1
        scheduleAudio()
      } else if nextPhase == "playing" && phase != "playing" {
        scheduleAudio()
      }
      awaitingJoinedState = false
      phase = nextPhase
      if phase != lastPhase {
        log("phase", detail: "\(phase), startAt=\(startAt)")
        lastPhase = phase
        if phase == "results" { audio.stop() }
      }
      if phase == "playing" && songTime >= lastLogTime + 1 {
        lastLogTime = songTime
        log("snapshot", detail: "serverStart=\(startAt), rtt=\(rtt)")
      }
    case "error":
      status = message.message ?? "Connection error"
      wantsConnection = false
      connected = false
      pingTimer?.invalidate()
      socket?.cancel(with: .normalClosure, reason: nil)
    default: break
    }
  }

  private func scheduleAudio() {
    let time = songTime
    audio.start(in: max(0, -time), offset: max(0, time))
    log("audioScheduled", detail: "delay=\(max(0, -time)), offset=\(offset)")
  }

  private func connectionLost() {
    connected = false
    status = "LINK LOST — RECONNECTING TO \(roomCode)"
    log("disconnected", detail: status)
    guard wantsConnection else { return }
    reconnectTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(1))
      guard !Task.isCancelled else { return }
      self.connect(create: self.createRoom)
    }
  }

  func ready() { send(WireMessage(type: "ready")) }

  func leave() {
    releaseAll()
    send(WireMessage(type: "leave"))
    wantsConnection = false
    reconnectTask?.cancel()
    receiveTask?.cancel()
    pingTimer?.invalidate()
    socket?.cancel(with: .normalClosure, reason: nil)
    socket = nil
    connected = false
    phase = "offline"
    peers = []
    roomCode = ""
    audio.stop()
    status = "LOCAL NETWORK / GUEST DUEL"
  }

  func button(_ lane: Int, down: Bool, source: String = "touch", at: Double? = nil) {
    guard buttons.indices.contains(lane), buttons[lane] != down else { return }
    buttons[lane] = down
    if down {
      flashes[lane] = songTime
      audio.hit(lane: lane)
    }
    var event = WireMessage(type: "input")
    event.kind = "button"
    event.lane = lane
    event.down = down
    input(event, source: source, at: at)
    updateEffects()
  }

  func laser(_ color: Int, x: Double, source: String = "touch", at: Double? = nil) {
    lasers[color] = max(0, min(1, x))
    var event = WireMessage(type: "input")
    event.kind = "laser"
    event.color = color
    event.x = lasers[color]
    input(event, source: source, at: at)
    updateEffects()
  }

  private func input(_ event: WireMessage, source: String, at: Double?) {
    guard phase == "playing", connected, songTime >= 0 else { return }
    var event = event
    event.time = at ?? songTime
    event.seq = seq
    event.epoch = epoch
    event.source = source
    seq += 1
    send(event)
    if source == "touch" {
      log(
        "touch",
        detail:
          "\(event.kind ?? "") lane=\(event.lane ?? -1) color=\(event.color ?? -1) down=\(event.down ?? false) x=\(event.x ?? -1)"
      )
    }
  }

  func releaseAll() {
    for lane in 0..<6 where buttons[lane] { button(lane, down: false) }
  }

  private func updateEffects() {
    let active = chart.lasers.first { songTime >= $0.start && songTime <= $0.end }
    audio.effects(fxLeft: buttons[4], fxRight: buttons[5], laser: active.map { lasers[$0.color] })
  }

  func frame() {
    guard phase == "playing" else { return }
    let time = songTime
    if driver && time >= driverDelay && time < chart.duration {
      for note in chart.notes {
        let skipped = driverVariant == 1 && note.id % 17 == 0
        let late = driverVariant == 1 && note.id % 7 == 0 ? 0.073 : 0.0
        let start = note.time + late
        if start <= time && !noteDown.contains(note.id) {
          noteDown.insert(note.id)
          if !skipped && time - start < 0.18 {
            button(note.lane, down: true, source: "automated-driver", at: start)
          }
        }
        if time >= start + max(0.075, note.duration) && !noteUp.contains(note.id) {
          noteUp.insert(note.id)
          if !skipped { button(note.lane, down: false, source: "automated-driver") }
        }
      }
      if time - lastLaserSend > 1.0 / 60.0 {
        lastLaserSend = time
        for path in chart.lasers where time >= path.start - 0.07 && time <= path.end + 0.05 {
          let x = path.position(at: time) + (driverVariant == 1 ? 0.035 : 0)
          laser(path.color, x: x, source: "automated-driver")
        }
      }
    }
  }

  func log(_ event: String, detail: String) {
    let entry = EvidenceEntry(
      event: event, wallTime: localTime, id: id, room: roomCode,
      epoch: epoch, songTime: songTime, audioTime: audio.time, detail: detail, peers: peers)
    guard var data = try? JSONEncoder().encode(entry) else { return }
    data.append(0x0A)
    if !FileManager.default.fileExists(atPath: logURL.path) {
      FileManager.default.createFile(atPath: logURL.path, contents: nil)
    }
    if let handle = try? FileHandle(forWritingTo: logURL) {
      defer { try? handle.close() }
      _ = try? handle.seekToEnd()
      try? handle.write(contentsOf: data)
    }
  }
}
