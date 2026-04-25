import SwiftUI
import Observation

nonisolated enum RadiusOption: Int, CaseIterable, Sendable, Identifiable {
    case ten = 10
    case fifteen = 15
    case twentyFive = 25
    case fifty = 50
    case hundred = 100

    nonisolated var id: Int { rawValue }

    var label: String { "\(rawValue) mi" }
}

nonisolated enum DiscoverySortOption: String, CaseIterable, Sendable {
    case rating = "Top Rated"
    case priceLow = "Price: Low"
    case priceHigh = "Price: High"
    case distance = "Nearest"
}

@Observable
@MainActor
class HomeViewModel {
    var featuredListings: [ServiceListing] = []
    var nearbyProviders: [ServiceListing] = []
    var searchText = ""
    var zipCode: String = ""
    var selectedRadius: RadiusOption = .twentyFive
    var selectedSort: DiscoverySortOption = .rating
    var isLoading = false

    var filteredListings: [ServiceListing] {
        var results = featuredListings

        if !searchText.isEmpty {
            results = results.filter {
                $0.title.localizedStandardContains(searchText) ||
                $0.providerName.localizedStandardContains(searchText) ||
                $0.category.displayName.localizedStandardContains(searchText)
            }
        }

        results = results.filter { listing in
            guard let dist = listing.distanceMiles else { return true }
            return dist <= Double(selectedRadius.rawValue)
        }

        switch selectedSort {
        case .rating: results.sort { $0.providerRating > $1.providerRating }
        case .priceLow: results.sort { $0.basePrice < $1.basePrice }
        case .priceHigh: results.sort { $0.basePrice > $1.basePrice }
        case .distance: results.sort { ($0.distanceMiles ?? 999) < ($1.distanceMiles ?? 999) }
        }

        return results
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        let loc = LocationService.shared
        if zipCode.isEmpty {
            zipCode = loc.currentZipCode
        }

        let store = DataStore.shared
        await store.loadRemoteListings(zipCode: zipCode)

        var listings = store.listings.isEmpty ? Self.sampleListings : store.listings

        listings = listings.map { listing in
            var l = listing
            if let lat = listing.latitude, let lon = listing.longitude {
                l.distanceMiles = LocationService.distanceMiles(
                    lat1: loc.currentLatitude, lon1: loc.currentLongitude,
                    lat2: lat, lon2: lon
                )
            } else {
                l.distanceMiles = Double.random(in: 1...30)
            }
            return l
        }

        featuredListings = listings
        nearbyProviders = listings
            .sorted { ($0.distanceMiles ?? 999) < ($1.distanceMiles ?? 999) }
            .prefix(4)
            .map { $0 }
    }

    func updateZipCode(_ newZip: String) {
        zipCode = newZip
        LocationService.shared.updateZipCode(newZip)
        Task { await loadData() }
    }

    static let sampleListings: [ServiceListing] = [
        ServiceListing(
            id: "1", providerId: "p1", providerName: "Mike's Auto Spa",
            providerRating: 4.9, providerReviewCount: 187, isVerified: true,
            category: .carDetailing, title: "Premium Interior & Exterior Detail",
            description: "Full showroom-quality detail including clay bar, polish, ceramic coating, leather conditioning, and engine bay cleaning.",
            basePrice: 149.99, priceUnit: "per vehicle", zipCode: "90210",
            latitude: 34.0736, longitude: -118.4004, serviceRadius: 15,
            tags: ["Ceramic Coating", "Interior", "Premium"],
            estimatedDuration: "3-4 hours"
        ),
        ServiceListing(
            id: "2", providerId: "p2", providerName: "GreenScape Pro",
            providerRating: 4.7, providerReviewCount: 234, isVerified: true,
            category: .yardMaintenance, title: "Complete Lawn Care Package",
            description: "Weekly mowing, edging, trimming, leaf blowing, and seasonal fertilization. Your yard, perfected.",
            basePrice: 65, priceUnit: "per visit", zipCode: "90210",
            latitude: 34.0680, longitude: -118.3950, serviceRadius: 25,
            tags: ["Mowing", "Edging", "Fertilizing"],
            estimatedDuration: "1-2 hours"
        ),
        ServiceListing(
            id: "3", providerId: "p3", providerName: "Crystal Clear Wash",
            providerRating: 4.8, providerReviewCount: 156, isVerified: true,
            category: .pressureWashing, title: "Driveway & Patio Power Wash",
            description: "High-pressure deep clean for driveways, patios, decks, and siding. Eco-friendly detergents included.",
            basePrice: 199, priceUnit: "per session", zipCode: "90210",
            latitude: 34.0800, longitude: -118.4100, serviceRadius: 20,
            tags: ["Driveway", "Patio", "Eco-Friendly"],
            estimatedDuration: "2-3 hours"
        ),
        ServiceListing(
            id: "4", providerId: "p4", providerName: "Sparkle Home Co.",
            providerRating: 4.6, providerReviewCount: 312, isVerified: true,
            category: .homeCleaning, title: "Deep Home Cleaning",
            description: "Top-to-bottom deep clean including bathrooms, kitchen, floors, dusting, and window cleaning.",
            basePrice: 120, priceUnit: "per session", zipCode: "90210",
            latitude: 34.0650, longitude: -118.3900, serviceRadius: 30,
            tags: ["Deep Clean", "Kitchen", "Bathroom"],
            estimatedDuration: "3-5 hours"
        ),
        ServiceListing(
            id: "5", providerId: "p5", providerName: "Marina Detail Works",
            providerRating: 4.9, providerReviewCount: 89, isVerified: true,
            category: .boatDetailing, title: "Full Boat Detail & Wax",
            description: "Hull cleaning, oxidation removal, wax & polish, interior detailing, and teak restoration.",
            basePrice: 349, priceUnit: "per boat", zipCode: "90210",
            latitude: 33.9800, longitude: -118.4500, serviceRadius: 50,
            tags: ["Hull", "Wax", "Teak"],
            estimatedDuration: "4-6 hours"
        ),
        ServiceListing(
            id: "6", providerId: "p1", providerName: "Mike's Auto Spa",
            providerRating: 4.9, providerReviewCount: 187, isVerified: true,
            category: .carDetailing, title: "Express Wash & Wax",
            description: "Quick exterior hand wash, clay, and spray wax. Perfect for maintaining your vehicle between full details.",
            basePrice: 49.99, priceUnit: "per vehicle", zipCode: "90210",
            latitude: 34.0736, longitude: -118.4004, serviceRadius: 15,
            tags: ["Quick", "Exterior", "Wax"],
            estimatedDuration: "45 min"
        )
    ]
}
