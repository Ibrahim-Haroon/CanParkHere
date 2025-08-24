//
//  ParkingAgent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation

protocol ParkingAgent: Agent where Context == (signText: String, parkingContext: ParkingContext), Result == ParkingDecision {
    var provider: ParkingAgentType { get }
}

enum ParkingAgentType: String, CaseIterable {
    case apple = "Apple"
    
    func createAgent() -> any ParkingAgent {
        switch self {
        case .apple:
            return AppleParkingAgent()
        }
    }
}

enum ParkingAgentError: LocalizedError {
    case modelUnavailable
    case invalidResponse
    case contextMissing
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable:
            return "Apple Intelligence is not available on this device"
        case .invalidResponse:
            return "Failed to parse parking decision"
        case .contextMissing:
            return "Missing required context information"
        }
    }
}

