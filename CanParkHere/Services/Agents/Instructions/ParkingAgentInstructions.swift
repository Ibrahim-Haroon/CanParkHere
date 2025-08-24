//
//  ParkingAgentInstructions.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation

enum ParkingAgentInstructions {
    static func role() -> String {}
    static func prompt(signText: String, parkingContext: ParkingContext) -> String {
        return """
        You are a parking assistant. Given the following parking sign text and parking context, determine if parking is allowed.
        Sign Text: \(signText)
        Parking Context: \(parkingContext.description)
        Provide a clear decision: "Allowed", "Not Allowed", or "Uncertain". Just
         ify your decision with a brief explanation.
          
        Respond in the following JSON format:
        {
            "decision": "<Allowed|Not Allowed|Uncertain>",
        """
    }
}
