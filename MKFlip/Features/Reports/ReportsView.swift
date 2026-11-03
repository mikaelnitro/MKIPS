import SwiftUI

/// Central de relatórios — lista os relatórios gerados pelas ferramentas,
/// com visualização, exportação (TXT/PDF) e remoção.
struct ReportsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ModuleScreen(title: "Relatórios") {
            if env.reportStore.reports.isEmpty {
                MKCard {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Nenhum relatório salvo", systemImage: "tray")
                            .font(MKFont.label(14)).foregroundStyle(MKTheme.Color.textSecondary)
                        Text("Gere relatórios em Forensics, Web Security ou OSINT e salve-os aqui.")
                            .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
                    }
                }
            } else {
                ForEach(env.reportStore.reports) { report in
                    NavigationLink {
                        ReportDetailView(report: report)
                    } label: {
                        reportRow(report)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func reportRow(_ r: Report) -> some View {
        MKCard {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.title).font(MKFont.label(14)).foregroundStyle(MKTheme.Color.textPrimary)
                        .lineLimit(1)
                    Text("\(r.tool) · \(Report.stamp.string(from: r.createdAt))")
                        .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(MKTheme.Color.textTertiary)
            }
        }
    }
}

/// Detalhe de um relatório com ações de exportar e excluir.
struct ReportDetailView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    let report: Report
    @State private var confirmDelete = false

    var body: some View {
        ModuleScreen(title: report.tool) {
            MKCard {
                ReportResultView(report: report)
            }
            MKButton(title: "Excluir relatório", systemImage: "trash", kind: .secondary) {
                confirmDelete = true
            }
            .confirmationDialog("Excluir este relatório?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Excluir", role: .destructive) {
                    env.reportStore.delete(report)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReportsView().environment({
            let e = AppEnvironment()
            e.reportStore.add(Report(tool: "Digital Forensics", title: "Análise de teste.bin",
                                     subject: "teste.bin",
                                     sections: [.init(heading: "Visão geral", lines: ["Tamanho: 1024 bytes"])]))
            return e
        }())
    }
}
