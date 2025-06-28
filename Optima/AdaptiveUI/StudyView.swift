//
//  StudyView.swift
//  AdaptiveUI
//
//  Vue des modes d'étude interactifs
//  Quiz, flashcards et révisions
//

import SwiftUI

struct StudyView: View {
    var body: some View {
        VStack {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text("Modes d'Étude")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Quiz interactifs et flashcards seront disponibles dans la Phase 5")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Étude")
    }
}

#Preview {
    StudyView()
} 