// swift-tools-version: 5.9
// The MIT License (MIT)
//
// flutter_vodozemac ships its Rust code as a prebuilt XCFramework because
// SwiftPM cannot run cargo during the build (build tool plugins are
// sandboxed). CI builds it on a macOS runner for every release and attaches it
// to the GitHub release; publish.yml rewrites the binaryTarget below to that
// release asset's url and checksum before publishing to pub.dev. In git it is a
// local path, filled by scripts/build_xcframework.sh for local testing.
// CocoaPods consumers still build from source via cargokit; see
// ../flutter_vodozemac.podspec.
import PackageDescription

let binaryTarget = Target.binaryTarget(
    name: "flutter_vodozemac",
    path: "flutter_vodozemac.xcframework"
)

// No FlutterFramework dependency on purpose: the only target is a
// binaryTarget (a pure-Rust dylib that does not link Flutter), and binary
// targets cannot declare dependencies. Mentioning FlutterFramework here also
// satisfies flutter_tools' string-based manifest check, which would otherwise
// warn on every consumer build.
let package = Package(
    name: "flutter_vodozemac",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "flutter-vodozemac", targets: ["flutter_vodozemac"])
    ],
    targets: [
        binaryTarget
    ]
)
