// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacMaintenanceSuite",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MoleApp", targets: ["MoleApp"]),
        .executable(name: "MoleDaemon", targets: ["MoleDaemon"]),
        .library(name: "MoleXPC", targets: ["MoleXPC"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MoleXPC",
            dependencies: []
        ),
        .executableTarget(
            name: "MoleApp",
            dependencies: ["MoleXPC"],
            swiftSettings: [
                .unsafeFlags(["-O", "-wmo", "-cross-module-optimization"], .when(configuration: .release))
            ]
        ),
        .executableTarget(
            name: "MoleDaemon",
            dependencies: ["MoleXPC"]
        )
    ]
)
