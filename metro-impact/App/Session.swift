import Combine
import Foundation
import UIKit

@MainActor
final class Session: ObservableObject {
  @Published var state: MatchState?
  @Published var playerID = ""
  @Published var room = ""
  @Published var error = ""
  @Published var connected = false
  @Published var connecting = false
  @Published var latency = 0
  @Published var driver = ""
  @Published var muted = false
  @Published var serverAddress =
    UserDefaults.standard.string(forKey: "server") ?? "ws://127.0.0.1:8743"
  @Published var guestName = "Player"
  @Published var chosenCharacter = "kai"
  @Published var roomEntry = ""
  private var socket: URLSessionWebSocketTask?
  private var receiver: Task<Void, Never>?
  private var reconnectTask: Task<Void, Never>?
  private var heartbeat: Timer?
  private var driverTimer: Timer?
  private var token = ""
  private var sequence = -1
  private var generation = 0
  private var createRoom = false
  private var autoRole = ""
  private var held: [String: Bool] = [:]
  private var lastDriveTick = -1
  private var firstResultAt: Date?
  private var driverEnabledAt = Date.distantFuture

  init() {
    let args = ProcessInfo.processInfo.arguments
    func arg(_ key: String) -> String? {
      guard let index = args.firstIndex(of: key), args.indices.contains(index + 1) else {
        return nil
      }
      return args[index + 1]
    }
    if let value = arg("--server") { serverAddress = value }
    if let value = arg("--name") { guestName = value }
    if let value = arg("--character") { chosenCharacter = value }
    if let value = arg("--room") { roomEntry = value }
    if let value = arg("--driver") { driver = value }
    if let value = arg("--auto") {
      autoRole = value
      driverEnabledAt = Date().addingTimeInterval(Double(arg("--delay") ?? "8") ?? 8)
      Task { [weak self] in
        try? await Task.sleep(for: .milliseconds(600))
        self?.connect(create: value == "host")
      }
    }
    driverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.drive() }
    }
  }

  var local: FighterState? { state?.players.first { $0.id == playerID } }

  func connect(create: Bool) {
    let trimmed = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let url = URL(string: trimmed), ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil
    else {
      error = "Enter a WebSocket address, for example ws://192.168.1.5:8743"
      return
    }
    guard !guestName.trimmingCharacters(in: .whitespaces).isEmpty else {
      error = "Enter a guest name"
      return
    }
    if !create && roomEntry.count < 4 && playerID.isEmpty {
      error = "Enter your host's room code"
      return
    }
    generation += 1
    let current = generation
    receiver?.cancel()
    socket?.cancel(with: .goingAway, reason: nil)
    error = ""
    connecting = true
    connected = false
    createRoom = create
    UserDefaults.standard.set(trimmed, forKey: "server")
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    task.resume()
    var hello = ClientMessage(
      type: "hello", name: guestName, character: chosenCharacter,
      room: playerID.isEmpty ? roomEntry.uppercased() : room, create: create)
    if !playerID.isEmpty {
      hello.playerID = playerID
      hello.token = token
      hello.create = false
    }
    send(hello)
    receiver = Task { [weak self] in
      do {
        while !Task.isCancelled {
          let message = try await task.receive()
          guard let self, self.generation == current else { return }
          let data: Data
          switch message {
          case .data(let value): data = value
          case .string(let value): data = Data(value.utf8)
          @unknown default: continue
          }
          self.receive(data)
        }
      } catch {
        guard let self, self.generation == current, !Task.isCancelled else { return }
        self.failed()
      }
    }
  }

  private func receive(_ data: Data) {
    do {
      let message = try JSONDecoder().decode(Envelope.self, from: data)
      switch message.type {
      case "welcome":
        playerID = message.playerID ?? ""
        token = message.token ?? ""
        room = message.room ?? ""
        sequence = message.seq ?? -1
        connected = true
        connecting = false
        error = ""
        held = [:]
        heartbeat?.invalidate()
        heartbeat = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
          Task { @MainActor in
            self?.send(ClientMessage(type: "ping", sent: Date().timeIntervalSince1970))
          }
        }
        print("METRO welcome player=\(playerID) room=\(room)")
      case "state":
        let snapshot = try JSONDecoder().decode(MatchState.self, from: data)
        if let state, state.tick > snapshot.tick { return }
        state = snapshot
      case "pong":
        if let sent = message.sent { latency = Int((Date().timeIntervalSince1970 - sent) * 1000) }
      case "error":
        error = message.message ?? "Server rejected the request"
        connecting = false
        if !autoRole.isEmpty && playerID.isEmpty && error.contains("not found") {
          reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.connect(create: false)
          }
        }
      default: break
      }
    } catch {
      self.error = "The server sent an incompatible game state."
    }
  }

  private func failed() {
    connected = false
    connecting = false
    heartbeat?.invalidate()
    error =
      playerID.isEmpty
      ? "Cannot reach server. Check address and start the local server."
      : "Connection lost — reconnecting…"
    if !playerID.isEmpty {
      reconnectTask = Task { [weak self] in
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        self?.connect(create: false)
      }
    }
  }

  func send(_ message: ClientMessage) {
    guard let socket, let data = try? JSONEncoder().encode(message),
      let text = String(data: data, encoding: .utf8)
    else { return }
    socket.send(.string(text)) { _ in }
  }

  func press(_ control: String) {
    switch control {
    case "ready": send(ClientMessage(type: "ready", ready: !(local?.ready ?? false)))
    case "rematch": send(ClientMessage(type: "rematch"))
    case "leave": leave()
    case "audio":
      muted.toggle()
      SoundBank.shared.mute(muted)
    case "driver":
      driver = driver.isEmpty ? "balanced" : ""
      driverEnabledAt = Date()
      releaseAll()
    case "light", "heavy", "fire", "super": transmit(action: control)
    default:
      held[control] = true
      transmit()
    }
  }

  func release(_ control: String) {
    if held[control] == true {
      held[control] = false
      transmit()
    }
  }

  func releaseAll() {
    held = [:]
    transmit()
  }

  private func transmit(action: String? = nil) {
    guard connected else { return }
    sequence += 1
    send(ClientMessage(type: "input", seq: sequence, held: held, action: action))
  }

  func leave() {
    send(ClientMessage(type: "leave"))
    generation += 1
    receiver?.cancel()
    reconnectTask?.cancel()
    heartbeat?.invalidate()
    socket?.cancel(with: .normalClosure, reason: nil)
    socket = nil
    state = nil
    playerID = ""
    token = ""
    room = ""
    error = ""
    connected = false
    connecting = false
    held = [:]
    autoRole = ""
    driver = ""
    firstResultAt = nil
  }

  func handleURL(_ url: URL) {
    guard url.scheme == "metroimpact" else { return }
    let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
    if url.host == "driver" {
      driver = query.first { $0.name == "mode" }?.value ?? "balanced"
      if driver == "off" { driver = "" }
      driverEnabledAt = Date()
      releaseAll()
    } else if url.host == "input" {
      if let key = query.first(where: { $0.name == "control" })?.value { press(key) }
      if let key = query.first(where: { $0.name == "release" })?.value { release(key) }
    } else if url.host == "reconnect" {
      socket?.cancel(with: .goingAway, reason: nil)
    }
  }

  // The opt-in demonstration driver uses the same press/release and WebSocket path as touch.
  private func drive() {
    guard !driver.isEmpty, Date() >= driverEnabledAt, connected, let state, let local else {
      return
    }
    if state.phase == "waiting" {
      if !local.ready { press("ready") }
      return
    }
    if state.phase == "matchOver" {
      if firstResultAt == nil { firstResultAt = Date() }
      if Date().timeIntervalSince(firstResultAt ?? Date()) > 9 && state.match == 1 {
        press("rematch")
      }
      return
    }
    firstResultAt = nil
    guard state.phase == "fight", !state.paused,
      let other = state.players.first(where: { $0.id != playerID }),
      state.tick != lastDriveTick
    else { return }
    lastDriveTick = state.tick
    let cycle = (3600 - state.remaining) % 540
    let distance = abs(local.x - other.x)
    let forward = local.x < other.x ? "right" : "left"
    releaseAll()
    if driver == "defensive" {
      if cycle < 90 {
        press(forward)
      } else if cycle < 150 {
        press("guard")
      } else if cycle < 210 {
        press("jump")
        press(forward)
      } else if cycle < 280 {
        press("crouch")
        press("guard")
      }
      if local.meter == 100 {
        press("super")
      } else if cycle % 100 < 8 {
        press("fire")
      } else if distance < 125 && cycle % 65 < 8 {
        press("heavy")
      } else if distance < 95 && cycle % 42 < 8 {
        press("light")
      }
    } else {
      if distance > 98 && cycle < 330 { press(forward) }
      if cycle > 330 && cycle < 370 {
        press("jump")
        press(forward)
      }
      if cycle > 400 && cycle < 435 { press("guard") }
      if cycle > 460 && cycle < 490 { press("crouch") }
      if local.meter >= 100 {
        press("super")
      } else if distance > 160 {
        if cycle % 55 < 9 { press("fire") }
      } else if cycle % 55 < 10 {
        press("heavy")
      } else if cycle % 24 < 9 {
        press("light")
      }
    }
  }
}
