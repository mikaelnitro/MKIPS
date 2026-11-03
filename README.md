# MK FLIP — AI Cyber Intelligence

Central de cibersegurança, laboratório de engenharia reversa e ambiente educacional de
segurança digital para **iPhone 16 / iOS 18**. Swift + SwiftUI + MVVM.

> **Uso autorizado e educacional.** As ferramentas de rede/web operam apenas sobre
> alvos que você possui ou tem autorização para testar. O app **não** clona cartões
> de pagamento/credenciais, **não** explora dispositivos de terceiros e **não** simula
> uma IA conectada quando não há API configurada.

---

## Como abrir no Xcode (macOS)

Este repositório contém o código-fonte e um `project.yml` para o
[XcodeGen](https://github.com/yonicd/XcodeGen), que gera o `.xcodeproj` de forma
determinística (nada de conflitos de merge em `.pbxproj`).

```bash
# 1. Instale o XcodeGen (uma vez)
brew install xcodegen

# 2. Gere o projeto
cd MKFlip
xcodegen generate

# 3. Abra
open MKFlip.xcodeproj
```

**Alternativa sem XcodeGen:** crie um novo projeto *App* (SwiftUI, iOS 18) no Xcode,
arraste a pasta `MKFlip/` para dentro e copie as descrições de permissão (seção
*Permissões* abaixo) para o target.

### Capacidades a habilitar no target
- **Near Field Communication Tag Reading** (para o NFC Lab) — já referenciada em
  `MKFlip/Resources/MKFlip.entitlements`.
- As permissões de uso (NFC, Bluetooth, Câmera, Rede Local) já estão no `project.yml`
  via chaves `INFOPLIST_KEY_*`.

---

## Testes

A lógica independente de frameworks tem cobertura em `MKFlipTests` (XCTest):

```bash
xcodebuild test -scheme MKFlip -destination 'platform=iOS Simulator,name=iPhone 16'
```

ou **⌘U** no Xcode. Cobrem: hashes (vetores NIST), Base64/hex, identificação de
hash, auditoria de senha, assinaturas de arquivo, extração de strings, hex dump,
análise de URL, comparação de arquivos e o motor do terminal.

> **Nota de ambiente:** este projeto foi escrito em Windows, onde não há Xcode nem
> toolchain Swift com os frameworks da Apple. Portanto **não foi compilado nem testado
> aqui** — a compilação e os testes devem ser executados no macOS. O código segue as
> APIs públicas de iOS 18 e está organizado para abrir e compilar no Xcode 16.

---

## Arquitetura

```
MKFlip/
├── App/              Entrada, injeção de dependências (AppEnvironment), navegação raiz
├── Core/
│   ├── Theme/        Cores, tipografia, métricas (identidade visual)
│   ├── Components/    MKCard, MKButton, StatusPill, TerminalPanel, Background…
│   ├── Navigation/   Rotas tipadas + AppRouter
│   ├── Models/       ToolModule, ActivityEvent, SystemStatus
│   ├── Security/     HashEngine, EncodingTools, HashIdentifier, KeyGenerator, PasswordAnalyzer
│   ├── Utilities/    HexDump, FileSignature, StringsExtractor, URLAnalyzer
│   ├── Services/     ActivityLog, ModuleCatalog, NetworkTools, WebSecurityScanner, DoHClient,
│   │                 Report, ReportStore, ReportExporter
│   └── AI/           AIProvider, LocalIntelligence, RemoteAIProvider, KeychainStore
└── Features/         Uma pasta por módulo (View + ViewModel/Service dedicados)
```

Cada serviço fica atrás de uma abstração, para que a UI não dependa de implementação
concreta e os módulos sejam testáveis isoladamente.

---

## Matriz de capacidades (honesta)

| Módulo | Estado | O que faz de verdade | Requisito |
|---|---|---|---|
| Cyber Terminal | ✅ online | Comandos reais (hash, encode, urlcheck, pwcheck, DNS, open…) | — |
| Cryptography Lab | ✅ online | SHA-256/512, MD5, Base64/hex, identificação, chaves demo (CryptoKit) | — |
| QR Intelligence | ✅ online | Leitura por câmera + análise de risco de URL antes de abrir | Câmera p/ scan |
| Digital Forensics | ✅ online | Tipo real por magic bytes, entropia, hashes, hex, strings | — |
| Password Lab | ✅ online | Entropia, classes de caracteres, padrões fracos | — |
| Network Intelligence | ✅ online | Interface atual, DNS (getaddrinfo), checagem de porta TCP | Rede |
| Web Security | ✅ online | TLS/certificado + cabeçalhos de segurança HTTP | Rede + autorização |
| OSINT Intelligence | ✅ online | DNS público (DoH), análise de URL, evidências, relatório | Rede |
| AI Reverse | ✅ online | Análise estática, comparação binária, biblioteca de protocolos | — |
| MK AI | ✅ online (local) | Roteamento de intenção + execução local; remota pronta p/ API | — |
| Relatórios | ✅ online | Lista, visualiza, exporta TXT/PDF, remove | — |
| NFC Lab | ⚙️ condicional | Leitura de UID + NDEF de tags compatíveis (Core NFC) | iPhone com NFC |
| Bluetooth Intelligence | ⚙️ condicional | Varredura BLE, RSSI, UUIDs, dados de anúncio (Core Bluetooth) | Permissão BLE |

**Condicional** = depende de hardware/permissão que pode não existir no simulador.
O app detecta e informa quando indisponível, sem fingir funcionamento.

---

## IA e chaves de API

- A **MK AI** funciona offline com inteligência local (`LocalIntelligence`): interpreta
  linguagem natural, executa operações reais e roteia para o módulo certo.
- A integração remota (`RemoteAIProvider`) tem a **arquitetura pronta**, mas só ativa
  quando houver uma chave gravada no **Keychain** (`KeychainStore`). Nenhuma chave é
  embutida no código-fonte. Sem chave, o app declara-se offline — não simula conexão.

---

## Roadmap técnico

- Migrar para o **modo de linguagem Swift 6** (hoje em Swift 5 para garantir build limpo).
- Persistência via **SwiftData** no lugar do JSON em `ReportStore` (interface já estável).
- Cliente HTTP real no `RemoteAIProvider` (ex.: Claude API) lendo a chave do Keychain.
- Ícone do app (o `AppIcon.appiconset` está presente como placeholder de 1024×1024).
