// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "FlappyOtter",
  platforms: [.macOS(.v14), .iOS(.v17)],
  products: [.library(name: "FlappyOtterCore", targets: ["FlappyOtterCore"])],
  targets: [
    .target(name: "FlappyOtterCore", path: "Core"),
    .testTarget(name: "FlappyOtterTests", dependencies: ["FlappyOtterCore"], path: "Tests"),
  ]
)
