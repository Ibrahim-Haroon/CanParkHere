//
//  OnboardingView.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomeView(currentPage: $currentPage)
                .tag(0)
            
            VehicleSelectionView(currentPage: $currentPage)
                .tag(1)
            
            LocationPermissionView(currentPage: $currentPage)
                .tag(2)
            
            OnboardingCompleteView()
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

struct WelcomeView: View {
    @Binding var currentPage: Int
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var userName = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 12) {
                Text("Welcome to ParkSmart")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Never get a parking ticket again")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                Text("What should we call you?")
                    .font(.headline)
                
                TextField("Name (optional)", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: {
                if !userName.isEmpty {
                    userPreferences.userName = userName
                }
                withAnimation {
                    currentPage = 1
                }
            }) {
                Label("Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

struct VehicleSelectionView: View {
    @Binding var currentPage: Int
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var selectedVehicle: VehicleType?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("What do you drive?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("This helps us check vehicle-specific restrictions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(VehicleType.allCases, id: \.self) { vehicle in
                    VehicleCard(
                        vehicle: vehicle,
                        isSelected: selectedVehicle == vehicle
                    )
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedVehicle = vehicle
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        currentPage = 0
                    }
                }) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    userPreferences.vehicleType = selectedVehicle
                    withAnimation {
                        currentPage = 2
                    }
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedVehicle != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(selectedVehicle == nil)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

struct VehicleCard: View {
    let vehicle: VehicleType
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: vehicle.icon)
                .font(.system(size: 40))
                .foregroundColor(isSelected ? .white : .blue)
            
            Text(vehicle.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct LocationPermissionView: View {
    @Binding var currentPage: Int
    @EnvironmentObject var userPreferences: UserPreferences
    @State private var locationChoice: UserPreferences.LocationPreference = .none
    @State private var manualCity = ""
    @State private var manualState = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Location Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Helps us check location-specific parking rules")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                LocationOption(
                    icon: "location.fill",
                    title: "Use Precise Location",
                    description: "Most accurate parking rules",
                    isSelected: locationChoice == .precise
                )
                .onTapGesture {
                    locationChoice = .precise
                    requestLocationPermission()
                }
                
                LocationOption(
                    icon: "location",
                    title: "Use Approximate Location",
                    description: "City-level accuracy",
                    isSelected: locationChoice == .approximate
                )
                .onTapGesture {
                    locationChoice = .approximate
                    requestLocationPermission()
                }
                
                LocationOption(
                    icon: "keyboard",
                    title: "Enter Manually",
                    description: "Type your city and state",
                    isSelected: locationChoice == .manual
                )
                .onTapGesture {
                    locationChoice = .manual
                }
                
                if locationChoice == .manual {
                    VStack(spacing: 12) {
                        TextField("City", text: $manualCity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("State", text: $manualState)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
                
                LocationOption(
                    icon: "location.slash",
                    title: "Skip for Now",
                    description: "Won't check location-specific rules",
                    isSelected: locationChoice == .none
                )
                .onTapGesture {
                    locationChoice = .none
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation {
                        currentPage = 1
                    }
                }) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    saveLocationPreferences()
                    withAnimation {
                        currentPage = 3
                    }
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    func requestLocationPermission() {
        // Implement location permission request
    }
    
    func saveLocationPreferences() {
        userPreferences.locationPreference = locationChoice
        if locationChoice == .manual {
            userPreferences.city = manualCity.isEmpty ? nil : manualCity
            userPreferences.state = manualState.isEmpty ? nil : manualState
        }
    }
}

struct LocationOption: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
        )
    }
}

struct OnboardingCompleteView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(.green.gradient)
            
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Let's check your first parking sign")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    userPreferences.hasCompletedOnboarding = true
                }
            }) {
                Label("Start Parking", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}
