import SwiftUI

struct GenerationSuccessView: View {
    let message: String
    let onDismiss: () -> Void
    let onNavigate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text(message)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Vous pouvez maintenant retrouver votre QCM dans la section 'Étudier'.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 15) {
                Button(action: onDismiss) {
                    Text("Rester ici")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onNavigate) {
                    Text("Aller à 'Étudier'")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(30)
        .background(Material.regular)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(40)
        .frame(maxWidth: 450)
    }
} 