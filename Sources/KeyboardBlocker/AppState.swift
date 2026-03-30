import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var isBlocking: Bool = false
}
