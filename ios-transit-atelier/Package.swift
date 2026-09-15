// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "TransitAtelier",
  platforms: [.macOS(.v14)],
  products: [.library(name: "TransitCore", targets: ["TransitCore"])],
  targets: [
    .target(name: "TransitCore", path: "Sources/Core"),
    .testTarget(name: "TransitCoreTests", dependencies: ["TransitCore"]),
  ]
)
