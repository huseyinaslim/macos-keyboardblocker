import SwiftUI
import AppKit

// Create and configure the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Run the application
app.run()

// App Delegate to handle application lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var overlayWindows: [NSWindow] = []
    var keyboardBlockerView: ContentView?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // İlk başlangıçta izinleri kontrol et ve iste
        let hasPermission = PermissionsManager.shared.checkInputMonitoringPermission()
        if !hasPermission {
            print("İzin verilmedi, izin isteniyor...")
            PermissionsManager.shared.requestInputMonitoringPermission()
            
            // Kullanıcıya izin vermesi için bir dialog göster
            let alert = NSAlert()
            alert.messageText = "Klavye Kilidi İzin Gerekiyor"
            alert.informativeText = "Bu uygulama, klavyenizi kilitlemek için 'Giriş İzleme' iznine ihtiyaç duyar. Lütfen izin verin ve sonra uygulamayı yeniden başlatın."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Ayarları Aç")
            alert.addButton(withTitle: "Tamam")
            
            if alert.runModal() == .alertFirstButtonReturn {
                PermissionsManager.shared.openPrivacyPreferences()
            }
        }
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView(overlayHandler: self)
        keyboardBlockerView = contentView
        
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 380),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window?.center()
        window?.setFrameAutosaveName("Main Window")
        window?.contentView = NSHostingView(rootView: contentView)
        window?.makeKeyAndOrderFront(nil)
        window?.title = "Keyboard Blocker"
        window?.level = .floating // Her zaman en üstte göster
        
        // Pencere stilini modernleştir - vibrancy ve şeffaflık ekle
        if let windowView = window?.contentView {
            windowView.wantsLayer = true
            windowView.layer?.cornerRadius = 10
            
            // Başlık çubuğunu daha modern göster
            window?.titlebarAppearsTransparent = true
            window?.titleVisibility = .hidden
        }
        
        // Ekranın altına transparan siyah overlay ekleme (tüm ekranlar için)
        createOverlayWindows()
        
        // Pencereyi öne getir
        NSApp.activate(ignoringOtherApps: true)
        
        // Acil durum kapatma için klavye kısayolu ekle
        registerAppTerminationHotkey()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Uygulamayı kapatmadan önce herhangi bir kilitleme varsa kaldır
        if let keyboardBlockerView = keyboardBlockerView, keyboardBlockerView.isBlocking {
            keyboardBlockerView.toggleBlocking()
        }
        return true
    }
    
    // Uygulamayı kapatma işlemi
    func applicationWillTerminate(_ notification: Notification) {
        // Uygulamayı kapatmadan önce herhangi bir kilitleme varsa kaldır
        if let keyboardBlockerView = keyboardBlockerView, keyboardBlockerView.isBlocking {
            keyboardBlockerView.toggleBlocking()
        }
    }
    
    // Escape tuşuyla uygulamayı kapatma kısayolunu kaydet
    private func registerAppTerminationHotkey() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            // CMD+Q kombinasyonu ile uygulamayı kapat
            if event.modifierFlags.contains(.command) && event.keyCode == 12 { // Q tuşu
                NSApp.terminate(nil)
                return nil
            }
            
            // CMD+W ile pencereyi kapat
            if event.modifierFlags.contains(.command) && event.keyCode == 13 { // W tuşu
                self?.window?.close()
                return nil
            }
            
            return event
        }
    }
    
    // Tüm ekranlar için overlay pencereleri oluştur
    func createOverlayWindows() {
        // Mevcut overlayleri temizle
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()
        
        // Sistemdeki tüm ekranları al
        let screens = NSScreen.screens
        
        // Her ekran için bir overlay penceresi oluştur
        for screen in screens {
            let overlayWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen)
            
            overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.0) // Başlangıçta tamamen transparan
            overlayWindow.isOpaque = false
            overlayWindow.hasShadow = false
            overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow))) // En yüksek seviye
            overlayWindow.ignoresMouseEvents = true // Başlangıçta mouse tıklamalarını engelleme
            
            // Tam ekran uygulamalar üzerinde de görünmesini sağla
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            // Pencereyi listeye ekle
            overlayWindows.append(overlayWindow)
        }
    }
    
    // Keyboard blocker aktifken overlay'i göster (tüm ekranlarda)
    func showOverlay() {
        // Yeni ekranlar eklenmişse pencerelerimizi güncelle
        if NSScreen.screens.count != overlayWindows.count {
            createOverlayWindows()
        }
        
        // Tüm ekranlardaki overlay'leri göster
        for (index, overlayWindow) in overlayWindows.enumerated() {
            guard index < NSScreen.screens.count else { break }
            
            // Ekran boyutuna göre overlay penceresini yeniden boyutlandır
            let screen = NSScreen.screens[index]
            overlayWindow.setFrame(screen.frame, display: true)
            
            // Daha zarif bir overlay için %40 saydamlık kullan
            overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.4)
            overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.ignoresMouseEvents = false // Mouse tıklamalarını engelle
        }
        
        // Ana pencereyi overlay'in üstünde tut
        window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 1)
        window?.orderFrontRegardless()
    }
    
    // Keyboard blocker deaktif olduğunda overlay'i gizle
    func hideOverlay() {
        // Tüm ekranlardaki overlay'leri gizle
        for overlayWindow in overlayWindows {
            overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.0)
            overlayWindow.orderOut(nil)
            overlayWindow.ignoresMouseEvents = true // Mouse tıklamalarını engelleme
        }
        
        // Ana pencere seviyesini düşür
        window?.level = .floating
        window?.orderFrontRegardless()
    }
} 