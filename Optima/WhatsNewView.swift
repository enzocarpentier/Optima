import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Nouveautés")
                .font(.largeTitle)
                .fontWeight(.bold)

            if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                Text("Version \(version)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            // List of new features
            VStack(alignment: .leading, spacing: 15) {
                FeatureView(icon: "gift.fill", title: "Suivi des Nouveautés", description: "Consultez facilement les dernières améliorations et fonctionnalités grâce au nouveau bouton de nouveautés.")
                FeatureView(icon: "macwindow", title: "Barre de Navigation Intégrée", description: "La fenêtre d'étude inclut désormais une barre de navigation pour un accès simplifié aux outils.")
                FeatureView(icon: "ellipsis.circle", title: "Menu Inférieur Amélioré", description: "Le menu en bas de l'application a été repensé pour une expérience plus fluide et intuitive.")
            }

            Spacer()

            Button("Fermer") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(width: 400, height: 500)
    }
}

struct FeatureView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.accentColor)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView()
    }
} 