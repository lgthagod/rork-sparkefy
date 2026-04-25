import SwiftUI

nonisolated enum ServiceCategory: String, Codable, Sendable, CaseIterable, Identifiable, Hashable {
    case carDetailing = "car_detailing"
    case boatDetailing = "boat_detailing"
    case pressureWashing = "pressure_washing"
    case yardMaintenance = "yard_maintenance"
    case homeCleaning = "home_cleaning"

    nonisolated var id: String { rawValue }

    var displayName: String {
        switch self {
        case .carDetailing: "Car Detailing"
        case .boatDetailing: "Boat Detailing"
        case .pressureWashing: "Pressure Washing"
        case .yardMaintenance: "Yard & Lawn"
        case .homeCleaning: "Home Cleaning"
        }
    }

    var icon: String {
        switch self {
        case .carDetailing: "car.fill"
        case .boatDetailing: "sailboat.fill"
        case .pressureWashing: "water.waves"
        case .yardMaintenance: "leaf.fill"
        case .homeCleaning: "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .carDetailing: Color(red: 0, green: 0.635, blue: 1)
        case .boatDetailing: Color(red: 0.2, green: 0.6, blue: 0.9)
        case .pressureWashing: Color(red: 0.4, green: 0.7, blue: 0.95)
        case .yardMaintenance: Color(red: 0, green: 0.773, blue: 0.557)
        case .homeCleaning: Color(red: 0.6, green: 0.4, blue: 0.8)
        }
    }

    var tagline: String {
        switch self {
        case .carDetailing: "Showroom shine, anywhere"
        case .boatDetailing: "Hull to helm perfection"
        case .pressureWashing: "Blast away the grime"
        case .yardMaintenance: "Curb appeal, delivered"
        case .homeCleaning: "Spotless spaces, stress-free"
        }
    }
}
