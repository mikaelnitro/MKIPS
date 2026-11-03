import SwiftUI

/// Exibe um `Report` já gerado com prévia e ações de exportar (TXT/PDF) e
/// salvar na central de relatórios. Reutilizado por todos os módulos.
struct ReportResultView: View {
    let report: Report
    let onSave: (() -> Void)?

    @State private var shareURL: ShareItem?
    @State private var exportError: String?

    private struct ShareItem: Identifiable { let id = UUID(); let url: URL }

    /// Init explícito: garante que o trailing closure dos chamadores vincule a
    /// `onSave` (e não a uma propriedade `@State` declarada depois).
    init(report: Report, onSave: (() -> Void)? = nil) {
        self.report = report
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(report.sections, id: \.heading) { section in
                VStack(alignment: .leading, spacing: 6) {
                    Text(section.heading.uppercased())
                        .font(MKFont.caption()).tracking(1)
                        .foregroundStyle(MKTheme.Color.purple)
                    ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(MKFont.mono(12))
                            .foregroundStyle(MKTheme.Color.textPrimary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            if let exportError {
                Text(exportError).font(MKFont.caption()).foregroundStyle(MKTheme.Color.danger)
            }

            HStack(spacing: 10) {
                MKButton(title: "TXT", systemImage: "doc.plaintext", kind: .secondary) { export(.txt) }
                MKButton(title: "PDF", systemImage: "doc.richtext", kind: .secondary) { export(.pdf) }
                if let onSave {
                    MKButton(title: "Salvar", systemImage: "tray.and.arrow.down") { onSave() }
                }
            }
        }
        .sheet(item: $shareURL) { item in
            ShareSheet(items: [item.url])
        }
    }

    private func export(_ format: ReportExporter.Format) {
        do {
            let url = try ReportExporter.export(report, as: format)
            shareURL = ShareItem(url: url)
        } catch {
            exportError = "Falha ao exportar: \(error.localizedDescription)"
        }
    }
}
