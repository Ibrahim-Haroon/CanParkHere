//
//  VisionAgent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation
import UIKit

protocol VisionAgent: Agent where Context == UIImage, Result == VisionOCR {
    var provider: VisionAgentType { get }
}

enum VisionAgentType: String, CaseIterable {
    case apple = "Apple"
    case openai = "OpenAI"
    
    func createAgent() throws -> any VisionAgent {
        switch self {
        case .apple:
            return AppleVisionAgent()
        case .openai:
            return try OpenAIVisionAgent()
        }
    }
}

enum VisionAgentError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .noTextFound:
            return "No text found in image"
        case .processingFailed:
            return "Failed to process image"
        }
    }
}
