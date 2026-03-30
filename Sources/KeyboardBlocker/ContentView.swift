import SwiftUI

struct ContentView: View {
    @StateObject private var keyboardBlocker = KeyboardBlocker()
    @State var isBlocking = false
    @State private var hasPermission = false
    var overlayHandler: AppDelegate
    
    init(overlayHandler: AppDelegate) {
        self.overlayHandler = overlayHandler
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Logo ve başlık
            VStack(spacing: 15) {
                ZStack {
                    // Arka plan halkası
                    Circle()
                        .fill(Color(.windowBackgroundColor).opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    // Dış halka (accent color)
                    Circle()
                        .strokeBorder(isBlocking ? Color.red.opacity(0.8) : Color.blue.opacity(0.8), lineWidth: 2)
                        .frame(width: 100, height: 100)
                    
                    // İkon
                    Image(systemName: isBlocking ? "keyboard.fill" : "keyboard")
                        .font(.system(size: 45, weight: .light))
                        .foregroundColor(isBlocking ? .red : .blue)
                        .frame(width: 70, height: 70)
                }
                .animation(.easeInOut(duration: 0.3), value: isBlocking)
                
                Text(isBlocking ? "Keyboard Locked" : "Keyboard Blocker")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(isBlocking ? .red : .primary)
            }
            .padding(.top, 20)
            
            if !hasPermission {
                permissionView
            } else {
                if isBlocking {
                    lockedView
                } else {
                    unlockView
                }
            }
            
            Spacer()
        }
        .frame(width: 320, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            checkPermission()
            setupEmergencyUnlock()
        }
    }
    
    // İzin View'i
    private var permissionView: some View {
        VStack(spacing: 20) {
            Text("Input Monitoring Permission Required")
                .font(.headline)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            
            Text("This app needs permission to monitor input to block your keyboard.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 15) {
                Button("Grant Permission") {
                    PermissionsManager.shared.requestInputMonitoringPermission()
                    checkPermission()
                }
                .buttonStyle(ModernButtonStyle(color: .blue))
                
                Button("Open Settings") {
                    PermissionsManager.shared.openPrivacyPreferences()
                }
                .buttonStyle(ModernButtonStyle(color: Color(NSColor.controlColor)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
        )
        .padding(.horizontal)
    }
    
    // Kilitli Durumda Görünüm
    private var lockedView: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Your keyboard is now locked for cleaning")
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Text("ESC")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Text("Hold ESC key for 3 seconds to unlock")
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)
            }
            .opacity(keyboardBlocker.isEscPressed ? 0 : 1.0)
            .animation(.easeInOut, value: keyboardBlocker.isEscPressed)
            
            // ESC Basılı Tutma Göstergesi
            if keyboardBlocker.isEscPressed {
                ZStack {
                    // Arka plan halkası
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    // İlerleme halkası (Tersi: Başlangıçta dolu, azalarak biter)
                    Circle()
                        .trim(from: 0.0, to: keyboardBlocker.unlockProgress)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.05), value: keyboardBlocker.unlockProgress)
                    
                    // Geri sayım sayısı
                    let secondsLeft = Int(ceil(keyboardBlocker.unlockProgress * 3.0))
                    Text("\(secondsLeft)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.primary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(keyboardBlocker.isEscPressed ? 0 : 0.6))
                .shadow(color: .black.opacity(keyboardBlocker.isEscPressed ? 0 : 0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .transition(.opacity)
    }
    
    // Kilit Açık Durumda Görünüm
    private var unlockView: some View {
        VStack(spacing: 20) {
            Text("Ready to lock your keyboard for cleaning")
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
            
            Button(action: toggleBlocking) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text("Lock Keyboard")
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(minWidth: 180)
            }
            .buttonStyle(ModernButtonStyle(color: .blue))
            .padding(.top, 10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .transition(.opacity)
    }
    
    private func checkPermission() {
        hasPermission = PermissionsManager.shared.checkInputMonitoringPermission()
    }
    
    private func setupEmergencyUnlock() {
        // Acil durum kilit açma handler'ını ayarla
        keyboardBlocker.setEmergencyUnlockHandler {
            if isBlocking {
                toggleBlocking()
            }
        }
    }
    
    func toggleBlocking() {
        withAnimation {
            isBlocking.toggle()
        }
        
        if isBlocking {
            keyboardBlocker.startBlocking()
            overlayHandler.showOverlay()
        } else {
            keyboardBlocker.stopBlocking()
            overlayHandler.hideOverlay()
        }
    }
}

// Modern macOS tarzı buton stili
struct ModernButtonStyle: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(configuration.isPressed ? 0.7 : 1))
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAppDelegate = AppDelegate()
        return ContentView(overlayHandler: mockAppDelegate)
    }
} 