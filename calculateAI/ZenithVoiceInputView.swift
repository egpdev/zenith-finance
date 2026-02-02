//
//  ZenithVoiceInputView.swift
//  calculateAI
//
//  Voice Input with Speech Recognition
//

import AVFoundation
import Speech
import SwiftData
import SwiftUI
import UIKit  // Required for UIBezierPath

struct ZenithVoiceInputView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext

    @State private var isAnimating = false
    @State private var isListening = false
    @State private var transcribedText = ""
    @State private var errorMessage: String?
    @State private var showResult = false
    @State private var parsedTransaction: ParsedTransaction?

    // Speech Recognition
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed Background
            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        stopListening()
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
            }

            if isPresented {
                VStack(spacing: 20) {
                    // Drag Handle
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 10)

                    // Status Text
                    Text(statusText)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))

                    // Transcribed text or error
                    if !transcribedText.isEmpty || errorMessage != nil {
                        Text(errorMessage ?? transcribedText)
                            .font(.body)
                            .foregroundColor(errorMessage != nil ? .red : .mintGreen)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    // Waveform Animation
                    HStack(spacing: 6) {
                        ForEach(0..<5) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [.mintGreen, .neonTurquoise],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(
                                    width: 6, height: isAnimating ? CGFloat.random(in: 30...60) : 10
                                )
                                .animation(
                                    Animation.easeInOut(duration: 0.4)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.1),
                                    value: isAnimating
                                )
                        }
                    }
                    .frame(height: 80)
                    .opacity(isListening ? 1 : 0.3)

                    // Action Buttons
                    HStack(spacing: 20) {
                        // Close Button
                        Button(action: {
                            stopListening()
                            withAnimation {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        // Save Transaction Button (only if parsed)
                        if let parsed = parsedTransaction {
                            Button(action: {
                                saveTransaction(parsed)
                                HapticManager.shared.success()
                                withAnimation {
                                    isPresented = false
                                }
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save $\(Int(parsed.amount))")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.mintGreen)
                                .cornerRadius(20)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .background(
                    ZStack {
                        ZenithBackground()
                        Color.black.opacity(0.2)  // Slight dim
                    }
                    .mask(
                        RoundedCorner(radius: 24, corners: [.topLeft, .topRight])
                    )
                )
                .transition(.move(edge: .bottom))
                .onAppear {
                    isAnimating = true
                    // Small delay to allow transition to complete before accessing hardware
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        requestSpeechAuthorization()
                    }
                }
                .onDisappear {
                    stopListening()
                }
            }
        }
        .animation(.spring(), value: isPresented)
    }

    private var statusText: String {
        if errorMessage != nil {
            return "Error"
        } else if parsedTransaction != nil {
            return "Got it! ✓"
        } else if isListening {
            return "Listening..."
        } else {
            return "Tap to speak"
        }
    }

    // MARK: - Speech Recognition

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    startListening()
                case .denied, .restricted:
                    errorMessage = "Speech recognition not authorized. Please enable in Settings."
                case .notDetermined:
                    errorMessage = "Speech recognition permission not determined."
                @unknown default:
                    errorMessage = "Unknown authorization status."
                }
            }
        }
    }

    private func startListening() {
        // Ensure we don't double-start
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition not available."
            return
        }

        do {
            // Configure audio session - playAndRecord is often safer to prevent routing crashes
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }

            recognitionRequest.shouldReportPartialResults = true

            // Force engine reset
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }

            let inputNode = audioEngine.inputNode

            // CRITICAL FIX: Remove generic tap if correctly installed to prevent crash
            inputNode.removeTap(onBus: 0)

            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) {
                result, error in
                // Ensure UI updates happen on main thread to prevent crashes
                DispatchQueue.main.async {
                    if let result = result {
                        self.transcribedText = result.bestTranscription.formattedString

                        // Try to parse after each result
                        if result.isFinal {
                            self.parseTranscription(self.transcribedText)
                            self.stopListening()
                        }
                    }

                    if let error = error {
                        print("Speech recognition error: \(error)")
                        // Don't show user errors for common cancellation
                        if (error as NSError).code != 1 && (error as NSError).code != 216 {
                            self.errorMessage = "Could not recognize speech."
                        }
                        self.stopListening()
                    }
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)

            // SAFETY CHECK: Ensure valid sample rate to prevent Simulator crash
            if recordingFormat.sampleRate == 0 {
                // Try standard format or fallback
                print("Invalid sample rate (0), skipping tap installation to prevent crash")
                errorMessage = "Audio input unavailable (Simulator)"
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isListening = true

            // Auto-stop after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if isListening {
                    parseTranscription(transcribedText)
                    stopListening()
                }
            }

        } catch {
            errorMessage = "Could not start audio recording."
            print("Audio engine error: \(error)")
        }
    }

    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }

    // MARK: - Parse Transcription

    private func parseTranscription(_ text: String) {
        let lowercased = text.lowercased()

        // Simple parsing: look for amount and merchant
        // Example: "I spent 15 dollars at Starbucks"
        // Example: "25 bucks on lunch"

        var amount: Double?
        var merchant = "Unknown"
        var category: TransactionCategory = .other

        // Find amount
        let patterns = [
            #"(\d+(?:\.\d{1,2})?)\s*(?:dollars?|bucks?|\$)"#,
            #"\$\s*(\d+(?:\.\d{1,2})?)"#,
            #"spent\s*(\d+(?:\.\d{1,2})?)"#,
            #"(\d+(?:\.\d{1,2})?)\s*(?:on|at|for)"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                let match = regex.firstMatch(
                    in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)),
                let range = Range(match.range(at: 1), in: lowercased)
            {
                amount = Double(lowercased[range])
                break
            }
        }

        // Find merchant (after "at" or "on")
        if let atRange = lowercased.range(of: " at ") {
            let afterAt = String(lowercased[atRange.upperBound...])
            merchant =
                afterAt.components(separatedBy: " ").prefix(3).joined(separator: " ").capitalized
        } else if let onRange = lowercased.range(of: " on ") {
            let afterOn = String(lowercased[onRange.upperBound...])
            merchant =
                afterOn.components(separatedBy: " ").prefix(3).joined(separator: " ").capitalized
        }

        // Detect category from keywords
        if lowercased.contains("food") || lowercased.contains("lunch")
            || lowercased.contains("dinner") || lowercased.contains("breakfast")
            || lowercased.contains("coffee") || lowercased.contains("restaurant")
        {
            category = .foodAndDrink
        } else if lowercased.contains("uber") || lowercased.contains("lyft")
            || lowercased.contains("taxi") || lowercased.contains("gas")
            || lowercased.contains("transport")
        {
            category = .transport
        } else if lowercased.contains("shopping") || lowercased.contains("store")
            || lowercased.contains("amazon")
        {
            category = .shopping
        } else if lowercased.contains("movie") || lowercased.contains("netflix")
            || lowercased.contains("entertainment")
        {
            category = .entertainment
        }

        if let amount = amount, amount > 0 {
            withAnimation {
                parsedTransaction = ParsedTransaction(
                    merchant: merchant.isEmpty ? "Unknown" : merchant,
                    amount: amount,
                    category: category
                )
            }
        } else if !text.isEmpty {
            errorMessage = "Could not understand amount. Try: \"I spent 15 dollars at Starbucks\""
        }
    }

    private func saveTransaction(_ parsed: ParsedTransaction) {
        let transaction = ZenithTransaction(
            merchant: parsed.merchant,
            date: Date(),
            amount: -parsed.amount,  // Expense is negative
            type: .expense,
            category: parsed.category
        )
        modelContext.insert(transaction)
        SpotlightManager.shared.index(transaction: transaction)
    }
}

// Helper struct
struct ParsedTransaction {
    let merchant: String
    let amount: Double
    let category: TransactionCategory
}

// Extension to allow corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZenithVoiceInputView(isPresented: .constant(true))
}
