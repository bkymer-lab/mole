import SwiftUI
import MoleXPC

@main
struct MoleApp: App {
    @StateObject private var viewModel = MaintenanceViewModel()
    
    init() {
        if CommandLine.arguments.contains("--background-scan") ||
           ProcessInfo.processInfo.environment["MOLE_BACKGROUND_MODE"] == "1" {
            // Running in headless background mode via launchd / SMAppService.
            // We perform a real quick scan and write results, then exit.
            // UI is NOT shown (NSApp.setActivationPolicy(.prohibited) below).
            Task.detached(priority: .background) {
                await performHeadlessBackgroundScan()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .visualEffect(material: .underWindowBackground, blendingMode: .behindWindow, state: .followsWindowActiveState)
                .ignoresSafeArea()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    viewModel.undoLastAction()
                }
                .keyboardShortcut("z", modifiers: [.command])
            }
        }

        MenuBarExtra("Mole", systemImage: "waveform.path.ecg.rectangle") {
            Text("Health Score: \(viewModel.snapshot.healthScore.finalScore)")
            Text("Memory Pressure: \(viewModel.memoryPressureDisplayTitle)")
            Text("Cleanup Estimate: \(Formatters.bytes(viewModel.snapshot.cleanup.totalSizeBytes))")
            Divider()
            Button("Refresh Snapshot") {
                viewModel.performSmartCareAction()
            }
            Button("Open Mole") {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}

/// Performs a real headless background scan (no UI).
/// Called when launched with --background-scan or MOLE_BACKGROUND_MODE=1.
/// Results are written to ~/Library/Logs/Mole/background-scan.log.

private func performHeadlessBackgroundScan() async {
    guard let targetInterval = BackgroundScheduleManager.shared.currentIntervalSeconds() else {
        exit(0) // Disabled
    }
    
    let lastRunDate = UserDefaults.standard.object(forKey: "com.mole.backgroundscan.lastRun") as? Date ?? .distantPast
    if Date().timeIntervalSince(lastRunDate) < targetInterval {
        // Not enough time has passed
        exit(0)
    }
    
    // Update last run time
    UserDefaults.standard.set(Date(), forKey: "com.mole.backgroundscan.lastRun")
    
    let logDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/Mole")
    try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
    let logFile = logDir.appendingPathComponent("background-scan.log")
    
    let start = Date()
    var log = "[\(start)] Mole background scan started.\n"
    
    do {
        let snapshot = await MaintenanceCore.healthSnapshot()
        let cleanupSize = Formatters.bytes(snapshot.cleanup.totalSizeBytes)
        let healthScore = snapshot.healthScore.finalScore
        // ThreatFinding.confidence is a Double 0.0-1.0; high-severity = confidence > 0.75
        let threats = snapshot.protection.findings.filter { $0.confidence > 0.75 }.count

        
        log += "[\(Date())] Health Score: \(healthScore)/100\n"
        log += "[\(Date())] Reclaimable: \(cleanupSize)\n"
        log += "[\(Date())] High/Critical Threats: \(threats)\n"
        log += "[\(Date())] Scan complete. Duration: \(String(format: "%.1f", Date().timeIntervalSince(start)))s\n"
        
        // Send notification if threats or large cleanup found
        if threats > 0 || snapshot.cleanup.totalSizeBytes > 500 * 1024 * 1024 {
            await sendBackgroundScanNotification(healthScore: healthScore, cleanupSize: cleanupSize, threats: threats)
        }
    }
    
    try? log.write(to: logFile, atomically: true, encoding: .utf8)
    
    // Background agent exits after completing its task
    exit(0)
}

import UserNotifications

private func sendBackgroundScanNotification(healthScore: Int, cleanupSize: String, threats: Int) async {
    let content = UNMutableNotificationContent()
    content.title = "Mole Background Scan Complete"
    if threats > 0 {
        content.subtitle = "\(threats) threat(s) detected"
    }
    content.body = "Health: \(healthScore)/100 · \(cleanupSize) reclaimable. Tap to review."
    content.sound = .default
    
    let request = UNNotificationRequest(identifier: "mole.background-scan.\(Date().timeIntervalSince1970)", content: content, trigger: nil)
    try? await UNUserNotificationCenter.current().add(request)
}
