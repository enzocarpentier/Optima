//
//  ContentView.swift
//  Optima
//
//  Vue de contenu temporaire - sera supprimée après migration complète
//  TODO: Supprimer ce fichier après validation de l'architecture
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "brain.head.profile")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Optima - Architecture en cours de construction")
                .font(.title2)
                .fontDesign(.rounded)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
