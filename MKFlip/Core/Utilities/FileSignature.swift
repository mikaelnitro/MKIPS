import Foundation

/// Identificação de formato por *magic bytes* (assinatura no início do arquivo).
/// A extensão mente; os bytes não. Útil em forense para detectar incompatibilidade
/// entre extensão declarada e conteúdo real.
struct FileType: Sendable, Equatable {
    let name: String
    let mime: String
    let category: String
}

enum FileSignature {

    private struct Magic {
        let bytes: [UInt8?]   // nil = coringa (qualquer byte)
        let offset: Int
        let type: FileType
    }

    private static let table: [Magic] = [
        Magic(bytes: [0xFF, 0xD8, 0xFF], offset: 0,
              type: .init(name: "JPEG", mime: "image/jpeg", category: "Imagem")),
        Magic(bytes: [0x89, 0x50, 0x4E, 0x47], offset: 0,
              type: .init(name: "PNG", mime: "image/png", category: "Imagem")),
        Magic(bytes: [0x47, 0x49, 0x46, 0x38], offset: 0,
              type: .init(name: "GIF", mime: "image/gif", category: "Imagem")),
        Magic(bytes: [0x25, 0x50, 0x44, 0x46], offset: 0,
              type: .init(name: "PDF", mime: "application/pdf", category: "Documento")),
        Magic(bytes: [0x50, 0x4B, 0x03, 0x04], offset: 0,
              type: .init(name: "ZIP / OOXML / APK", mime: "application/zip", category: "Arquivo")),
        Magic(bytes: [0x1F, 0x8B], offset: 0,
              type: .init(name: "GZIP", mime: "application/gzip", category: "Arquivo")),
        Magic(bytes: [0x52, 0x61, 0x72, 0x21], offset: 0,
              type: .init(name: "RAR", mime: "application/x-rar", category: "Arquivo")),
        Magic(bytes: [0x7F, 0x45, 0x4C, 0x46], offset: 0,
              type: .init(name: "ELF", mime: "application/x-elf", category: "Executável")),
        Magic(bytes: [0xCF, 0xFA, 0xED, 0xFE], offset: 0,
              type: .init(name: "Mach-O (64-bit)", mime: "application/x-mach-binary", category: "Executável")),
        Magic(bytes: [0x4D, 0x5A], offset: 0,
              type: .init(name: "PE / DOS (EXE)", mime: "application/x-msdownload", category: "Executável")),
        Magic(bytes: [0x66, 0x4C, 0x61, 0x43], offset: 0,
              type: .init(name: "FLAC", mime: "audio/flac", category: "Áudio")),
        Magic(bytes: [0x49, 0x44, 0x33], offset: 0,
              type: .init(name: "MP3 (ID3)", mime: "audio/mpeg", category: "Áudio")),
        Magic(bytes: [0x00, 0x00, 0x00, nil, 0x66, 0x74, 0x79, 0x70], offset: 0,
              type: .init(name: "MP4 / QuickTime", mime: "video/mp4", category: "Vídeo"))
    ]

    /// Detecta o tipo pelos bytes iniciais, ou `nil` se desconhecido.
    static func detect(_ data: Data) -> FileType? {
        let bytes = [UInt8](data.prefix(32))
        for magic in table {
            guard bytes.count >= magic.offset + magic.bytes.count else { continue }
            var match = true
            for (i, expected) in magic.bytes.enumerated() {
                if let expected, bytes[magic.offset + i] != expected { match = false; break }
            }
            if match { return magic.type }
        }
        return nil
    }
}
