import Foundation

/// Capacidades planejadas por módulo, exibidas nos placeholders honestos.
/// Mantido separado do catálogo para facilitar revisão do escopo por fase.
enum ModuleCapabilities {
    static func planned(for id: ModuleID) -> [String] {
        switch id {
        case .mkAI:
            ["Interpretação de comandos em linguagem natural",
             "Roteamento para o módulo adequado",
             "Análise dos resultados das ferramentas",
             "Geração de relatórios e histórico"]
        case .terminal:
            ["Console de comandos reais (sem comandos falsos)",
             "Histórico de comandos", "Logs de execução com severidade"]
        case .cryptography:
            ["SHA-256 / SHA-512", "Base64 e hex", "Identificação de hashes",
             "Comparação de hashes", "Geração de chaves de demonstração"]
        case .qrIntelligence:
            ["Leitura de QR via câmera", "Classificação do conteúdo",
             "Análise de URL antes de abrir", "Histórico de leituras"]
        case .forensics:
            ["Importação de arquivos", "Metadados e extensão",
             "Visualização hexadecimal", "Cálculo de hashes", "Preservação do original"]
        case .nfcLab:
            ["Leitura de tags NFC compatíveis (Core NFC)", "Registros NDEF",
             "Identificação de tecnologia", "Aviso claro de incompatibilidade",
             "Sem clonagem de pagamento/credenciais"]
        case .bluetooth:
            ["Varredura de dispositivos BLE (Core Bluetooth)", "UUIDs de serviço",
             "RSSI e dados anunciados", "Histórico — somente observação autorizada"]
        case .network:
            ["Informações da conexão atual", "Consulta DNS", "Disponibilidade de serviços",
             "Análise de certificado TLS autorizado", "Respeita restrições do iOS"]
        case .webSecurity:
            ["DNS", "Verificação de HTTPS", "Inspeção de certificado",
             "Cabeçalhos HTTP de segurança", "Requer domínio autorizado"]
        case .osint:
            ["Análise de domínio", "Registros DNS públicos", "Análise de URL",
             "Identificação de links suspeitos", "Organização de evidências"]
        case .passwordLab:
            ["Análise de força", "Estimativa de entropia",
             "Detecção de padrões fracos", "Recomendações de segurança"]
        case .aiReverse:
            ["Análise de arquivos fornecidos", "Hex e strings", "Metadados",
             "Comparação de arquivos", "Sem exploração automática de terceiros"]
        case .reports:
            ["Compilação por ferramenta", "Data/hora e dados analisados",
             "Resultados e recomendações", "Exportação PDF/TXT"]
        }
    }
}
