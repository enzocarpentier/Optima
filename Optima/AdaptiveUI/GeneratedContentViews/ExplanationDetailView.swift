import SwiftUI

/// Vue pour afficher une explication détaillée d'un concept.
struct ExplanationDetailView: View {
    let explanationContent: ExplanationContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("Explication Détaillée")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Texte principal de l'explication
                SectionBox(title: "Explication", icon: "text.book.closed.fill") {
                    Text(explanationContent.text)
                }

                // Exemples
                if !explanationContent.examples.isEmpty {
                    SectionBox(title: "Exemples Concrets", icon: "lightbulb.fill") {
                        ForEach(explanationContent.examples, id: \.self) { example in
                            Text("• \(example)")
                        }
                    }
                }
                
                // Analogies
                if !explanationContent.analogies.isEmpty {
                    SectionBox(title: "Analogies", icon: "arrow.2.squarepath") {
                        ForEach(explanationContent.analogies, id: \.self) { analogy in
                            Text("• \(analogy)")
                        }
                    }
                }
                
                // Descriptions visuelles
                if !explanationContent.visualDescriptions.isEmpty {
                    SectionBox(title: "Descriptions pour Visualisation", icon: "eye.fill") {
                        ForEach(explanationContent.visualDescriptions, id: \.self) { desc in
                            Text("• \(desc)")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Explication")
    }
}

/// Une vue conteneur réutilisable pour les sections.
struct SectionBox<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            
            Divider()
            
            content
                .padding(.top, 5)
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
} 