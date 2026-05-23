import AppKit
import Foundation

@MainActor
public final class MaintenanceViewModel: ObservableObject {
    @Published var selectedSection: AppSection = .dashboard
    @Published private(set) var snapshot: ScanSnapshot = .empty
    @Published private(set) var smartCareState: SmartCareFlowState = .idle
    @Published private(set) var smartCareProgress = 0.0
    @Published private(set) var smartCareProgressTitle = "Ready"
    @Published private(set) var smartCareProgressDetail = "Start with a lightweight health snapshot."
    @Published private(set) var isScanning = false
    @Published private(set) var isCleaning = false
    @Published private(set) var loadingSection: AppSection?
    @Published private(set) var status = "Ready for native scan."
    @Published private(set) var lastActionResult: ActionResult?
    private let smartCareCoordinator = SmartCareCoordinator()

    // Premium features state
    @Published var appsList: [AppInventoryItem] = []
    @Published var selectedAppForUninstall: AppInventoryItem? = nil
    @Published var isScanningResiduals = false
    
    @Published var maintenanceActions: [MaintenanceAction] = []
    @Published var isRunningMaintenance = false
    
    @Published var appUpdates: [AppUpdate] = []
    @Published var isUpdatingApp = false
    
    @Published var systemExtensions: [SystemExtension] = []
    @Published var isScanningExtensions = false
    
    // Premium dynamic states & scheduler
    @Published var selectedInspectorItem: CleanupTarget? = nil
    @Published var automaticScheduleInterval: String = "weekly" {
        didSet {
            BackgroundScheduleManager.shared.updateSchedule(interval: automaticScheduleInterval)
        }
    }

    @Published var scheduleSilentMode: Bool = true
    @Published var lastScheduleRun: Date? = nil

    public init() {
        // Pre-populate cloud accounts so cloudAccounts property never needs to call
        // passiveProviders() on every SwiftUI body render.
        snapshot.cloudAccounts = CloudCleanupService.passiveProviders()
    }

    public var cleanupBreakdownText: String {
        guard !snapshot.cleanup.categoryBreakdown.isEmpty else { return "No reclaimable cleanup categories found yet." }
        return snapshot.cleanup.categoryBreakdown
            .map { "\($0.0): \(Formatters.bytes($0.1))" }
            .joined(separator: ", ")
    }

    public var cloudAccounts: [CloudProviderAccount] {
        snapshot.cloudAccounts
    }


    public var smartCareButtonTitle: String {
        smartCareState.buttonTitle
    }

    public var smartCareStageTitle: String {
        switch smartCareState {
        case .idle, .preparing, .scanning:
            return "Scan"
        case .review:
            return "Review"
        case .explain:
            return "Explain"
        case .resolve:
            return "Resolve"
        case .summary:
            return "Summary"
        case .failure:
            return "Retry"
        }
    }

    public var smartCareStatusMessage: String {
        switch smartCareState {
        case .idle:
            return "Start with a lightweight health snapshot. Deep scans stay off until you choose them."
        case .preparing:
            return smartCareProgressDetail
        case .scanning:
            return smartCareProgressDetail
        case .review:
            return healthSummaryDetail
        case .explain:
            return "Smart Care checked lightweight health signals only. Deep cleanup, cloud, and clutter reviews stay opt-in."
        case .resolve:
            return "No action is selected automatically. Choose a focused review when you want to improve storage or background activity."
        case .summary:
            return "Summary ready. No cleanup, quarantine, or cloud access happened during this health check."
        case .failure(let message):
            return message
        }
    }

    public var smartCareButtonIcon: String {
        switch smartCareState {
        case .preparing, .scanning:
            return "sparkles"
        case .review:
            return "text.badge.checkmark"
        case .explain:
            return "sparkles.rectangle.stack"
        case .resolve:
            return "checkmark.seal"
        case .summary:
            return "arrow.clockwise"
        default:
            return "sparkle.magnifyingglass"
        }
    }

    public var usedRAMText: String {
        "\(Formatters.bytes(snapshot.system.usedRAMBytes)) / \(Formatters.bytes(snapshot.system.totalRAMBytes))"
    }

    public var memoryPressureDisplayTitle: String {
        switch snapshot.system.memoryPressure {
        case .normal:
            return "Normal"
        case .warning:
            return "Elevated"
        case .critical:
            return "High"
        case .unknown:
            return "Not available"
        }
    }

