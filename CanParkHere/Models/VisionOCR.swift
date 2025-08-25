//
//  VisionOCR.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

enum Confidence: String, Codable {
    case high
    case medium
    case low
}

struct VisionOCR: Codable {
    let signText: String
    let confidence: Confidence
}
