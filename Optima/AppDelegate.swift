import SwiftUI
import Sparkle

// 3. Démarrer Sparkle au lancement de l’app
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Lance la recherche périodique et crée le menu
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,      // démarre immédiatement
            updaterDelegate: nil,       // déléguez si besoin d’événements
            userDriverDelegate: nil
        )
    }
} 