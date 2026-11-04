import SwiftUI
import UIKit

/// Ajustes do app: informações de sistema e configuração da IA (provedor
/// gratuito + chave inserida manualmente, guardada só no Keychain).
struct SettingsView: View {
    @State private var providerID: String = AIConfiguration.providers.first?.id ?? "groq"
    @State private var baseURL: String = AIConfiguration.baseURL
    @State private var model: String = AIConfiguration.model
    @State private var apiKey: String = ""
    @State private var revealKey = false
    @State private var saved = false
    @State private var hasKey = AIConfiguration.isConfigured

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MKTheme.Metric.spacingLarge) {
                systemSection
                aiSection
            }
            .padding(MKTheme.Metric.spacing)
            .padding(.bottom, 40)
        }
        .background(MKBackground())
        .navigationTitle("Configurações")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { syncFromStore() }
    }

    // MARK: Sistema

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MKSectionHeader(title: "Sistema")
            MKCard {
                infoRow("Versão", "0.1.0")
                Divider().overlay(MKTheme.Color.hairline)
                infoRow("Plataforma", "iOS 18 · iPhone 16")
                Divider().overlay(MKTheme.Color.hairline)
                infoRow("Módulos online", "\(ModuleCatalog.onlineCount)/\(ModuleCatalog.all.count)")
            }
        }
    }

    // MARK: IA

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MKSectionHeader(title: "Inteligência artificial")

            MKCard(highlighted: hasKey) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Status").font(MKFont.body(13)).foregroundStyle(MKTheme.Color.textSecondary)
                        Spacer()
                        StatusPill(text: hasKey ? "CONECTADA" : "OFFLINE (LOCAL)",
                                   tint: hasKey ? MKTheme.Color.neon : MKTheme.Color.warning,
                                   pulsing: hasKey)
                    }

                    Text("Escolha um provedor **gratuito**, gere a chave no site dele e cole abaixo. A chave fica só no Keychain do aparelho.")
                        .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)

                    // Provedor
                    Text("PROVEDOR").font(MKFont.caption()).tracking(1).foregroundStyle(MKTheme.Color.textTertiary)
                    Picker("Provedor", selection: $providerID) {
                        ForEach(AIConfiguration.providers) { Text($0.name).tag($0.id) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: providerID) { _, newValue in applyPreset(newValue) }

                    if let p = AIConfiguration.providers.first(where: { $0.id == providerID }),
                       !p.signupURL.isEmpty, let url = URL(string: p.signupURL) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            Label("Gerar chave grátis em \(p.name)", systemImage: "arrow.up.right.square")
                                .font(MKFont.caption()).foregroundStyle(MKTheme.Color.neon)
                        }
                    }

                    // Base URL + modelo
                    labeledField("BASE URL (OpenAI-compatible)", text: $baseURL)
                    labeledField("MODELO", text: $model)

                    // Chave
                    Text("API KEY").font(MKFont.caption()).tracking(1).foregroundStyle(MKTheme.Color.textTertiary)
                    HStack {
                        Group {
                            if revealKey { TextField("cole sua chave…", text: $apiKey) }
                            else { SecureField(hasKey ? "•••••• (chave salva)" : "cole sua chave…", text: $apiKey) }
                        }
                        .font(MKFont.mono(12)).foregroundStyle(MKTheme.Color.textPrimary)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button { revealKey.toggle() } label: {
                            Image(systemName: revealKey ? "eye.slash" : "eye")
                                .foregroundStyle(MKTheme.Color.textSecondary)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 8).fill(MKTheme.Color.background))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(MKTheme.Color.hairline, lineWidth: 1))

                    HStack(spacing: 10) {
                        MKButton(title: saved ? "Salvo ✓" : "Salvar", systemImage: "checkmark.circle") { save() }
                        if hasKey {
                            MKButton(title: "Remover chave", systemImage: "trash", kind: .secondary) { removeKey() }
                        }
                    }
                }
            }
        }
    }

    // MARK: Ações

    private func syncFromStore() {
        baseURL = AIConfiguration.baseURL
        model = AIConfiguration.model
        hasKey = AIConfiguration.isConfigured
        // Detecta o preset atual pela base URL.
        if let match = AIConfiguration.providers.first(where: { $0.baseURL == baseURL }) {
            providerID = match.id
        } else {
            providerID = "custom"
        }
    }

    private func applyPreset(_ id: String) {
        guard let p = AIConfiguration.providers.first(where: { $0.id == id }), id != "custom" else { return }
        baseURL = p.baseURL
        model = p.model
    }

    private func save() {
        AIConfiguration.baseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        AIConfiguration.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AIConfiguration.setAPIKey(apiKey)
            apiKey = ""
        }
        hasKey = AIConfiguration.isConfigured
        saved = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            saved = false
        }
    }

    private func removeKey() {
        AIConfiguration.setAPIKey(nil)
        apiKey = ""
        hasKey = false
    }

    // MARK: Componentes

    private func labeledField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(MKFont.caption()).tracking(1).foregroundStyle(MKTheme.Color.textTertiary)
            MKTextField(placeholder: label, text: text, mono: true)
        }
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).font(MKFont.body()).foregroundStyle(MKTheme.Color.textSecondary)
            Spacer()
            Text(value).font(MKFont.mono(13)).foregroundStyle(MKTheme.Color.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
