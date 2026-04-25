import Foundation
import CoreLocation
import Observation

@Observable
@MainActor
class LocationService {
    static let shared = LocationService()

    var currentZipCode: String = "90210"
    var currentLatitude: Double = 34.0736
    var currentLongitude: Double = -118.4004

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "sparkefy_zip_code"), !saved.isEmpty {
            currentZipCode = saved
        }
        currentLatitude = UserDefaults.standard.double(forKey: "sparkefy_lat")
        currentLongitude = UserDefaults.standard.double(forKey: "sparkefy_lon")
        if currentLatitude == 0 { currentLatitude = 34.0736 }
        if currentLongitude == 0 { currentLongitude = -118.4004 }
    }

    func updateZipCode(_ zip: String) {
        currentZipCode = zip
        UserDefaults.standard.set(zip, forKey: "sparkefy_zip_code")
        geocodeZipCode(zip)
    }

    private func geocodeZipCode(_ zip: String) {
        Task {
            let geocoder = CLGeocoder()
            let placemarks = try? await geocoder.geocodeAddressString(zip)
            guard let coordinate = placemarks?.first?.location?.coordinate else { return }
            currentLatitude = coordinate.latitude
            currentLongitude = coordinate.longitude
            UserDefaults.standard.set(coordinate.latitude, forKey: "sparkefy_lat")
            UserDefaults.standard.set(coordinate.longitude, forKey: "sparkefy_lon")
        }
    }

    nonisolated static func distanceMiles(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let earthRadiusMiles = 3958.8
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMiles * c
    }
}
