// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "TerraCore",
  products: [.library(name: "TerraCore", targets: ["TerraCore"])],
  targets: [
    .target(name: "TerraCore"),
    .testTarget(name: "TerraCoreTests", dependencies: ["TerraCore"]),
  ]
)
