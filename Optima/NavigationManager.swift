import SwiftUI
import Combine

enum NavigationDestination {
    case studyTab(studyItemId: UUID?)
    // Ajoutez d'autres destinations si nécessaire
}

class NavigationManager: ObservableObject {
    @Published var requestedDestination: NavigationDestination?

    func requestNavigation(to destination: NavigationDestination) {
        self.requestedDestination = destination
    }
} 