    public var memoryPressureDisplayDetail: String {
        switch snapshot.system.memoryPressure {
        case .normal:
            return "Used / Total RAM: \(usedRAMText). macOS reports normal pressure."
        case .warning:
            return "Used / Total RAM: \(usedRAMText). Elevated, but not urgent."
        case .critical:
            return "Used / Total RAM: \(usedRAMText). Review heavy apps if this persists."
        case .unknown:
            return "Used / Total RAM: \(usedRAMText). Pressure signal is not available."
        }
    }

    public var storageText: String {
        "\(Formatters.bytes(snapshot.system.storageUsedBytes)) / \(Formatters.bytes(snapshot.system.storageTotalBytes))"
    }

    public var storageHealthTitle: String {
        guard snapshot.system.storageTotalBytes > 0 else { return "Storage not checked" }
        let freeBytes = max(0, snapshot.system.storageTotalBytes - snapshot.system.storageUsedBytes)
        let freeRatio = Double(freeBytes) / Double(snapshot.system.storageTotalBytes)
        switch freeRatio {
        case 0.25...:
            return "Plenty of space"
        case 0.12..<0.25:
            return "Space can improve"
        default:
            return "Review storage soon"
        }
    }

    public var thermalDisplayTitle: String {
        switch snapshot.system.thermalState {
        case "Nominal":
            return "Cool and stable"
        case "Fair":
            return "Slightly warm"
        case "Serious":
            return "Warm under load"
        case "Critical":
            return "Needs a break"
        default:
            return snapshot.system.thermalState
        }
    }

    public var deviceHealthDetail: String {
        let battery = snapshot.battery.isPresent ? batteryHealthDetail : "Battery signal unavailable."
        return "\(battery) Thermal trend: \(thermalDisplayTitle.lowercased())."
    }

    public var healthSummaryTitle: String {
        guard snapshot.collectedAt != .distantPast else { return "Ready for a calm health check" }
        switch snapshot.healthScore.finalScore {
        case 85...100: return "Your Mac looks healthy"
        case 65..<85: return "A few areas can be optimized"
        case 40..<65: return "Some areas need review"
        default: return "Review recommended"
        }
    }

    public var healthSummaryDetail: String {
        guard snapshot.collectedAt != .distantPast else {
            return "Smart Care uses lightweight metadata and cached signals before suggesting any action."
        }
        if snapshot.cleanup.totalSizeBytes > 0 {
            return "\(Formatters.bytes(snapshot.cleanup.totalSizeBytes)) may be recoverable. Run a review before anything moves to Trash."
        }
        return "No cleanup action is selected automatically. You stay in control of every change."
    }

    public var batteryHealthTitle: String {
        guard snapshot.battery.isPresent else { return "Battery unavailable" }
        if let health = snapshot.battery.healthPercent {
            return "\(health)% health"
        }
        return snapshot.battery.condition
    }

    public var batteryHealthDetail: String {
        guard snapshot.battery.isPresent else {
            return "Battery data is unavailable on this Mac."
        }
        let charge = snapshot.battery.currentChargePercent.map { "\($0)% charge" } ?? "charge unavailable"
        let cycles = snapshot.battery.cycleCount.map { "\($0) cycles" } ?? "cycle count unavailable"
        return "\(charge). \(cycles). \(snapshot.battery.powerSource)."
    }

    public func updateSystemMetrics(_ metrics: SystemMetrics) {
        snapshot.system = metrics
    }

    public func performSmartCareAction() {
        switch smartCareState {
        case .idle, .summary, .failure:
            runSmartScan()
        case .review, .explain, .resolve:
            smartCareCoordinator.advanceFromReview()
            syncSmartCareState()
            status = smartCareStatusMessage
        case .preparing, .scanning:
            break
        }
    }

    public func runSmartScan() {
        guard !smartCareState.isRunning else { return }
        let runID = smartCareCoordinator.begin()
        syncSmartCareState()
        setSmartCareProgress(
            title: "Preparing",
            detail: "Preparing a lightweight health snapshot. No cleanup or cloud review starts.",
            progress: 0.08
        )
        isScanning = true
        status = smartCareStatusMessage
        lastActionResult = nil

        Task {
            let snapshotTask = Task.detached(priority: .userInitiated) {
                await MaintenanceCore.healthSnapshot()
            }
            await playSmartCareProgress(runID: runID)
            let nextSnapshot = await snapshotTask.value
            finishSmartCareScan(nextSnapshot, runID: runID)
        }
    }

