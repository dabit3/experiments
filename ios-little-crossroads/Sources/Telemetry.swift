import Darwin
import Foundation

/// Debug-only UDP broadcast of the live run state so an external input driver
/// (Scripts/Autopilot.swift) can play the visible app with real taps.
/// Enabled with the launch argument `-telemetryPort <port>`; disabled otherwise.
/// It only reports state; it never changes the rules.
final class Telemetry {
    private let socketDescriptor: Int32
    private var address = sockaddr_in()

    init?(arguments: [String] = CommandLine.arguments) {
        guard let index = arguments.firstIndex(of: "-telemetryPort"), index + 1 < arguments.count,
              let port = UInt16(arguments[index + 1]) else { return nil }
        socketDescriptor = socket(AF_INET, SOCK_DGRAM, 0)
        guard socketDescriptor >= 0 else { return nil }
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
    }

    deinit {
        close(socketDescriptor)
    }

    func send(_ game: GameRules) {
        let stateCode = switch game.state {
        case .ready: 0
        case .playing: 1
        case .paused: 2
        case .finished: 3
        }
        var fields = [
            String(format: "%.4f", game.time),
            String(format: "%.4f", game.x),
            String(game.row),
            String(game.furthest),
            game.hop == nil ? "0" : "1",
            String(stateCode),
            String(game.coins),
        ]
        for row in max(0, game.row - 1) ... game.row + 5 {
            let lane = game.course.lane(row)
            let kind = switch lane.kind {
            case .meadow: "m"
            case .road: "r"
            case .river: "w"
            }
            fields.append("\(row):\(kind):\(String(format: "%.3f", lane.speed)):\(String(format: "%.3f", lane.phase))")
        }
        let payload = fields.joined(separator: " ")
        payload.withCString { pointer in
            withUnsafePointer(to: &address) { addressPointer in
                addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { generic in
                    _ = sendto(
                        socketDescriptor,
                        pointer,
                        strlen(pointer),
                        0,
                        generic,
                        socklen_t(MemoryLayout<sockaddr_in>.size)
                    )
                }
            }
        }
    }
}
