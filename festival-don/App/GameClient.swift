import Foundation
import SwiftUI

@MainActor
final class GameClient: ObservableObject {
    @Published var room: Room?
    @Published var chart = SongChart.load("lantern")
    @Published var connection = "OFFLINE"
    @Published var error = ""
    @Published var name = LaunchOptions.value("--name") ?? UserDefaults.standard.string(forKey: "guestName") ?? "Hana"
    @Published var address = LaunchOptions.value("--server") ?? UserDefaults.standard.string(forKey: "serverAddress") ?? "ws://127.0.0.1:8786"
    @Published var code = ""
    @Published var playerID = ""
    @Published var calibration = UserDefaults.standard.double(forKey: "calibration")
    @Published var rtt = 0.0
    @Published var clockSamples = 0
    @Published var previewing = false
    @Published var showCalibration = false
    @Published var calibrationRunning = false
    @Published var calibrationTaps: [Double] = []
    @Published var leftFlash = 0.0
    @Published var rightFlash = 0.0
    @Published var flashKind = "don"
    @Published var automationPaused = false
    @Published var judgmentAt = 0.0
    @Published var now = Date().timeIntervalSince1970 * 1000

    let automated = LaunchOptions.has("--autoplay")
    let audio = FestivalAudio()
    private var socket: URLSessionWebSocketTask?
    private var resumeToken: String?
    private var generation = 0
    private var sequence = 0
    private var offset = 0.0
    private var bestRTT = Double.infinity
    private var timer: Timer?
    private var lastPing = 0.0
    private var reconnectAt = 0.0
    private var startedRound = -1
    private var autoNotes = Set<Int>()
    private var autoRollAt = -Double.infinity
    private var lastEvent = -1
    private var calibrationStart = 0.0
    private var calibrationBeat = -1
    private var intentionalClose = false
    private var pendingAction = ""

