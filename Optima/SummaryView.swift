import SwiftUI

struct SummaryView: View {
    let documentSummary: DocumentSummary
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSection: Int = 0
    @State private var showBookmarkAnimation = false
    @State private var isBookmarked: Bool = false
    
    private var summary: TextSummary {
        documentSummary.summary
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arrière-plan avec dégradé
                LinearGradient(
                    colors: [.green, .teal.opacity(0.8), .cyan.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // En-tête
                    SummaryHeaderView(
                        documentName: documentSummary.documentName,
                        wordCount: summary.wordCount,
                        compressionRatio: summary.compressionRatio,
                        isBookmarked: isBookmarked,
                        onBookmark: {
                            toggleBookmark()
                        },
                        onClose: {
                            dismiss()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Contenu principal avec onglets
                    VStack(spacing: 0) {
                        // Sélecteur d'onglets
                        SummaryTabSelector(
                            selectedTab: $selectedSection,
                            tabs: ["Résumé", "Points clés", "Sujets"]
                        )
                        .padding(.horizontal)
                        
                        // Contenu des onglets
                        TabView(selection: $selectedSection) {
                            // Onglet 1: Résumé principal
                            SummaryContentView(
                                content: summary.summaryText,
                                title: "Résumé principal"
                            )
                            .tag(0)
                            
                            // Onglet 2: Points clés
                            KeyPointsView(keyPoints: summary.keyPoints)
                            .tag(1)
                            
                            // Onglet 3: Sujets principaux
                            TopicsView(topics: summary.mainTopics)
                            .tag(2)
                        }
                    }
                    .background(.ultraThinMaterial.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            isBookmarked = documentSummary.isBookmarked
        }
    }
    
    private func toggleBookmark() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isBookmarked.toggle()
            showBookmarkAnimation = true
        }
        
        // Animation de retour
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showBookmarkAnimation = false
            }
        }
    }
}

// MARK: - Composants

private struct SummaryHeaderView: View {
    let documentName: String
    let wordCount: Int
    let compressionRatio: Double
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            StudyHeaderView(
                sessionTitle: "Résumé",
                documentName: documentName,
                onClose: onClose
            )
            .padding(.bottom, -8) // Réduire l'espace pour mieux intégrer
            
            // Statistiques
            HStack(spacing: 20) {
                StatCard(
                    title: "Mots",
                    value: "\(wordCount)",
                    icon: "textformat.abc"
                )
                
                StatCard(
                    title: "Compression",
                    value: "\(Int(compressionRatio * 100))%",
                    icon: "arrow.down.circle"
                )
                
                StatCard(
                    title: "Lecture",
                    value: "\((wordCount / 200) + 1) min",
                    icon: "clock"
                )
                
                // Bouton favori intégré dans les stats
                VStack(spacing: 4) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.headline)
                        .foregroundColor(isBookmarked ? .yellow : .white.opacity(0.8))
                    
                    Text(isBookmarked ? "Enregistré" : "Enregistrer")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial.opacity(0.5))
                .cornerRadius(12)
                .onTapGesture(perform: onBookmark)
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.headline.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(12)
    }
}

private struct SummaryTabSelector: View {
    @Binding var selectedTab: Int
    let tabs: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    Text(tab)
                        .font(.subheadline.bold())
                        .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if selectedTab == index {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Material.ultraThinMaterial)
                                        .opacity(0.8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.clear)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(.ultraThinMaterial.opacity(0.3))
        .cornerRadius(12)
        .padding(.bottom, 16)
    }
}

private struct SummaryContentView: View {
    let content: String
    let title: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
    }
}

private struct KeyPointsView: View {
    let keyPoints: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Points clés")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVStack(spacing: 12) {
                    ForEach(Array(keyPoints.enumerated()), id: \.offset) { index, point in
                        KeyPointCard(
                            point: point,
                            number: index + 1
                        )
                    }
                }
            }
            .padding()
        }
    }
}

private struct KeyPointCard: View {
    let point: String
    let number: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Numéro
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.8))
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            // Contenu
            Text(point)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.4))
        .cornerRadius(12)
    }
}

private struct TopicsView: View {
    let topics: [String]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sujets principaux")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(topics.enumerated()), id: \.offset) { index, topic in
                        TopicCard(
                            topic: topic,
                            color: topicColors[index % topicColors.count]
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private let topicColors: [Color] = [
        .blue, .purple, .orange, .pink, .teal, .indigo
    ]
}

private struct TopicCard: View {
    let topic: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tag.fill")
                .font(.title2)
                .foregroundColor(color)
            
            Text(topic)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Aperçu

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView(
            documentSummary: DocumentSummary(
                documentId: UUID(),
                documentName: "Exemple de document long avec un nom qui prend plusieurs lignes",
                textSummary: TextSummary(
                    id: UUID(),
                    summaryText: "Ceci est un résumé détaillé du document, expliquant les principaux concepts et les conclusions. Il est conçu pour être plus long et fournir une compréhension approfondie sans avoir à lire le texte original en entier.",
                    keyPoints: [
                        "Le premier point clé est très important.",
                        "Le deuxième point clé développe une idée cruciale.",
                        "Un troisième point pour la route."
                    ],
                    mainTopics: ["Technologie", "SwiftUI", "IA"],
                    wordCount: 50,
                    originalWordCount: 500
                )
            )
        )
    }
}
