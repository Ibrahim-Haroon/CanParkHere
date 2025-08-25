//
//  CameraViewModel.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI
import AVFoundation
import Photos
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    
    init(userPreferences: UserPreferences) {
        self.userPreferences = userPreferences
        
        // Initialize with user's preferred providers
        do {
            self.visionAgent = try userPreferences.selectedVisionAgent.createAgent()
        } catch {
            // Fallback to Apple if OpenAI fails (e.g., no API key)
            print("Failed to create preferred vision agent: \(error.localizedDescription), falling back to Apple")
            self.visionAgent = AppleVisionAgent()
        }
        
        do {
            self.parkingAgent = try userPreferences.selectedParkingAgent.createAgent()
        } catch {
            // Fallback to Apple if OpenAI fails (e.g., no API key)
            print("Failed to create preferred parking agent: \(error.localizedDescription), falling back to Apple")
            self.parkingAgent = AppleParkingAgent()
        }
        
        // Listen for provider changes in settings
        setupProviderChangeListeners()
    }
    
    private func setupProviderChangeListeners() {
        // Update vision agent when user changes provider in settings
        userPreferences.$selectedVisionAgent
            .sink { [weak self] newProvider in
                self?.updateVisionAgent(to: newProvider)
            }
            .store(in: &cancellables)
        
        // Update parking agent when user changes provider in settings
        userPreferences.$selectedParkingAgent
            .sink { [weak self] newProvider in
                self?.updateParkingAgent(to: newProvider)
            }
            .store(in: &cancellables)
        
        // Update agents when API key changes
        userPreferences.$openAIAPIKey
            .sink { [weak self] _ in
                self?.refreshAgentsIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    private func updateVisionAgent(to provider: VisionAgentType) {
        do {
            self.visionAgent = try provider.createAgent()
        } catch {
            print("Failed to update vision agent to \(provider): \(error.localizedDescription)")
            // Keep current agent on failure
        }
    }
    
    private func updateParkingAgent(to provider: ParkingAgentType) {
        do {
            self.parkingAgent = try provider.createAgent()
        } catch {
            print("Failed to update parking agent to \(provider): \(error.localizedDescription)")
            // Keep current agent on failure
        }
    }
    
    private func refreshAgentsIfNeeded() {
        // Refresh agents if they're using OpenAI (API key might have changed)
        if visionAgent.provider == .openai {
            updateVisionAgent(to: userPreferences.selectedVisionAgent)
        }
        if parkingAgent.provider == .openai {
            updateParkingAgent(to: userPreferences.selectedParkingAgent)
        }
    }
    
    func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        capturedImage = image
        
        do {
            // Check if OpenAI is selected but no API key is provided
            if (userPreferences.selectedVisionAgent == .openai || userPreferences.selectedParkingAgent == .openai) &&
                (userPreferences.openAIAPIKey?.isEmpty != false) {
                throw NSError(domain: "CameraViewModel", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "OpenAI API key is required. Please add your API key in Settings → AI Providers."])
            }
            
            let extractedContent = try await visionAgent.execute(image)
            let context = await buildParkingContext()
            let decision = try await parkingAgent.execute((
                signText: extractedContent.signText,
                parkingContext: context
            ))
            
            parkingDecision = decision
            
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
            isHoliday: HolidayChecker.isHoliday()
        )
    }
    
    func updateProviders(vision: VisionAgentType, agent: ParkingAgentType) {
        do {
            self.visionAgent = try vision.createAgent()
        } catch {
            print("Failed to create vision agent: \(error.localizedDescription)")
            self.errorMessage = "Failed to initialize \(vision.rawValue) vision agent. Please check your API key in Settings."
        }
        
        do {
            self.parkingAgent = try agent.createAgent()
        } catch {
            print("Failed to create parking agent: \(error.localizedDescription)")
            self.errorMessage = "Failed to initialize \(agent.rawValue) parking agent. Please check your API key in Settings."
        }
    }
    
    func refreshAgents() {
        updateProviders(vision: userPreferences.selectedVisionAgent, agent: userPreferences.selectedParkingAgent)
    }
}
