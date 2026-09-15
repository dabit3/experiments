// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "LuckyVelvetRules",
  platforms: [.macOS(.v14)],
  products: [.library(name: "LuckyVelvetRules", targets: ["LuckyVelvetRules"])],
  targets: [
    .target(name: "LuckyVelvetRules", path: "Sources/Core"),
    .testTarget(name: "LuckyVelvetRulesTests", dependencies: ["LuckyVelvetRules"], path: "Tests"),
  ]
)
