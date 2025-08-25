//
//  SettingsView.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @Environment(\.dismiss) var dismiss
    @State private var showingAPIKeyAlert = false
    @State private var tempAPIKey = ""
    
    var body: some View {
        NavigationView {
            Form {
                // User Profile
                Section("Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(userPreferences.userName ?? "Not set")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Vehicle")
                        Spacer()
                        Text(userPreferences.vehicleType?.rawValue ?? "Not set")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(locationText)
                            .foregroundColor(.secondary)
                    }
                }
                
                // AI Providers
                Section("AI Providers") {
                    Picker("Vision Agent", selection: $userPreferences.selectedVisionAgent) {
                        ForEach(VisionAgentType.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    
                    Picker("Parking Agent", selection: $userPreferences.selectedParkingAgent) {
                        ForEach(ParkingAgentType.allCases, id: \.self) { agent in
                            Text(agent.rawValue).tag(agent)
                        }
                    }
                    
                    // OpenAI API Key Section
                    if userPreferences.selectedVisionAgent == .openai || userPreferences.selectedParkingAgent == .openai {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("OpenAI API Key")
                                Spacer()
                                if userPreferences.openAIAPIKey != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                            
                            Button(userPreferences.openAIAPIKey != nil ? "Update API Key" : "Add API Key") {
                                tempAPIKey = userPreferences.openAIAPIKey ?? ""
                                showingAPIKeyAlert = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // Privacy
                Section("Privacy") {
                    Button("Clear History") {
                        userPreferences.parkingHistory = []
                    }
                    .foregroundColor(.red)
                    
                    Button("Reset All Settings") {
                        resetSettings()
                    }
                    .foregroundColor(.red)
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/Ibrahim-Haroon")!) {
                        HStack {
                            Text("Developer")
                            Spacer()
                            Text("@Ibrahim-Haroon")
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("OpenAI API Key", isPresented: $showingAPIKeyAlert) {
                TextField("Enter your OpenAI API Key", text: $tempAPIKey)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    userPreferences.openAIAPIKey = tempAPIKey.isEmpty ? nil : tempAPIKey
                }
            } message: {
                Text("Enter your OpenAI API key to enable OpenAI features. Your key is stored securely on your device.")
            }
        }
    }
    
    var locationText: String {
        switch userPreferences.locationPreference {
        case .precise:
            return "Precise Location"
        case .approximate:
            return "Approximate Location"
        case .manual:
            let city = userPreferences.city ?? ""
            let state = userPreferences.state ?? ""
            if !city.isEmpty || !state.isEmpty {
                return "\(city)\(!city.isEmpty && !state.isEmpty ? ", " : "")\(state)"
            }
            return "Manual Entry"
        case .none:
            return "Not sharing"
        }
    }
    
    func resetSettings() {
        userPreferences.hasCompletedOnboarding = false
        userPreferences.userName = nil
        userPreferences.vehicleType = nil
        userPreferences.locationPreference = .none
        userPreferences.city = nil
        userPreferences.state = nil
        userPreferences.parkingHistory = []
    }
}
