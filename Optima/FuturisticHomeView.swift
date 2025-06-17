//
//  FuturisticHomeView.swift
//  Optima
//
//  Created on 10 juin 2025.
//

import SwiftUI
import Foundation

// Carte flottante avec glassmorphism avancé
struct FloatingGlassCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var animateGlow = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // Icône avec effect de glow
                ZStack {
                    // Glow animé
                    Circle()
                        .fill(color.opacity(animateGlow ? 0.4 : 0.2))
                        .frame(width: 80, height: 80)
                        .blur(radius: 15)
                        .scaleEffect(animateGlow ? 1.2 : 1.0)
                    
                    // Cercle de fond
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            color.opacity(0.6),
                                            color.opacity(0.2),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    // Icône
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(color)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                }
                .shadow(color: color.opacity(0.3), radius: 20)
                
                // Texte
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(24)
            .frame(minHeight: 200) // Hauteur minimale au lieu de largeur fixe
            .frame(maxWidth: .infinity) // Prend toute la largeur disponible
            .background(
                // Glass effect ultra-avancé
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.4),
                                        .white.opacity(0.1),
                                        .clear,
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .shadow(color: color.opacity(0.1), radius: 40, x: 0, y: 0)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .rotationEffect(.degrees(isHovered ? 1 : 0))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
            ) {
                animateGlow = true
            }
        }
    }
}

// Carte d'activité récente flottante
struct FloatingActivityCard: View {
    let title: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Contenu
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(time)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Indicateur
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.02))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct FuturisticHomeView: View {
    @AppStorage("userName") private var userName: String = "Étudiant"
    @Binding var selectedTab: NavigationItem
    
    @State private var showWelcome = false
    @State private var showCards = false
    @State private var showWhatsNew = false
    
    var body: some View {
        ZStack {
            UnifiedBackground()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 40) {
                        // En-tête avec animation
                        VStack(spacing: 16) {
                            // Salutation
                            ZStack {
                                HStack {
                                    Text("Bonjour")
                                        .font(.system(size: 28, weight: .light, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(userName)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [
                                                    .cyan,
                                                    .blue,
                                                    .purple
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }

                                HStack {
                                    Spacer()
                                    Button(action: {
                                        showWhatsNew = true
                                    }) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(8)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .shadow(radius: 5)
                                }
                            }
                            .opacity(showWelcome ? 1 : 0)
                            .offset(y: showWelcome ? 0 : 20)
                            
                            // Sous-titre
                            Text("Que souhaitez-vous faire aujourd'hui ?")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(showWelcome ? 1 : 0)
                                .offset(y: showWelcome ? 0 : 20)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal, 40)
                        
                        // Grille de cartes flottantes
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20)
                        ], spacing: 20) {
                            FloatingGlassCard(
                                title: "Étudier",
                                subtitle: "Accéder à vos fiches",
                                icon: "brain.head.profile",
                                color: .blue,
                                action: { selectedTab = .study }
                            )
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showCards)
                            
                            FloatingGlassCard(
                                title: "Bibliothèque",
                                subtitle: "Accéder à vos documents",
                                icon: "books.vertical.fill",
                                color: .purple,
                                action: { selectedTab = .library }
                            )
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showCards)
                            
                            FloatingGlassCard(
                                title: "Historique",
                                subtitle: "Voir vos activités récentes",
                                icon: "clock.arrow.circlepath",
                                color: .orange,
                                action: { selectedTab = .history }
                            )
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showCards)
                            
                            FloatingGlassCard(
                                title: "Paramètres",
                                subtitle: "Configurer l'application",
                                icon: "gearshape.fill",
                                color: .gray,
                                action: { selectedTab = .settings }
                            )
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showCards)
                        }
                        .padding(.horizontal, 40) // Augmenter le padding pour plus d'espace
                        
                        Spacer()
                    }
                    .padding(.bottom, 120) // Espace pour la navigation flottante
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .onAppear {
            // Animations séquentielles
            withAnimation(.easeOut(duration: 0.8)) {
                showWelcome = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showCards = true
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView()
        }
    }
}

struct FuturisticHomeView_Previews: PreviewProvider {
    @State static var selectedTab: NavigationItem = .home
    
    static var previews: some View {
        FuturisticHomeView(selectedTab: $selectedTab)
    }
}
