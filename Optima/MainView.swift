import SwiftUI

// Arrière-plan animé avec particules flottantes
struct FloatingParticlesBackground: View {
    @State private var particleOffset1 = CGPoint(x: 0, y: 0)
    @State private var particleOffset2 = CGPoint(x: 0, y: 0)
    @State private var particleOffset3 = CGPoint(x: 0, y: 0)
    @State private var particleOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Dégradé de base ultra-moderne
            RadialGradient(
                colors: [
                    Color(red: 0.10, green: 0.16, blue: 0.32), // Bleu nuit saturé
                    Color(red: 0.13, green: 0.10, blue: 0.30), // Bleu-violet subtil
                    Color(red: 0.04, green: 0.09, blue: 0.20), // Bleu foncé
                    Color(red: 0.01, green: 0.02, blue: 0.08), // Presque noir
                    Color.black
                ],
                center: .init(x: 0.5, y: 0.7), // Centré plus bas
                startRadius: 200,
                endRadius: 1200
            )
            
            // Particules flottantes avec glass effect
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.cyan.opacity(0.4), Color.cyan.opacity(0.1)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    ))
                    .frame(width: 240, height: 240)
                    .blur(radius: 60)
                    .offset(x: particleOffset1.x, y: particleOffset1.y)
                    .opacity(particleOpacity)
                
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.purple.opacity(0.5), Color.purple.opacity(0.1)],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    ))
                    .frame(width: 180, height: 180)
                    .blur(radius: 40)
                    .offset(x: particleOffset2.x, y: particleOffset2.y)
                    .opacity(particleOpacity)
                
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                        center: .center,
                        startRadius: 25,
                        endRadius: 90
                    ))
                    .frame(width: 160, height: 160)
                    .blur(radius: 35)
                    .offset(x: particleOffset3.x, y: particleOffset3.y)
                    .opacity(particleOpacity)
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            animateParticles()
        }
    }
    
    private func animateParticles() {
        withAnimation(
            Animation.easeInOut(duration: 8.0)
                .repeatForever(autoreverses: true)
        ) {
            particleOffset1 = CGPoint(x: 200, y: -150)
            particleOffset2 = CGPoint(x: -180, y: 200)
            particleOffset3 = CGPoint(x: 150, y: 180)
        }
        
        withAnimation(
            Animation.easeInOut(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            particleOpacity = 0.6
        }
    }
}

// Navigation flottante en pilule
struct FloatingNavigation: View {
    @Binding var selection: NavigationItem
    @State private var hoverItem: NavigationItem?
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(NavigationItem.allCases) { item in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selection = item
                    }
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            // Glow effect pour l'élément actif
                            if selection == item {
                                Circle()
                                    .fill(item.accentColor.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .blur(radius: 10)
                                    .scaleEffect(1.2)
                            }
                            
                            // Background de l'icône
                            Circle()
                                .fill(selection == item ? 
                                      item.accentColor.opacity(0.2) : 
                                      Color.white.opacity(hoverItem == item ? 0.1 : 0.05))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            selection == item ? 
                                            item.accentColor.opacity(0.5) : 
                                            Color.white.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                            
                            // Icône
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selection == item ? item.accentColor : .white.opacity(0.8))
                                .scaleEffect(selection == item ? 1.1 : 1.0)
                        }
                        
                        // Label
                        Text(item.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(selection == item ? item.accentColor : .white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(width: 70)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        hoverItem = hovering ? item : nil
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            // Glass morphism ultra-avancé
            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.2).opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .stroke(
                            Color.white.opacity(0.1),
                            lineWidth: 1.2
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .shadow(color: Color.cyan.opacity(0.1), radius: 40, x: 0, y: 0)
        .scaleEffect(isHovering ? 1.0 : 0.95)
        .opacity(isHovering ? 1.0 : 0.5)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
    }
}

struct MainView: View {
    @StateObject private var navigationManager = NavigationManager()
    @State private var selectedTab: NavigationItem = .home
    @State private var navigationZone: NavigationZone = .main
    @State private var showNavigation = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                UnifiedBackground()
                
                // Contenu principal
                Group {
                    if navigationZone == .onboarding {
                        OnboardingView()
                    } else {
                        VStack(spacing: 0) {
                            switch selectedTab {
                            case .home:
                                FuturisticHomeView(selectedTab: $selectedTab)
                            case .study:
                                StudyView()
                            case .library:
                                LibraryView()
                            case .history:
                                FuturisticPlaceholderView(
                                    title: "Historique",
                                    icon: "clock.arrow.circlepath",
                                    color: .orange
                                )
                            case .settings:
                                SettingsView()
                            }
                        }
                    }
                }
                
                // Navigation flottante
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingNavigation(selection: $selectedTab)
                            .opacity(showNavigation ? 1 : 0)
                            .offset(y: showNavigation ? 0 : 50)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .environmentObject(navigationManager)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showNavigation = true
                }
            }
        }
        .onReceive(navigationManager.$requestedDestination) { destination in
            guard let destination = destination else { return }
            
            switch destination {
            case .studyTab:
                selectedTab = .study
            }
            
            // Réinitialiser la demande pour éviter une navigation répétée
            // On le fait après un court délai pour laisser le temps à la vue de changer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                navigationManager.requestedDestination = nil
            }
        }
    }
}

// Vue placeholder futuriste
struct FuturisticPlaceholderView: View {
    let title: String
    let icon: String
    let color: Color
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            UnifiedBackground()
            
        VStack(spacing: 30) {
            // Icône animée avec glow
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 100)
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
                                lineWidth: 2
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(color)
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
            }
            .shadow(color: color.opacity(0.3), radius: 20)
            
            // Titre avec effet de verre
            Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            
            Text("Bientôt disponible...")
                .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                animateIcon = true
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

// PreferenceKey pour tracker le scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
