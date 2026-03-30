import SwiftUI

struct MenuBarIconView: View {
    @ObservedObject var appState: AppState
    @State private var pulse = false

    private var symbolName: String {
        if #available(macOS 12.0, *) {
            return appState.isBlocking ? "keyboard.badge.lock" : "keyboard"
        }
        return appState.isBlocking ? "lock.fill" : "keyboard"
    }

    var body: some View {
        ZStack {
            if appState.isBlocking {
                Circle()
                    .stroke(Color.primary.opacity(0.35), lineWidth: 1)
                    .frame(width: 15, height: 15)
                    .scaleEffect(pulse ? 1.2 : 1.0)
                    .opacity(pulse ? 0.15 : 0.55)
            }
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
                .scaleEffect(appState.isBlocking && pulse ? 1.05 : 1.0)
        }
        .frame(width: 18, height: 18)
        .onChange(of: appState.isBlocking) { locked in
            pulse = false
            if locked {
                withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .onAppear {
            if appState.isBlocking {
                withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }
}
