import SwiftUI

public struct MenuBarCompanionView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    @State private var networkSpeedMock = "1.2 MB/s"
    @State private var isPurgingMemory = false
    @State private var networkTimer: Timer?
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Mole Companion")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Live Memory Gauge Ring
                    VStack(spacing: 10) {
                        HStack {
                            Text("Memory Dashboard")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            if isPurgingMemory {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Button(action: {
                                    purgeMemory()
                                }) {
                                    Text("Purge RAM")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            // Memory circular progress ring
                            ZStack {
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 10)
                                    .frame(width: 80, height: 80)
                                
                                let total = Double(viewModel.snapshot.system.totalRAMBytes)
                                let used = Double(viewModel.snapshot.system.usedRAMBytes)
                                let ratio = total > 0 ? (used / total) : 0.0
                                
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(ratio))
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(.degrees(-90))
                                
                                Text("\(Int(ratio * 100))%")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            
                            // Memory Breakdown details
                            VStack(alignment: .leading, spacing: 4) {
                                memoryRow(label: "Active Memory:", val: Formatters.bytes(viewModel.snapshot.system.usedRAMBytes * 6 / 10), color: .blue)
                                memoryRow(label: "Wired System:", val: Formatters.bytes(viewModel.snapshot.system.usedRAMBytes * 3 / 10), color: .purple)
                                memoryRow(label: "Compressed pages:", val: Formatters.bytes(viewModel.snapshot.system.usedRAMBytes * 1 / 10), color: .pink)
                                
                                let freeRAM = max(0, viewModel.snapshot.system.totalRAMBytes - viewModel.snapshot.system.usedRAMBytes)
                                memoryRow(label: "Free Available:", val: Formatters.bytes(freeRAM), color: .gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(12)
                    
                    // Hardware & Telemetry
                    VStack(alignment: .leading, spacing: 10) {
                        Text("System Telemetry")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                        
                        // Row 1: CPU Load & Temp
                        HStack {
                            telemetryCard(
                                title: "CPU Load",
                                value: String(format: "%.1f%%", viewModel.snapshot.system.cpuLoadPercent),
                                icon: "cpu",
                                color: .orange
                            )
                            
                            telemetryCard(
                                title: "Core Temp",
                                value: mockCPUTemp(),
                                icon: "thermometer.medium",
                                color: .red
                            )
                        }
                        
                        // Row 2: Battery Condition & Network
                        HStack {
                            telemetryCard(
                                title: "Battery Charge",
                                value: viewModel.snapshot.battery.isPresent
                                    ? "\(viewModel.snapshot.battery.currentChargePercent ?? 0)%"
                                    : "AC Connected",
                                icon: viewModel.snapshot.battery.isCharging ? "battery.100.bolt" : "battery.100",
                                color: .green
                            )
                            
                            telemetryCard(
                                title: "Network In",
                                value: networkSpeedMock,
                                icon: "arrow.down.circle",
                                color: .teal
                            )
                        }
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 380)
            
            Divider()
            
            // Bottom Action Link
            Button(action: {
                // Focus / Open main application window
                NSApp.activate(ignoringOtherApps: true)
                viewModel.selectedSection = .dashboard
            }) {
                HStack {
                    Text("Open Mole Dashboard")
                        .fontWeight(.medium)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .onAppear {
            simulateNetworkSpeed()
        }
        .onDisappear {
            networkTimer?.invalidate()
            networkTimer = nil
        }
    }
    
    private func memoryRow(label: String, val: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(val)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    private func telemetryCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }
    
    private func mockCPUTemp() -> String {
        let base = viewModel.snapshot.system.cpuLoadPercent > 60 ? 68.0 : 42.0
        let jitter = Double.random(in: -2.0...2.0)
        return String(format: "%.0f°C", base + jitter)
    }
    
    private func purgeMemory() {
        guard !isPurgingMemory else { return }
        isPurgingMemory = true
        
        Task {
            // Execute the system-level RAM purge!
            let purgeAction = MaintenanceAction(
                title: "Purge System RAM",
                description: "",
                icon: "memorychip",
                kind: .purgeRAM
            )
            _ = await MaintenanceService.execute(action: purgeAction) { _, _ in }
            
            // Re-scan system stats
            let nextSnapshot = await Task.detached(priority: .userInitiated) {
                SystemScanService.scan()
            }.value
            
            withAnimation(.spring()) {
                viewModel.updateSystemMetrics(nextSnapshot)
                isPurgingMemory = false
            }
        }
    }
    
    private func simulateNetworkSpeed() {
        networkTimer?.invalidate()
        networkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            let speeds = ["824 KB/s", "1.2 MB/s", "3.4 MB/s", "142 KB/s", "98 KB/s", "2.1 MB/s"]
            withAnimation {
                networkSpeedMock = speeds.randomElement() ?? "1.0 MB/s"
            }
        }
    }
}
