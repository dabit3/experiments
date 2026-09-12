// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BloomguardRules",
    platforms: [.macOS(.v14)],
    products: [.library(name: "BloomguardRules", targets: ["BloomguardRules"])],
    targets: [
        .target(name: "BloomguardRules", path: "Sources", exclude: ["GardenArt.swift", "GardenBoard.swift", "BloomguardApp.swift"], sources: ["GardenEngine.swift"]),
        .testTarget(name: "BloomguardRulesTests", dependencies: ["BloomguardRules"], path: "Tests"),
    ]
)
