import SwiftUI
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    var overlayWindows: [NSWindow] = []
    var keyboardBlockerView: ContentView?
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var iconHostingView: NSHostingView<MenuBarIconView>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hasPermission = PermissionsManager.shared.checkInputMonitoringPermission()
        if !hasPermission {
            print("İzin verilmedi, izin isteniyor...")
            PermissionsManager.shared.requestInputMonitoringPermission()

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

        let contentView = ContentView(overlayHandler: self, appState: appState)
        keyboardBlockerView = contentView

        setupStatusItem(with: contentView)
        createOverlayWindows()
        NSApp.activate(ignoringOtherApps: true)
        registerAppTerminationHotkey()
    }

    private func setupStatusItem(with contentView: ContentView) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item

        guard let button = item.button else { return }

        let iconView = MenuBarIconView(appState: appState)
        let hosting = NSHostingView(rootView: iconView)
        hosting.frame = NSRect(x: 0, y: 0, width: 22, height: 22)
        iconHostingView = hosting

        button.title = ""
        button.image = nil
        button.addSubview(hosting)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            hosting.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            hosting.widthAnchor.constraint(equalToConstant: 22),
            hosting.heightAnchor.constraint(equalToConstant: 22)
        ])

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 320, height: 420)
        // transient: overlay / dış tıklama popover'ı kapatır; kilit sonrası açık kalsın diye applicationDefined
        pop.behavior = .applicationDefined
        pop.animates = true
        pop.delegate = self
        let host = NSHostingView(rootView: contentView)
        host.frame = NSRect(origin: .zero, size: pop.contentSize)
        let controller = NSViewController()
        controller.view = host
        pop.contentViewController = controller
        popover = pop

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem?.button, let popover = popover else { return }

        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showStatusMenu(from: button)
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func showStatusMenu(from button: NSStatusBarButton) {
        let menu = NSMenu()
        let openItem = NSMenuItem(title: "Open", action: #selector(openPopoverFromMenu), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Keyboard Blocker", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        quitItem.isEnabled = keyboardBlockerView?.isBlocking != true
        menu.addItem(quitItem)
        menu.popUp(positioning: nil, at: NSPoint(x: button.bounds.midX, y: button.bounds.minY), in: button)
    }

    @objc private func openPopoverFromMenu() {
        guard let button = statusItem?.button, let popover = popover, !popover.isShown else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let keyboardBlockerView = keyboardBlockerView, keyboardBlockerView.isBlocking {
            keyboardBlockerView.toggleBlocking()
        }
    }

    private func registerAppTerminationHotkey() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.modifierFlags.contains(.command) && event.keyCode == 12 {
                if self?.keyboardBlockerView?.isBlocking == true {
                    NSSound.beep()
                    return nil
                }
                NSApp.terminate(nil)
                return nil
            }
            return event
        }
    }

    func createOverlayWindows() {
        overlayWindows.forEach { $0.orderOut(nil) }
        overlayWindows.removeAll()

        for screen in NSScreen.screens {
            let overlayWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen)

            overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.0)
            overlayWindow.isOpaque = false
            overlayWindow.hasShadow = false
            overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            overlayWindow.ignoresMouseEvents = true
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            overlayWindows.append(overlayWindow)
        }
    }

    func showOverlay() {
        if NSScreen.screens.count != overlayWindows.count {
            createOverlayWindows()
        }

        for (index, overlayWindow) in overlayWindows.enumerated() {
            guard index < NSScreen.screens.count else { break }

            let screen = NSScreen.screens[index]
            overlayWindow.setFrame(screen.frame, display: true)
            overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.4)
            overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            overlayWindow.makeKeyAndOrderFront(nil)
            overlayWindow.ignoresMouseEvents = false
        }

        raisePopoverWindowAboveOverlayIfNeeded()
    }

    func hideOverlay() {
        for overlayWindow in overlayWindows {
            overlayWindow.backgroundColor = NSColor.black.withAlphaComponent(0.0)
            overlayWindow.orderOut(nil)
            overlayWindow.ignoresMouseEvents = true
        }
        resetPopoverWindowLevelIfNeeded()
    }

    private func raisePopoverWindowAboveOverlayIfNeeded() {
        guard let popover = popover, popover.isShown,
              let w = popover.contentViewController?.view.window else { return }
        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)) + 2)
        w.orderFrontRegardless()
    }

    private func resetPopoverWindowLevelIfNeeded() {
        guard let w = popover?.contentViewController?.view.window else { return }
        w.level = .popUpMenu
    }
}

extension AppDelegate: KeyboardBlockerMousePolicy {
    func isOverlayWindow(_ window: NSWindow) -> Bool {
        overlayWindows.contains { $0 === window }
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidShow(_ notification: Notification) {
        if keyboardBlockerView?.isBlocking == true {
            raisePopoverWindowAboveOverlayIfNeeded()
        }
    }
}