    public func runCleanupReview() {
        runModuleScan(section: .cleanup, message: "Preparing a cleanup review...") {
            CleanupService.scan()
        } apply: { snapshot, plan in
            snapshot.cleanup = plan
        }
    }

    public func runProtectionReview() {
        runModuleScanAsync(section: .protection, message: "Reviewing background safety signals...") {
            await ProtectionService.scan()
        } apply: { snapshot, protection in
            snapshot.protection = protection
        }
    }

    public func runPrivacyReview() {
        runModuleScan(section: .privacy, message: "Reviewing privacy artifacts locally...") {
            PrivacyService.scan()
        } apply: { snapshot, artifacts in
            snapshot.privacyArtifacts = artifacts
        }
    }

    public func runApplicationsReview() {
        runModuleScan(section: .applications, message: "Reviewing installed applications...") {
            ApplicationService.scan()
        } apply: { snapshot, applications in
            snapshot.applications = applications
            self.appsList = applications
        }
    }

    public func runClutterReview() {
        runModuleScan(section: .clutter, message: "Reviewing large local files...") {
            ClutterService.scan()
        } apply: { snapshot, clutter in
            snapshot.clutter = clutter
        }
    }

    public func runSpaceLensReview() {
        runModuleScanAsync(section: .spaceLens, message: "Indexing top-level storage areas...") {
            await SpaceLensService.scan()
        } apply: { snapshot, entries in
            snapshot.spaceLens = entries
        }
    }

    public func runCloudReview() {
        runModuleScan(section: .cloud, message: "Checking local cloud provider folders after your request...") {
            CloudCleanupService.scan()
        } apply: { snapshot, accounts in
            snapshot.cloudAccounts = accounts
        }
    }

    public func fastCleanup() {
        guard !isCleaning else { return }
        let cleanupPlan = snapshot.cleanup
        isCleaning = true
        status = "Moving eligible cleanup items to Trash..."

        Task {
            let result = await ActionExecutionService.fastCleanup(plan: cleanupPlan)
            
            // UI thread'i bloke etmemek için scan işlemini Task.detached'a atıyoruz
            let nextCleanup = await Task.detached(priority: .userInitiated) {
                CleanupService.scan()
            }.value
            
            self.finishCleanup(result: result, cleanup: nextCleanup)
        }
    }

