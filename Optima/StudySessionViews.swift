import SwiftUI

struct StudyHeaderView: View {
    let sessionTitle: String
    let documentName: String
    let progress: Double?
    let progressText: String?
    let onClose: () -> Void

    init(sessionTitle: String, documentName: String, progress: Double? = nil, progressText: String? = nil, onClose: @escaping () -> Void) {
        self.sessionTitle = sessionTitle
        self.documentName = documentName
        self.progress = progress
        self.progressText = progressText
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionTitle)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(documentName)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }

            if let progress = progress, let progressText = progressText {
                VStack(spacing: 8) {
                    HStack {
                        Text(progressText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.9),
                    Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
} 