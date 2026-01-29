import ProjectDescription

let project = Project(
    name: "FileSorter",
    targets: [
        .target(
            name: "FileSorter",
            destinations: .macOS,
            product: .app,
            bundleId: "com.filesorter.app",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [:]
                ]
            ),
            sources: ["Targets/FileSorter/Sources/**"],
            resources: ["Targets/FileSorter/Resources/**"],
            dependencies: []
        )
    ]
)