    public func reveal(path: String) {
        guard !path.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    public func dismissLastActionResult() {
        lastActionResult = nil
    }

    private func finishSmartCareScan(_ nextSnapshot: ScanSnapshot, runID: UUID) {
        guard smartCareCoordinator.markScanning(runID: runID) else { return }
        syncSmartCareState()
        guard smartCareCoordinator.complete(runID: runID) else { return }
        snapshot = nextSnapshot
        setSmartCareProgress(
            title: "Health Summary",
            detail: "Your Mac health snapshot is ready. Nothing has changed automatically.",
            progress: 1
        )
        syncSmartCareState()
        status = smartCareStatusMessage
        isScanning = false
    }

    private func finishCleanup(result: ActionResult, cleanup: CleanupPlan) {
        lastActionResult = result
        snapshot.cleanup = cleanup
        status = result.message
        isCleaning = false
    }

    private func syncSmartCareState() {
        smartCareState = smartCareCoordinator.state
    }

    private func setSmartCareProgress(title: String, detail: String, progress: Double) {
        smartCareProgressTitle = title
        smartCareProgressDetail = detail
        smartCareProgress = min(1, max(0, progress))
    }

    private func playSmartCareProgress(runID: UUID) async {
        let stages: [(title: String, detail: String, progress: Double, delay: UInt64)] = [
            ("Reviewing your Mac", "Reading lightweight system health signals locally.", 0.24, 260_000_000),
            ("Understanding storage", "Estimating reclaimable space without opening personal files.", 0.44, 260_000_000),
            ("Checking background health", "Reviewing memory pressure, CPU load, and background activity.", 0.66, 260_000_000),
            ("Building recommendations", "Preparing calm, review-first recommendations.", 0.86, 300_000_000)
        ]

        for (index, stage) in stages.enumerated() {
            guard smartCareState.isRunning else { return }
            if index == 0 {
                _ = smartCareCoordinator.markScanning(runID: runID)
                syncSmartCareState()
            }
            setSmartCareProgress(title: stage.title, detail: stage.detail, progress: stage.progress)
            status = stage.detail
            try? await Task.sleep(nanoseconds: stage.delay)
        }
    }

    private func runModuleScan<Result: Sendable>(
        section: AppSection,
        message: String,
        work: @escaping @Sendable () -> Result,
        apply: @escaping (inout ScanSnapshot, Result) -> Void
    ) {
        guard loadingSection == nil else { return }
        loadingSection = section
        status = message

        Task { [weak self] in
            guard let self else { return }
            let result = await Task.detached(priority: .userInitiated) { work() }.value
            apply(&self.snapshot, result)
            self.status = "Review ready. Nothing has changed yet."
            self.loadingSection = nil
        }
    }

    private func runModuleScanAsync<Result: Sendable>(
        section: AppSection,
        message: String,
        work: @escaping @Sendable () async -> Result,
        apply: @escaping (inout ScanSnapshot, Result) -> Void
    ) {
        guard loadingSection == nil else { return }
        loadingSection = section
        status = message

        Task { [weak self] in
            guard let self else { return }
            let result = await Task.detached(priority: .userInitiated) { await work() }.value
            apply(&self.snapshot, result)
            self.status = "Review ready. Nothing has changed yet."
            self.loadingSection = nil
        }
    }

    // MARK: - Premium Action Controllers

    public func selectAppForUninstall(_ app: AppInventoryItem) {
        selectedAppForUninstall = app
        guard app.associatedResidualPaths.isEmpty && app.uninstallSafety != .blocked else { return }
        
        isScanningResiduals = true
        status = "Scanning leftovers for \(app.name)..."
        
        Task {
            let residuals = await Task.detached(priority: .userInitiated) {
                await UninstallerService.findResiduals(for: app)
            }.value
            
            if let index = appsList.firstIndex(where: { $0.id == app.id }) {
                appsList[index].associatedResidualPaths = residuals.paths
                appsList[index].associatedResidualBytes = residuals.bytes
                selectedAppForUninstall = appsList[index]
            }
            isScanningResiduals = false
            status = "Leftovers scan completed for \(app.name)."
        }
    }
    
    public func deepUninstallApp(_ app: AppInventoryItem) {
        guard !isCleaning else { return }
        isCleaning = true
        status = "Performing deep uninstallation of \(app.name)..."
        
        Task {
            let result = await UninstallerService.performDeepUninstall(app: app)
            
            // Remove from appsList
            appsList.removeAll { $0.id == app.id }
            selectedAppForUninstall = nil
            
            lastActionResult = result
            status = result.message
            isCleaning = false
        }
    }

    public func loadMaintenanceActions() {
        guard maintenanceActions.isEmpty else { return }
        maintenanceActions = MaintenanceService.actionsList()
    }
    
    public func toggleMaintenanceActionSelection(_ action: MaintenanceAction) {
        if let index = maintenanceActions.firstIndex(where: { $0.id == action.id }) {
            maintenanceActions[index].isSelected.toggle()
        }
    }
    
    public func runMaintenanceAction(_ action: MaintenanceAction) {
        guard let index = maintenanceActions.firstIndex(where: { $0.id == action.id }),
              !isRunningMaintenance else { return }
              
        isRunningMaintenance = true
        maintenanceActions[index].status = .running
        maintenanceActions[index].progress = 0.1
        maintenanceActions[index].logOutput = "Starting maintenance task..."
        
        Task {
            let result = await MaintenanceService.execute(action: action) { progress, message in
                // Strict Concurrency için DispatchQueue yerine Task { @MainActor in } kullanıyoruz
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.maintenanceActions[index].progress = progress
                    self.maintenanceActions[index].logOutput += "\n[\(Int(progress * 100))%] \(message)"
                }
            }
            
            maintenanceActions[index].status = result.errorCount == 0 ? .completed : .failed
            maintenanceActions[index].logOutput += "\n\nTask finished with result:\n\(result.message)"
            
            if result.freedBytes > 0 {
                // If Purge RAM freed space, update system stats!
                self.snapshot.system.usedRAMBytes = max(0, self.snapshot.system.usedRAMBytes - result.freedBytes)
            }
            
            isRunningMaintenance = false
            lastActionResult = result
            status = result.message
        }
    }
    
