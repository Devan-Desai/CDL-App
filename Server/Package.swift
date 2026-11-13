// swift-tools-version:6.0
//
// The CDL server — a Swift package (not part of the Xcode app project).
// Run it:  cd Server && swift run      (see Server/README.md)
//
import PackageDescription

let package = Package(
    name: "CDLServer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.100.0"),     // the web server
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.11.3"), // same HTML reader as the app
    ],
    targets: [
        .executableTarget(
            name: "CDLServer",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                "SwiftSoup",
            ]
            // Sources/CDLServer/Shared/ holds LINKS to the app's own files (match page reader,
            // MatchDetail, CDLAttributes, …), so both compile the very same code.
        ),
    ],
    // Same Swift version mode as the app (Swift 5), so the shared files behave the same.
    swiftLanguageModes: [.v5]
)
