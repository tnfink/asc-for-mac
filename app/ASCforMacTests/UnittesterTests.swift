// UnittesterTests.swift - Runs ASC's unittester (built by scripts/build-core.sh) as part of the
// Swift tests, the same way scripts/test-core.sh does.

import Foundation
import Testing

struct UnittesterTests {
    /// The repository root, derived from the location of this source file.
    private static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()  // ASCforMacTests
        .deletingLastPathComponent()  // app
        .deletingLastPathComponent()  // repository root

    @Test(.timeLimit(.minutes(10)))
    func ascUnittesterPasses() throws {
        // The sanitizer run (scripts/test-sanitizers.sh) passes the directory of the instrumented
        // build in ASC_CORE_BUILD_DIR; otherwise the normal build in build/core is used.
        let buildDirectory =
            ProcessInfo.processInfo.environment["ASC_CORE_BUILD_DIR"].map { URL(filePath: $0) }
            ?? Self.repositoryRoot.appending(path: "build/core")
        let unittester = buildDirectory.appending(path: "unittester")
        #expect(FileManager.default.isExecutableFile(atPath: unittester.path()))

        let process = Process()
        process.executableURL = unittester
        process.arguments = ["-c", "asc2rc"]
        process.currentDirectoryURL = buildDirectory.appending(path: "unittest-run")
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0, "unittester failed; run scripts/test-core.sh for details")
    }
}
