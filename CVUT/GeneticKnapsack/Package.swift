import PackageDescription

let package = Package(
    name: "Task4",
    targets: [
        Target(name: "Task4"),
        Target(name: "Executable", dependencies: [ .Target(name: "Task4") ]),
        Target(name: "Generator", dependencies: [ .Target(name: "Task4") ])

        
    ],
    dependencies: [
        .Package(url: "https://github.com/dmcyk/cvut_utils", majorVersion: 0, minor: 3),
        .Package(url: "https://github.com/osjup/cvut_console.git", majorVersion: 0, minor: 7)
    ]
)
