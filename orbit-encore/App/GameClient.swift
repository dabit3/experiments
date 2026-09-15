import Combine
import Foundation
import UIKit

@MainActor
final class GameClient: ObservableObject {
    @Published var snapshot: Snapshot?
    @Published var charts: [Chart] = []
    @Published var playerID = ""
    @Published var status = "Connect two iPhones. One shared stage."
    @Published var error = ""
    @Published var connected = false
    @Published var connecting = false
    @Published var serverAddress = "ws://127.0.0.1:8788"
    @Published var guestName = "Nova"
    @Published var roomCode = ""
    @Published var clockRTT = 0.0
    @Published var clockReady = false
    @Published var audioOffset = 0.0
    @Published var musicVolume = 0.75 {
        didSet { audio.volume = Float(musicVolume) }
    }
    let audio = AudioEngine()
    let automation: String
    let autoReady: Bool
    private var socket: URLSessionWebSocketTask?
    private var token = ""
    private var clockOffset = 0.0
    private var bestRTT = Double.greatestFiniteMagnitude
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var sequence = 0
    private var scheduledMatch = -1
    private var lastLoggedSecond = -1
    private var wantConnection = false
    private var sentReadyMatch = -1
    private var lastEffect = ""
    private let epochOrigin = Date().timeIntervalSince1970 * 1000
    private let uptimeOrigin = ProcessInfo.processInfo.systemUptime
    private let telemetryQueue = DispatchQueue(label: "games.orbitencore.telemetry", qos: .utility)

    var localNow: Double { epochOrigin + (ProcessInfo.processInfo.systemUptime - uptimeOrigin) * 1000 }
    var serverNow: Double { localNow + clockOffset }
    var me: Player? { snapshot?.players.first { $0.id == playerID } }
    var rival: Player? { snapshot?.players.first { $0.id != playerID } }
    var chart: Chart? { charts.first { $0.id == snapshot?.songID } ?? charts.first }
    var isHost: Bool { snapshot?.players.first?.id == playerID }
    var songTime: Double { (serverNow - (snapshot?.startAt ?? serverNow)) / 1000 }
    var phase: String { snapshot?.phase ?? "connect" }

