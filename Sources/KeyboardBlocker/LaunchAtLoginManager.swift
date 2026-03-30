import Foundation
import ServiceManagement

enum LaunchAtLoginManager {
    static var isSupported: Bool {
        if #available(macOS 13.0, *) {
            return true
        }
        return false
    }

    @available(macOS 13.0, *)
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @available(macOS 13.0, *)
    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static func syncToggleToSystem(_ enabled: Bool, completion: @escaping (Error?) -> Void) {
        guard #available(macOS 13.0, *) else {
            completion(nil)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try setEnabled(enabled)
                DispatchQueue.main.async { completion(nil) }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }

    static func refreshStatus() -> Bool {
        guard #available(macOS 13.0, *) else { return false }
        return isEnabled
    }
}
