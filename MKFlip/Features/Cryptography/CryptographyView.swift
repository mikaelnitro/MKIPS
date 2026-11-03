import SwiftUI

/// Cryptography Lab — hash, codificação, identificação e chaves de demonstração.
/// Toda computação é local e real (CryptoKit). Abas organizam as ferramentas.
struct CryptographyView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var tab: Tab = .hash

    enum Tab: String, CaseIterable, Identifiable {
        case hash = "Hash"
        case encode = "Codificar"
        case identify = "Identificar"
        case keys = "Chaves"
        var id: String { rawValue }
    }

    var body: some View {
        ModuleScreen(title: "Cryptography Lab") {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            switch tab {
            case .hash:     HashTabView(log: env.activityLog)
            case .encode:   EncodeTabView()
            case .identify: IdentifyTabView()
            case .keys:     KeysTabView()
            }
        }
    }
}

// MARK: - Hash

private struct HashTabView: View {
    let log: ActivityLog
    @State private var input = ""
    @State private var results: [(HashAlgorithm, String)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MKSectionHeader(title: "Texto de entrada")
            MKTextField(placeholder: "Digite o texto para gerar o hash…", text: $input)
            MKButton(title: "Gerar hashes", systemImage: "number") {
                results = HashEngine.digest(Data(input.utf8))
                log.log("CRYPTO", "Hash gerado para \(input.count) caractere(s)", severity: .success)
            }

            if !results.isEmpty {
                MKCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(results, id: \.0) { algo, value in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(algo.rawValue).font(MKFont.label(12))
                                        .foregroundStyle(MKTheme.Color.neon)
                                    if algo.isLegacy {
                                        Text("legado").font(MKFont.caption())
                                            .foregroundStyle(MKTheme.Color.warning)
                                    }
                                }
                                Text(value).font(MKFont.mono(11))
                                    .foregroundStyle(MKTheme.Color.textPrimary)
                                    .textSelection(.enabled)
                            }
                            if algo != results.last?.0 { Divider().overlay(MKTheme.Color.hairline) }
                        }
                    }
                }
                Text("Hash é uma via de mão única — não é criptografia reversível.")
                    .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
            }
        }
    }
}

// MARK: - Codificar

private struct EncodeTabView: View {
    @State private var input = ""
    @State private var b64 = ""
    @State private var hex = ""
    @State private var decoded = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MKSectionHeader(title: "Entrada")
            MKTextField(placeholder: "Texto ou valor codificado…", text: $input)

            HStack(spacing: 10) {
                MKButton(title: "→ Base64", kind: .secondary) {
                    b64 = EncodingTools.base64Encode(input); hex = ""; decoded = ""
                }
                MKButton(title: "→ Hex", kind: .secondary) {
                    hex = EncodingTools.hexEncode(input); b64 = ""; decoded = ""
                }
            }
            HStack(spacing: 10) {
                MKButton(title: "Base64 →", kind: .ghost) {
                    decoded = EncodingTools.base64Decode(input) ?? "⚠︎ Base64 inválido"
                }
                MKButton(title: "Hex →", kind: .ghost) {
                    decoded = EncodingTools.hexDecode(input) ?? "⚠︎ Hex inválido"
                }
            }

            if !b64.isEmpty { resultCard("Base64", b64) }
            if !hex.isEmpty { resultCard("Hex", hex) }
            if !decoded.isEmpty { resultCard("Decodificado", decoded) }
        }
    }

    private func resultCard(_ title: String, _ value: String) -> some View {
        MKCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(MKFont.label(12)).foregroundStyle(MKTheme.Color.neon)
                Text(value).font(MKFont.mono(12)).foregroundStyle(MKTheme.Color.textPrimary)
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - Identificar

private struct IdentifyTabView: View {
    @State private var input = ""
    @State private var guesses: [HashGuess] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MKSectionHeader(title: "Hash desconhecido")
            MKTextField(placeholder: "Cole um hash para identificar…", text: $input, mono: true)
            MKButton(title: "Identificar", systemImage: "questionmark.circle") {
                guesses = HashIdentifier.identify(input)
            }
            if !guesses.isEmpty {
                MKCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(guesses) { g in
                            HStack {
                                Text(g.name).font(MKFont.body(14))
                                    .foregroundStyle(MKTheme.Color.textPrimary)
                                Spacer()
                                StatusPill(text: g.confidence.uppercased(),
                                           tint: g.confidence == "provável" ? MKTheme.Color.neon : MKTheme.Color.warning)
                            }
                        }
                    }
                }
                Text("Identificação heurística por comprimento/alfabeto — candidatos, não certezas.")
                    .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
            }
        }
    }
}

// MARK: - Chaves

private struct KeysTabView: View {
    @State private var output: [(String, String)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MKSectionHeader(title: "Geração de demonstração")
            VStack(spacing: 10) {
                MKButton(title: "Bytes aleatórios (32)", systemImage: "dice") {
                    output = [("Random 32 bytes (hex)", KeyGenerator.randomBytes(count: 32))]
                }
                MKButton(title: "Chave AES-256", systemImage: "key", kind: .secondary) {
                    output = [("AES-256 (Base64)", KeyGenerator.symmetricKeyBase64(bits: 256))]
                }
                MKButton(title: "Par Curve25519", systemImage: "key.horizontal", kind: .secondary) {
                    let pair = KeyGenerator.curve25519Pair()
                    output = [("Privada (Base64)", pair.privateKey), ("Pública (Base64)", pair.publicKey)]
                }
            }
            ForEach(output, id: \.0) { title, value in
                MKCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(MKFont.label(12)).foregroundStyle(MKTheme.Color.neon)
                        Text(value).font(MKFont.mono(11)).foregroundStyle(MKTheme.Color.textPrimary)
                            .textSelection(.enabled)
                    }
                }
            }
            if !output.isEmpty {
                Text("Material de demonstração — não use em produção; gere e guarde chaves reais no Keychain.")
                    .font(MKFont.caption()).foregroundStyle(MKTheme.Color.textTertiary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CryptographyView().environment({ let e = AppEnvironment(); e.bootstrap(); return e }())
    }
}
