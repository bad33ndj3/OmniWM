// swift-tools-version: 6.5
import PackageDescription

let package = Package(
    name: "PersonalWMDashboard",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(name: "PersonalWMDashboard"),
        .testTarget(name: "PersonalWMDashboardTests", dependencies: ["PersonalWMDashboard"])
    ]
)
