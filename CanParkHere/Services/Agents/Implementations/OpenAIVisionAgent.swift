//
//  OpenAIVisionAgent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation
import UIKit
import os.log

class OpenAIVisionAgent: VisionAgent {
    let provider: VisionAgentType = .openai
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
            throw NSError(domain: "OpenAIVisionAgent", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not found. Please set your API key in Settings."])
        }
        
        self.headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(self.apiKey)"
        ]
    }
    
    func encodeImage(image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Error converting image to JPEG data")
            return nil
        }
        return imageData.base64EncodedString()
    }
    
    func execute(_ context: UIImage) async throws -> VisionOCR {
        guard context.cgImage != nil else {
            throw VisionAgentError.invalidImage
        }
        
        guard let base64Image = encodeImage(image: context) else {
            throw NSError(domain: "ImageEncoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
        }
        
        let payload: [String: Any] = [
            "model": _model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": VisionAgentInstructions.prompt()],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
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
        
        return try parseContent(from: content)
    }
    
    private func parseContent(from jsonString: String) throws -> VisionOCR {
        let cleanedJsonString = cleanJsonContent(jsonString)
        
        guard let jsonData = cleanedJsonString.data(using: .utf8) else {
            throw NSError(domain: "OpenAIVisionAgent", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to convert sign extraction response to data"])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "OpenAIVisionAgent", code: 7, userInfo: [NSLocalizedDescriptionKey: "Sign extraction response is not in valid JSON format \n \(cleanedJsonString)"])
        }
        
        guard let signText = json["sign_text"] as? String else {
            throw NSError(domain: "OpenAIVisionAgent", code: 8, userInfo: [NSLocalizedDescriptionKey: "Missing required field: sign_text"])
        }
        
        guard let confidence_str = json["confidence"] as? String else {
            throw NSError(domain: "OpenAIVisionAgent", code: 9, userInfo: [NSLocalizedDescriptionKey: "Missing required field: confidence"])
        }
        
        var confidence = Confidence.low
        
        switch confidence_str.lowercased() {
        case "high":
            confidence = .high
        case "medium":
            confidence = .medium
        case "low":
            confidence = .low
        default:
            confidence = .low
        }
        
        return VisionOCR(
            signText: signText,
            confidence: confidence
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
