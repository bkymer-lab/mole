import Foundation
import ServiceManagement

public final class BackgroundScheduleManager {
    static let shared = BackgroundScheduleManager()
    private let intervalKey = "com.mole.backgroundscan.interval"
    
    public func updateSchedule(interval: String) {
        UserDefaults.standard.set(interval, forKey: intervalKey)
        
        if #available(macOS 13.0, *) {
            let service = SMAppService.agent(plistName: "com.mole.backgroundscan.plist")
            
            // SMAppService uses the bundled plist which triggers every 30 minutes.
            // The actual logic of whether to run the scan or skip it based on the 
            // "interval" preference is handled inside MoleApp.swift's background task.
            
            if interval == "disabled" {
                if service.status == .enabled {
                    try? service.unregister()
                }
                print("Arka plan taraması devre dışı bırakıldı.")
                return
            }
            
            if service.status != .enabled {
                do {
                    try service.register()
                    print("Arka plan servisi kaydedildi. Seçilen aralık: \(interval)")
                } catch {
                    print("Zamanlama kaydedilemedi: \(error.localizedDescription)")
                }
            } else {
                print("Arka plan servisi zaten aktif. Aralık güncellendi: \(interval)")
            }
        } else {
            print("SMAppService macOS 13.0 ve üzeri gerektirir.")
        }
    }
    
    public func currentIntervalSeconds() -> TimeInterval? {
        let interval = UserDefaults.standard.string(forKey: intervalKey) ?? "weekly"
        switch interval {
        case "daily": return 86400
        case "weekly": return 604800
        case "monthly": return 2592000
        case "disabled": return nil
        default: return 604800
        }
    }
}
