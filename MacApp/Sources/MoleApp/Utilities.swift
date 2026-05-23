import AppKit
import CryptoKit
import Foundation
import ImageIO

public enum Utilities {
    static func deviceModelIdentifier() -> String {
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}

public enum Formatters {
    static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    static func bytes(_ value: Int64) -> String {
        byteFormatter.string(fromByteCount: max(0, value))
    }

    static func shortDate(_ date: Date?) -> String {
        guard let date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

public enum IgnoreListManager {
    static let defaultsKey = "com.mole.ignoreList"
    
    private static let systemDefaults: Set<String> = [
        "/System/Library",
        "/System/Volumes",
        "/private/var/vm",
        "/Library/Keychains",
        "MobileSync/Backup"
    ]
    
    static func getIgnoredPaths() -> Set<String> {
        let saved = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        return systemDefaults.union(saved)
    }
    
    static func addPath(_ path: String) {
        var current = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        let standardized = (path as NSString).standardizingPath
        if !current.contains(standardized) {
            current.append(standardized)
            UserDefaults.standard.set(current, forKey: defaultsKey)
        }
    }
    
    static func removePath(_ path: String) {
        var current = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        let standardized = (path as NSString).standardizingPath
        current.removeAll { $0 == standardized }
        UserDefaults.standard.set(current, forKey: defaultsKey)
    }
    
    static func isIgnored(_ path: String) -> Bool {
        let standardized = (path as NSString).standardizingPath
        let ignored = getIgnoredPaths()
        return ignored.contains { standardized == $0 || standardized.hasPrefix($0 + "/") }
    }
}

public enum PathSafety {
    static let protectedPrefixes = [
        "/System",
        "/bin",
        "/sbin",
        "/usr/bin",
        "/usr/sbin",
        "/private/var/db",
        "/Library/Apple",
        "/Applications/Safari.app"
    ]

    static func isProtected(_ path: String) -> Bool {
        let standardized = (path as NSString).standardizingPath
        if protectedPrefixes.contains(where: { standardized == $0 || standardized.hasPrefix($0 + "/") }) {
            return true
        }
        return IgnoreListManager.isIgnored(standardized)
    }

    static func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
    }

    static func isInsideHome(_ path: String) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let standardized = (path as NSString).standardizingPath
        return standardized == home || standardized.hasPrefix(home + "/")
    }
}

public enum SensitiveRedactor {
    static func userFacingPath(_ path: String, advanced: Bool) -> String {
        guard !path.isEmpty else { return "Path hidden until review." }
        if advanced {
            return path
        }
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? "Path hidden in standard view." : "\(name) - path hidden"
    }
}

public enum ScanContext {
    case appLaunch
    case onboarding
    case smartCare
    case dashboardRefresh
    case menuBarRefresh
    case cleanupReview
    case protectionReview
    case privacyReview
    case applicationsReview
    case clutterReview
    case spaceLensReview
    case cloudReview
}

public enum ProtectedScanGate {
    static func canReadMetadata(at url: URL, context: ScanContext) -> Bool {
        let path = (url.path as NSString).standardizingPath
        guard !PathSafety.isProtected(path), !PathSafety.isSymbolicLink(url) else { return false }

        switch context {
        case .appLaunch, .onboarding, .smartCare, .dashboardRefresh, .menuBarRefresh:
            return isPassiveSafe(path)
        case .cleanupReview, .protectionReview, .privacyReview, .applicationsReview, .clutterReview, .spaceLensReview, .cloudReview:
            return true
        }
    }

    static func canExecuteAction(at url: URL) -> Bool {
        let path = (url.path as NSString).standardizingPath
        return !PathSafety.isProtected(path) && !PathSafety.isSymbolicLink(url)
    }

    private static func isPassiveSafe(_ path: String) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let passiveRoots = [
            home,
            "\(home)/Downloads",
            "\(home)/.Trash"
        ]
        return passiveRoots.contains { path == $0 || path.hasPrefix($0 + "/") }
    }
}

public struct FileInventory {
    static let fm = FileManager.default

