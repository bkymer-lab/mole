import Foundation

public enum AppSection: String, CaseIterable, Identifiable {
    case dashboard = "Smart Care"
    case cleanup = "Cleanup"
    case protection = "Protection"
    case performance = "Performance"
    case applications = "Applications"
    case clutter = "My Clutter"
    case spaceLens = "Space Lens"
    case cloud = "Cloud Cleanup"
    case myTools = "My Tools"
    case myActivity = "My Activity"
    case privacy = "Privacy"
    case settings = "Settings"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .dashboard: "desktopcomputer"
        case .cleanup: "eraser"
        case .protection: "hand.raised.fill"
        case .performance: "bolt.fill"
        case .applications: "app.badge.fill"
        case .clutter: "doc.on.doc.fill"
        case .spaceLens: "magnifyingglass.circle.fill"
        case .cloud: "cloud.fill"
        case .myTools: "cube.box.fill"
        case .myActivity: "chart.xyaxis.line"
        case .privacy: "hand.raised"
        case .settings: "gearshape"
        }
    }
}

public enum RiskLevel: String, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case blocked = "Blocked"
}

public enum MemoryPressureLevel: String, Hashable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    case unknown = "Unknown"
}

public enum SmartCareFlowState: Hashable {
    case idle
    case preparing
    case scanning
    case review
    case explain
    case resolve
    case summary
    case failure(String)

    public var isRunning: Bool {
        switch self {
        case .preparing, .scanning:
            return true
        default:
            return false
        }
    }

    public var buttonTitle: String {
        switch self {
        case .idle:
            return "Start Smart Care"
        case .preparing, .scanning:
            return "Reviewing..."
        case .review:
            return "Review Insights"
        case .explain:
            return "Explain"
        case .resolve:
            return "View Summary"
        case .summary:
            return "Refresh Health"
        case .failure:
            return "Try Again"
        }
    }
}

public enum CloudProvider: String, CaseIterable, Identifiable {
    case iCloud = "iCloud Drive"
    case googleDrive = "Google Drive"
    case dropbox = "Dropbox"
    case oneDrive = "OneDrive"

    public var id: String { rawValue }
}

public struct HealthScoreBreakdown: Hashable {
    public var baseScore: Int = 100
    public var storagePenalty: Int
    public var memoryPenalty: Int
    public var cpuPenalty: Int
    public var processPenalty: Int
    public var protectionPenalty: Int

    public var finalScore: Int {
        max(0, min(100, baseScore - storagePenalty - memoryPenalty - cpuPenalty - processPenalty - protectionPenalty))
    }

    public var rows: [(String, Int)] {
        [
            ("Storage", storagePenalty),
            ("Memory pressure", memoryPenalty),
            ("CPU load", cpuPenalty),
            ("Background processes", processPenalty),
            ("Protection", protectionPenalty)
        ]
    }
}

public struct SystemMetrics: Hashable {
    public var modelName: String
    public var osVersion: String
    public var cpuLoadPercent: Double
    public var memoryPressure: MemoryPressureLevel
    public var usedRAMBytes: Int64
    public var totalRAMBytes: Int64
    public var storageUsedBytes: Int64
    public var storageTotalBytes: Int64
    public var processCount: Int
    public var backgroundProcessCount: Int
    public var thermalState: String
}

public struct BatteryHealthSnapshot: Hashable {
    public var isPresent: Bool
    public var healthPercent: Int?
    public var cycleCount: Int?
    public var currentChargePercent: Int?
    public var isCharging: Bool
    public var powerSource: String
    public var condition: String

    static let unavailable = BatteryHealthSnapshot(
        isPresent: false,
        healthPercent: nil,
        cycleCount: nil,
        currentChargePercent: nil,
        isCharging: false,
        powerSource: "Power source unavailable",
        condition: "Not available"
    )
}

public struct CleanupTarget: Identifiable, Hashable {
    public let id = UUID()
    public var category: String
    public var path: String
    public var sizeBytes: Int64
    public var itemCount: Int
    public var risk: RiskLevel
    public var reversible: Bool
    public var permissionRequired: Bool
    public var detail: String
}

public struct CleanupPlan: Hashable {
    public enum Kind: String, Hashable {
        case estimate
        case review
    }

    public var targets: [CleanupTarget]
    public var kind: Kind = .review

    public var isExecutable: Bool {
        kind == .review && !targets.isEmpty
    }

    public var totalSizeBytes: Int64 {
        targets.reduce(0) { $0 + max(0, $1.sizeBytes) }
    }

    public var categoryBreakdown: [(String, Int64)] {
        Dictionary(grouping: targets, by: \.category)
            .map { ($0.key, $0.value.reduce(0) { $0 + $1.sizeBytes }) }
            .sorted { $0.0 < $1.0 }
    }
}

public struct ThreatFinding: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var type: String
    public var confidence: Double
    public var path: String
    public var reason: String
    public var recommendedAction: String
    public var quarantineEligible: Bool
}

public struct ProtectionStatus: Hashable {
    public var definitionVersion: String
    public var definitionDate: Date?
    public var realTimeMonitorEnabled: Bool
    public var fullDiskAccessLikely: Bool
    public var findings: [ThreatFinding]
    public var suspiciousPersistenceCount: Int

