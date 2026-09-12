// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "PaperRelicsRules",
  products: [.library(name: "PaperRelicsRules", targets: ["PaperRelicsRules"])],
  targets: [
    .target(name: "PaperRelicsRules", path: "Sources/Core"),
    .testTarget(name: "PaperRelicsTests", dependencies: ["PaperRelicsRules"], path: "Tests"),
  ]
)
