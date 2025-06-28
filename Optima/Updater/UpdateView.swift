//
//  UpdateView.swift
//  Optima
//
//  Composants SwiftUI pour l'intégration de Sparkle.
//  Inspiré par l'exemple officiel de Sparkle.
//

import SwiftUI
import Sparkle

// Ce view model publie l'état d'activation pour la vérification des mises à jour.
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// Vue pour l'élément de menu "Vérifier les mises à jour...".
// L'utilisation d'une vue intermédiaire est nécessaire pour que l'état `disabled`
// du bouton de menu fonctionne correctement sur les versions de macOS antérieures à Monterey.
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        
        // Création du view model pour notre vue.
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button("Vérifier les mises à jour…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

// Vue pour les paramètres de mise à jour Sparkle.
// Gère l'état local pour les préférences de mise à jour et les propage à l'updater.
struct UpdaterSettingsView: View {
    private let updater: SPUUpdater
    @StateObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    
    @State private var automaticallyChecksForUpdates: Bool
    @State private var automaticallyDownloadsUpdates: Bool
    
    init(updater: SPUUpdater) {
        self.updater = updater
        
        // Le view model pour observer l'état du bouton "Vérifier maintenant"
        self._checkForUpdatesViewModel = StateObject(wrappedValue: CheckForUpdatesViewModel(updater: updater))
        
        // Initialiser l'état local avec les valeurs actuelles de l'updater.
        self._automaticallyChecksForUpdates = State(initialValue: updater.automaticallyChecksForUpdates)
        self._automaticallyDownloadsUpdates = State(initialValue: updater.automaticallyDownloadsUpdates)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Vérifier automatiquement les mises à jour", isOn: $automaticallyChecksForUpdates)
                .onChange(of: automaticallyChecksForUpdates) { newValue in
                    updater.automaticallyChecksForUpdates = newValue
                }
            
            Toggle("Télécharger automatiquement les mises à jour", isOn: $automaticallyDownloadsUpdates)
                .disabled(!automaticallyChecksForUpdates)
                .onChange(of: automaticallyDownloadsUpdates) { newValue in
                    updater.automaticallyDownloadsUpdates = newValue
                }
        }
    }
} 