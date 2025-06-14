import SwiftUI

struct AnimatedBrain: View {
    @State private var animating = false
    @State private var rotationAngle = 0.0
    @State private var glowOpacity = 0.0
    @State private var particleOpacity = 0.0
    
    var body: some View {
        ZStack {
            // Particules d'énergie
            ForEach(0..<8) { index in
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: 60 * cos(Double(index) * .pi / 4),
                        y: 60 * sin(Double(index) * .pi / 4)
                    )
                    .rotationEffect(.degrees(rotationAngle))
                    .opacity(particleOpacity)
            }
            
            // Cercle lumineux derrière
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.6),
                            Color.purple.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 100
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .opacity(glowOpacity)
            
            // Cercle de fond avec effet de verre
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.6),
                                    .white.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Icône du cerveau
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .symbolRenderingMode(.hierarchical)
                .shadow(color: .blue.opacity(0.8), radius: 15, x: 0, y: 0)
                .scaleEffect(animating ? 1.05 : 1.0)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .symbolRenderingMode(.hierarchical)
                        .opacity(0.5)
                        .blur(radius: 8)
                        .scaleEffect(animating ? 1.15 : 1.0)
                )
            
            // Anneaux d'énergie
            ForEach(0..<3) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .blue.opacity(0.4),
                                .purple.opacity(0.3),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 120 + CGFloat(ring * 20), height: 120 + CGFloat(ring * 20))
                    .rotationEffect(.degrees(rotationAngle * Double(ring + 1)))
                    .opacity(glowOpacity)
            }
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                animating = true
                glowOpacity = 0.8
            }
            
            withAnimation(
                Animation.linear(duration: 8)
                    .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
            
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                particleOpacity = 0.6
            }
        }
    }
}

struct GlowButton: View {
    var title: String
    var isDisabled: Bool
    var action: () -> Void
    @State private var hovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    isDisabled ? 
                    LinearGradient(
                        colors: [.gray.opacity(0.4), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.5, blue: 0.9),
                            Color(red: 0.5, green: 0.3, blue: 0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: isDisabled ? .clear : Color(red: 0.5, green: 0.3, blue: 0.9).opacity(hovered ? 0.5 : 0.3),
                        radius: hovered ? 15 : 10, x: 0, y: 5)
                .scaleEffect(hovered ? 1.02 : 1.0)
                .animation(.spring(response: 0.3), value: hovered)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onHover { hover in
            hovered = hover
        }
    }
}

struct OnboardingView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var nameInput: String = ""
    @FocusState private var isNameFieldFocused: Bool
    @State private var showWelcomeAnimation: Bool = false
    
    var body: some View {
        ZStack {
            UnifiedBackground()
            
            VStack(spacing: 40) {
                // Logo et titre
                VStack(spacing: 20) {
                    AnimatedBrain()
                        .offset(y: showWelcomeAnimation ? 0 : -40)
                        .opacity(showWelcomeAnimation ? 1 : 0)
                    
                    VStack(spacing: 8) {
                        Text("Bienvenue sur Optima")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            .opacity(showWelcomeAnimation ? 1 : 0)
                            .offset(y: showWelcomeAnimation ? 0 : 20)
                        
                        Text("L'assistant d'étude intelligent")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(showWelcomeAnimation ? 1 : 0)
                            .offset(y: showWelcomeAnimation ? 0 : 20)
                    }
                }
                .padding(.top, 50)
                
                // Carte de formulaire
                GlassCard(title: nil) {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Comment souhaitez-vous être appelé ?")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        GlassTextField(
                            text: $nameInput,
                            placeholder: "Votre prénom",
                            isFocused: $isNameFieldFocused
                        )
                        .onChange(of: nameInput) { oldValue, newValue in
                            if newValue.count > 15 {
                                nameInput = String(newValue.prefix(15))
                            }
                        }
                        
                        GlowButton(
                            title: "Commencer",
                            isDisabled: nameInput.isEmpty,
                            action: saveAndContinue
                        )
                        .padding(.top, 16)
                    }
                }
                .frame(width: 400)
                .padding(.horizontal)
                .opacity(showWelcomeAnimation ? 1 : 0)
                .offset(y: showWelcomeAnimation ? 0 : 20)
                
                Spacer()
            }
            .padding()
        }
        .onSubmit {
            saveAndContinue()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    showWelcomeAnimation = true
                }
            }
            
            // Auto-focus le champ de texte
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isNameFieldFocused = true
            }
        }
    }
    
    private func saveAndContinue() {
        if !nameInput.isEmpty {
            withAnimation(.easeInOut(duration: 0.3)) {
                userName = nameInput
                hasCompletedOnboarding = true
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
} 