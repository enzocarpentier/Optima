//
//  OptimaCommands.swift
//  Optima
//
//  Commandes de menu pour l'application macOS
//  Architecture centralisée des raccourcis clavier et actions natives
//

import SwiftUI
import Foundation

/// **Commandes de menu principales pour l'application Optima**
/// 
/// Ce fichier centralise TOUTES les commandes macOS de l'application.
/// Aucune commande ne doit être définie ailleurs dans le codebase.
/// 
/// **Raccourcis clavier définis :**
/// - ⌘I : Importer un document
/// - ⌘R : Nouvelle session d'étude  
/// - ⌘⇧A : Assistant IA (Toggle)
/// - ⌘1-5 : Navigation rapide (1=Bibliothèque, 2=Lecteur, 3=Génération, 4=Étude, 5=Statistiques)
/// - ⌘, : Préférences
/// - ⌘? : Aide raccourcis
struct OptimaCommands: Commands {
    
    /// Référence à l'état global de l'application
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some Commands {
        
        // MARK: - Menu Fichier
        CommandGroup(replacing: .newItem) {
            Button("Importer un document...") {
                coordinator.showImportSheet()
            }
            .keyboardShortcut("i", modifiers: .command)
            .help("Importer un nouveau document PDF à étudier (⌘I)")
        }
        
        // MARK: - Menu Étude
        CommandMenu("Étude") {
            Button("Démarrer une nouvelle session de révision") {
                coordinator.startNewStudySession()
            }
            .keyboardShortcut("r", modifiers: .command)
            .help("Commencer une session d'étude interactive (⌘R)")
            
            Divider()
            
            Button("Basculer l'Assistant IA") {
                coordinator.toggleAIAssistant()
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            .help("Ouvrir/fermer l'assistant IA (⌘⇧A)")
        }
        
        // MARK: - Menu Navigation
        CommandMenu("Navigation") {
            Button("Aller à la Bibliothèque") {
                coordinator.navigateTo(.library)
            }
            .keyboardShortcut("1", modifiers: .command)
            .help("Parcourir vos documents importés (⌘1)")
            
            Button("Aller au Lecteur") {
                coordinator.navigateTo(.reader)
            }
            .keyboardShortcut("2", modifiers: .command)
            .help("Lire le document sélectionné (⌘2)")
            
            Button("Aller à la Génération") {
                coordinator.navigateTo(.generation)
            }
            .keyboardShortcut("3", modifiers: .command)
            .help("Générer du contenu d'apprentissage (⌘3)")
            
            Button("Aller à l'Étude") {
                coordinator.navigateTo(.study)
            }
            .keyboardShortcut("4", modifiers: .command)
            .help("Accéder aux modes d'étude (⌘4)")
            
            Button("Afficher les Statistiques") {
                coordinator.navigateTo(.analytics)
            }
            .keyboardShortcut("5", modifiers: .command)
            .help("Consulter vos statistiques d'apprentissage (⌘5)")
        }
        
        // MARK: - Menu Préférences
        // Maintenant que nous avons supprimé la Settings Scene automatique,
        // nous pouvons créer notre propre commande Préférences sans conflit
        CommandGroup(replacing: .appSettings) {
            Button("Préférences...") {
                coordinator.showPreferences()
            }
            .keyboardShortcut(",", modifiers: .command)
            .help("Configurer les paramètres de l'application (⌘,)")
        }
        
        // MARK: - Menu Application (Mises à jour)
        CommandGroup(after: .appInfo) {
            Button("Vérifier les mises à jour...") {
                coordinator.checkForUpdates()
            }
            .keyboardShortcut("u", modifiers: .command)
            .help("Vérifier s'il existe une nouvelle version d'Optima (⌘U)")
            
            Divider()
        }
        
        // MARK: - Menu Aide
        CommandGroup(after: .help) {
            Button("Guide d'utilisation d'Optima") {
                coordinator.openUserGuide()
            }
            .help("Apprendre à utiliser Optima efficacement")
            
            Button("Raccourcis clavier") {
                coordinator.showKeyboardShortcuts()
            }
            .keyboardShortcut("?", modifiers: .command)
            .help("Afficher tous les raccourcis clavier disponibles (⌘?)")
        }
    }
} 