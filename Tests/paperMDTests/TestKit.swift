import Foundation

/// Minimal assertion harness for paperMD's executable test runner.
///
/// The Command Line Tools toolchain (no Xcode) cannot run XCTest or
/// swift-testing under `swift test`, so tests are a plain executable that
/// accumulates failures and exits non-zero if any check fails. Run with:
///
///     swift run paperMDTests
enum TestKit {
    private(set) static var failures = 0
    private(set) static var checks = 0
    private static var currentSuite = ""

    /// Begins a named group of related checks (printed as a header).
    static func suite(_ name: String, _ body: () -> Void) {
        currentSuite = name
        print("▸ \(name)")
        body()
    }

    /// Records a boolean expectation.
    static func expect(_ condition: @autoclosure () -> Bool,
                       _ message: String,
                       file: StaticString = #file,
                       line: UInt = #line) {
        checks += 1
        if condition() {
            print("  ✓ \(message)")
        } else {
            failures += 1
            print("  ✗ \(message)  (\(shortFile(file)):\(line))")
        }
    }

    /// Records an equality expectation, printing both values on mismatch.
    static func expectEqual<T: Equatable>(_ actual: @autoclosure () -> T,
                                          _ expected: @autoclosure () -> T,
                                          _ message: String,
                                          file: StaticString = #file,
                                          line: UInt = #line) {
        checks += 1
        let a = actual(), e = expected()
        if a == e {
            print("  ✓ \(message)")
        } else {
            failures += 1
            print("  ✗ \(message)  expected \(e), got \(a)  (\(shortFile(file)):\(line))")
        }
    }

    /// Prints the summary and terminates the process with an appropriate code.
    static func finish() -> Never {
        print("")
        if failures == 0 {
            print("✅ All \(checks) checks passed")
            exit(0)
        } else {
            print("❌ \(failures) of \(checks) checks FAILED")
            exit(1)
        }
    }

    private static func shortFile(_ file: StaticString) -> String {
        (("\(file)") as NSString).lastPathComponent
    }
}
