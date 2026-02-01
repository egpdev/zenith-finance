//
//  DataExportManager.swift
//  calculateAI
//
//  Export transactions to CSV and PDF
//

import Combine
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class DataExportManager: ObservableObject {
    static let shared = DataExportManager()

    @Published var isExporting = false
    @Published var exportProgress: Double = 0

    private init() {}

    // MARK: - Export to CSV
    func exportToCSV(transactions: [ZenithTransaction]) -> URL? {
        isExporting = true
        defer { isExporting = false }

        var csvString = "Date,Merchant,Amount,Type,Category\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for (index, transaction) in transactions.enumerated() {
            let date = dateFormatter.string(from: transaction.date)
            let merchant = transaction.merchant.replacingOccurrences(of: ",", with: ";")
            let amount = String(format: "%.2f", transaction.amount)
            let type = transaction.type.rawValue
            let category = transaction.category.rawValue

            csvString += "\(date),\(merchant),\(amount),\(type),\(category)\n"

            exportProgress = Double(index + 1) / Double(transactions.count)
        }

        // Save to temporary file
        let fileName = "zenith_transactions_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    // MARK: - Export to PDF
    func exportToPDF(transactions: [ZenithTransaction], summary: TransactionSummary) -> URL? {
        isExporting = true
        defer { isExporting = false }

        let pdfMetaData = [
            kCGPDFContextCreator: "Zenith Finance",
            kCGPDFContextAuthor: "Zenith App",
            kCGPDFContextTitle: "Financial Report",
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = margin

            // Title
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black,
            ]

            let title = "Zenith Finance Report"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = "Generated: \(dateFormatter.string(from: Date()))"
            let dateFont = UIFont.systemFont(ofSize: 12)
            dateString.draw(
                at: CGPoint(x: margin, y: yPosition),
                withAttributes: [.font: dateFont, .foregroundColor: UIColor.gray])
            yPosition += 40

            // Summary Section
            let summaryFont = UIFont.systemFont(ofSize: 16, weight: .semibold)
            "Summary".draw(
                at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: summaryFont])
            yPosition += 25

            let bodyFont = UIFont.systemFont(ofSize: 12)
            let summaryItems = [
                "Total Income: $\(String(format: "%.2f", summary.totalIncome))",
                "Total Expenses: $\(String(format: "%.2f", summary.totalExpenses))",
                "Net Balance: $\(String(format: "%.2f", summary.balance))",
                "Total Transactions: \(summary.transactionCount)",
            ]

            for item in summaryItems {
                item.draw(
                    at: CGPoint(x: margin + 10, y: yPosition), withAttributes: [.font: bodyFont])
                yPosition += 18
            }
            yPosition += 20

            // Transactions Header
            "Transactions".draw(
                at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: summaryFont])
            yPosition += 25

            // Table Header
            let headerFont = UIFont.systemFont(ofSize: 10, weight: .bold)
            let headers = ["Date", "Merchant", "Category", "Amount"]
            let columnWidths: [CGFloat] = [100, 180, 120, 80]
            var xPos: CGFloat = margin

            for (index, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPos, y: yPosition), withAttributes: [.font: headerFont])
                xPos += columnWidths[index]
            }
            yPosition += 20

            // Draw line
            let line = UIBezierPath()
            line.move(to: CGPoint(x: margin, y: yPosition))
            line.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            UIColor.gray.setStroke()
            line.stroke()
            yPosition += 10

            // Transaction rows
            let rowFont = UIFont.systemFont(ofSize: 10)
            let shortDateFormatter = DateFormatter()
            shortDateFormatter.dateFormat = "MMM d, yyyy"

            for (index, transaction) in transactions.enumerated() {
                if yPosition > pageHeight - margin - 50 {
                    context.beginPage()
                    yPosition = margin
                }

                xPos = margin

                let date = shortDateFormatter.string(from: transaction.date)
                date.draw(at: CGPoint(x: xPos, y: yPosition), withAttributes: [.font: rowFont])
                xPos += columnWidths[0]

                let merchant = String(transaction.merchant.prefix(25))
                merchant.draw(at: CGPoint(x: xPos, y: yPosition), withAttributes: [.font: rowFont])
                xPos += columnWidths[1]

                transaction.category.rawValue.draw(
                    at: CGPoint(x: xPos, y: yPosition), withAttributes: [.font: rowFont])
                xPos += columnWidths[2]

                let amountColor: UIColor = transaction.type == .income ? .systemGreen : .systemRed
                let amountString =
                    transaction.type == .income
                    ? "+$\(String(format: "%.2f", transaction.amount))"
                    : "-$\(String(format: "%.2f", transaction.amount))"
                amountString.draw(
                    at: CGPoint(x: xPos, y: yPosition),
                    withAttributes: [.font: rowFont, .foregroundColor: amountColor])

                yPosition += 18
                exportProgress = Double(index + 1) / Double(transactions.count)
            }

            // Footer
            yPosition = pageHeight - margin
            let footerText = "Generated by Zenith Finance App"
            footerText.draw(
                at: CGPoint(x: margin, y: yPosition),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.gray,
                ])
        }

        // Save to temporary file
        let fileName = "zenith_report_\(Date().timeIntervalSince1970).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }
}

