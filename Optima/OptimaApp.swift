//
//  OptimaApp.swift
//  Optima
//
//  Architecture principale de l'application Optima
//  Gère le cycle de vie et la navigation globale
//

import SwiftUI
import Sparkle

// 🔑 CORRECTION : Imports manquants pour résoudre les erreurs de compilation
// Ces imports sont nécessaires pour que les commandes menu fonctionnent correctement

@main
struct OptimaApp: App {
    
    // MARK: - Configuration Centrale
    @StateObject private var appCoordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            MainNavigationView()
                .environmentObject(appCoordinator)
                .frame(minWidth: 1200, minHeight: 800)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    // 🔑 CORRECTION : Sauvegarde avant fermeture de l'application
                    Task {
                        await appCoordinator.applicationWillTerminate()
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            OptimaCommands(coordinator: appCoordinator)
        }
        
        // MARK: - Fenêtre Préférences (Gestion Manuelle)
        // Suppression de la Settings Scene automatique pour éviter le doublon
        // La fenêtre sera gérée manuellement par AppCoordinator
    }
}