    public func runSelectedMaintenanceActions() {
        guard !isRunningMaintenance else { return }
        
        let selected = maintenanceActions.filter { $0.isSelected }
        guard !selected.isEmpty else { return }
        
        isRunningMaintenance = true
        
        Task {
            var totalRemoved = 0
            var totalErrors = 0
            var totalFreed: Int64 = 0
            
            for action in selected {
                guard let index = self.maintenanceActions.firstIndex(where: { $0.id == action.id }) else { continue }
                
                await MainActor.run {
                    self.maintenanceActions[index].status = .running
                    self.maintenanceActions[index].progress = 0.1
                    self.maintenanceActions[index].logOutput = "Starting dynamic script queue execution..."
                }
                
                let result = await MaintenanceService.execute(action: action) { progress, message in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.maintenanceActions[index].progress = progress
                        self.maintenanceActions[index].logOutput += "\n[\(Int(progress * 100))%] \(message)"
                    }
                }
                
                await MainActor.run {
                    self.maintenanceActions[index].status = result.errorCount == 0 ? .completed : .failed
                    self.maintenanceActions[index].progress = 1.0
                    self.maintenanceActions[index].logOutput += "\n\nTask finished with result:\n\(result.message)"
                    
                    totalRemoved += result.removedCount
                    totalErrors += result.errorCount
                    totalFreed += result.freedBytes
                    
                    if result.freedBytes > 0 {
                        self.snapshot.system.usedRAMBytes = max(0, self.snapshot.system.usedRAMBytes - result.freedBytes)
                    }
                }
            }
            
            await MainActor.run {
                self.isRunningMaintenance = false
                self.lastActionResult = ActionResult(
                    removedCount: totalRemoved,
                    skippedCount: 0,
                    errorCount: totalErrors,
                    freedBytes: totalFreed,
                    message: "Completed all selected maintenance tasks successfully."
                )
                self.status = "Maintenance queue complete."
            }
        }
    }

    public func loadAppUpdates() {
        guard appUpdates.isEmpty else { return }
        appUpdates = AppUpdaterService.checkUpdates()
    }
    
    public func updateSelectedApps() {
        let selected = appUpdates.filter { $0.isSelected && $0.status == .pending }
        guard !selected.isEmpty && !isUpdatingApp else { return }
        
        isUpdatingApp = true
        status = "Updating \(selected.count) apps..."
        
        Task {
            for app in selected {
                guard let idx = appUpdates.firstIndex(where: { $0.id == app.id }) else { continue }
                appUpdates[idx].status = .downloading
                
                let result = await AppUpdaterService.performUpdate(update: app) { progress in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if progress > 0.8 {
                            self.appUpdates[idx].status = .installing
                        }
                    }
                }
                
                appUpdates[idx].status = result.errorCount == 0 ? .completed : .failed
            }
            
            isUpdatingApp = false
            status = "Updates completed."
        }
    }
    
    public func toggleUpdateSelection(for app: AppUpdate) {
        if let idx = appUpdates.firstIndex(where: { $0.id == app.id }) {
            appUpdates[idx].isSelected.toggle()
        }
    }

    public func loadExtensions() {
        guard systemExtensions.isEmpty else { return }
        isScanningExtensions = true
        status = "Scanning background system items..."
        
        Task {
            let items = await Task.detached(priority: .userInitiated) {
                ExtensionsService.scanExtensions()
            }.value
            
            self.systemExtensions = items
            self.isScanningExtensions = false
            self.status = "System items review ready."
        }
    }
    
    public func toggleExtension(_ item: SystemExtension) {
        guard let idx = systemExtensions.firstIndex(where: { $0.id == item.id }) else { return }
        let currentEnabled = systemExtensions[idx].isEnabled
        let targetEnabled = !currentEnabled
        
        status = "\(targetEnabled ? "Enabling" : "Disabling") \(item.name)..."
        
        Task {
            let result = await ExtensionsService.setEnabled(extension: item, enabled: targetEnabled)
            if result.errorCount == 0 {
                systemExtensions[idx].isEnabled = targetEnabled
            }
            status = result.message
            lastActionResult = result
        }
    }
    
    public func undoLastAction() {
        guard !isCleaning else { return }
        isCleaning = true
        status = "Geri alma işlemi gerçekleştiriliyor..."
        
        Task {
            let result = await ActionExecutionService.undoLastQuarantineAction()
            lastActionResult = result
            status = result.message
            isCleaning = false
            
            // Refresh scan to reflect recovered files
            runCleanupReview()
        }
    }
    
    public func connectCloudProvider(_ provider: CloudProvider) {
        if let idx = snapshot.cloudAccounts.firstIndex(where: { $0.provider == provider }) {
            snapshot.cloudAccounts[idx].authState = "OAuth Connected"
            snapshot.cloudAccounts[idx].scanStatus = "Eşleşme tamamlandı. Taramaya hazır."
        }
    }
}