    init() {
        let args = ProcessInfo.processInfo.arguments
        func argument(_ key: String) -> String? {
            guard let index = args.firstIndex(of: key), index + 1 < args.count else { return nil }
            return args[index + 1]
        }
        automation = argument("--autoplay") ?? ""
        autoReady = args.contains("--auto-ready")
        serverAddress = argument("--server") ?? UserDefaults.standard.string(forKey: "server") ?? serverAddress
        guestName = argument("--name") ?? UserDefaults.standard.string(forKey: "name") ?? guestName
        roomCode = argument("--room") ?? ""
        if let url = Bundle.main.url(forResource: "charts", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Chart].self, from: data) { charts = decoded }
        if args.contains("--connect") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in self?.connect() }
        }
    }

    func telemetry(_ event: String, fields: [String: String] = [:]) {
        var row = fields
        row["event"] = event
        row["localTime"] = String(localNow)
        row["serverTime"] = String(serverNow)
        row["player"] = playerID
        row["room"] = snapshot?.room ?? roomCode
        guard let data = try? JSONEncoder().encode(row),
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = directory.appendingPathComponent("telemetry.jsonl")
        telemetryQueue.async {
            if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
            guard let handle = try? FileHandle(forWritingTo: url) else { return }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.write(contentsOf: Data([10]))
                try handle.close()
            } catch { print("Telemetry write failed") }
        }
    }

    func connect() {
        guard !connecting else { return }
        guard let url = URL(string: serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)),
              ["ws", "wss"].contains(url.scheme), url.host != nil else {
            error = "Use ws://HOST:8788 or wss://HOST"
            return
        }
        wantConnection = true
        connecting = true
        error = ""
        status = "Connecting to your stage…"
        UserDefaults.standard.set(serverAddress, forKey: "server")
        UserDefaults.standard.set(guestName, forKey: "name")
        let task = URLSession.shared.webSocketTask(with: url)
        socket = task
        task.resume()
        receive(task)
        send(Outbound(type: "join", name: guestName, room: roomCode.uppercased(), token: token))
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.send(Outbound(type: "ping", sentAt: self.localNow))
            }
        }
    }

    private func receive(_ task: URLSessionWebSocketTask) {
        Task { [weak self] in
            do {
                let message = try await task.receive()
                guard let self, self.socket === task else { return }
                switch message {
                case .string(let string): self.handle(Data(string.utf8))
                case .data(let data): self.handle(data)
                @unknown default: break
                }
                self.receive(task)
            } catch {
                guard let self, self.socket === task else { return }
                self.connectionLost()
            }
        }
    }

    private func connectionLost() {
        connected = false
        connecting = false
        pingTimer?.invalidate()
        status = "Connection lost · retrying"
        telemetry("disconnected")
        if wantConnection {
            reconnectTimer?.invalidate()
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.connect() }
            }
        }
    }

    private func handle(_ data: Data) {
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return }
        switch envelope.type {
        case "joined":
            playerID = envelope.id ?? ""
            token = envelope.token ?? ""
            roomCode = envelope.room ?? ""
            charts = envelope.charts ?? charts
            connected = true
            connecting = false
            status = "Connected · real-time score battle"
            telemetry("joined", fields: ["automation": automation])
        case "pong":
            guard let sent = envelope.sentAt, let server = envelope.serverTime else { return }
            let rtt = localNow - sent
            clockRTT = rtt
            if rtt < bestRTT {
                bestRTT = rtt
                clockOffset = server - (sent + localNow) / 2
            }
            clockReady = true
            automateReady()
        case "state":
            guard let next = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
            let oldPhase = snapshot?.phase
            if snapshot?.players != next.players || snapshot?.phase != next.phase ||
                snapshot?.matchID != next.matchID || snapshot?.songID != next.songID ||
                snapshot?.room != next.room || snapshot?.startAt != next.startAt {
                snapshot = next
            }
            if next.phase != oldPhase {
                telemetry("phase", fields: ["phase": next.phase, "matchID": String(next.matchID), "startAt": String(next.startAt)])
            }
            if next.phase == "playing" && scheduledMatch != next.matchID && clockReady {
                scheduledMatch = next.matchID
                let success = audio.play(song: next.songID, startAt: next.startAt, now: serverNow, offset: audioOffset)
                telemetry("audioScheduled", fields: ["startAt": String(next.startAt), "ok": String(success),
                                                      "rtt": String(clockRTT), "deviceAt": String(audio.scheduledAt),
                                                      "preparationTime": String(audio.preparationTime)])
                if !success { error = "Audio could not start. Rejoin before playing." }
            }
            if next.phase == "results" { audio.stop() }
            if let judgment = me?.lastJudgment {
                let key = "\(next.matchID)-\(judgment.id)-\(judgment.text)"
                if key != lastEffect {
                    lastEffect = key
                    if judgment.text != "MISS" { audio.sparkle() }
                }
            }
            let second = Int(serverNow / 1000)
            if second != lastLoggedSecond {
                lastLoggedSecond = second
                telemetry("state", fields: ["phase": next.phase, "matchID": String(next.matchID),
                                            "score": String(me?.score ?? 0), "rivalScore": String(rival?.score ?? 0),
                                            "songTime": String(songTime), "combo": String(me?.combo ?? 0),
                                            "snapshotAgeMs": String(serverNow - next.serverTime), "rtt": String(clockRTT)])
            }
            automateReady()
        case "error":
            error = envelope.message ?? "Connection error"
            connecting = false
            if !connected {
                wantConnection = false
                pingTimer?.invalidate()
                socket?.cancel(with: .goingAway, reason: nil)
            }
        case "left":
            reset()
        default: break
        }
    }

    func send(_ message: Outbound) {
        guard let data = try? JSONEncoder().encode(message), let text = String(data: data, encoding: .utf8) else { return }
        socket?.send(.string(text)) { _ in }
    }

    func ready() { send(Outbound(type: "ready", ready: !(me?.ready ?? false))) }
    func select(_ chart: Chart) { send(Outbound(type: "select", songID: chart.id)) }
    func rematch() { send(Outbound(type: "rematch")) }

    private func automateReady() {
        guard let next = snapshot else { return }
        if autoReady && next.phase == "lobby" && next.players.count == 2 && clockReady &&
            !next.players.contains(where: { !$0.connected }) && sentReadyMatch != next.matchID {
            sentReadyMatch = next.matchID
            ready()
        }
    }

    func input(phase: String, pointer: Int, point: Point, source: String) {
        guard connected, snapshot?.phase == "playing", songTime >= 0 else { return }
        sequence += 1
        send(Outbound(type: "input", matchID: snapshot?.matchID, at: serverNow, seq: sequence,
                      pointer: pointer, phase: phase, x: point.x, y: point.y))
        if phase != "move" {
            telemetry("input", fields: ["phase": phase, "pointer": String(pointer), "source": source,
                                        "x": String(point.x), "y": String(point.y), "songTime": String(songTime)])
        }
    }

    func leave() {
        send(Outbound(type: "leave"))
        reset()
    }

    private func reset() {
        wantConnection = false
        reconnectTimer?.invalidate()
        pingTimer?.invalidate()
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        snapshot = nil
        token = ""
        roomCode = ""
        playerID = ""
        connected = false
        connecting = false
        scheduledMatch = -1
        sentReadyMatch = -1
        audio.stop()
        status = "Connect two iPhones. One shared stage."
    }

    func reconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        connecting = false
        connected = false
        scheduledMatch = -1
        connect()
    }
}
