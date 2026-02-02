//
//  ZenithScannerView.swift
//  calculateAI
//
//  Receipt Scanner with Camera, Photo Library and Vision OCR
//

import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import Vision

struct ZenithScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.modelContext) private var modelContext

    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var scannedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: ScannedReceipt?
    @State private var showingResult = false
    @State private var showingCamera = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            ZenithBackground()

            // Mock Camera Feed
            Image(systemName: "camera.metering.center.weighted")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.1)
                .background(Color.zenithCharcoal)

            // Scanner Overlay
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            )
                    }
                    Spacer()

                    // Gallery button
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                            )
                    }
                }
                .padding()

                Spacer()

                // Scan Frame or Result
                if let result = analysisResult, showingResult {
                    // Show parsed result
                    ScanResultView(
                        result: result,
                        scannedImage: scannedImage,
                        onScanAgain: resetScanner,
                        onSave: {
                            saveTransaction(result)
                            HapticManager.shared.success()
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))

                } else if isAnalyzing {
                    // Analyzing state
                    AnalyzingView()

                } else if let error = errorMessage {
                    // Error state
                    ErrorStateView(title: "Scan Error", message: error, retryAction: resetScanner)

                } else {
                    // Scan frame
                    ScanFrameView()
                }

                Text(instructionText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top)

                Spacer()

                // Capture Button
                if !showingResult && !isAnalyzing && errorMessage == nil {
                    Button(action: {
                        showingCamera = true
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(Color.mintGreen, lineWidth: 4)
                                    .padding(4)
                            )
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem = newItem {
                loadImage(from: newItem)
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                scannedImage = image
                analyzeReceiptWithVision(image: image)
            }
        }
    }

    private var instructionText: String {
        if showingResult {
            return "Receipt scanned successfully!"
        } else if isAnalyzing {
            return "Analyzing with AI..."
        } else if errorMessage != nil {
            return "Could not read receipt"
        } else {
            return "Tap to capture or select from gallery"
        }
    }

    private func loadImage(from item: PhotosPickerItem) {
        isAnalyzing = true
        errorMessage = nil

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            {
                await MainActor.run {
                    scannedImage = image
                    analyzeReceiptWithVision(image: image)
                }
            } else {
                await MainActor.run {
                    isAnalyzing = false
                    errorMessage = "Failed to load image"
                }
            }
        }
    }

    // MARK: - Vision OCR Analysis
    private func analyzeReceiptWithVision(image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        HapticManager.shared.medium()

        guard let cgImage = image.cgImage else {
            errorMessage = "Invalid image format"
            isAnalyzing = false
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "OCR Error: \(error.localizedDescription)"
                    self.isAnalyzing = false
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.errorMessage = "No text found in image"
                    self.isAnalyzing = false
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                self.parseReceiptText(recognizedText)
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US", "ru-RU"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to process image"
                    self.isAnalyzing = false
                }
            }
        }
    }

    // MARK: - Parse Receipt Text
    private func parseReceiptText(_ lines: [String]) {
        var merchant = "Unknown Store"
        var amount: Double = 0.0
        var category: TransactionCategory = .other

        // Known merchant patterns - Expanded list
        let merchantPatterns: [(pattern: String, name: String, cat: TransactionCategory)] = [
            // Food & Drink - Coffee & Fast Food
            ("starbucks", "Starbucks", .foodAndDrink),
            ("mcdonald", "McDonald's", .foodAndDrink),
            ("subway", "Subway", .foodAndDrink),
            ("dunkin", "Dunkin'", .foodAndDrink),
            ("chipotle", "Chipotle", .foodAndDrink),
            ("taco bell", "Taco Bell", .foodAndDrink),
            ("burger king", "Burger King", .foodAndDrink),
            ("wendy", "Wendy's", .foodAndDrink),
            ("chick-fil-a", "Chick-fil-A", .foodAndDrink),
            ("panera", "Panera Bread", .foodAndDrink),
            ("kfc", "KFC", .foodAndDrink),
            ("pizza hut", "Pizza Hut", .foodAndDrink),
            ("domino", "Domino's", .foodAndDrink),
            ("papa john", "Papa John's", .foodAndDrink),
            ("five guys", "Five Guys", .foodAndDrink),
            ("panda express", "Panda Express", .foodAndDrink),
            ("popeyes", "Popeyes", .foodAndDrink),
            ("sonic", "Sonic", .foodAndDrink),
            ("dairy queen", "Dairy Queen", .foodAndDrink),
            ("tim horton", "Tim Hortons", .foodAndDrink),

            // Grocery Stores
            ("walmart", "Walmart", .shopping),
            ("target", "Target", .shopping),
            ("costco", "Costco", .shopping),
            ("whole foods", "Whole Foods", .foodAndDrink),
            ("trader joe", "Trader Joe's", .foodAndDrink),
            ("kroger", "Kroger", .foodAndDrink),
            ("safeway", "Safeway", .foodAndDrink),
            ("publix", "Publix", .foodAndDrink),
            ("aldi", "ALDI", .foodAndDrink),
            ("wegmans", "Wegmans", .foodAndDrink),
            ("heb", "H-E-B", .foodAndDrink),
            ("food lion", "Food Lion", .foodAndDrink),
            ("albertsons", "Albertsons", .foodAndDrink),
            ("sprouts", "Sprouts", .foodAndDrink),

            // Online & Tech
            ("amazon", "Amazon", .shopping),
            ("apple", "Apple", .shopping),
            ("best buy", "Best Buy", .shopping),
            ("microsoft", "Microsoft", .shopping),
            ("ebay", "eBay", .shopping),

            // Gas & Transport
            ("uber", "Uber", .transport),
            ("lyft", "Lyft", .transport),
            ("shell", "Shell Gas", .transport),
            ("chevron", "Chevron Gas", .transport),
            ("exxon", "Exxon", .transport),
            ("mobil", "Mobil", .transport),
            ("bp", "BP Gas", .transport),
            ("speedway", "Speedway", .transport),
            ("circle k", "Circle K", .transport),
            ("7-eleven", "7-Eleven", .transport),
            ("wawa", "Wawa", .transport),

            // Health & Pharmacy
            ("cvs", "CVS Pharmacy", .health),
            ("walgreens", "Walgreens", .health),
            ("rite aid", "Rite Aid", .health),
            ("pharmacy", "Pharmacy", .health),
            ("doctor", "Doctor Visit", .health),
            ("hospital", "Hospital", .health),
            ("clinic", "Clinic", .health),

            // Entertainment & Subscriptions
            ("netflix", "Netflix", .entertainment),
            ("spotify", "Spotify", .entertainment),
            ("disney", "Disney+", .entertainment),
            ("hulu", "Hulu", .entertainment),
            ("hbo", "HBO Max", .entertainment),
            ("youtube", "YouTube", .entertainment),
            ("twitch", "Twitch", .entertainment),
            ("amc", "AMC Theaters", .entertainment),
            ("regal", "Regal Cinemas", .entertainment),
            ("steam", "Steam", .entertainment),
            ("playstation", "PlayStation", .entertainment),
            ("xbox", "Xbox", .entertainment),
            ("nintendo", "Nintendo", .entertainment),

            // Retail & Home
            ("home depot", "Home Depot", .shopping),
            ("ikea", "IKEA", .shopping),
            ("lowe", "Lowe's", .shopping),
            ("bed bath", "Bed Bath & Beyond", .shopping),
            ("macy", "Macy's", .shopping),
            ("nordstrom", "Nordstrom", .shopping),
            ("tjmaxx", "TJ Maxx", .shopping),
            ("marshalls", "Marshalls", .shopping),
            ("ross", "Ross", .shopping),
            ("sephora", "Sephora", .shopping),
            ("ulta", "Ulta Beauty", .shopping),
            ("nike", "Nike", .shopping),
            ("adidas", "Adidas", .shopping),
            ("gap", "Gap", .shopping),
            ("old navy", "Old Navy", .shopping),
            ("h&m", "H&M", .shopping),
            ("zara", "Zara", .shopping),
            ("uniqlo", "Uniqlo", .shopping),
            ("dollar tree", "Dollar Tree", .shopping),
            ("dollar general", "Dollar General", .shopping),
            ("family dollar", "Family Dollar", .shopping),

            // Utilities & Bills
            ("electric", "Electric Bill", .bills),
            ("water bill", "Water Bill", .bills),
            ("internet", "Internet Bill", .bills),
            ("phone bill", "Phone Bill", .bills),
            ("insurance", "Insurance", .bills),
            ("rent", "Rent", .bills),
            ("mortgage", "Mortgage", .bills),
        ]

        let joinedText = lines.joined(separator: " ").lowercased()

        // Find merchant from known patterns
        for mp in merchantPatterns {
            if joinedText.contains(mp.pattern) {
                merchant = mp.name
                category = mp.cat
                break
            }
        }

        // If no known merchant, use first significant line as merchant
        if merchant == "Unknown Store" {
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.count > 3 && !trimmed.contains("$") && !containsDate(trimmed) {
                    merchant = trimmed.capitalized
                    break
                }
            }
        }

        // Find amounts - look for patterns like $12.34, 12.34, TOTAL: 12.34
        let amountPattern =
            #"(?:total|amount|due|charge|subtotal)?[:\s]*\$?\s*(\d{1,6}[.,]\d{2})"#
        let regex = try? NSRegularExpression(pattern: amountPattern, options: .caseInsensitive)

        var amounts: [Double] = []
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            if let matches = regex?.matches(in: line, options: [], range: range) {
                for match in matches {
                    if let captureRange = Range(match.range(at: 1), in: line) {
                        let amountStr = String(line[captureRange])
                            .replacingOccurrences(of: ",", with: ".")
                        if let parsed = Double(amountStr) {
                            amounts.append(parsed)
                        }
                    }
                }
            }
        }

        // Take the largest amount as likely total
        if let maxAmount = amounts.max() {
            amount = maxAmount
        }

        // Detect category from keywords if not already set
        if category == .other {
            category = detectCategory(from: joinedText)
        }

        // Validate we have meaningful data
        if amount > 0 {
            withAnimation {
                analysisResult = ScannedReceipt(
                    merchant: merchant,
                    amount: amount,
                    category: category,
                    rawText: lines.joined(separator: "\n")
                )
                isAnalyzing = false
                showingResult = true
            }
            HapticManager.shared.success()
        } else {
            errorMessage = "Could not find amount on receipt"
            isAnalyzing = false
        }
    }

    private func containsDate(_ text: String) -> Bool {
        let datePatterns = [
            #"\d{1,2}/\d{1,2}/\d{2,4}"#,
            #"\d{1,2}-\d{1,2}-\d{2,4}"#,
            #"\d{4}-\d{2}-\d{2}"#,
        ]
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
                regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
            {
                return true
            }
        }
        return false
    }

    private func detectCategory(from text: String) -> TransactionCategory {
        let categoryKeywords: [(keywords: [String], category: TransactionCategory)] = [
            (["restaurant", "cafe", "coffee", "food", "pizza", "burger", "sushi"], .foodAndDrink),
            (["grocery", "supermarket", "market"], .foodAndDrink),
            (["gas", "fuel", "parking", "taxi", "uber", "lyft", "transit"], .transport),
            (["pharmacy", "hospital", "clinic", "medical", "health"], .health),
            (["movie", "cinema", "theater", "concert", "game"], .entertainment),
            (["electric", "water", "internet", "phone", "utility"], .bills),
            (["store", "shop", "mall", "retail", "clothing"], .shopping),
        ]

        for (keywords, category) in categoryKeywords {
            for keyword in keywords {
                if text.contains(keyword) {
                    return category
                }
            }
        }
        return .other
    }

    private func saveTransaction(_ receipt: ScannedReceipt) {
        let transaction = ZenithTransaction(
            merchant: receipt.merchant,
            date: Date(),
            amount: receipt.amount,
            type: .expense,
            category: receipt.category
        )
        modelContext.insert(transaction)
        SpotlightManager.shared.index(transaction: transaction)
    }

    private func resetScanner() {
        withAnimation {
            scannedImage = nil
            analysisResult = nil
            showingResult = false
            selectedPhotoItem = nil
            errorMessage = nil
        }
    }
}

