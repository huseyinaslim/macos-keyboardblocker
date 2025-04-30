import Foundation
import Cocoa

class PermissionsManager {
    static let shared = PermissionsManager()
    
    private init() {}
    
    func checkInputMonitoringPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func requestInputMonitoringPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    func openPrivacyPreferences() {
        // Farklı macOS sürümleri için uygun ayarlar
        if #available(macOS 13.0, *) {
            // macOS 13 ve üzeri
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else if #available(macOS 12.0, *) {
            // macOS 12 için
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
            NSWorkspace.shared.open(url)
        } else {
            // Eski macOS sürümleri için
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security")!
            NSWorkspace.shared.open(url)
        }
    }
    
    // Kullanıcıya uygulamayı System Preferences'a eklemesi için rehberlik et
    func showPrivacyInstructions() {
        let alert = NSAlert()
        alert.messageText = "Klavye Kilitleme İzni Gerekli"
        alert.informativeText = "Bu uygulama, klavyenizi kilitleme işlevi için macOS'un 'Gizlilik & Güvenlik' ayarlarında 'Erişilebilirlik' izinlerine ihtiyaç duymaktadır.\n\n1. 'Ayarları Aç' butonuna tıklayın\n2. Sol menüden 'Gizlilik & Güvenlik' kısmını seçin\n3. 'Erişilebilirlik' seçeneğini bulun\n4. Kilit simgesini açın (kimlik doğrulama gerekebilir)\n5. Bu uygulamayı listede bulun ve yanındaki kutuyu işaretleyin\n6. Uygulamayı yeniden başlatın"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Ayarları Aç")
        alert.addButton(withTitle: "Kapat")
        
        if alert.runModal() == .alertFirstButtonReturn {
            openPrivacyPreferences()
        }
    }
} 