    static func allocatedSize(of url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isDirectoryKey]) else {
            return 0
        }
        if values.isDirectory == true {
            return directorySummary(url, maxItems: 20_000).bytes
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }

    static func quickSize(of url: URL, maxItems: Int = 400) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isDirectoryKey]) else {
            return 0
        }
        if values.isDirectory == true {
            return quickDirectorySummary(url, maxItems: maxItems).bytes
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }

    static func directorySummary(_ url: URL, maxItems: Int) -> (bytes: Int64, count: Int, skipped: Int) {
        guard fm.fileExists(atPath: url.path) else { return (0, 0, 0) }
        var bytes: Int64 = 0
        var count = 0
        var skipped = 0

        let keys: [URLResourceKey] = [
            .isRegularFileKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey
        ]

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in
                skipped += 1
                return true
            }
        ) else {
            return (0, 0, 1)
        }

        for case let itemURL as URL in enumerator {
            if count >= maxItems {
                skipped += 1
                break
            }

            guard let values = try? itemURL.resourceValues(forKeys: Set(keys)) else {
                skipped += 1
                continue
            }
            if values.isSymbolicLink == true {
                skipped += 1
                continue
            }
            if values.isRegularFile == true {
                bytes += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
            }
            count += 1
        }

        return (bytes, count, skipped)
    }

    static func quickDirectorySummary(_ url: URL, maxItems: Int) -> (bytes: Int64, count: Int, skipped: Int) {
        guard fm.fileExists(atPath: url.path) else { return (0, 0, 0) }
        let children = immediateChildren(of: url)
        var bytes: Int64 = 0
        var count = 0
        var skipped = max(0, children.count - maxItems)

        for child in children.prefix(maxItems) {
            guard !PathSafety.isSymbolicLink(child),
                  let values = try? child.resourceValues(forKeys: [
                      .isRegularFileKey,
                      .totalFileAllocatedSizeKey,
                      .fileAllocatedSizeKey
                  ])
            else {
                skipped += 1
                continue
            }

            if values.isRegularFile == true {
                bytes += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
            }
            count += 1
        }

        return (bytes, count, skipped)
    }

    static func immediateChildren(of url: URL) -> [URL] {
        guard let names = try? fm.contentsOfDirectory(atPath: url.path) else { return [] }
        return names
            .filter { !$0.hasPrefix(".") }
            .map { url.appendingPathComponent($0) }
    }

    static func sha256Hex(of url: URL, maxBytes: Int64 = 150 * 1024 * 1024) -> String? {
        guard !PathSafety.isSymbolicLink(url),
              let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
              values.isRegularFile == true,
              Int64(values.fileSize ?? 0) <= maxBytes,
              let data = try? Data(contentsOf: url, options: [.mappedIfSafe])
        else {
            return nil
        }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func imageAverageHash(of url: URL) -> UInt64? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceThumbnailMaxPixelSize: 8
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let width = 8
        let height = 8
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let average = pixels.reduce(0) { $0 + Int($1) } / max(1, pixels.count)
        var hash: UInt64 = 0
        for pixel in pixels {
            hash <<= 1
            if Int(pixel) >= average {
                hash |= 1
            }
        }
        return hash
    }

    static func hammingDistance(_ lhs: UInt64, _ rhs: UInt64) -> Int {
        Int((lhs ^ rhs).nonzeroBitCount)
    }

    static func sha256HexPartial(of url: URL, prefixBytesCount: Int = 4096) -> String? {
        guard !PathSafety.isSymbolicLink(url),
              let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
              values.isRegularFile == true,
              let fileHandle = try? FileHandle(forReadingFrom: url)
        else {
            return nil
        }
        defer {
            try? fileHandle.close()
        }
        guard let data = try? fileHandle.read(upToCount: prefixBytesCount) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

public class QuarantineManager {
    static let shared = QuarantineManager()
    
    private let fm = FileManager.default
    private let quarantineDir: URL
    private let manifestURL: URL
    
    private init() {
        let home = fm.homeDirectoryForCurrentUser
        quarantineDir = home.appendingPathComponent(".mole/Quarantine")
        manifestURL = quarantineDir.appendingPathComponent("manifest.json")
        try? fm.createDirectory(at: quarantineDir, withIntermediateDirectories: true)
    }
    
    public func getQuarantineDirectory() -> URL {
        return quarantineDir
    }
    
    public func loadManifest() -> [QuarantineItem] {
        guard fm.fileExists(atPath: manifestURL.path),
              let data = try? Data(contentsOf: manifestURL),
              let items = try? JSONDecoder().decode([QuarantineItem].self, from: data) else {
            return []
        }
        return items
    }
    
    private func saveManifest(_ items: [QuarantineItem]) {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: manifestURL)
        }
    }
    
    public func quarantine(url: URL) -> QuarantineItem? {
        let standardizedPath = (url.path as NSString).standardizingPath
        guard fm.fileExists(atPath: standardizedPath),
              !PathSafety.isProtected(standardizedPath) else {
            return nil
        }
        
        let id = UUID()
        let filename = url.lastPathComponent
        let destURL = quarantineDir.appendingPathComponent(id.uuidString)
        
        // Get size
        let size = FileInventory.allocatedSize(of: url)
        
        do {
            try fm.moveItem(at: url, to: destURL)
            let item = QuarantineItem(
                id: id,
                originalPath: standardizedPath,
                quarantinedPath: destURL.path,
                fileName: filename,
                sizeBytes: size,
                quarantineDate: Date(),
                expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
            )
            
            var items = loadManifest()
            items.append(item)
            saveManifest(items)
            return item
        } catch {
            print("Failed to quarantine \(standardizedPath): \(error)")
            return nil
        }
    }
    
    public func restore(item: QuarantineItem) -> Bool {
        let sourceURL = URL(fileURLWithPath: item.quarantinedPath)
        let destURL = URL(fileURLWithPath: item.originalPath)
        
        guard fm.fileExists(atPath: sourceURL.path) else { return false }
        
        do {
            let parentDir = destURL.deletingLastPathComponent()
            try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
            
            if fm.fileExists(atPath: destURL.path) {
                try? fm.removeItem(at: destURL)
            }
            
            try fm.moveItem(at: sourceURL, to: destURL)
            
            var items = loadManifest()
            items.removeAll { $0.id == item.id }
            saveManifest(items)
            return true
        } catch {
            print("Failed to restore \(item.originalPath): \(error)")
            return false
        }
    }
    
    public func deletePermanently(item: QuarantineItem) {
        let fileURL = URL(fileURLWithPath: item.quarantinedPath)
        try? fm.removeItem(at: fileURL)
        
        var items = loadManifest()
        items.removeAll { $0.id == item.id }
        saveManifest(items)
    }
    
    public func emptyExpired() {
        let items = loadManifest()
        let now = Date()
        var remaining: [QuarantineItem] = []
        
        for item in items {
            if now >= item.expiryDate {
                let fileURL = URL(fileURLWithPath: item.quarantinedPath)
                try? fm.removeItem(at: fileURL)
            } else {
                remaining.append(item)
            }
        }
        saveManifest(remaining)
    }
}

public class DifferentialScanCache {
    static let shared = DifferentialScanCache()
    
    private var cache: [String: (lastScanDate: Date, modificationDate: Date, sizeBytes: Int64, itemCount: Int)] = [:]
    private let lock = NSRecursiveLock()
    
    private init() {}
    
    public func get(for path: String, currentModDate: Date) -> (sizeBytes: Int64, itemCount: Int)? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = cache[path] else { return nil }
        if entry.modificationDate == currentModDate {
            return (entry.sizeBytes, entry.itemCount)
        }
        return nil
    }
    
    public func set(for path: String, modificationDate: Date, sizeBytes: Int64, itemCount: Int) {
        lock.lock()
        defer { lock.unlock() }
        cache[path] = (Date(), modificationDate, sizeBytes, itemCount)
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}


