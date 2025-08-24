//
//  ContentView.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if !userPreferences.hasCompletedOnboarding {
            OnboardingView()
        } else {
            MainCameraView()
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab = 0
}
