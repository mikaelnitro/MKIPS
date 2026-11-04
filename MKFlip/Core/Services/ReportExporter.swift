import Foundation
import UIKit

/// Exporta um `Report` para arquivos temporários (.txt e .pdf) prontos para
/// compartilhar via `ShareLink`/UIActivityViewController.
enum ReportExporter {

    enum Format { case txt, pdf, json }

    /// Escreve o relatório num arquivo temporário e devolve a URL.
    static func export(_ report: Report, as format: Format) throws -> URL {
        switch format {
        case .txt: try exportTXT(report)
        case .pdf: try exportPDF(report)
        case .json: try exportJSON(report)
        }
    }

    private static func exportJSON(_ report: Report) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(report, ext: "json"))
        let data = try JSONEncoder.mk.encode(report)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func fileName(_ report: Report, ext: String) -> String {
        let safeTool = report.tool.lowercased().replacingOccurrences(of: " ", with: "_")
        let ts = Int(report.createdAt.timeIntervalSince1970)
        return "mkflip_\(safeTool)_\(ts).\(ext)"
    }

    private static func exportTXT(_ report: Report) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(report, ext: "txt"))
        try report.plainText.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func exportPDF(_ report: Report) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName(report, ext: "pdf"))

        let pageWidth: CGFloat = 595   // A4 @ 72dpi
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        try renderer.writePDF(to: url) { ctx in
            var y: CGFloat = margin
            ctx.beginPage()

            func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 6) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let maxWidth = pageWidth - margin * 2
                let bounding = (text as NSString).boundingRect(
                    with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attrs, context: nil)
                if y + bounding.height > pageHeight - margin {
                    ctx.beginPage(); y = margin
                }
                (text as NSString).draw(in: CGRect(x: margin, y: y, width: maxWidth, height: bounding.height),
                                        withAttributes: attrs)
                y += bounding.height + spacingAfter
            }

            draw("MK FLIP — Relatório", font: .boldSystemFont(ofSize: 22), color: UIColor(white: 0.1, alpha: 1))
            draw("\(report.tool) · \(report.title)", font: .systemFont(ofSize: 13), color: .darkGray)
            draw("Assunto: \(report.subject)", font: .systemFont(ofSize: 11), color: .darkGray)
            draw("Data/Hora: \(Report.stamp.string(from: report.createdAt))",
                 font: .systemFont(ofSize: 11), color: .darkGray, spacingAfter: 16)

            for section in report.sections {
                draw(section.heading, font: .boldSystemFont(ofSize: 14),
                     color: UIColor(red: 0.42, green: 0.13, blue: 0.66, alpha: 1))
                for line in section.lines {
                    draw(line, font: .monospacedSystemFont(ofSize: 10, weight: .regular), spacingAfter: 3)
                }
                y += 8
            }
        }
        return url
    }
}
