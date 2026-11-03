import SwiftUI
import UIKit

/// Ponte para `UIActivityViewController` — folha de compartilhamento do iOS,
/// usada para exportar relatórios (.txt/.pdf) e dados.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
