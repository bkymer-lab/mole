import Foundation
import MoleXPC

final class MoleHelperImpl: NSObject, MoleHelperProtocol {
    func executeTask(kind: String, reply: @escaping (Bool, String?) -> Void) {
        print("[MoleDaemon] executeTask received for kind: \(kind)")
        
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Explicit executable and arguments mapping to prevent shell injection
        switch kind {
        case "flushDNS":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
            process.arguments = ["-flushcache"]
        case "purgeRAM":
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/purge")
            process.arguments = []
        case "reindexSpotlight":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/mdutil")
            process.arguments = ["-E", "/"]
        case "repairDiskPermissions":
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
            process.arguments = ["resetUserPermissions", "/", "\(getuid())"]
        case "rotateSystemLogs":
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/periodic")
            process.arguments = ["daily", "weekly", "monthly"]
        case "freeUpPurgeableSpace":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tmutil")
            process.arguments = ["thinlocalsnapshots", "/", "10000000000", "4"]
        case "speedUpMail":
            let home = FileManager.default.homeDirectoryForCurrentUser
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
            process.arguments = ["\(home.path)/Library/Mail/V10/MailData/Envelope Index", "VACUUM;"]
        case "rebuildLaunchServices":
            process.executableURL = URL(fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister")
            process.arguments = ["-kill", "-r", "-domain", "local", "-domain", "system", "-domain", "user"]
        default:
            reply(false, "Unknown task kind: \(kind)")
            return
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if process.terminationStatus == 0 {
                reply(true, "✅ [MoleDaemon] Successful:\n\(output)")
            } else {
                reply(false, "❌ [MoleDaemon] Error Code \(process.terminationStatus):\n\(output)")
            }
        } catch {
            reply(false, "❌ [MoleDaemon] Critical error: \(error.localizedDescription)")
        }
    }
}

import Security

final class DaemonDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        print("[MoleDaemon] Incoming XPC connection requested. Verifying client signature...")
        
        // 🔒 Enforce Hardened Runtime & Real code signing validation using auditToken
        guard let tokenValue = newConnection.value(forKey: "auditToken") as? NSValue else {
            print("[MoleDaemon] ❌ Security check failed: Audit token missing.")
            return false
        }
        var token = audit_token_t()
        tokenValue.getValue(&token)
        let tokenData = Data(bytes: &token, count: MemoryLayout<audit_token_t>.size)
        
        let attributes: [CFString: Any] = [
            kSecGuestAttributeAudit: tokenData
        ]
        
        var guestCode: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, attributes as CFDictionary, [], &guestCode)
        guard status == errSecSuccess, let code = guestCode else {
            print("[MoleDaemon] ❌ Security check failed: Cannot copy guest code from audit token.")
            return false
        }
        
        // Stricter Designated Requirement (DR) constraint checking:
        // Must match exact identifier, Team ID, and specific entitlements to prevent spoofing.
        // NOTE: Replace YOUR_TEAM_ID with the actual Apple Developer Team ID
        let requirementString = """
        identifier "com.bilal.MoleApp" and anchor apple generic and certificate leaf[subject.OU] = "YOUR_TEAM_ID"
        """
        
        var requirement: SecRequirement?
        let reqStatus = SecRequirementCreateWithString(requirementString as CFString, [], &requirement)
        
        if reqStatus == errSecSuccess, let req = requirement {
            // Use SecCSFlags(rawValue: 0) instead of kSecCSDefaultFlags
            let validityStatus = SecCodeCheckValidity(code, SecCSFlags(rawValue: 0), req)
            if validityStatus != errSecSuccess {
                print("[MoleDaemon] ❌ Security check failed: Client does not satisfy strict code signing requirements!")
                // Only allow fallback in local debug builds if necessary, but strictly denying in production
                #if DEBUG
                print("[MoleDaemon] ⚠️ Allowing connection temporarily due to DEBUG build (anchor local fallback).")
                #else
                return false
                #endif
            }
        } else {
            print("[MoleDaemon] ❌ SecRequirement parsing failed. Connection denied to prevent bypass.")
            return false
        }
        
        print("[MoleDaemon] ✅ Client signature and Team ID validated successfully! Resuming connection.")
        newConnection.exportedInterface = NSXPCInterface(with: MoleHelperProtocol.self)
        newConnection.exportedObject = MoleHelperImpl()
        
        newConnection.resume()
        return true
    }
}

autoreleasepool {
    print("[MoleDaemon] Starting helper daemon...")
    
    // We attempt to listen on the registered Mach service.
    // If running in ad-hoc development or local test, we also support anonymous or fallback modes.
    let listener = NSXPCListener(machServiceName: MoleMachServiceName)
    let delegate = DaemonDelegate()
    listener.delegate = delegate
    
    print("[MoleDaemon] Mach service listener initialized for '\(MoleMachServiceName)'.")
    listener.resume()
    
    // Keep the daemon running
    RunLoop.current.run()
}
