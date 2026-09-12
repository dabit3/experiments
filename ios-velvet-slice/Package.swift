// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VelvetRules",
    products: [.library(name: "VelvetRules", targets: ["VelvetRules"])],
    targets: [
        .target(name: "VelvetRules", path: "Sources/Core"),
        .testTarget(name: "VelvetRulesTests", dependencies: ["VelvetRules"], path: "Tests"),
    ]
)
