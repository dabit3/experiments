import Combine
import Foundation

@MainActor
final class GameClient: ObservableObject {
  @Published var state: MatchState?
  @Published var connected = false
  @Published var connecting = false
  @Published var error = ""
  @Published var serverAddress = "ws://127.0.0.1:8767"
  @Published var guestName = "Challenger"
  @Published var roomCode = ""
  @Published var roster = ["rook", "vesper", "atlas"]
  @Published var automationLabel = ""
  @Published var muted = false
  let id: String
  let autoRole: String?
  var input = InputState()
  var eventHandler: ((CombatEvent) -> Void)?
  var audio = SoundEngine()
  private var socket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var pulse: Timer?
  private var token = ""
  private var sequence = 0
  private var eventID = 0
  private var generation = 0
  private var lastLoggedTick = -60
  private var autoTick = 0
  private var autoReady = false
  private var resultTime: Date?
  private var autoReconnectDone = false
  private var autoActionCount = 0
  private var logHandle: FileHandle?
  private var wantsReconnect = false

  init() {
    autoRole = launchValue("--autoplay")
    id = launchValue("--player-id") ?? UUID().uuidString
    if let server = launchValue("--server") { serverAddress = server }
    if let room = launchValue("--room") { roomCode = room }
    if let name = launchValue("--name") { guestName = name }
    if autoRole == "bravo" {
      roster = ["sora", "kestrel", "jin"]
      guestName = launchValue("--name") ?? "BRAVO"
    } else if autoRole != nil {
      guestName = launchValue("--name") ?? "ALPHA"
    }
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let logURL = documents.appendingPathComponent("crown-evidence.jsonl")
    FileManager.default.createFile(atPath: logURL.path, contents: nil)
    logHandle = try? FileHandle(forWritingTo: logURL)
    record("launch", fields: ["player": id, "driver": autoRole ?? "manual"])
    pulse = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.pulseInput() }
    }
    if autoRole != nil {
      automationLabel = "AUTOMATED INPUT DRIVER • \(autoRole!.uppercased())"
      Task {
        try? await Task.sleep(for: .seconds(autoRole == "bravo" ? 3 : 1))
        connect(create: autoRole != "bravo")
      }
    }
  }

  var localPeer: PeerState? { state?.peers.first { $0.id == id } }
  var inArena: Bool { state.map { $0.phase != "lobby" } ?? false }

  func select(_ fighter: String) {
    if let index = roster.firstIndex(of: fighter) {
      roster.remove(at: index)
    } else if roster.count < 3 {
      roster.append(fighter)
    }
    audio.play(.select)
  }

  func rotateOrder() {
    if roster.count == 3 { roster.append(roster.removeFirst()) }
    audio.play(.select)
  }

  func connect(create: Bool, resume: Bool = false) {
    guard let url = URL(string: serverAddress),
      ["ws", "wss"].contains(url.scheme?.lowercased() ?? ""), url.host != nil
    else {
      error = "Enter a ws:// or wss:// server address."
      return
    }
    if !resume && roster.count != 3 {
      error = "Choose three different fighters in order."
      return
    }
    if !resume {
      eventID = 0
      lastLoggedTick = -60
      sequence = 0
    }
    generation += 1
    let currentGeneration = generation
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    connected = false
    connecting = true
    error = ""
    wantsReconnect = true
    let connection = URLSession.shared.webSocketTask(with: url)
    socket = connection
    connection.resume()
    let hello = WireMessage(
      type: "hello", id: id, name: guestName,
      code: roomCode, create: create, roster: roster,
      token: resume ? token : nil)
    send(hello)
    receiveTask = Task { [weak self] in
      do {
        while !Task.isCancelled {
          let message = try await connection.receive()
          guard let self, currentGeneration == self.generation else { return }
          let data: Data
          switch message {
          case .data(let bytes): data = bytes
          case .string(let text): data = Data(text.utf8)
          @unknown default: continue
          }
          self.receive(data)
        }
      } catch {
        guard let self, currentGeneration == self.generation, !Task.isCancelled else { return }
        self.connected = false
        self.connecting = false
        self.input = InputState()
        self.error = "Connection lost. Match is paused; reconnect to resume."
        self.record("connectionLost")
        if self.wantsReconnect && !self.token.isEmpty {
          try? await Task.sleep(for: .seconds(1.2))
          guard currentGeneration == self.generation else { return }
          self.connect(create: false, resume: true)
        }
      }
    }
  }

  private func receive(_ data: Data) {
    let decoder = JSONDecoder()
    guard let kind = try? decoder.decode(MessageKind.self, from: data) else { return }
    if kind.type == "welcome", let welcome = try? decoder.decode(Welcome.self, from: data) {
      token = welcome.token
      roomCode = welcome.code
      sequence = max(sequence, welcome.ack + 1)
      connected = true
      connecting = false
      error = ""
      record("welcome", fields: ["room": welcome.code, "player": id])
    }
    if kind.type == "error" {
      error = kind.message ?? "Server rejected the request."
      connecting = false
      if autoRole == "bravo" && token.isEmpty {
        Task {
          try? await Task.sleep(for: .seconds(2))
          if !connected { connect(create: false) }
        }
      }
    }
    if kind.type == "state", let snapshot = try? decoder.decode(MatchState.self, from: data) {
      state = snapshot
      for event in snapshot.events where event.id > eventID {
        eventID = event.id
        eventHandler?(event)
        if let encoded = try? JSONEncoder().encode(event) {
          writeLog(encoded)
        }
        switch event.kind {
        case "hit": audio.play(event.action == "super" ? .superHit : .hit)
        case "guard": audio.play(.guardHit)
        case "ko": audio.play(.knockout)
        case "fight":
          audio.startMusic()
          audio.play(.start)
        case "result": audio.play(.win)
        default: break
        }
      }
      if snapshot.tick - lastLoggedTick >= 60 {
        lastLoggedTick = snapshot.tick
        if let encoded = try? JSONEncoder().encode(snapshot) { writeLog(encoded) }
      }
    }
  }

  func ready() {
    send(WireMessage(type: "ready", roster: roster))
    audio.startMusic()
    audio.play(.start)
  }

  func rematch() {
    send(WireMessage(type: "rematch"))
    record("rematchRequested")
  }

  func reconnect(after delay: TimeInterval = 0) {
    input = InputState()
    if delay > 0 {
      generation += 1
      let currentGeneration = generation
      receiveTask?.cancel()
      socket?.cancel(with: .goingAway, reason: nil)
      connected = false
      error = "Reconnection test: reconnecting the same guest in 1.5 seconds."
      Task {
        try? await Task.sleep(for: .seconds(delay))
        guard currentGeneration == generation else { return }
        connect(create: false, resume: true)
      }
      return
    }
    connect(create: false, resume: true)
  }

  func leave() {
    generation += 1
    wantsReconnect = false
    receiveTask?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    state = nil
    token = ""
    connected = false
    connecting = false
    roomCode = ""
    input = InputState()
    autoReady = false
    audio.stopMusic()
  }

  func action(_ name: String, source: String = "touch") {
    transmit(action: name)
    record("input", fields: ["action": name, "source": source, "seq": String(sequence - 1)])
    if name == "super" {
      audio.play(.charge)
    } else if name == "hop" || name == "jump" {
      audio.play(.jump)
    } else if name != "roll" {
      audio.play(.swing)
    }
  }

  func record(_ kind: String, fields: [String: String] = [:]) {
    var value = fields
    value["kind"] = kind
    value["localTime"] = String(Date().timeIntervalSince1970)
    value["localPlayer"] = id
    if let bytes = try? JSONEncoder().encode(value) { writeLog(bytes) }
  }

  private func writeLog(_ data: Data) {
    try? logHandle?.write(contentsOf: data)
    try? logHandle?.write(contentsOf: Data([10]))
  }

  private func send(_ message: WireMessage) {
    guard let data = try? JSONEncoder().encode(message),
      let text = String(data: data, encoding: .utf8)
    else { return }
    socket?.send(.string(text)) { _ in }
  }

  private func transmit(action: String = "") {
    guard connected else { return }
    send(
      WireMessage(
        type: "input", seq: sequence, move: input.move,
        guardValue: input.guardValue, crouch: input.crouch,
        run: input.run, action: action))
    sequence += 1
  }

  private func pulseInput() {
    if autoRole != nil { driveAutomation() }
    if inArena { transmit() }
  }

  private func driveAutomation() {
    guard connected, let state else { return }
    if state.phase == "lobby" && !autoReady {
      autoTick += 1
      automationLabel = "DRIVER • 01 JOIN ROOM \(roomCode) / SELECT ORDER"
      if state.peers.count == 2 && autoTick > 70 {
        ready()
        autoReady = true
        record(
          "assertion",
          fields: [
            "check": "two distinct peers joined",
            "result": String(Set(state.peers.map(\.id)).count == 2),
          ])
      }
      return
    }
    if state.phase == "countdown" {
      autoTick = 0
      input = InputState()
      automationLabel = "DRIVER • 02 BOTH READY / SYNCHRONIZED START"
      return
    }
    if state.phase == "transition" {
      input = InputState()
      automationLabel = "DRIVER • 04 KO / AUTHORITATIVE TEAM REPLACEMENT"
      return
    }
    if state.phase == "result" {
      input = InputState()
      automationLabel = "DRIVER • 05 SHARED WINNER / ALL THREE DEFEATED"
      if resultTime == nil {
        resultTime = Date()
        record(
          "assertion",
          fields: [
            "check": "team defeat", "winner": state.winner,
            "room": state.code, "match": String(state.match),
            "defeated": String(state.peers.contains { $0.roster.allSatisfy { $0.hp == 0 } }),
          ])
      }
      if Date().timeIntervalSince(resultTime!) > 7 && state.match == 1
        && localPeer?.rematch == false
      {
        rematch()
      }
      return
    }
    guard state.phase == "fight", !state.paused,
      let local = localPeer, let opponent = state.peers.first(where: { $0.id != id })
    else { return }
    autoTick += 1
    resultTime = nil
    if state.match >= 2 && !autoReconnectDone && autoTick > 100 && autoRole == "bravo" {
      autoReconnectDone = true
      automationLabel = "DRIVER • 06 RECONNECT SAME PLAYER / RETAIN TEAM"
      record("reconnectTest")
      reconnect(after: 1.5)
      return
    }
    let distance = opponent.x - local.x
    input = InputState(move: abs(distance) > 98 ? (distance > 0 ? 1 : -1) : 0)
    automationLabel = "DRIVER • 03 LIVE INPUTS / \(autoRole!.uppercased()) • ROOM \(roomCode)"
    if autoTick < 45 {
      if autoTick == 12 { action("hop", source: "automated-driver") }
      if autoTick == 30 { action("jump", source: "automated-driver") }
      if (32...40).contains(autoTick) { input.guardValue = true }
      return
    }
    let aggressive = autoRole == "alpha"
    let cadence = aggressive ? 6 : 36
    if autoTick % cadence == 0 {
      autoActionCount += 1
      let actionName: String
      if local.meter >= 200 {
        actionName = "super"
      } else if aggressive {
        actionName = autoActionCount % 3 == 0 ? "heavyPunch" : "special"
      } else {
        actionName = ["kick", "heavyKick", "special", "punch", "hop"][autoActionCount % 5]
        input.guardValue = autoActionCount % 6 == 0
      }
      action(actionName, source: "automated-driver")
    }
  }
}
