import SwiftUI

/// Vue pour afficher un paquet de flashcards.
struct FlashcardsDetailView: View {
    let flashcardsContent: FlashcardsContent

    @State private var flippedCardID: UUID?

    var body: some View {
        ScrollView {
            VStack {
                Text("Flashcards : \(flashcardsContent.cards.count) Cartes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250, maximum: 350))], spacing: 20) {
                    ForEach(flashcardsContent.cards) { card in
                        FlashcardView(card: card, isFlipped: flippedCardID == card.id)
                            .onTapGesture {
                                withAnimation(.spring) {
                                    flippedCardID = flippedCardID == card.id ? nil : card.id
                                }
                            }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Jeu de Flashcards")
    }
}

/// Vue pour une seule flashcard avec effet de retournement.
struct FlashcardView: View {
    let card: Flashcard
    var isFlipped: Bool

    var body: some View {
        ZStack {
            if isFlipped {
                BackView(text: card.back)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                FrontView(text: card.front)
            }
        }
        .frame(width: 250, height: 150)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
    }

    struct FrontView: View {
        let text: String
        var body: some View {
            Text(text)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.blue.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .foregroundStyle(.white)
        }
    }

    struct BackView: View {
        let text: String
        var body: some View {
            Text(text)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.secondary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .foregroundStyle(.primary)
        }
    }
} 