    public var headline: String {
        findings.isEmpty ? "Safety review looks calm in the current scope." : "\(findings.count) item(s) are ready for review."
    }
}

public struct PrivacyArtifact: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var path: String
    public var sizeBytes: Int64
    public var risk: RiskLevel
    public var detail: String
    public var recordCount: Int?
}

public struct AppInventoryItem: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var bundleID: String
    public var path: String
    public var sizeBytes: Int64
    public var lastUsed: Date?
    public var source: String
    public var isRunning: Bool
    public var uninstallSafety: RiskLevel
    public var associatedResidualPaths: [String] = []
    public var associatedResidualBytes: Int64 = 0
}

public struct ClutterItem: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var path: String
    public var type: String
    public var sizeBytes: Int64
    public var lastModified: Date?
    public var duplicateGroupID: String?
    public var similarityScore: Double?
    public var suggestedAction: String
}

public struct SpaceLensEntry: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var path: String
    public var sizeBytes: Int64
    public var itemCount: Int
    public var cleanable: Bool
}

public struct CloudProviderAccount: Identifiable, Hashable {
    public let id = UUID()
    public var provider: CloudProvider
    public var authState: String
    public var localSyncPath: String?
    public var estimatedLocalSizeBytes: Int64
    public var scanStatus: String
}

public struct ActionPlan: Hashable {
    public var title: String
    public var reviewText: String
    public var affectedPaths: [String]
    public var reversibleMethod: String
    public var requiresPermission: Bool
    public var fastRemoveEligible: Bool
}

public struct ActionResult: Hashable {
    public var removedCount: Int
    public var skippedCount: Int
    public var errorCount: Int
    public var freedBytes: Int64
    public var message: String
}

public struct ScanSnapshot: Hashable {
    public var collectedAt: Date
    public var healthScore: HealthScoreBreakdown
    public var system: SystemMetrics
    public var battery: BatteryHealthSnapshot
    public var cleanup: CleanupPlan
    public var protection: ProtectionStatus
    public var privacyArtifacts: [PrivacyArtifact]
    public var applications: [AppInventoryItem]
    public var clutter: [ClutterItem]
    public var spaceLens: [SpaceLensEntry]
    public var cloudAccounts: [CloudProviderAccount]

    static let empty = ScanSnapshot(
        collectedAt: .distantPast,
        healthScore: HealthScoreBreakdown(storagePenalty: 0, memoryPenalty: 0, cpuPenalty: 0, processPenalty: 0, protectionPenalty: 0),
        system: SystemMetrics(
            modelName: "Unknown Mac",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            cpuLoadPercent: 0,
            memoryPressure: .unknown,
            usedRAMBytes: 0,
            totalRAMBytes: Int64(ProcessInfo.processInfo.physicalMemory),
            storageUsedBytes: 0,
            storageTotalBytes: 0,
            processCount: 0,
            backgroundProcessCount: 0,
            thermalState: "Unknown"
        ),
        battery: .unavailable,
        cleanup: CleanupPlan(targets: []),
        protection: ProtectionStatus(definitionVersion: "Not loaded", definitionDate: nil, realTimeMonitorEnabled: false, fullDiskAccessLikely: false, findings: [], suspiciousPersistenceCount: 0),
        privacyArtifacts: [],
        applications: [],
        clutter: [],
        spaceLens: [],
        cloudAccounts: []
    )
}

public enum MaintenanceTaskKind: String, Codable, Hashable {
    case flushDNS
    case purgeRAM
    case reindexSpotlight
    case repairDiskPermissions
    case rotateSystemLogs
    case freeUpPurgeableSpace
    case speedUpMail
    case rebuildLaunchServices
}

public struct MaintenanceAction: Identifiable, Hashable {
    public let id = UUID()
    public var title: String
    public var description: String
    public var icon: String
    public var kind: MaintenanceTaskKind
    public var status: ActionStatus = .idle
    public var progress: Double = 0.0
    public var logOutput: String = ""
    public var isSelected: Bool = true
    
    public enum ActionStatus: String, Hashable {
        case idle = "Ready"
        case running = "Running"
        case completed = "Completed"
        case failed = "Failed"
    }
}

public struct AppUpdate: Identifiable, Hashable {
    public let id = UUID()
    public var appName: String
    public var installedVersion: String
    public var latestVersion: String
    public var releaseNotes: String
    public var sizeBytes: Int64
    public var downloadURL: URL?
    public var expectedChecksum: String?
    public var isSelected: Bool = true
    public var status: UpdateStatus = .pending
    
    public enum UpdateStatus: String, Hashable {
        case pending = "Update Available"
        case downloading = "Downloading..."
        case installing = "Installing..."
        case completed = "Updated"
        case failed = "Failed"
    }
}

public struct SystemExtension: Identifiable, Hashable {
    public let id = UUID()
    public var name: String
    public var bundleID: String
    public var path: String
    public var type: ExtensionType
    public var isEnabled: Bool
    public var description: String
    
    public enum ExtensionType: String, Hashable {
        case launchAgent = "LaunchAgent"
        case launchDaemon = "LaunchDaemon"
        case loginItem = "Login Item"
        case preferencePane = "Preference Pane"
    }
}

public struct QuarantineItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var originalPath: String
    public var quarantinedPath: String
    public var fileName: String
    public var sizeBytes: Int64
    public var quarantineDate: Date
    public var expiryDate: Date
}

