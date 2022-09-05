// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "lunarcmd",
    platforms: [
        .macOS(.v10_13)
    ],
    
    dependencies: [
        .package(url: "https://github.com/FreeApp2014/SwiftyJSON", from: "17.0.6"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", .upToNextMajor(from: "0.9.9")),
        .package(url: "https://github.com/GameParrot/TinyLogger.git", .upToNextMajor(from: "1.0.0")),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "lunarcmd",
            dependencies: ["SwiftyJSON", "ZIPFoundation", "TinyLogger"]),
    ]
)
