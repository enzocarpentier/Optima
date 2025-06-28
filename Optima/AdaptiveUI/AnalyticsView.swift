//
//  AnalyticsView.swift
//  AdaptiveUI
//
//  Vue des analytics d'apprentissage
//  Suivi de progression et insights personnels
//

import SwiftUI

/// Une vue qui affiche les statistiques et la progression de l'apprentissage de l'utilisateur.
struct AnalyticsView: View {
    
    /// Le coordinateur de l'application, source de vérité pour les services.
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                
                Text("Tableau de Bord")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Section des indicateurs clés de performance (KPI)
                keyStatsGrid
                

                
                Spacer()
            }
            .padding(30)
        }
        .navigationTitle("Analytics")
        .onAppear {
            // Recharger les données à chaque fois que la vue apparaît pour être sûr d'avoir les dernières statistiques.
            Task {
                await coordinator.loadAnalyticsData()
            }
        }
        .refreshable {
            // Permettre le rafraîchissement manuel des données
            await coordinator.loadAnalyticsData()
        }
    }
    
    // MARK: - Vues Enfants
    
    /// Une grille affichant les statistiques clés.
    private var keyStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
            StatCardView(title: "Temps d'Étude Total", value: format(duration: coordinator.analyticsService.totalStudyTime), icon: "clock.fill", color: .blue)
            StatCardView(title: "Sessions d'Étude", value: "\(coordinator.analyticsService.totalSessions)", icon: "brain.head.profile.fill", color: .indigo)
            StatCardView(title: "Score Moyen aux Quiz", value: format(score: coordinator.analyticsService.averageQuizScore), icon: "star.fill", color: .orange)
        }
    }
    

    

    

    

    
    // MARK: - Fonctions de Formatage
    

    
    private func format(duration: TimeInterval) -> String {
        let totalMinutes = Int(duration / 60)
        
        if totalMinutes == 0 {
            return "0 minute"
        } else if totalMinutes == 1 {
            return "1 minute"
        } else {
            return "\(totalMinutes) minutes"
        }
    }
    
    private func format(score: Double?) -> String {
        guard let score else { return "N/A" }
        return String(format: "%.1f%%", score * 100)
    }
}

/// Une carte réutilisable pour afficher une statistique clé.
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(AppCoordinator())
} 