//
//  AppleParkingAgent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation
import FoundationModels

@Generable
struct AppleParkingAgentDecision {
    @Guide(description: "Can the user park here?")
    var canPark: Bool
    @Guide(description: "Maximum parking duration allowed (in minutes). If no limit, return null.")
    var duration: Int?
    @Guide(description: "Any parking restrictions (e.g., no parking during street cleaning hours)")
    var restrictions: [String]
    @Guide(description: "Reason for the parking decision")
    var reason: String
    @Guide(description: "Time until which this parking decision is valid (ISO 8601)")
    var validUntil: String?
}

class AppleParkingAgent: ParkingAgent {
    let provider: ParkingAgentType = .apple
    private let model = SystemLanguageModel.default
    
    var isAvailable: Bool {
        switch model.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
    
    func execute(_ context: (signText: String, parkingContext: ParkingContext)) async throws -> ParkingDecision {
        guard isAvailable else {
            throw ParkingAgentError.modelUnavailable
        }
        
        let session = LanguageModelSession(
            model: model,
            instructions: ParkingAgentInstructions.role()
        )
        
        let prompt = ParkingAgentInstructions.prompt(
            context.signText,
            context.parkingContext
        )
        
        let response = try await session.respond(
            to: prompt,
            generating: AppleParkingAgentDecision.self
        )
        
        var validUntilDate: Date? = nil
        if let validUntilString = response.content.validUntil {
            let formatter = ISO8601DateFormatter()
            validUntilDate = formatter.date(from: validUntilString)
        }
        
        return ParkingDecision(
            canPark: response.content.canPark,
            duration: response.content.duration,
            restrictions: response.content.restrictions,
            reason: response.content.reason,
            validUntil: validUntilDate,
            cost: response.content.cost
        )
    }
}

