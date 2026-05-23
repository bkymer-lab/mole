import SwiftUI
import MoleXPC

@main
struct MoleApp: App {
    @StateObject private var viewModel = MaintenanceViewModel()
    
    init() {
        if CommandLine.arguments.contains("--background-scan") {
            // Arka planda başlatıldık (SMAppService / launchd tarafından)
            print("Arka plan taraması tetiklendi.")
            
            // Gerçek senaryoda burada UI oluşturulmaz, doğrudan görev çalıştırılıp bitirilir.
            // Örnek: MaintenanceViewModel().runSmartScan()
            // Ancak SwiftUI lifecycle içinde olduğumuz için bu kadarla bırakıyoruz, UI gizlenebilir
            // veya AppDelegate üzerinden tamamen headless çalıştırılabilir.
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
