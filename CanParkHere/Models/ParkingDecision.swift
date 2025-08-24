//
//  ParkingDecision.swift
//  CanParkHere
//
//  Created by Ibrahim Haroon on 8/24/25.
//

import Foundation

struct ParkingDecision: Codable {
    let canPark: Bool
    let duration: TimeInterval?
    let restrictions: [String]
    let reason: String?
    let validUntil: Date?
    
    enum CodingKeys: String, CodingKey {
        case canPark = "can_park"
        case duration
        case restrictions
        case reason
        case validUntil = "valid_until"
    }
}

struct ParkingContext {
    let currentTime: Date
    let location: Location?
    let vehicleType: VehicleType
    let isHoliday: Bool
    
    struct Location {
        let city: String?
        let state: String?
        let coordinates: (latitude: Double, longitude: Double)?
    }
}

enum VehicleType: String, CaseIterable, Codable {
    case sedan = "Sedan"
    case suv = "SUV"
    case truck = "Truck"
    case motorcycle = "Motorcycle"
    case commercial = "Commercial"
    case electric = "Electric"
    
    var icon: String {
        switch self {
        case .sedan: return "car.fill"
        case .suv: return "car.fill"
        case .truck: return "truck.box.fill"
        case .motorcycle: return "figure.outdoor.cycle"
        case .commercial: return "bus.fill"
        case .electric: return "bolt.car.fill"
        }
    }
}
