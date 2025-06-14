import SwiftUI

struct FlashcardView: View {
    let flashcardSet: FlashcardSet
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentCardIndex = 0
    @State private var isFlipped = false
    @State private var showResults = false
    @State private var studiedCards: Set<UUID> = []
    @State private var cardProgress: [UUID: Bool] = [:] // true = correct, false = incorrect
    
    private var currentCard: FlashCard {
        flashcardSet.cards[currentCardIndex]
    }
    
    private var isLastCard: Bool {
        currentCardIndex >= flashcardSet.cards.count - 1
    }
    
    private var studyProgress: Double {
        guard !flashcardSet.cards.isEmpty else { return 0 }
        return Double(studiedCards.count) / Double(flashcardSet.cards.count)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Arrière-plan avec dégradé
                LinearGradient(
                    colors: [.purple, .blue.opacity(0.8), .cyan.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showResults {
                    ResultsView(
                        flashcardSet: flashcardSet,
                        cardProgress: cardProgress,
                        onRetry: {
                            resetStudySession()
                        },
                        onClose: {
                            dismiss()
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        // En-tête avec informations et contrôles
                        StudyHeaderView(
                            sessionTitle: "Flashcards",
                            documentName: flashcardSet.documentName,
                            progress: studyProgress,
                            progressText: "Carte \(currentCardIndex + 1) sur \(flashcardSet.cards.count)",
                            onClose: {
                                dismiss()
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top)
                        
                        Spacer()
                        
                        // Carte principale
                        FlashcardMainView(
                            card: currentCard,
                            isFlipped: isFlipped,
                            onFlip: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isFlipped.toggle()
                                }
                            }
                        )
                        .frame(maxWidth: min(400, geometry.size.width - 40))
                        
                        Spacer()
                        
                        // Contrôles de navigation
                        if isFlipped {
                            FlashcardControlsView(
                                onCorrect: {
                                    markCard(correct: true)
                                },
                                onIncorrect: {
                                    markCard(correct: false)
                                },
                                isLastCard: isLastCard
                            )
                            .padding(.horizontal)
                        } else {
                            FlashcardHintView()
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func markCard(correct: Bool) {
        cardProgress[currentCard.id] = correct
        studiedCards.insert(currentCard.id)
        
        if isLastCard {
            withAnimation(.easeInOut(duration: 0.5)) {
                showResults = true
            }
        } else {
            moveToNextCard()
        }
    }
    
    private func moveToNextCard() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCardIndex += 1
            isFlipped = false
        }
    }
    
    private func resetStudySession() {
        currentCardIndex = 0
        isFlipped = false
        showResults = false
        studiedCards.removeAll()
        cardProgress.removeAll()
    }
}

// MARK: - Composants

private struct FlashcardMainView: View {
    let card: FlashCard
    let isFlipped: Bool
    let onFlip: () -> Void
    
    var body: some View {
        Button(action: onFlip) {
            ZStack {
                // Face arrière (réponse)
                if isFlipped {
                    VStack(spacing: 20) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title)
                            .foregroundColor(.yellow)
                        
                        Text("Réponse")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        ScrollView {
                            Text(card.definition) // Changed from card.back
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Tags
                        // if !card.tags.isEmpty { // tags property does not exist on FlashCard
                        //     HStack {
                        //         ForEach(card.tags, id: \\.self) { tag in
                        //             Text(tag)
                        //                 .font(.caption)
                        //                 .padding(.horizontal, 8)
                        //                 .padding(.vertical, 4)
                        //                 .background(Color.white.opacity(0.2))
                        //                 .cornerRadius(8)
                        //                 .foregroundColor(.white.opacity(0.8))
                        //         }
                        //     }
                        // }
                    }
                    .padding(24)
                    .rotation3DEffect(
                        .degrees(0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                } else {
                    // Face avant (question)
                    VStack(spacing: 20) {
                        Image(systemName: "brain.head.profile")
                            .font(.title)
                            .foregroundColor(.cyan)
                        
                        Text("Question")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        ScrollView {
                            Text(card.term) // Changed from card.front
                                .font(.title3)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Text("Touchez pour révéler la réponse")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .frame(minHeight: 300)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct FlashcardControlsView: View {
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    let isLastCard: Bool
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: onIncorrect) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    Text("Difficile")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial.opacity(0.6))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onCorrect) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text(isLastCard ? "Terminer" : "Facile")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial.opacity(0.6))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

private struct FlashcardHintView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.6))
            
            Text("Touchez la carte pour voir la réponse")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Vue des résultats

private struct ResultsView: View {
    let flashcardSet: FlashcardSet
    let cardProgress: [UUID: Bool]
    let onRetry: () -> Void
    let onClose: () -> Void
    
    private var correctCount: Int {
        cardProgress.values.filter { $0 }.count
    }
    
    private var accuracy: Int {
        guard !cardProgress.isEmpty else { return 0 }
        return (correctCount * 100) / cardProgress.count
    }
    
    private var accuracyColor: Color {
        switch accuracy {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private var message: String {
        switch accuracy {
        case 90...100: return "Excellent travail ! 🎉"
        case 80..<90: return "Très bien ! 👏"
        case 60..<80: return "Bon travail ! 👍"
        default: return "Continuez à réviser ! 📚"
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Titre
            Text("Session terminée !")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            // Statistiques principales
            VStack(spacing: 24) {
                Text(message)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                // Cercle de progression
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: Double(accuracy) / 100)
                        .stroke(accuracyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(accuracy)%")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                }
                
                // Détails
                VStack(spacing: 8) {
                    HStack {
                        Text("Cartes réussies:")
                        Spacer()
                        Text("\(correctCount)/\(flashcardSet.cards.count)")
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Temps d'étude:")
                        Spacer()
                        // Text("\\(flashcardSet.metadata.suggestedStudyTime) min") // suggestedStudyTime does not exist on FlashCardMetadata
                        Text("- min") // Placeholder
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal)
            }
            .padding()
            .background(.ultraThinMaterial.opacity(0.6))
            .cornerRadius(20)
            
            // Boutons d'action
            VStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("Recommencer", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial.opacity(0.8))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onClose) {
                    Text("Terminer")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial.opacity(0.4))
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}

struct FlashcardView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleResponse = FlashCardResponse(
            flashcards: [ // Changed from cards
                FlashCard(
                    term: "Qu'est-ce que la photosynthèse ?", // Changed from front
                    definition: "Processus par lequel les plantes convertissent la lumière solaire en énergie chimique" // Changed from back
                    // difficulty: .medium, // difficulty does not exist on FlashCard
                    // tags: ["biologie", "plantes"] // tags does not exist on FlashCard
                ),
                FlashCard(
                    term: "Quelle est la formule de l'eau ?", // Changed from front
                    definition: "H2O - deux atomes d'hydrogène et un atome d'oxygène" // Changed from back
                    // difficulty: .easy, // difficulty does not exist on FlashCard
                    // tags: ["chimie", "molécules"] // tags does not exist on FlashCard
                )
            ],
            metadata: FlashCardMetadata(
                // totalCards: 2, // totalCards does not exist on FlashCardMetadata
                // categories: ["Sciences"], // categories does not exist on FlashCardMetadata
                // suggestedStudyTime: 10 // suggestedStudyTime does not exist on FlashCardMetadata
                version: "1.0", // Added example value
                level: "Débutant", // Added example value
                subject: "Sciences" // Added example value
            )
        )
        
        let sampleSet = FlashcardSet(
            documentId: UUID(),
            documentName: "Sciences Naturelles",
            flashcardResponse: sampleResponse
        )
        
        FlashcardView(flashcardSet: sampleSet)
    }
}
