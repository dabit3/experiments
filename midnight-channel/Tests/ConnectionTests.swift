import Foundation

@MainActor
final class ArenaScene {
  func apply(_ state: MatchState, localID: String) {}
}

@MainActor
final class GameAudio {
  var muted = false
  func start() {}
  func effect(_ kind: String) {}
}

private struct Failure: Error, CustomStringConvertible {
  let description: String
}

private struct Health: Decodable {
  let rooms: Int
}

@main
struct ConnectionTests {
  @MainActor
  static func main() async {
    do {
      try await run()
      print("PASS: delayed welcome, repeated connect/reconnect, second peer and leave cancellation")
    } catch {
      print("FAIL: \(error)")
      exit(1)
    }
  }

  @MainActor
  static func expect(_ condition: Bool, _ message: String) throws {
    if !condition { throw Failure(description: message) }
  }

  @MainActor
  static func until(_ condition: () -> Bool) async throws {
    for _ in 0..<500 {
      if condition() { return }
      try await Task.sleep(for: .milliseconds(10))
    }
    throw Failure(description: "Timed out waiting for native client state")
  }

  @MainActor
  static func run() async throws {
    let args = CommandLine.arguments
    let client = MatchClient()
    client.serverAddress = args[1]
    client.roomCode = "MC" + UUID().uuidString.prefix(6)
    client.guestName = "Alpha"
    defer { client.leave() }
    client.connect()
    for _ in 0..<500 {
      let (data, _) = try await URLSession.shared.data(from: URL(string: args[3])!)
      if try JSONDecoder().decode(Health.self, from: data).rooms == 1 { break }
      try await Task.sleep(for: .milliseconds(10))
    }
    try expect(!client.connected, "The fixture must hold welcome until repeated connects")
    for _ in 0..<20 { client.connect() }
    try await until { client.connected || !client.error.isEmpty }
    try expect(client.connected, "Alpha failed to join: \(client.error)")
    let originalID = client.playerID

    let peer = URLSession.shared.webSocketTask(with: URL(string: args[2])!)
    defer { peer.cancel(with: .normalClosure, reason: nil) }
    peer.resume()
    let join = ClientMessage(type: "join", code: client.roomCode, name: "Beta")
    try await peer.send(.data(JSONEncoder().encode(join)))
    let response = try await peer.receive()
    let data: Data
    switch response {
    case .data(let value): data = value
    case .string(let value): data = Data(value.utf8)
    @unknown default: throw Failure(description: "Unsupported WebSocket response")
    }
    let welcome = try JSONDecoder().decode(ServerMessage.self, from: data)
    try expect(welcome.type == "welcome", "Beta rejected: \(welcome.message ?? welcome.type)")
    try expect(welcome.playerID != originalID, "Both peers must have distinct identities")
    try await until { client.state?.fighters.count == 2 }

    for _ in 0..<20 { client.reconnect() }
    try await until { client.connected }
    try expect(client.playerID == originalID, "Reconnect must restore the same identity")

    client.reconnect()
    client.leave()
    try await Task.sleep(for: .milliseconds(700))
    try expect(!client.connected && client.state == nil, "Cancelled receive restored stale state")
    client.reconnect()
    try await until { client.connected && client.state?.fighters.count == 2 }
    try expect(client.playerID == originalID, "Leave/rejoin must retain the original identity")
  }
}
