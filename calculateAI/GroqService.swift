import Foundation

class GroqService {
    static let shared = GroqService()

    private let apiKey = "YOUR_GROQ_API_KEY"  // ⚠️ Insert your key here for local testing
    private let apiUrl = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    func fetchFinancialInsight(
        transactions: [ZenithTransaction], completion: @escaping (String) -> Void
    ) {
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Calculate simplified stats for the AI
        let balance = transactions.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
        let recent = transactions.prefix(5).map {
            "\($0.merchant) ($\(String(format: "%.2f", $0.amount)))"
        }.joined(separator: ", ")

        // Prompt for the AI
        let systemPrompt = """
            You are an advanced financial AI assistant named Zenith.
            Analyze the following user data:
            - Current Balance: $\(String(format: "%.2f", balance))
            - Recent Transactions: \(recent)

            Provide a single, short, insightful sentence about their finances.
            Focus on saving opportunities, spending trends, or positive reinforcement.
            Keep it strictly under 15 words.
            Start with "AI Insight:".
            """

        let body: [String: Any] = [
            "model": "llama3-8b-8192",
            "messages": [
                ["role": "system", "content": "You are a helpful financial assistant."],
                ["role": "user", "content": systemPrompt],
            ],
            "max_tokens": 60,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Groq API Error: \(error?.localizedDescription ?? "Unknown error")")
                completion("AI Insight: Unable to connect to Zenith Brain.")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let choices = json["choices"] as? [[String: Any]],
                    let firstChoice = choices.first,
                    let message = firstChoice["message"] as? [String: Any],
                    let content = message["content"] as? String
                {

                    DispatchQueue.main.async {
                        completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                } else {
                    completion("AI Insight: Data analysis failed.")
                }
            } catch {
                print("JSON Parsing Error: \(error)")
                completion("AI Insight: Error processing data.")
            }
        }.resume()
    }

}
