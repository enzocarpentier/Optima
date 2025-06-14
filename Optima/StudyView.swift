import SwiftUI

struct StudyView: View {
    @StateObject private var libraryManager = PDFLibraryManager.shared
    @State private var showContent = false
    
    @State private var showQCMAlert = false
    @State private var showQCMView = false
    @State private var showFlashcards = false
    @State private var showSummary = false
    @State private var showKeyTerms = false
    
    @State private var selectedQCM: QCMTest?
    @State private var selectedFlashcardSet: FlashcardSet?
    @State private var selectedSummary: DocumentSummary?
    @State private var selectedKeyTerms: KeyTermList?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // En-tête
                VStack(alignment: .leading, spacing: 8) {
                    Text("Espace d'étude")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Retrouvez ici tous vos QCM, fiches et résumés.")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Sections
                StudySectionView(
                    title: "QCM",
                    icon: "questionmark.diamond.fill",
                    color: .cyan,
                    items: libraryManager.qcmTests,
                    onSelect: { item in
                        selectedQCM = item
                        showQCMAlert = true
                    }
                )
                
                StudySectionView(
                    title: "Flashcards",
                    icon: "rectangle.on.rectangle.fill",
                    color: .purple,
                    items: libraryManager.flashcardSets,
                    onSelect: { item in
                        selectedFlashcardSet = item
                        showFlashcards = true
                    }
                )

                StudySectionView(
                    title: "Résumés",
                    icon: "text.book.closed.fill",
                    color: .orange,
                    items: libraryManager.summaries,
                    onSelect: { item in
                        selectedSummary = item
                        showSummary = true
                    }
                )
                
                StudySectionView(
                    title: "Termes clés",
                    icon: "character.book.closed.fill",
                    color: .green,
                    items: libraryManager.keyTermLists,
                    onSelect: { item in
                        selectedKeyTerms = item
                        showKeyTerms = true
                    }
                )
            }
            .padding(.bottom, 120)
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
        .alert("Commencer le QCM ?", isPresented: $showQCMAlert, presenting: selectedQCM) { qcm in
            Button("Commencer") {
                showQCMAlert = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showQCMView = true
                }
            }
            Button("Annuler", role: .cancel) { }
        } message: { qcm in
            Text("Vous êtes sur le point de commencer un QCM pour le document \"\(qcm.documentName)\".")
        }
        .sheet(isPresented: $showQCMView) {
            if let qcm = selectedQCM {
                QuizView(qcmTest: qcm)
            }
        }
        .sheet(isPresented: $showFlashcards) {
            if let flashcardSet = selectedFlashcardSet {
                FlashcardView(flashcardSet: flashcardSet)
            }
        }
        .sheet(isPresented: $showSummary) {
            if let summary = selectedSummary {
                SummaryView(documentSummary: summary)
            }
        }
        .sheet(isPresented: $showKeyTerms) {
            if let keyTerms = selectedKeyTerms {
                TermDefinitionView(keyTermList: keyTerms)
            }
        }
    }
}

private struct StudySectionView<T: StudyMaterial & Identifiable>: View {
    let title: String
    let icon: String
    let color: Color
    let items: [T]
    let onSelect: (T) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            if items.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(items) { item in
                            StudyItemCard(
                                documentName: item.documentName,
                                dateCreated: item.dateCreated,
                                color: color
                            )
                            .onTapGesture {
                                onSelect(item)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(alignment: .center, spacing: 12) {
             Image(systemName: "eyes.inverse")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
             Text("Aucun élément pour le moment")
                 .font(.system(size: 16, weight: .medium))
                 .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, minHeight: 110)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal)
    }
}

private struct StudyItemCard: View {
    let documentName: String
    let dateCreated: Date
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(documentName)
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                Spacer()
            }
            
            Spacer()
            
            Text("Créé le \(dateCreated, style: .date)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(width: 200, height: 110)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isHovered ? 0.1 : 0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isHovered ?
                            LinearGradient(
                                colors: [color.opacity(0.8), color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            GlassStyle.strokeGradient,
                        lineWidth: isHovered ? 2 : 1
                    )
            }
        )
        .shadow(
            color: isHovered ? color.opacity(0.3) : .black.opacity(0.2),
            radius: isHovered ? 15 : 8
        )
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .onHover { hover in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isHovered = hover
            }
        }
    }
}

struct StudyView_Previews: PreviewProvider {
    static var previews: some View {
        StudyView()
            .background(UnifiedBackground())
    }
} 