// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cabinet",
     platforms: [
              .macOS(.v10_15),
              .iOS(.v13),
              .watchOS(.v6)
         ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Cabinet",
            targets: ["Cabinet"]),
    ],
    dependencies: [
		.package(url: "https://github.com/bengottlieb/Suite.git", from: "0.9.55"),
		.package(url: "https://github.com/bengottlieb/ID3TagEditor", from: "3.2.0"),
		.package(url: "https://github.com/bengottlieb/SwiftyDropbox", from: "5.2.0"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Cabinet", dependencies: ["Suite", "ID3TagEditor", "SwiftyDropbox"]),
		
        
       // .testTarget(name: "CabinetTests", dependencies: ["Cabinet"]),
    ]
)
