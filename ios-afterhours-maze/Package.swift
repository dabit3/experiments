// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "AfterhoursCore",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [.library(name: "AfterhoursCore", targets: ["AfterhoursCore"])],
  targets: [
    .target(name: "AfterhoursCore"),
    .testTarget(name: "AfterhoursCoreTests", dependencies: ["AfterhoursCore"]),
  ]
)
