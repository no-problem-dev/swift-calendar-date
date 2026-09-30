// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-calendar-date",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "CalendarDate",
            targets: ["CalendarDate"]
        ),
    ],
    targets: [
        .target(name: "CalendarDate"),
        .testTarget(
            name: "CalendarDateTests",
            dependencies: ["CalendarDate"]
        ),
    ]
)