// MARK: - Scanned Receipt Model
struct ScannedReceipt {
    let merchant: String
    let amount: Double
    let category: TransactionCategory
    var rawText: String = ""
}

// MARK: - Scan Result View
struct ScanResultView: View {
    let result: ScannedReceipt
    let scannedImage: UIImage?
    let onScanAgain: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let image = scannedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .cornerRadius(12)
            }

            VStack(spacing: 8) {
                Text(result.merchant)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("$\(String(format: "%.2f", result.amount))")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.mintGreen)

                HStack {
                    Image(systemName: result.category.icon)
                    Text(result.category.rawValue)
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.1)))
            }

            HStack(spacing: 16) {
                Button(action: onScanAgain) {
                    Text("Scan Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }

                Button(action: onSave) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.mintGreen)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10)
        )
        .padding(40)
    }
}

// MARK: - Analyzing View
struct AnalyzingView: View {
    @State private var dots = ""

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.mintGreen.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.mintGreen, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: dots)

                Image(systemName: "doc.text.viewfinder")
                    .font(.title2)
                    .foregroundColor(.mintGreen)
            }

            Text("Analyzing receipt\(dots)")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(height: 300)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }
}

// MARK: - Scan Frame View
struct ScanFrameView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                .frame(height: 300)

            // Corners
            VStack {
                HStack {
                    CornerView()
                    Spacer()
                    CornerView().rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    CornerView().rotationEffect(.degrees(-90))
                    Spacer()
                    CornerView().rotationEffect(.degrees(180))
                }
            }
            .frame(height: 300)

            // Scanning Beam
            ScanningBeam()
        }
        .padding(40)
    }
}

// MARK: - Corner View
struct CornerView: View {
    var body: some View {
        VStack {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.mintGreen)
                    .frame(width: 40, height: 4)
                Spacer()
            }
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.mintGreen)
                    .frame(width: 4, height: 40)
                Spacer()
            }
            Spacer()
        }
        .frame(width: 40, height: 40)
    }
}

// MARK: - Scanning Beam Animation
struct ScanningBeam: View {
    @State private var offset: CGFloat = -150

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .mintGreen.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 4)
            .offset(y: offset)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: true)) {
                    offset = 150
                }
            }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ZenithScannerView()
}