    var local: Drummer? { room?.players.first { $0.id == playerID } }
    var rival: Drummer? { room?.players.first { $0.id != playerID } }
    var isHost: Bool { room?.host == playerID }
    var serverNow: Double { Date().timeIntervalSince1970 * 1000 + offset }
    var elapsed: Double { serverNow - (room?.startAt ?? 0) }
    var phase: String { room?.phase ?? "welcome" }

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if LaunchOptions.has("--create") {
            Task { try? await Task.sleep(for: .milliseconds(500)); createRoom() }
        } else if let roomCode = LaunchOptions.value("--join") {
            code = roomCode
            Task { try? await Task.sleep(for: .milliseconds(500)); joinRoom() }
        }
    }

    func createRoom() { pendingAction = "create"; connect() }
    func joinRoom() {
        code = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6 else { error = "Enter the six-character room code."; return }
        pendingAction = "join"
        connect()
    }

    func connect() {
        guard let url = URL(string: address), ["ws", "wss"].contains(url.scheme), url.host != nil else {
            error = "Use a server address such as ws://192.168.1.8:8786"
            return
        }
        UserDefaults.standard.set(address, forKey: "serverAddress")
        UserDefaults.standard.set(name, forKey: "guestName")
        intentionalClose = false
        generation += 1
        let currentGeneration = generation
        socket?.cancel(with: .goingAway, reason: nil)
        socket = URLSession.shared.webSocketTask(with: url)
        connection = "CONNECTING"
        error = ""
        bestRTT = .infinity
        clockSamples = 0
        socket?.resume()
        receive(currentGeneration)
        send(ClientMessage(type: "hello"))
        ping()
    }

    private func receive(_ currentGeneration: Int) {
        guard let socket else { return }
        Task {
            do {
                let message = try await socket.receive()
                guard currentGeneration == generation else { return }
                let data: Data
                switch message {
                case .string(let text): data = Data(text.utf8)
                case .data(let value): data = value
                @unknown default: return
                }
                if let response = try? JSONDecoder().decode(ServerMessage.self, from: data) { handle(response) }
                receive(currentGeneration)
            } catch {
                guard currentGeneration == generation, !intentionalClose else { return }
                connection = "RECONNECTING"
                reconnectAt = Date().timeIntervalSince1970 + 2
                if room == nil { self.error = "Cannot reach the server. Check the address and start the local server." }
            }
        }
    }

    func send(_ message: ClientMessage) {
        guard let data = try? JSONEncoder().encode(message), let text = String(data: data, encoding: .utf8) else { return }
        socket?.send(.string(text)) { _ in }
    }

    private func handle(_ message: ServerMessage) {
        switch message.type {
        case "catalog":
            connected()
        case "pong":
            synchronize(message)
        case "joined":
            joined(message)
        case "state":
            if let room = message.room { update(room) }
        case "chart":
            if let chart = message.chart { self.chart = chart }
        case "error":
            error = message.message ?? "Connection error"
        case "left":
            clearRoom()
        default: break
        }
    }

    private func connected() {
        connection = "ONLINE"
        if room != nil, let resumeToken {
            send(ClientMessage(type: "join", name: name, code: room?.code, token: resumeToken))
        } else if !pendingAction.isEmpty {
            send(ClientMessage(type: pendingAction, name: name, code: code))
            pendingAction = ""
        }
    }

    private func synchronize(_ message: ServerMessage) {
        guard let sent = message.sent, let serverTime = message.now else { return }
        let received = Date().timeIntervalSince1970 * 1000
        let latency = received - sent
        rtt = latency
        clockSamples += 1
        if latency < bestRTT && (phase != "playing" || elapsed < -2000) {
            bestRTT = latency
            offset = serverTime - (sent + received) / 2
        }
    }

    private func joined(_ message: ServerMessage) {
        playerID = message.id ?? playerID
        resumeToken = message.token ?? resumeToken
        if let chart = message.chart { self.chart = chart }
        if let room = message.room { update(room) }
        connection = "ONLINE"
        if automated && LaunchOptions.has("--auto-ready") && phase == "lobby" {
            Task { try? await Task.sleep(for: .seconds(2)); ready() }
        }
    }

    private func update(_ next: Room) {
        let previousPhase = phase
        room = next
        code = next.code
        if chart.id != next.song || chart.difficulty != next.difficulty {
            chart = SongChart.load(next.song, difficulty: next.difficulty)
        }
        if next.phase == "playing" && startedRound != next.round {
            startedRound = next.round
            autoNotes = Set(chart.notes.filter { $0.at < elapsed - 140 }.map(\.id))
            autoRollAt = -.infinity
            automationPaused = false
            previewing = false
            audio.start(next.song, secondsUntilStart: (next.startAt - serverNow) / 1000)
            evidence("audioScheduled", detail: "round=\(next.round) start=\(next.startAt) offset=\(offset)")
        }
        if previousPhase != "results" && next.phase == "results" {
            audio.finish()
            evidence("result", detail: "round=\(next.round) winner=\(next.winner) local=\(local?.score ?? 0) rival=\(rival?.score ?? 0)")
        }
        if local?.event != lastEvent {
            lastEvent = local?.event ?? 0
            judgmentAt = Date().timeIntervalSince1970
        }
    }

    func select(_ song: String, difficulty: String? = nil) {
        if previewing { audio.stop(); previewing = false }
        send(ClientMessage(type: "select", song: song, difficulty: difficulty ?? chart.difficulty))
    }

    func ready() {
        audio.stop()
        previewing = false
        send(ClientMessage(type: "ready", ready: !(local?.ready ?? false)))
    }

    func togglePreview() {
        previewing.toggle()
        if previewing { audio.preview(chart.id) } else { audio.stop() }
    }

    func leave() {
        send(ClientMessage(type: "leave"))
        clearRoom()
    }

    private func clearRoom() {
        intentionalClose = true
        generation += 1
        socket?.cancel(with: .normalClosure, reason: nil)
        room = nil
        resumeToken = nil
        playerID = ""
        startedRound = -1
        sequence = 0
        connection = "OFFLINE"
        previewing = false
        audio.stop()
    }

    func reconnect() {
        startedRound = -1
        connect()
    }

    func hit(_ kind: String, hand: String, automatedInput: Bool = false) {
        audio.hit(kind)
        let time = Date().timeIntervalSince1970
        if hand == "left" { leftFlash = time } else { rightFlash = time }
        flashKind = kind
        if phase == "playing" {
            sequence += 1
            send(ClientMessage(type: "hit", seq: sequence, at: serverNow - calibration, kind: kind, hand: hand))
            if !automatedInput { evidence("manualHit", detail: "\(kind) \(hand) seq=\(sequence)") }
        }
    }

    func beginCalibration() {
        calibrationRunning = true
        calibrationTaps = []
        calibrationStart = Date().timeIntervalSince1970 + 1
        calibrationBeat = -1
    }

    func calibrationTap() {
        audio.hit("don")
        guard calibrationRunning else { return }
        let elapsed = Date().timeIntervalSince1970 - calibrationStart
        guard elapsed >= 0 else { return }
        let nearest = (elapsed / 0.6).rounded() * 0.6
        calibrationTaps.append((elapsed - nearest) * 1000)
        if calibrationTaps.count >= 8 {
            let sorted = calibrationTaps.sorted()
            calibration = min(120, max(-120, (sorted[3] + sorted[4]) / 2)).rounded()
            calibrationRunning = false
            saveCalibration()
        }
    }

    func saveCalibration() { UserDefaults.standard.set(calibration, forKey: "calibration") }

    private func ping() {
        send(ClientMessage(type: "ping", sent: Date().timeIntervalSince1970 * 1000))
        lastPing = Date().timeIntervalSince1970
    }

    private func tick() {
        let wall = Date().timeIntervalSince1970
        now = wall * 1000 + offset
        if !intentionalClose && connection == "RECONNECTING" && wall >= reconnectAt {
            reconnectAt = wall + 3
            reconnect()
        }
        if connection == "ONLINE" && wall - lastPing > (clockSamples < 8 ? 0.15 : 3) { ping() }
        if calibrationRunning {
            let beat = Int(floor((wall - calibrationStart) / 0.6))
            if beat >= 0 && beat > calibrationBeat { calibrationBeat = beat; audio.hit("ka") }
        }
        guard automated, !automationPaused, phase == "playing", elapsed >= 0, elapsed < chart.duration else { return }
        driveInputs()
    }

    private func driveInputs() {
        let delay = name.lowercased().contains("sora") ? 63.0 : 12.0
        for note in chart.notes {
            if note.kind == "roll" {
                if elapsed >= note.at && elapsed <= note.at + note.duration && elapsed - autoRollAt >= 85 {
                    autoRollAt = elapsed
                    hit(Int(elapsed / 85) % 2 == 0 ? "don" : "ka", hand: "left", automatedInput: true)
                }
            } else if !autoNotes.contains(note.id) && elapsed >= note.at + delay {
                autoNotes.insert(note.id)
                if name.lowercased().contains("sora") && note.id % 17 == 12 { continue }
                hit(note.kind, hand: "left", automatedInput: true)
                if note.big { hit(note.kind, hand: "right", automatedInput: true) }
            }
        }
    }

    private func evidence(_ event: String, detail: String) {
        struct Entry: Encodable {
            let time: Double
            let event: String
            let player: String
            let detail: String
        }
        let entry = Entry(time: serverNow, event: event, player: playerID, detail: detail)
        guard let data = try? JSONEncoder().encode(entry),
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = directory.appendingPathComponent("evidence.jsonl")
        if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
        guard let file = try? FileHandle(forWritingTo: url) else { return }
        defer { try? file.close() }
        do { try file.seekToEnd(); try file.write(contentsOf: data + Data([10])) } catch { print("Evidence log write failed") }
    }
}
