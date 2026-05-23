import XCTest
import Foundation
@testable import MoleTestSupport

// MARK: - PathSafety Tests

final class PathSafetyTests: XCTestCase {

    func test_protectedSystemDirectory_isDetected() {
        XCTAssertTrue(MolePathSafety.isProtected("/System/Library"))
        XCTAssertTrue(MolePathSafety.isProtected("/bin"))
        XCTAssertTrue(MolePathSafety.isProtected("/usr"))
        XCTAssertTrue(MolePathSafety.isProtected("/usr/bin/swift"))
        // /private/var/db → standardizes to /var/db on macOS (symlink resolution)
        XCTAssertTrue(MolePathSafety.isProtected("/var/db"))
    }

    func test_userDocuments_notProtected() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertFalse(MolePathSafety.isProtected("\(home)/Documents"))
        XCTAssertFalse(MolePathSafety.isProtected("\(home)/Downloads"))
        XCTAssertFalse(MolePathSafety.isProtected("\(home)/Desktop"))
    }

    func test_libraryApple_isProtected() {
        XCTAssertTrue(MolePathSafety.isProtected("/Library/Apple/System"))
    }

    func test_safari_isProtected() {
        XCTAssertTrue(MolePathSafety.isProtected("/Applications/Safari.app/Contents/MacOS/Safari"))
    }

    func test_homeDirectory_check() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertTrue(MolePathSafety.isInsideHome("\(home)/Desktop/file.txt"))
        XCTAssertFalse(MolePathSafety.isInsideHome("/tmp/file.txt"))
        XCTAssertFalse(MolePathSafety.isInsideHome("/Applications/Xcode.app"))
    }

    func test_exactProtectedPath_isDetected() {
        XCTAssertTrue(MolePathSafety.isProtected("/System"))
        XCTAssertTrue(MolePathSafety.isProtected("/bin"))
        XCTAssertTrue(MolePathSafety.isProtected("/sbin"))
    }

    func test_partialMatch_doesNotFalsePositive() {
        // /systems (typo) should NOT be protected
        XCTAssertFalse(MolePathSafety.isProtected("/systems"))
        XCTAssertFalse(MolePathSafety.isProtected("/systems/foo"))
    }
}

// MARK: - Formatters Tests

final class FormattersTests: XCTestCase {

    func test_zeroBytesFormat() {
        let result = MoleFormatters.bytes(0)
        XCTAssertFalse(result.isEmpty)
    }

    func test_negativeBytesClampedToZero() {
        let result = MoleFormatters.bytes(-1024)
        // Should not be negative
        XCTAssertFalse(result.contains("-"))
    }

    func test_kilobyteFormat() {
        let result = MoleFormatters.bytes(1024)
        XCTAssertTrue(result.contains("KB") || result.contains("1"))
    }

    func test_megabyteFormat() {
        let result = MoleFormatters.bytes(1024 * 1024)
        XCTAssertTrue(result.contains("MB") || result.contains("1"))
    }

    func test_gigabyteFormat() {
        let result = MoleFormatters.bytes(1024 * 1024 * 1024)
        XCTAssertTrue(result.contains("GB") || result.contains("1"))
    }

    func test_dateFormat_nilDate() {
        let result = MoleFormatters.shortDate(nil)
        XCTAssertEqual(result, "Unknown")
    }

    func test_dateFormat_validDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let result = MoleFormatters.shortDate(date)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, "Unknown")
    }
}

// MARK: - IgnoreList Tests

final class IgnoreListTests: XCTestCase {

    func test_systemDefaultsAreIgnored() {
        let list = MoleIgnoreList()
        XCTAssertTrue(list.isIgnored("/System/Library"))
        XCTAssertTrue(list.isIgnored("/System/Library/CoreServices"))
        XCTAssertTrue(list.isIgnored("/System/Volumes"))
        // /private/var/vm → standardizes to /var/vm on macOS (symlink)
        XCTAssertTrue(list.isIgnored("/var/vm"))
        XCTAssertTrue(list.isIgnored("/Library/Keychains"))
    }

    func test_userPathNotIgnoredByDefault() {
        let list = MoleIgnoreList()
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        XCTAssertFalse(list.isIgnored("\(home)/Downloads"))
        XCTAssertFalse(list.isIgnored("\(home)/Documents"))
    }

    func test_addCustomPath_isIgnored() {
        let list = MoleIgnoreList()
        let testPath = "/tmp/test-mole-\(UUID().uuidString)"
        list.add(testPath)
        XCTAssertTrue(list.isIgnored(testPath))
        XCTAssertTrue(list.isIgnored("\(testPath)/subdir"))
    }

    func test_removePath_notIgnoredAfterRemoval() {
        let list = MoleIgnoreList()
        let testPath = "/tmp/test-mole-\(UUID().uuidString)"
        list.add(testPath)
        XCTAssertTrue(list.isIgnored(testPath))
        list.remove(testPath)
        XCTAssertFalse(list.isIgnored(testPath))
    }

    func test_childPath_isIgnoredWhenParentIgnored() {
        let list = MoleIgnoreList(extra: ["/opt/ignored"])
        XCTAssertTrue(list.isIgnored("/opt/ignored/subdir/file.txt"))
    }

    func test_siblingPath_notIgnored() {
        let list = MoleIgnoreList(extra: ["/opt/ignored"])
        XCTAssertFalse(list.isIgnored("/opt/other"))
    }
}

// MARK: - XPC Config Tests

final class XPCConfigTests: XCTestCase {

    func test_timeoutIsPositive() {
        XCTAssertGreaterThan(MoleXPCConfig.replyTimeoutSeconds, 0)
    }

    func test_timeoutIsReasonable() {
        // Should be between 5 and 30 seconds
        XCTAssertGreaterThanOrEqual(MoleXPCConfig.replyTimeoutSeconds, 5)
        XCTAssertLessThanOrEqual(MoleXPCConfig.replyTimeoutSeconds, 30)
    }
}
