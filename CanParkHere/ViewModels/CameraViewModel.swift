//
//  CameraViewModel.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI
import AVFoundation
import Photos

@MainActor
class CameraViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isProcessing = false
    @Published var parkingDecision: ParkingDecision?
    @Published var showResult = false
    @Published var errorMessage: String?
    
    private var visionAgent: any VisionAgent
    private var parkingAgent: any ParkingAgent
    private let userPreferences: UserPreferences
    
    init(userPreferences: UserPreferences) {
        self.userPreferences = userPreferences
        // Default providers - can be changed in settings
        self.visionAgent = AppleVisionAgent()
        self.parkingAgent = AppleParkingAgent()
    }
    
    func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        capturedImage = image
        
        do {
            // Extract text from image
            let extractedText = try await visionAgent.execute(image)
            
            // Build context
            let context = await buildParkingContext()
            
            // Get parking decision
            let decision = try await parkingAgent.execute((
                signText: extractedText,
                parkingContext: context
            ))
            
            parkingDecision = decision
            
            // Add to history
            let historyItem = ParkingHistoryItem(
                date: Date(),
                canPark: decision.canPark,
                location: userPreferences.city,
                imageData: image.jpegData(compressionQuality: 0.5),
                decision: decision
            )
            userPreferences.addToHistory(historyItem)
            
            showResult = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
    
    private func buildParkingContext() async -> ParkingContext {
        let location = ParkingContext.Location(
            city: userPreferences.city,
            state: userPreferences.state,
            coordinates: nil // Would get from LocationManager if permission granted
        )
        
        return ParkingContext(
            currentTime: Date(),
            location: location,
            vehicleType: userPreferences.vehicleType ?? .sedan,
            isHoliday: false // Would check holiday calendar
        )
    }
    
    func updateProviders(vision: VisionAgentType, agent: ParkingAgentType) {
        self.visionAgent = vision.createAgent()
        self.parkingAgent = agent.createAgent()
    }
}
