//
//  ParkingResultView.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI

struct ParkingResultView: View {
    let decision: ParkingDecision
    let image: UIImage?
    let onDismiss: () -> Void
    
    @State private var showDetails = false
    @State private var animateResult = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: decision.canPark ?
                [Color.green.opacity(0.8), Color.green] :
                    [Color.red.opacity(0.8), Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Quick result view
                if !showDetails {
                    QuickResultView(
                        canPark: decision.canPark,
                        animateResult: $animateResult
                    )
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Detailed view
                if showDetails {
                    DetailedResultView(
                        decision: decision,
                        image: image
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    if !showDetails {
                        Button(action: {
                            withAnimation(.spring()) {
                                showDetails = true
                            }
                        }) {
                            Label("View Details", systemImage: "info.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: onDismiss) {
                        Label(showDetails ? "Check Another Sign" : "Continue",
                              systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(decision.canPark ? .green : .red)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateResult = true
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(
                style: decision.canPark ? .light : .heavy
            )
            impactFeedback.impactOccurred()
            
            // Auto-show details after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring()) {
                    showDetails = true
                }
            }
        }
    }
}

struct QuickResultView: View {
    let canPark: Bool
    @Binding var animateResult: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: canPark ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 150))
                .foregroundColor(.white)
                .scaleEffect(animateResult ? 1.0 : 0.5)
                .opacity(animateResult ? 1.0 : 0)
            
            // Text
            Text(canPark ? "YES" : "NO")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(animateResult ? 1.0 : 0.5)
                .opacity(animateResult ? 1.0 : 0)
            
            Text(canPark ? "You can park here" : "You cannot park here")
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
                .opacity(animateResult ? 1.0 : 0)
                .animation(.easeIn.delay(0.3), value: animateResult)
            
            Spacer()
            Spacer()
        }
    }
}

struct DetailedResultView: View {
    let decision: ParkingDecision
    let image: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Result header
                HStack {
                    Image(systemName: decision.canPark ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading) {
                        Text(decision.canPark ? "You can park" : "No parking")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let reason = decision.reason {
                            Text(reason)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                
                // Duration info
                if let duration = decision.duration {
                    InfoCard(
                        icon: "clock.fill",
                        title: "Time Limit",
                        value: "\(duration) minutes"
                    )
                }
                
                // Valid until
                if let validUntil = decision.validUntil {
                    InfoCard(
                        icon: "calendar",
                        title: "Valid Until",
                        value: formatTime(validUntil)
                    )
                }
                
                // Restrictions
                if !decision.restrictions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Restrictions", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(decision.restrictions, id: \.self) { restriction in
                            HStack {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(restriction)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Original image
                if let image = image {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original Sign")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
