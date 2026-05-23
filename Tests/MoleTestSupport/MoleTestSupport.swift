import Foundation

// MARK: - PathSafety (Testable copy, no AppKit dependency)
// This support module re-exposes logic needed in unit tests.

public enum MolePathSafety {
    // These paths are pre-standardized (symlinks resolved) for consistent comparison on macOS.
    // /bin, /sbin, /usr/bin etc. are virtual symlinks on macOS — keep both forms.
    public static let protectedPrefixes = [
        "/System",
        "/private/bin", "/bin",       // /bin is a symlink to /private/bin on macOS
        "/private/sbin", "/sbin",
        "/private/usr", "/usr",
        "/private/var/db", "/var/db",  // /private/var symlinks
        "/Library/Apple",
        "/Applications/Safari.app"
    ]

    public static func isProtected(_ path: String) -> Bool {
        let standardized = (path as NSString).standardizingPath
        return protectedPrefixes.contains { standardized == $0 || standardized.hasPrefix($0 + "/") }
    }

    public static func isSymbolicLink(at path: String) -> Bool {
        let attrs = (try? FileManager.default.attributesOfItem(atPath: path)) ?? [:]
        return (attrs[.type] as? FileAttributeType) == FileAttributeType.typeSymbolicLink
    }

    public static func isInsideHome(_ path: String) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let standardized = (path as NSString).standardizingPath
        return standardized == home || standardized.hasPrefix(home + "/")
    }
}

// MARK: - Formatters (Testable)

public enum MoleFormatters {
    public static func bytes(_ value: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: max(0, value))
    }

    public static func shortDate(_ date: Date?) -> String {
        guard let date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - IgnoreList (Testable in-memory version)

public final class MoleIgnoreList {
    public var ignored: Set<String>

    private static let systemDefaults: Set<String> = [
        "/System/Library",
        "/System/Volumes",
        // /private/var and /var are the same — keep both for symlink safety
        "/private/var/vm", "/var/vm",
        "/Library/Keychains",
        "/Library/Apple"
    ]

    public init(extra: Set<String> = []) {
        ignored = Self.systemDefaults.union(extra)
    }

    public func isIgnored(_ path: String) -> Bool {
        let standardized = (path as NSString).standardizingPath
        return ignored.contains { standardized == $0 || standardized.hasPrefix($0 + "/") }
    }

    public func add(_ path: String) {
        ignored.insert((path as NSString).standardizingPath)
    }

    public func remove(_ path: String) {
        ignored.remove((path as NSString).standardizingPath)
    }
}

// MARK: - XPC Timeout Configuration

public enum MoleXPCConfig {
    /// Maximum seconds to wait for an XPC reply before timing out.
    public static let replyTimeoutSeconds: TimeInterval = 10
}
