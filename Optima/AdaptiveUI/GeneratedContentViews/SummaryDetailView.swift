import SwiftUI

/// Vue pour afficher un résumé détaillé.
struct SummaryDetailView: View {
    let summaryContent: SummaryContent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Résumé du Document")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(summaryContent.text)
                    .font(.body)
                
                Divider()
                
                Text("Points Clés")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                ForEach(summaryContent.keyPoints, id: \.self) { point in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.blue)
                        Text(point)
                    }
                }
                
                if !summaryContent.concepts.isEmpty {
                    Divider()
                    
                    Text("Concepts Importants")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ForEach(summaryContent.concepts) { concept in
                        VStack(alignment: .leading) {
                            Text(concept.name).font(.headline)
                            Text(concept.definition).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 5)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Résumé")
    }
} 