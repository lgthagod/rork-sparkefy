import SwiftUI

@Observable
@MainActor
class BookingViewModel {
    var selectedFilter: BookingFilter = .upcoming
    var isLoading = false

    private var dataStore: DataStore { DataStore.shared }

    var bookings: [Booking] { dataStore.bookings }

    var filteredBookings: [Booking] {
        switch selectedFilter {
        case .upcoming:
            return bookings.filter { $0.status == .pending || $0.status == .confirmed || $0.status == .inProgress }
        case .completed:
            return bookings.filter { $0.status == .completed }
        case .cancelled:
            return bookings.filter { $0.status == .cancelled || $0.status == .disputed }
        }
    }

    func loadBookings(userId: String? = nil, role: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        if let userId, let role {
            await dataStore.loadRemoteBookings(userId: userId, role: role)
        }

        if dataStore.bookings.isEmpty {
            try? await Task.sleep(for: .seconds(0.3))
            dataStore.loadSampleBookingsIfNeeded()
        }
    }

    func cancelBooking(_ booking: Booking) {
        dataStore.cancelBooking(id: booking.id)
    }

    func acceptBooking(_ booking: Booking) {
        dataStore.acceptBooking(id: booking.id)
    }

    func completeBooking(_ booking: Booking) {
        dataStore.completeBooking(id: booking.id)
    }

    func toggleTracking(for booking: Booking) {
        dataStore.toggleTracking(id: booking.id)
    }

    static let sampleBookings: [Booking] = {
        let fees1 = Booking.calculateFees(basePrice: 149.99)
        let fees2 = Booking.calculateFees(basePrice: 65)
        let fees3 = Booking.calculateFees(basePrice: 120)
        return [
            Booking(
                id: "b1", customerId: "u1", customerName: "Alex Johnson",
                providerId: "p1", providerName: "Mike's Auto Spa",
                serviceListingId: "1", category: .carDetailing,
                serviceTitle: "Premium Interior & Exterior Detail",
                status: .confirmed,
                scheduledDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                scheduledTime: "10:00 AM", address: "123 Beverly Dr, Beverly Hills",
                zipCode: "90210", basePrice: 149.99,
                platformFee: fees1.platformFee, providerEarnings: fees1.providerEarnings,
                tipAmount: 22.50,
                totalPrice: 149.99 + 22.50,
                isTrackingEnabled: true,
                trackingStatus: .enRoute,
                providerLocation: Coordinate(latitude: 34.0722, longitude: -118.4041),
                jobLocation: Coordinate(latitude: 34.0736, longitude: -118.4004),
                estimatedArrivalMinutes: 12
            ),
            Booking(
                id: "b2", customerId: "u1", customerName: "Alex Johnson",
                providerId: "p2", providerName: "GreenScape Pro",
                serviceListingId: "2", category: .yardMaintenance,
                serviceTitle: "Complete Lawn Care Package",
                status: .pending,
                scheduledDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                scheduledTime: "8:00 AM", address: "123 Beverly Dr, Beverly Hills",
                zipCode: "90210", basePrice: 65,
                platformFee: fees2.platformFee, providerEarnings: fees2.providerEarnings,
                totalPrice: 65, recurrence: .weekly
            ),
            Booking(
                id: "b3", customerId: "u1", customerName: "Alex Johnson",
                providerId: "p4", providerName: "Sparkle Home Co.",
                serviceListingId: "4", category: .homeCleaning,
                serviceTitle: "Deep Home Cleaning",
                status: .completed,
                scheduledDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                scheduledTime: "9:00 AM", address: "123 Beverly Dr, Beverly Hills",
                zipCode: "90210", basePrice: 120,
                platformFee: fees3.platformFee, providerEarnings: fees3.providerEarnings,
                tipAmount: 18,
                totalPrice: 120 + 18, providerRating: 5, reviewText: "Absolutely spotless! Will book again."
            )
        ]
    }()
}

enum BookingFilter: String, CaseIterable {
    case upcoming = "Upcoming"
    case completed = "Completed"
    case cancelled = "Cancelled"
}
