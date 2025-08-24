//
//  HistoryView.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            if userPreferences.parkingHistory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No History Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Your parking checks will appear here")
                        .foregroundColor(.secondary)
                }
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            } else {
                List {
                    ForEach(userPreferences.parkingHistory) { item in
                        HistoryRow(item: item)
                    }
                }
                .navigationTitle("History")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }
}

struct HistoryRow: View {
    let item: ParkingHistoryItem
    @State private var showDetail = false
    
    var body: some View {
        HStack {
            // Status icon
            Image(systemName: item.canPark ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(item.canPark ? .green : .red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.canPark ? "Could Park" : "No Parking")
                    .font(.headline)
                
                if let location = item.location {
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(formatDate(item.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let imageData = item.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            HistoryDetailView(item: item)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct HistoryDetailView: View {
    let item: ParkingHistoryItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let imageData = item.imageData,
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                    }
                    
                    // Decision details
                    DetailedResultView(
                        decision: item.decision,
                        image: nil
                    )
                }
                .padding()
            }
            .navigationTitle("Parking Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
