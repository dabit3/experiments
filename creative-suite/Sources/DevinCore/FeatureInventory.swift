import Foundation

public struct AppFeatureInventory: Codable, Sendable {
    public let tool: StudioTool
    public let available: [String]
    public let unavailable: [String]
}

public enum FeatureInventory {
    public static var all: [AppFeatureInventory] { StudioTool.allCases.map(profile) }
    public static func profile(_ tool: StudioTool) -> AppFeatureInventory {
        let features = ParityLedger.features(tool)
        return AppFeatureInventory(tool: tool, available: features.filter { $0.status != .missing }.map { $0.name + " — " + $0.status.title }, unavailable: features.filter { $0.status == .missing }.map(\.name))
    }
}
