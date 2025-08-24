//
//  CanParkHereApp.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI

@main
struct CanParkHereApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var userPreferences = UserPreferences()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(userPreferences)
        }
    }
}
