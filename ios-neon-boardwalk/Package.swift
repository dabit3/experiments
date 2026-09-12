// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "BoardwalkRules",
  products: [.library(name: "BoardwalkRules", targets: ["BoardwalkRules"])],
  targets: [
    .target(name: "BoardwalkRules", path: "Sources/Core"),
    .testTarget(name: "BoardwalkRulesTests", dependencies: ["BoardwalkRules"], path: "Tests"),
  ]
)
