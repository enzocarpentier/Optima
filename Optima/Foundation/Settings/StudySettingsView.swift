//
//  StudySettingsView.swift
//  Foundation/Settings
//

import SwiftUI

struct StudySettingsView: View {
    @AppStorage("defaultQuizQuestionCount") private var defaultQuizQuestionCount: Int = 10
    @AppStorage("enableStudySounds") private var enableStudySounds: Bool = true
    @AppStorage("flashcardInterval") private var flashcardInterval: Double = 1.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                settingsSection(title: "Quiz", icon: "questionmark.circle") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Text("Nombre de questions par défaut :")
                                .frame(width: 200, alignment: .leading)
                            
                            Picker("Questions", selection: $defaultQuizQuestionCount) {
                                Text("5 questions").tag(5)
                                Text("10 questions").tag(10)
                                Text("15 questions").tag(15)
                                Text("20 questions").tag(20)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 130)
                        }
                    }
                }
                
                settingsSection(title: "Flashcards", icon: "rectangle.on.rectangle") {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Text("Intervalle d'affichage :")
                                .frame(width: 150, alignment: .leading)
                            
                            Picker("Intervalle", selection: $flashcardInterval) {
                                Text("Rapide (0.5s)").tag(0.5)
                                Text("Normal (1s)").tag(1.0)
                                Text("Lent (2s)").tag(2.0)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 130)
                        }
                    }
                }
                
                settingsSection(title: "Interface", icon: "speaker.wave.2") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Sons d'étude", isOn: $enableStudySounds)
                    }
                }
                
            }
            .padding(24)
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            content()
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    StudySettingsView()
        .frame(width: 580, height: 450)
}
