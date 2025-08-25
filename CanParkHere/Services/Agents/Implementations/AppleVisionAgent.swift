//
//  AppleVisionAgent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation
import Vision
import UIKit

class AppleVisionAgent: VisionAgent {
    let provider: VisionAgentType = .apple
    
    func execute(_ context: UIImage) async throws -> String {
        guard let cgImage = context.cgImage else {
            throw VisionAgentError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: VisionAgentError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: VisionAgentError.noTextFound)
                } else {
                    continuation.resume(returning: VisionOCR(
                        signText: finalText,
                        confidence: Confidence.high
                    ))
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
