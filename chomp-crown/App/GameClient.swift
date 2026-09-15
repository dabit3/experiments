import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class GameClient: ObservableObject {
  @Published var state: ArenaState?
  @Published var status = "OFFLINE"
  @Published var error = ""
  @Published var address = "ws://127.0.0.1:8873"
  @Published var name = "Guest"
  @Published var room = ""
  @Published var sound = true
  @Published var automation = ""
  @Published var lastInput = "—"
  @Published var connecting = false
  let playerID: String
  private var socket: URLSessionWebSocketTask?
  private var generation = 0
  private var token = ""
  private var sequence = 0
  private var eventID = 0
  private var autoTimer: Timer?
  private var audio: [String: AVAudioPlayer] = [:]
  private var music: AVAudioPlayer?
  private var lastPelletSound = Date.distantPast
  private let args = ProcessInfo.processInfo.arguments
  private var autoReady = false
  private var lastDriverTime = 0.0
  private var recoveryAttempts = 0

  init() {
    let defaults = UserDefaults.standard
    playerID = defaults.string(forKey: "guestID") ?? UUID().uuidString
    defaults.set(playerID, forKey: "guestID")
    address = defaults.string(forKey: "server") ?? address
    name = defaults.string(forKey: "name") ?? "Guest \(Int.random(in: 10...99))"
    room = defaults.string(forKey: "room") ?? ""
    token = defaults.string(forKey: "token") ?? ""
    if let value = argument("--server") { address = value }
    if let value = argument("--name") { name = value }
    if let value = argument("--room") { room = value }
    if let value = argument("--autoplay") { automation = value }
    autoReady = args.contains("--auto-ready")
    prepareAudio()
    autoTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
      Task { @MainActor in self?.drive() }
    }
    if args.contains("--create") || args.contains("--join") {
      Task {
        try? await Task.sleep(for: .milliseconds(700))
        connect(create: args.contains("--create"))
      }
    }
  }
  private func argument(_ flag: String) -> String? {
    guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else {
      return nil
    }
    return args[index + 1]
  }
  var me: PlayerState? { state?.players.first { $0.id == playerID } }
  func connect(create: Bool = false) {
    guard let url = URL(string: address),
      ["ws", "wss"].contains(url.scheme ?? ""), url.host != nil
    else {
      error = "Enter a WebSocket address such as ws://192.168.1.5:8873"
      return
    }
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
      error = "Choose a guest name."
      return
    }
    generation += 1
    let current = generation
    socket?.cancel(with: .goingAway, reason: nil)
    let task = URLSession.shared.webSocketTask(with: url)
    socket = task
    connecting = true
    status = "CONNECTING"
    error = ""
    if create {
      state = nil
      token = ""
      room = ""
      eventID = 0
    }
    task.resume()
    UserDefaults.standard.set(address, forKey: "server")
    UserDefaults.standard.set(name, forKey: "name")
    transmit(
      ClientMessage(
        type: "join", create: create, code: room.uppercased(),
        playerId: playerID, name: name, token: token))
    Task { await receive(task, generation: current) }
  }
  private func receive(_ task: URLSessionWebSocketTask, generation current: Int) async {
    do {
      while current == generation {
        let frame = try await task.receive()
        guard current == generation else { return }
        let data: Data
        switch frame {
        case .data(let value): data = value
        case .string(let value): data = Data(value.utf8)
        @unknown default: continue
        }
        let envelope = try JSONDecoder().decode(Envelope.self, from: data)
        if envelope.type == "joined" {
          room = envelope.code ?? room
          token = envelope.token ?? token
          sequence = max(sequence, (envelope.lastSeq ?? -1) + 1)
          UserDefaults.standard.set(room, forKey: "room")
          UserDefaults.standard.set(token, forKey: "token")
          status = "LIVE"
          connecting = false
          recoveryAttempts = 0
          print("EVIDENCE joined peer=\(playerID) room=\(room)")
          startMusic()
        } else if envelope.type == "state" {
          let snapshot = try JSONDecoder().decode(ArenaState.self, from: data)
          if state?.phase != snapshot.phase {
            print(
              "EVIDENCE phase=\(snapshot.phase) room=\(snapshot.code) round=\(snapshot.round) tick=\(snapshot.tick) winner=\(snapshot.winnerId ?? "-")"
            )
          }
          state = snapshot
          processEvents(snapshot)
        } else if envelope.type == "error" {
          error = envelope.message ?? "The server rejected the request."
          connecting = false
          status = "ERROR"
          generation += 1
          task.cancel(with: .normalClosure, reason: nil)
        }
      }
    } catch {
      guard current == generation else { return }
      connecting = false
      status = "DISCONNECTED"
      self.error = "Connection lost. Check the server address or reconnect."
      if state != nil && recoveryAttempts < 4 {
        recoveryAttempts += 1
        try? await Task.sleep(for: .seconds(2))
        if current == generation { connect() }
      }
    }
  }
  private func transmit(_ message: ClientMessage) {
    guard let data = try? JSONEncoder().encode(message),
      let string = String(data: data, encoding: .utf8), let task = socket
    else { return }
    Task {
      do { try await task.send(.string(string)) } catch {
        if task === socket { self.error = "Cannot reach the room server." }
      }
    }
  }
  func direction(_ value: String, source: String = "touch") {
    guard ["up", "right", "down", "left"].contains(value) else { return }
    sequence += 1
    lastInput = value.uppercased()
    transmit(ClientMessage(type: "input", seq: sequence, direction: value))
    if source != "auto" {
      print("EVIDENCE input peer=\(playerID) source=\(source) direction=\(value) seq=\(sequence)")
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
  }
  func ready() {
    transmit(ClientMessage(type: "ready"))
    print("EVIDENCE ready peer=\(playerID) room=\(room)")
  }
  func leave() {
    transmit(ClientMessage(type: "leave"))
    generation += 1
    let previous = socket
    socket = nil
    Task {
      try? await Task.sleep(for: .milliseconds(100))
      previous?.cancel(with: .normalClosure, reason: nil)
    }
    state = nil
    status = "OFFLINE"
    error = ""
    room = ""
    token = ""
    eventID = 0
    music?.stop()
  }
  func handleURL(_ url: URL) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let value = components?.queryItems?.first(where: { $0.name == "value" })?.value ?? ""
    switch url.host {
    case "input": direction(value, source: "automation-url")
    case "ready", "rematch": ready()
    case "reconnect": connect()
    case "driver": automation = value == "off" ? "" : value
    default: break
    }
  }
  func toggleSound() {
    sound.toggle()
    if sound { startMusic() } else { music?.pause() }
  }
  private func prepareAudio() {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    for effect in ["pellet", "power", "eliminated", "roundEnd", "ghostEaten", "bump", "go"] {
      if let url = Bundle.main.url(forResource: effect, withExtension: "wav"),
        let player = try? AVAudioPlayer(contentsOf: url)
      {
        player.volume = effect == "pellet" ? 0.22 : 0.55
        player.prepareToPlay()
        audio[effect] = player
      }
    }
    if let url = Bundle.main.url(forResource: "neon-loop", withExtension: "wav") {
      music = try? AVAudioPlayer(contentsOf: url)
      music?.numberOfLoops = -1
      music?.volume = 0.16
    }
  }
  private func startMusic() { if sound { music?.play() } }
  private func processEvents(_ snapshot: ArenaState) {
    for event in snapshot.events where event.id > eventID {
      eventID = event.id
      if event.kind == "pellet" {
        guard event.playerId == playerID, Date().timeIntervalSince(lastPelletSound) > 0.09 else {
          continue
        }
        lastPelletSound = Date()
      }
      if sound {
        audio[event.kind]?.currentTime = 0
        audio[event.kind]?.play()
      }
    }
  }
  private func drive() {
    guard let snapshot = state else { return }
    if autoReady && snapshot.phase == "lobby" && snapshot.players.count >= 2 && me?.ready == false {
      ready()
    }
    guard !automation.isEmpty, snapshot.phase == "playing", let player = me, player.alive,
      snapshot.clock - lastDriverTime > 0.12
    else { return }
    lastDriverTime = snapshot.clock
    if let input = AutoPilot.direction(snapshot, player: player, style: automation) {
      direction(input, source: "auto")
    }
  }
}
