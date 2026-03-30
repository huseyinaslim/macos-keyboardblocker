import Foundation
import Cocoa
import SwiftUI
import IOKit
import IOKit.pwr_mgt

// ESC tuşu ve Power tuşu için özel bildirim adı
extension NSNotification.Name {
    static let escKeyPressed = NSNotification.Name("escKeyPressed")
    static let powerButtonPressed = NSNotification.Name("powerButtonPressed")
}

class KeyboardBlocker: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var systemEventMonitor: Any?
    private var keyEventMonitor: Any?
    private var localMonitor: Any?
    private var functionKeyMonitor: Any?
    private var allEventTap: CFMachPort?
    private var allRunLoopSource: CFRunLoopSource?
    private var mouseEventMonitor: Any?
    private var powerAssertion: IOPMAssertionID = 0
    private var powerAssertion2: IOPMAssertionID = 0
    
    // Kilidi kaldıracak ESC tuşunun key code'u
    private let emergencyKeyCode: UInt16 = 53 // ESC tuşu
    
    // Klavye kilitliyken durumu izlemek için
    @Published var isBlocking = false
    
    // Emergency handler closure
    private var emergencyUnlockHandler: (() -> Void)?
    
    // Timer for ESC key
    private var escTimer: Timer?
    private let pressDuration: TimeInterval = 3.0
    private let timerInterval: TimeInterval = 0.05 // Update 20 times per second for smooth UI
    
    @Published var unlockProgress: Double = 1.0 // 1.0 -> 0.0
    @Published var isEscPressed: Bool = false
    
    // F Tuşları için keyCodes
    private let fKeyCodes = Set([
        122, 123,  // Ses tuşları
        96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 109, 111, 113, 114, 115, 116, 117, 118, 119, 120, 121, // Olası tüm F tuşları
        126, 125,  // Yukarı/aşağı ok tuşları
        124, 123,  // Sağ/sol ok tuşları
        7, 8, 9, 10, 11, 12, 13,  // F1-F12 için alternatif kodlar
        63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82  // Diğer özel tuşlar
    ])
    
    deinit {
        stopBlocking()
    }
    
    // Acil durum kilit açma handler'ını ayarla
    func setEmergencyUnlockHandler(_ handler: @escaping () -> Void) {
        emergencyUnlockHandler = handler
    }
    
    func startBlocking() {
        isBlocking = true
        
        // 1. TÜM KLAVYE OLAYLARI İÇİN ENGELLEYİCİ
        captureAllKeyEvents()
        
        // 2. MEDYA TUŞLARI İÇİN ÖZEL MONİTÖR
        captureFunctionKeys()
        
        // 3. FARE OLAYLARI İÇİN MONİTÖR
        captureMouseEvents()
        
        // 4. GÜÇ TUŞUNU İZLE
        setupPowerButtonMonitoring()
        
        print("Keyboard blocking started with FULL protection")
    }
    
    // Sadece klavye olaylarını yakalayan engelleme
    private func captureAllKeyEvents() {
        // Geniş bir maske oluştur - tüm klavye ve sistem olayları için
        let eventMask = (1 << CGEventType.keyDown.rawValue) | 
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue) |
                        (1 << 14) // NX_SYSDEFINED (sistem olayları: F tuşları, ses, vb.)
        
        // Pass self as userInfo
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else { return nil }
                let mySelf = Unmanaged<KeyboardBlocker>.fromOpaque(userInfo).takeUnretainedValue()
                
                // Acil durum çıkışı: ESC tuşu
                let keycode = event.getIntegerValueField(.keyboardEventKeycode)
                if UInt16(keycode) == 53 { // ESC tuşu
                    if type == .keyDown {
                        // Start timer on key down
                        DispatchQueue.main.async {
                            mySelf.startEscTimer()
                        }
                    } else if type == .keyUp {
                        // Stop timer on key up
                        DispatchQueue.main.async {
                            mySelf.stopEscTimer()
                        }
                    }
                    // Block ESC event
                    return nil
                }
                
                // Diğer tüm olayları engelle
                // Sadece ekrana basmayı engelle, loglamayı azalt
                return nil
            },
            userInfo: observer
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        // Notification'ı dinleyelim
        NotificationCenter.default.addObserver(forName: .escKeyPressed, object: nil, queue: .main) { [weak self] _ in
            self?.emergencyUnlockHandler?()
        }
        
        // Power tuşu bildirimini de dinle
        NotificationCenter.default.addObserver(forName: .powerButtonPressed, object: nil, queue: .main) { [weak self] _ in
            self?.emergencyUnlockHandler?()
        }
    }
    
    private func startEscTimer() {
        guard escTimer == nil else { return }
        print("ESC timer started - hold for 3 seconds to unlock")
        
        // Reset state
        unlockProgress = 1.0
        isEscPressed = true
        
        let startTime = Date()
        
        escTimer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return 
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = max(0, self.pressDuration - elapsed)
            self.unlockProgress = remaining / self.pressDuration
            
            if remaining <= 0 {
                self.triggerEmergencyUnlock()
            }
        }
    }
    
    private func stopEscTimer() {
        if escTimer != nil {
            print("ESC released too early")
            escTimer?.invalidate()
            escTimer = nil
            
            // Reset UI state
            DispatchQueue.main.async {
                self.isEscPressed = false
                self.unlockProgress = 1.0
            }
        }
    }
    
    private func triggerEmergencyUnlock() {
        print("ESC held for 3 seconds - Unlocking")
        escTimer?.invalidate()
        escTimer = nil
        
        DispatchQueue.main.async {
            self.isEscPressed = false
            self.unlockProgress = 1.0 // Reset for next time
            self.emergencyUnlockHandler?()
            NotificationCenter.default.post(name: .escKeyPressed, object: nil)
        }
    }
    
    // Güç tuşunu izleme ve yakalama
    private func setupPowerButtonMonitoring() {
        // Sistem Uyku modunu engelle - güç tuşuna basıldığında uyku moduna geçmesini önle
        var assertionID: IOPMAssertionID = 0
        let success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "KeyboardBlocker is running" as CFString,
            &assertionID
        )
        
        if success == kIOReturnSuccess {
            self.powerAssertion = assertionID
            print("Power button monitoring setup successfully")
        }
        
        // Güç tuşunu izlemek için NSWorkspace'i kullan
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Güç tuşuna basıldığında kilit açma işlemini tetikle
            print("Power button pressed - unlocking keyboard")
            NotificationCenter.default.post(name: .powerButtonPressed, object: nil)
        }
        
        // Alternatif güç tuşu izleme yöntemi
        DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil,
            queue: .main
        ) { _ in
            // Ekran koruyucu başladığında (güç tuşuna uzun basma) kilit açma işlemini tetikle
            print("Power button held - screen saver starting - unlocking keyboard")
            NotificationCenter.default.post(name: .powerButtonPressed, object: nil)
        }
        
        // Güç butonu olaylarını yakalamak için IOKit kullanırken sistem uykusunu engelle
        var assertionID2: IOPMAssertionID = 0
        let success2 = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "KeyboardBlocker is running" as CFString,
            &assertionID2
        )
        
        if success2 == kIOReturnSuccess {
            self.powerAssertion2 = assertionID2
        }
    }
    
    // F tuşları ve medya tuşları için özel yakalayıcı
    private func captureFunctionKeys() {
        // F tuşları için local monitor
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .keyDown, .keyUp, .flagsChanged, .systemDefined
        ]) { [weak self] event in
            guard let self = self else { return nil }
            
            // ESC tuşu kontrolü
            if event.keyCode == self.emergencyKeyCode {
                if event.type == .keyDown {
                    self.startEscTimer()
                } else if event.type == .keyUp {
                    self.stopEscTimer()
                }
            }
            
            // Tüm klavye olaylarını engelle
            return nil
        }
        
        // Global monitor (özellikle F tuşları için)
        functionKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .keyDown, .keyUp, .systemDefined
        ]) { [weak self] event in
            guard let self = self else { return }
            
            // ESC tuşu kontrolü
            if event.keyCode == self.emergencyKeyCode {
                if event.type == .keyDown {
                     DispatchQueue.main.async { self.startEscTimer() }
                } else if event.type == .keyUp {
                     DispatchQueue.main.async { self.stopEscTimer() }
                }
            }
            
            if event.type == .systemDefined {
                print("Sistem olayı engellendi (global)")
                
                // Power tuşuna basılma kontrolü - System Defined Event'lerin içinde
                let subtype = Int16(event.subtype.rawValue)
                if subtype == 6 { // Power tuşuna karşılık gelen subtype değeri
                    print("Power button pressed - unlocking keyboard (systemDefined event)")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .powerButtonPressed, object: nil)
                    }
                }
            } else {
               // print("Tuş engellendi (global): \(event.keyCode)")
            }
        }
        
        // Daha güçlü sistem olayları engelleme
        systemEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.systemDefined]) { [weak self] event in
            guard let self = self else { return }
            
            print("Sistem olayı engellendi (system)")
            
            // Power tuşu kontrolü
            let subtype = Int16(event.subtype.rawValue)
            if subtype == 6 { // Power tuşuna karşılık gelen subtype değeri
                print("Power button pressed - unlocking keyboard (systemMonitor)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .powerButtonPressed, object: nil)
                }
            }
        }
        
        // Normal tuşlar için yardımcı monitor
        keyEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { _ in
            // Normal klavye olaylarını izle
        }
    }
    
    // Fare olaylarını yakalayan monitör
    private func captureMouseEvents() {
        mouseEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            // Mouse koordinatlarını al
            let mouseLocation = NSEvent.mouseLocation
            
            // Ana uygulamanın penceresinde ise tıklamaya izin ver
            if let window = NSApp.mainWindow,
               window.frame.contains(mouseLocation) {
                // Ana uygulamaya tıklamalara izin ver
                print("Ana uygulamaya tıklamaya izin verildi: \(mouseLocation)")
                return event
            } else {
                // Diğer tüm tıklamaları engelle
                print("Fare tıklaması engellendi: \(mouseLocation)")
                return nil
            }
        }
    }
    
    func stopBlocking() {
        isBlocking = false
        
        // Event tap'leri devre dışı bırak
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        if let allEventTap = allEventTap {
            CGEvent.tapEnable(tap: allEventTap, enable: false)
        }
        
        // RunLoop kaynaklarını kaldır
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        if let allRunLoopSource = allRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), allRunLoopSource, .commonModes)
        }
        
        // Power uyku engellemeyi kaldır
        if powerAssertion != 0 {
            IOPMAssertionRelease(powerAssertion)
            powerAssertion = 0
        }
        
        if powerAssertion2 != 0 {
            IOPMAssertionRelease(powerAssertion2)
            powerAssertion2 = 0
        }
        
        // Tüm monitörleri kaldır
        if let systemEventMonitor = systemEventMonitor {
            NSEvent.removeMonitor(systemEventMonitor)
        }
        
        if let keyEventMonitor = keyEventMonitor {
            NSEvent.removeMonitor(keyEventMonitor)
        }
        
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        
        if let functionKeyMonitor = functionKeyMonitor {
            NSEvent.removeMonitor(functionKeyMonitor)
        }
        
        if let mouseEventMonitor = mouseEventMonitor {
            NSEvent.removeMonitor(mouseEventMonitor)
        }
        
        // Referansları temizle
        eventTap = nil
        runLoopSource = nil
        systemEventMonitor = nil
        keyEventMonitor = nil
        localMonitor = nil
        functionKeyMonitor = nil
        allEventTap = nil
        allRunLoopSource = nil
        mouseEventMonitor = nil
        
        print("Keyboard blocking stopped")
    }
} 