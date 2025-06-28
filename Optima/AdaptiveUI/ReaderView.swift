//
//  ReaderView.swift
//  AdaptiveUI
//
//  Vue de lecture de documents PDF avec PDFKit
//  Interface complète pour lire et interagir avec les vrais PDFs
//

import SwiftUI
import PDFKit

struct ReaderView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    // 🔑 CORRECTION : Suppression de l'assistant local pour utiliser l'assistant global unifié
    @State private var pdfView = PDFView()
    @State private var currentPage = 1
    @State private var totalPages = 1
    
    var body: some View {
        if let selectedDocument = coordinator.selectedDocument {
            HSplitView {
                // Zone de lecture PDF principale
                VStack(spacing: 0) {
                    // Contrôles de navigation
                    navigationControls
                    
                    Divider()
                    
                    // Vue PDF réelle
                    PDFKitView(pdfView: $pdfView, document: selectedDocument) { page, total in
                        currentPage = page
                        totalPages = total
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
                
                // 🔑 CORRECTION : L'assistant IA est maintenant géré globalement par MainNavigationView
                // Plus besoin d'assistant local ici
            }
            .navigationTitle(selectedDocument.title)
            .toolbar {
                toolbarContent
            }
        } else {
            // État vide quand aucun document n'est sélectionné
            emptyStateView
        }
    }
    
    // MARK: - Contrôles de Navigation
    
    private var navigationControls: some View {
        HStack {
            Button {
                pdfView.goToPreviousPage(nil)
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(currentPage <= 1)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("Page")
                TextField("Page", value: $currentPage, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .onSubmit {
                        goToPage(currentPage)
                    }
                Text("sur \(totalPages)")
            }
            .font(.headline)
            
            Spacer()
            
            Button {
                pdfView.goToNextPage(nil)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(currentPage >= totalPages)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - État Vide
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("Aucun document sélectionné")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Sélectionnez un document dans la bibliothèque pour commencer la lecture")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retour à la bibliothèque") {
                coordinator.navigateTo(.library)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Lecteur")
    }
    
    // 🔑 CORRECTION : Assistant IA supprimé - maintenant géré globalement par MainNavigationView
    // Toutes les fonctionnalités IA sont disponibles via l'assistant global unifié
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button {
                // 🔑 CORRECTION : Toggle intelligent de l'assistant global
                // Si fermé → ouvre intelligemment selon l'état API
                // Si ouvert → ferme directement
                print("🔧 DEBUG: Bouton assistant ReaderView cliqué")
                print("🔧 DEBUG: État actuel showingAIAssistant = \(coordinator.showingAIAssistant)")
                
                if coordinator.showingAIAssistant {
                    // Assistant ouvert → le fermer
                    coordinator.showingAIAssistant = false
                } else {
                    // Assistant fermé → l'ouvrir intelligemment
                    coordinator.openAIAssistant()
                }
            } label: {
                Label("Assistant IA", 
                      systemImage: coordinator.showingAIAssistant ? "brain.head.profile.fill" : "brain.head.profile")
            }
        }
        
        ToolbarItem(placement: .automatic) {
            Button {
                coordinator.navigateTo(.generation)
            } label: {
                Label("Générer du contenu", systemImage: "wand.and.stars")
            }
        }
        
        ToolbarItem(placement: .automatic) {
            Menu {
                Button("Zoom avant") {
                    pdfView.scaleFactor *= 1.2
                }
                Button("Zoom arrière") {
                    pdfView.scaleFactor *= 0.8
                }
                Button("Taille réelle") {
                    pdfView.scaleFactor = 1.0
                }
                Divider()
                Button("Ajuster à la largeur") {
                    pdfView.autoScales = true
                }
            } label: {
                Label("Zoom", systemImage: "magnifyingglass")
            }
        }
    }
    
    // MARK: - Actions
    
    private func goToPage(_ page: Int) {
        guard page >= 1 && page <= totalPages else { return }
        if let pdfPage = pdfView.document?.page(at: page - 1) {
            pdfView.go(to: pdfPage)
        }
    }
    
    // 🔑 CORRECTION : contextualActionButton supprimée - maintenant dans l'assistant global
}

// MARK: - PDFKit Integration

/// Vue SwiftUI qui encapsule PDFView de PDFKit
struct PDFKitView: NSViewRepresentable {
    @Binding var pdfView: PDFView
    let document: DocumentModel
    let onPageChange: (Int, Int) -> Void
    
    func makeNSView(context: Context) -> PDFView {
        pdfView.document = PDFDocument(url: document.url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        
        // Configuration de l'apparence
        pdfView.backgroundColor = NSColor.textBackgroundColor
        
        // Observer pour les changements de page
        NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { _ in
            updatePageInfo()
        }
        
        // Info initiale
        updatePageInfo()
        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        // Mise à jour si nécessaire
        if nsView.document?.documentURL != document.url {
            nsView.document = PDFDocument(url: document.url)
            updatePageInfo()
        }
    }
    
    private func updatePageInfo() {
        guard let document = pdfView.document,
              let currentPage = pdfView.currentPage else { return }
        
        let currentPageIndex = document.index(for: currentPage)
        let totalPages = document.pageCount
        
        onPageChange(currentPageIndex + 1, totalPages)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ReaderView()
            .environmentObject(AppCoordinator())
    }
} 