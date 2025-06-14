import SwiftUI

struct TermDefinitionView: View {
    let keyTermList: KeyTermList
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: String = "Tous"
    @State private var studiedTerms: Set<UUID> = []
    @State private var selectedTerm: TermDefinition?
    @State private var showTermDetail = false
    
    private var categories: [String] {
        let allCategories = Set(keyTermList.terms.compactMap { _ in "Général" }) // Placeholder car pas de catégorie dans le modèle
        return ["Tous"] + Array(allCategories).sorted()
    }
    
    private var filteredTerms: [TermDefinition] {
        keyTermList.terms.filter { term in
            let matchesSearch = searchText.isEmpty || 
                term.term.localizedCaseInsensitiveContains(searchText) ||
                term.definition.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == "Tous" // Toujours vrai pour l'instant
            
            return matchesSearch && matchesCategory
        }
    }
    
    private var studyProgress: Double {
        guard !keyTermList.terms.isEmpty else { return 0 }
        return Double(studiedTerms.count) / Double(keyTermList.terms.count)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arrière-plan avec dégradé
                LinearGradient(
                    colors: [.cyan, .blue.opacity(0.8), .purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // En-tête
                    TermDefinitionHeaderView(
                        documentName: keyTermList.documentName,
                        totalTerms: keyTermList.terms.count,
                        studiedTerms: studiedTerms.count,
                        progress: studyProgress,
                        onClose: {
                            dismiss()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Contrôles de recherche et filtrage
                    VStack(spacing: 12) {
                        // Barre de recherche
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("Rechercher un terme...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(.ultraThinMaterial.opacity(0.6))
                        .cornerRadius(12)
                        
                        // Sélecteur de catégorie (pour l'instant simplifié)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    CategoryButton(
                                        title: category,
                                        isSelected: selectedCategory == category,
                                        onTap: {
                                            selectedCategory = category
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    // Liste des termes
                    if filteredTerms.isEmpty {
                        EmptyStateView(searchText: searchText)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTerms) { term in
                                    TermCard(
                                        term: term,
                                        isStudied: studiedTerms.contains(term.id),
                                        onTap: {
                                            selectedTerm = term
                                            showTermDetail = true
                                        },
                                        onToggleStudied: {
                                            toggleStudiedState(for: term)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showTermDetail, content: {
            if let term = selectedTerm {
                TermDetailView(
                    term: term,
                    isStudied: studiedTerms.contains(term.id),
                    onToggleStudied: {
                        toggleStudiedState(for: term)
                    }
                )
            }
        })
        .onAppear {
            // Charger les termes déjà étudiés si sauvegardés
            studiedTerms = keyTermList.studiedTerms
        }
    }
    
    private func toggleStudiedState(for term: TermDefinition) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            if studiedTerms.contains(term.id) {
                studiedTerms.remove(term.id)
            } else {
                studiedTerms.insert(term.id)
            }
        }
    }
}

// MARK: - Composants

private struct TermDefinitionHeaderView: View {
    let documentName: String
    let totalTerms: Int
    let studiedTerms: Int
    let progress: Double
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            StudyHeaderView(
                sessionTitle: "Termes clés",
                documentName: documentName,
                onClose: onClose
            )
            
            // Statistiques de progression
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(totalTerms)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Termes")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 4) {
                    Text("\(studiedTerms)")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                    
                    Text("Étudiés")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title2.bold())
                        .foregroundColor(.cyan)
                    
                    Text("Progression")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Barre de progression circulaire
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(progress * 100))")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

private struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial) // Fill with the base material
                        .opacity(isSelected ? 0.8 : 0.3)   // Apply opacity to the filled shape
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct TermCard: View {
    let term: TermDefinition
    let isStudied: Bool
    let onTap: () -> Void
    let onToggleStudied: () -> Void
    
    private var importanceColor: Color {
        switch term.importance {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(term.term)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(term.importance.rawValue)
                            .font(.caption)
                            .foregroundColor(importanceColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(importanceColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: onToggleStudied) {
                        Image(systemName: isStudied ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isStudied ? .green : .white.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Text(term.definition)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !term.relatedTerms.isEmpty {
                    HStack {
                        Text("Liés:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(term.relatedTerms.prefix(3).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial.opacity(0.6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isStudied ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.4))
            
            Text(searchText.isEmpty ? "Aucun terme disponible" : "Aucun résultat trouvé")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            if !searchText.isEmpty {
                Text("Essayez avec d'autres mots-clés")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Vue détaillée d'un terme

private struct TermDetailView: View {
    let term: TermDefinition
    let isStudied: Bool
    let onToggleStudied: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Titre principal
                    VStack(alignment: .leading, spacing: 8) {
                        Text(term.term)
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text(term.importance.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(importanceColor)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Button(action: onToggleStudied) {
                                HStack {
                                    Image(systemName: isStudied ? "checkmark.circle.fill" : "circle")
                                    Text(isStudied ? "Étudié" : "Marquer comme étudié")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(isStudied ? .green : .blue)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Définition
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Définition")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(term.definition)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    
                    // Contexte si disponible
                    if let context = term.context, !context.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contexte")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(context)
                                .font(.body)
                                .lineSpacing(4)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Termes liés
                    if !term.relatedTerms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Termes liés")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(term.relatedTerms, id: \.self) { relatedTerm in
                                    Text(relatedTerm)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Terme")
            .toolbar {
                ToolbarItem(placement: .automatic) { // Changed to .automatic for broader compatibility
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var importanceColor: Color {
        switch term.importance {
        case .high: return .red
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}

struct TermDefinitionView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTerms = [
            TermDefinition(
                term: "Photosynthèse",
                definition: "Processus biologique par lequel les plantes vertes et certaines bactéries convertissent la lumière solaire, le dioxyde de carbone et l'eau en glucose et en oxygène.",
                context: "La photosynthèse est le processus fondamental qui permet aux plantes de produire leur propre nourriture.",
                relatedTerms: ["Chlorophylle", "Glucose", "Oxygène"],
                importance: .high
            ),
            TermDefinition(
                term: "Chlorophylle",
                definition: "Pigment vert présent dans les chloroplastes des plantes, essentiel pour la capture de la lumière solaire lors de la photosynthèse.",
                context: "La chlorophylle donne aux feuilles leur couleur verte caractéristique.",
                relatedTerms: ["Photosynthèse", "Chloroplaste"],
                importance: .medium
            )
        ]
        
        let sampleResponse = TermDefinitionResponse(
            definitions: sampleTerms,
            metadata: TermMetadata(version: "1.0", source: "Preview", notes: "Sample data")
        )
        
        let sampleKeyTermList = KeyTermList(
            documentId: UUID(),
            documentName: "Biologie Végétale",
            termResponse: sampleResponse
        )
        
        TermDefinitionView(keyTermList: sampleKeyTermList)
    }
}
