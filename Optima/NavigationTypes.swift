//
//  NavigationTypes.swift
//  Optima
//
//  Created on 10 juin 2025.
//

import SwiftUI

// Définition de NavigationItem pour la navigation
enum NavigationItem: CaseIterable, Identifiable {
    case home, library, study, history, settings

    var id: Self { self }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .library:    return "books.vertical.fill"
        case .study:      return "brain.head.profile"
        case .history:    return "clock.arrow.circlepath"
        case .settings:   return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .home:      return "Accueil"
        case .library:    return "Bibliothèque"
        case .study:      return "Étudier"
        case .history:    return "Historique"
        case .settings:   return "Réglages"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .home:      return .cyan
        case .library:   return .purple
        case .study:     return .blue
        case .history:   return .orange
        case .settings:  return .gray
        }
    }
}

// Définition des zones de navigation
enum NavigationZone {
    case main
    case detail
    case onboarding
}
