import Foundation
import ServiceManagement

public final class BackgroundScheduleManager {
    static let shared = BackgroundScheduleManager()
    
    public func updateSchedule(interval: String) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.agent(plistName: "com.mole.backgroundscan.plist")
            
            // Eski zamanlamayı temizle
            if service.status == .enabled {
                try? service.unregister()
            }
            
            guard interval != "disabled" else { return }
            
            do {
                try service.register()
                print("Arka plan taraması SMAppService üzerinden \(interval) olarak ayarlandı.")
            } catch {
                print("Zamanlama kaydedilemedi: \(error.localizedDescription)")
            }
        } else {
            print("SMAppService macOS 13.0 ve üzeri gerektirir.")
        }
    }
}
