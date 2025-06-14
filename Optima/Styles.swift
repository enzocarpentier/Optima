import SwiftUI

// MARK: - Arrière-plan unifié

struct UnifiedBackground: View {
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            EllipticalGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.25), location: 0),
                    Gradient.Stop(color: .black, location: 0.8)
                ],
                center: .top
            )
            .edgesIgnoringSafeArea(.all)
            
            Circle()
                .fill(Color.blue.opacity(0.4))
                .blur(radius: 120)
                .offset(x: -150, y: -200)

            Circle()
                .fill(Color.purple.opacity(0.3))
                .blur(radius: 150)
                .offset(x: 150, y: 100)
        }
    }
}

// MARK: - Styles de contrôles

// Style de champ de texte personnalisé
struct GlassTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(.black.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accentColor : Color.white.opacity(0.2), lineWidth: 1)
            )
            .focused($isFocused)
    }
}

// Style de bouton personnalisé
struct GlassButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(configuration.isPressed ? 0.5 : 0.8))
                    
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.black.opacity(0.2))
                    }
                }
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Composants de style

struct GlassCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            content
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct GlassButton: View {
    let title: String
    let icon: String
    var color: Color = .accentColor
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
        }
        .buttonStyle(GlassButtonStyle(color: color))
    }
}

struct GlassTextField: View {
    @Binding var text: String
    let placeholder: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(GlassTextFieldStyle())
            .focused(isFocused)
    }
}

// MARK: - Composants spécifiques

// Vue pour le bouton d'import
struct GlassImportButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void
    
    var body: some View {
        GlassButton(title: title, icon: systemImage, action: action)
            .frame(maxWidth: 300)
    }
}

// Card pour afficher les questions générées
struct QuestionGlassCard: View {
    let question: String
    
    var body: some View {
        GlassCard(title: nil) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color.purple.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                Text(question)
                    .font(.body)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
        }
    }
}

enum GlassStyle {
    static let strokeColor = Color.white.opacity(0.2)
    static let strokeGradient = LinearGradient(
        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
} 