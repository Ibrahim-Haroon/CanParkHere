//
//  OpenAIParkingAgent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//


import Foundation

class OpenAIParkingAgent: ParkingAgent {
    let provider: ParkingAgentType = .openai
    private let _model: String
    private let url: URL
    private let apiKey: String
    private let headers: [String: String]
    
    init(model: String = "gpt-4o-mini", apiKey: String? = nil) throws {
        self._model = model
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        self.url = url
        
        if let providedKey = apiKey {
            self.apiKey = providedKey
        } else if let storedKey = UserDefaults.standard.string(forKey: "openAIAPIKey") {
            self.apiKey = storedKey
        } else {
            throw NSError(domain: "OpenAIParkingAgent", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not found. Please set your API key in Settings."])
        }
        
        self.headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(self.apiKey)"
        ]
    }
    
    func execute(_ context: (signText: String, parkingContext: ParkingContext)) async throws -> ParkingDecision {
        let payload: [String: Any] = [
            "model": _model,
            "messages": [
                [
                    "role": "system",
                    "content": ParkingAgentInstructions.role()
                ],
                [
                    "role": "user",
                    "content": ParkingAgentInstructions.prompt(
                        signText: context.signText,
                        parkingContext: context.parkingContext
                    )
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAIAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenAI API error: \(errorMessage)"])
        }
        
        guard let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = responseData["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "ParseError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No content found in the response"])
        }
        
        return try parseParkingDecision(from: content)
    }
    
    private func parseParkingDecision(from jsonString: String) throws -> ParkingDecision {
        let cleanedJsonString = cleanJsonContent(jsonString)
        
        guard let jsonData = cleanedJsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenAIParkingAgent", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to convert response string to data"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "OpenAIParkingAgent", code: 4, userInfo: [NSLocalizedDescriptionKey: "Response is not in valid JSON format \n \(cleanedJsonString)"])
        }
        
        // Required field
        guard let canPark = json["can_park"] as? Bool else {
            throw NSError(domain: "OpenAIParkingAgent", code: 5, userInfo: [NSLocalizedDescriptionKey: "Missing required field: can_park"])
        }
        
        let duration = json["duration"] as? Int
        let restrictions = json["restrictions"] as? [String] ?? []
        let reason = json["reason"] as? String
        
        var validUntil: Date? = nil
        if let validUntilString = json["valid_until"] as? String {
            let dateFormatter = ISO8601DateFormatter()
            validUntil = dateFormatter.date(from: validUntilString)
        }
        
        return ParkingDecision(
            canPark: canPark,
            duration: duration,
            restrictions: restrictions,
            reason: reason,
            validUntil: validUntil
        )
    }
    
    private func cleanJsonContent(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if let firstBrace = cleaned.firstIndex(of: "{"),
           let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[firstBrace...lastBrace])
        }
        
        return cleaned
    }
}
