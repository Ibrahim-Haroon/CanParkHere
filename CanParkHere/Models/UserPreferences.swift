//
//  UserPreferences.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation
import SwiftUI

class UserPreferences: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    
    @Published var userName: String? {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    
    @Published var vehicleType: VehicleType? {
        didSet {
            if let vehicleType = vehicleType {
                UserDefaults.standard.set(vehicleType.rawValue, forKey: "vehicleType")
            }
        }
    }
    
    @Published var locationPreference: LocationPreference {
        didSet {
            UserDefaults.standard.set(locationPreference.rawValue, forKey: "locationPreference")
        }
    }
    
    @Published var city: String? {
        didSet { UserDefaults.standard.set(city, forKey: "city") }
    }
    
    @Published var state: String? {
        didSet { UserDefaults.standard.set(state, forKey: "state") }
    }
    
    @Published var parkingHistory: [ParkingHistoryItem] = []
    
    @Published var selectedVisionAgent: VisionAgentType {
        didSet {
            UserDefaults.standard.set(selectedVisionAgent.rawValue, forKey: "selectedVisionAgent")
        }
    }
    
    @Published var selectedParkingAgent: ParkingAgentType {
        didSet {
            UserDefaults.standard.set(selectedParkingAgent.rawValue, forKey: "selectedParkingAgent")
        }
    }
    
    @Published var openAIAPIKey: String? {
        didSet {
            if let key = openAIAPIKey {
                UserDefaults.standard.set(key, forKey: "openAIAPIKey")
            } else {
                UserDefaults.standard.removeObject(forKey: "openAIAPIKey")
            }
        }
    }
    
    enum LocationPreference: String, Codable {
        case precise = "precise"
        case approximate = "approximate"
        case manual = "manual"
        case none = "none"
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.userName = UserDefaults.standard.string(forKey: "userName")
        
        if let vehicleTypeString = UserDefaults.standard.string(forKey: "vehicleType"),
           let vehicleType = VehicleType(rawValue: vehicleTypeString) {
            self.vehicleType = vehicleType
        }
        
        if let locationPrefString = UserDefaults.standard.string(forKey: "locationPreference"),
           let locationPref = LocationPreference(rawValue: locationPrefString) {
            self.locationPreference = locationPref
        } else {
            self.locationPreference = .none
        }
        
        self.city = UserDefaults.standard.string(forKey: "city")
        self.state = UserDefaults.standard.string(forKey: "state")
        
        // Initialize AI provider preferences
        if let selectedVisionAgentString = UserDefaults.standard.string(forKey: "selectedVisionAgent"),
           let selectedVisionAgent = VisionAgentType(rawValue: selectedVisionAgentString) {
            self.selectedVisionAgent = selectedVisionAgent
        } else {
            self.selectedVisionAgent = .apple
        }
        
        if let selectedParkingAgentString = UserDefaults.standard.string(forKey: "selectedParkingAgent"),
           let selectedParkingAgent = ParkingAgentType(rawValue: selectedParkingAgentString) {
            self.selectedParkingAgent = selectedParkingAgent
        } else {
            self.selectedParkingAgent = .apple
        }
        
        self.openAIAPIKey = UserDefaults.standard.string(forKey: "openAIAPIKey")
        
        loadParkingHistory()
    }
    
    func addToHistory(_ item: ParkingHistoryItem) {
        parkingHistory.insert(item, at: 0)
        if parkingHistory.count > 50 { // Keep last 50 items
            parkingHistory.removeLast()
        }
        saveParkingHistory()
    }
    
    private func loadParkingHistory() {
        if let data = UserDefaults.standard.data(forKey: "parkingHistory"),
           let history = try? JSONDecoder().decode([ParkingHistoryItem].self, from: data) {
            self.parkingHistory = history
        }
    }
    
    private func saveParkingHistory() {
        if let data = try? JSONEncoder().encode(parkingHistory) {
            UserDefaults.standard.set(data, forKey: "parkingHistory")
        }
    }
}

struct ParkingHistoryItem: Codable, Identifiable {
    let id: UUID
    let date: Date
    let canPark: Bool
    let location: String?
    let imageData: Data?
    let decision: ParkingDecision
    
    enum CodingKeys: String, CodingKey {
        case id, date, canPark, location, imageData, decision
    }
    
    init(date: Date, canPark: Bool, location: String?, imageData: Data?, decision: ParkingDecision) {
        self.id = UUID()
        self.date = date
        self.canPark = canPark
        self.location = location
        self.imageData = imageData
        self.decision = decision
    }
}