// MARK: - Transaction Summary
struct TransactionSummary {
    let totalIncome: Double
    let totalExpenses: Double
    let balance: Double
    let transactionCount: Int

    init(transactions: [ZenithTransaction]) {
        totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        totalExpenses = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        balance = totalIncome - totalExpenses
        transactionCount = transactions.count
    }
}

// MARK: - Export View
struct DataExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var exportManager = DataExportManager.shared

    let transactions: [ZenithTransaction]

    @State private var exportFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF Report"
    }

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Export Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding()

                ScrollView {
                    VStack(spacing: 24) {
                        // Format Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Format")
                                .font(.headline)
                                .foregroundColor(.gray)

                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Button(action: { exportFormat = format }) {
                                    HStack {
                                        Image(
                                            systemName: format == .csv ? "doc.text" : "doc.richtext"
                                        )
                                        .foregroundColor(
                                            exportFormat == format ? .mintGreen : .gray)

                                        VStack(alignment: .leading) {
                                            Text(format.rawValue)
                                                .foregroundColor(.white)
                                            Text(
                                                format == .csv
                                                    ? "Simple spreadsheet format"
                                                    : "Formatted report with summary"
                                            )
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        }

                                        Spacer()

                                        if exportFormat == format {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.mintGreen)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        exportFormat == format
                                                            ? Color.mintGreen : Color.clear,
                                                        lineWidth: 2)
                                            )
                                    )
                                }
                            }
                        }

                        // Summary Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Preview")
                                .font(.headline)
                                .foregroundColor(.gray)

                            let summary = TransactionSummary(transactions: transactions)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Transactions")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(summary.transactionCount)")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }

                                HStack {
                                    Text("Total Income")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", summary.totalIncome))")
                                        .foregroundColor(.green)
                                        .fontWeight(.semibold)
                                }

                                HStack {
                                    Text("Total Expenses")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", summary.totalExpenses))")
                                        .foregroundColor(.red)
                                        .fontWeight(.semibold)
                                }

                                Divider().background(Color.white.opacity(0.2))

                                HStack {
                                    Text("Net Balance")
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("$\(String(format: "%.2f", summary.balance))")
                                        .foregroundColor(summary.balance >= 0 ? .mintGreen : .red)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }

                        // Export Button
                        Button(action: exportData) {
                            HStack {
                                if isExporting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                Text(
                                    isExporting ? "Exporting..." : "Export \(exportFormat.rawValue)"
                                )
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.mintGreen)
                            .cornerRadius(16)
                        }
                        .disabled(isExporting || transactions.isEmpty)
                        .opacity(transactions.isEmpty ? 0.5 : 1)

                        if transactions.isEmpty {
                            Text("No transactions to export")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportData() {
        isExporting = true

        Task {
            var url: URL?

            if exportFormat == .csv {
                url = exportManager.exportToCSV(transactions: transactions)
            } else {
                let summary = TransactionSummary(transactions: transactions)
                url = exportManager.exportToPDF(transactions: transactions, summary: summary)
            }

            await MainActor.run {
                isExporting = false
                if let url = url {
                    exportedFileURL = url
                    showingShareSheet = true
                    HapticManager.shared.success()
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
