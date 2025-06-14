import SwiftUI
import PDFKit

struct PDFPreview: View {
    let document: StoredPDFDocument
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(document.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            // PDF View
            PDFKitRepresentedView(url: document.url)
                .background(Color(nsColor: .darkGray))
        }
        .frame(minWidth: 400, idealWidth: 800, minHeight: 500, idealHeight: 1000)
    }
}

struct PDFKitRepresentedView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: self.url)
        pdfView.autoScales = true
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = PDFDocument(url: self.url)
    }
} 