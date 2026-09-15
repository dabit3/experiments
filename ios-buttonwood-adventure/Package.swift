// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ButtonwoodCore",
    products: [.library(name: "ButtonwoodCore", targets: ["ButtonwoodCore"])],
    targets: [
        .target(name: "ButtonwoodCore", path: "Sources/Core"),
        .testTarget(name: "ButtonwoodCoreTests", dependencies: ["ButtonwoodCore"], path: "Tests"),
    ]
)
