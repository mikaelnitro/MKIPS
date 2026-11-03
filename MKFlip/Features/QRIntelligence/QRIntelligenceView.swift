import SwiftUI
import UIKit

/// QR Intelligence — lê QR Codes e analisa o conteúdo **antes** de abrir
/// qualquer link. Nunca abre destinos automaticamente.
struct QRIntelligenceView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var scanning = false
    @State private var manual = ""
    @State private var analysis: URLAnalysis?
    @State private var raw = ""
    @State private var cameraMessage: String?
    @State private var history: [String] = []
    @State private var confirmOpen = false

    var body: some View {
        ModuleScreen(title: "QR Intelligence") {
            MKButton(title: scanning ? "Parar câmera" : "Escanear QR Code",
                     systemImage: "qrcode.viewfinder") {
                scanning.toggle()
            }

            if scanning {
                QRScannerView(
                    onScan: { value in handle(value); scanning = false },
                    onUnavailable: { msg in cameraMessage = msg; scanning = false }
                )
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: MKTheme.Metric.cornerRadius, style: .continuous)
                        .strokeBorder(MKTheme.Color.neon.opacity(0.5), lineWidth: 1)
                )
            }

            if let cameraMessage {
                Text(cameraMessage).font(MKFont.caption()).foregroundStyle(MKTheme.Color.warning)
            }

            MKSectionHeader(title: "Analisar manualmente")
            MKTextField(placeholder: "Cole o conteúdo de um QR / URL…", text: $manual, mono: true)
            MKButton(title: "Analisar", systemImage: "magnifyingglass", kind: .secondary) {
                handle(manual)
            }

            if let analysis { resultView(analysis) }

            if !history.isEmpty {
                MKSectionHeader(title: "Histórico de leituras")
                MKCard {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(history.enumerated()), id: \.offset) { _, item in
                            Text(item).font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    private func handle(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        raw = trimmed
        analysis = URLAnalyzer.analyze(trimmed)
        history.insert(trimmed, at: 0)
        if history.count > 20 { history.removeLast() }
        env.activityLog.log("QR", "Conteúdo lido: \(analysis?.kind.rawValue ?? "?") · risco \(analysis?.riskLevel.rawValue ?? "?")",
                            severity: (analysis?.riskLevel == .high) ? .warning : .success)
    }

    @ViewBuilder
    private func resultView(_ a: URLAnalysis) -> some View {
        let tint: Color = a.riskLevel == .high ? MKTheme.Color.danger
                        : (a.riskLevel == .medium ? MKTheme.Color.warning : MKTheme.Color.neon)
        MKCard(highlighted: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(a.kind.rawValue).font(MKFont.title(16)).foregroundStyle(MKTheme.Color.textPrimary)
                    Spacer()
                    StatusPill(text: "RISCO \(a.riskLevel.rawValue.uppercased())", tint: tint)
                }
                Text(a.normalized).font(MKFont.mono(12)).foregroundStyle(MKTheme.Color.textSecondary)
                    .textSelection(.enabled)
                if let host = a.host { MKKeyValueRow(key: "Host", value: host) }
                if let scheme = a.scheme {
                    MKKeyValueRow(key: "Esquema", value: scheme,
                                  valueTint: a.isHTTPS ? MKTheme.Color.neon : MKTheme.Color.warning)
                }
            }
        }

        if !a.riskSignals.isEmpty {
            MKCard {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Sinais de risco", systemImage: "exclamationmark.triangle")
                        .font(MKFont.label(13)).foregroundStyle(MKTheme.Color.danger)
                    ForEach(a.riskSignals, id: \.self) { s in
                        Text("• \(s)").font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textPrimary)
                    }
                }
            }
        }

        if a.kind == .url, let url = URL(string: a.normalized) {
            MKButton(title: "Abrir link (com confirmação)", systemImage: "arrow.up.right.square",
                     kind: a.riskLevel == .high ? .secondary : .primary) {
                confirmOpen = true
            }
            .confirmationDialog("Abrir \(a.host ?? a.normalized)?",
                                isPresented: $confirmOpen, titleVisibility: .visible) {
                Button("Abrir", role: a.riskLevel == .high ? .destructive : nil) {
                    UIApplication.shared.open(url)
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text(a.riskLevel == .high
                     ? "Esta URL tem sinais de risco ALTO. Abra apenas se confiar no destino."
                     : "O link será aberto no navegador padrão.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        QRIntelligenceView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
