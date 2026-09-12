// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PicnicRules",
    products: [.library(name: "PicnicRules", targets: ["PicnicRules"])],
    targets: [
        .target(
            name: "PicnicRules", path: "Sources",
            exclude: ["PicnicWorld.swift", "GameController.swift", "DriftPicnicApp.swift"],
            sources: ["RaceEngine.swift"]),
        .testTarget(name: "PicnicRulesTests", dependencies: ["PicnicRules"], path: "Tests")
    ]
)
