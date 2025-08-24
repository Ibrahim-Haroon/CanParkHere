//
//  VisionAgent.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation
import UIKit

protocol VisionAgent: Agent where Context == UIImage, Result == String {
    var provider: VisionAgentType { get }
}

enum VisionAgentType: String, CaseIterable {
    case apple = "Apple"
    
    func createAgent() -> any VisionAgent {
        switch self {
        case .apple:
            return AppleVisionAgent()
        }
    }
}
