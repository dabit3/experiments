// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PowderlineRules",
  products: [.library(name: "PowderlineRules", targets: ["PowderlineRules"])],
  targets: [
    .target(name: "PowderlineRules", path: "Sources/Core"),
    .testTarget(name: "PowderlineRulesTests", dependencies: ["PowderlineRules"], path: "Tests"),
  ]
)
