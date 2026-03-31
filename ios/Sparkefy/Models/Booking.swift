import Foundation

nonisolated enum BookingStatus: String, Codable, Sendable, CaseIterable {
    case pending
    case confirmed
    case inProgress = "in_progress"
    case completed
    case cancelled
    case disputed

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .confirmed: "Confirmed"
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        case .disputed: "Disputed"
        }
    }
}

nonisolated enum RecurrenceType: String, Codable, Sendable, CaseIterable {
    case once
    case weekly
    case biweekly
    case monthly

    var displayName: String {
        switch self {
        case .once: "One-time"
        case .weekly: "Weekly"
        case .biweekly: "Bi-weekly"
        case .monthly: "Monthly"
        }
    }
}

nonisolated struct Coordinate: Codable, Sendable, Hashable {
    let latitude: Double
    let longitude: Double
}

nonisolated enum TrackingStatus: String, Codable, Sendable {
    case idle
    case enRoute = "en_route"
    case arriving
    case onSite = "on_site"

    var displayName: String {
        switch self {
        case .idle: "Not Started"
        case .enRoute: "Provider is on the way"
        case .arriving: "Provider is arriving"
        case .onSite: "Provider is at the job site"
        }
    }

    var icon: String {
        switch self {
        case .idle: "circle.dashed"
        case .enRoute: "car.fill"
        case .arriving: "location.fill"
        case .onSite: "checkmark.circle.fill"
        }
    }
}

nonisolated struct Booking: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var customerId: String
    var customerName: String
    var providerId: String
    var providerName: String
    var serviceListingId: String
    var category: ServiceCategory
    var serviceTitle: String
    var status: BookingStatus
    var scheduledDate: Date
    var scheduledTime: String
    var address: String
    var zipCode: String
    var notes: String
    var photos: [String]
    var basePrice: Double
    var platformFee: Double
    var providerEarnings: Double
    var tipAmount: Double
    var totalPrice: Double
    var recurrence: RecurrenceType
    var parentBookingId: String?
    var providerRating: Double?
    var reviewText: String?
    var createdAt: Date
    var isTrackingEnabled: Bool
    var trackingStatus: TrackingStatus
    var providerLocation: Coordinate?
    var jobLocation: Coordinate?
    var estimatedArrivalMinutes: Int?

    var formattedDate: String {
        scheduledDate.formatted(date: .abbreviated, time: .omitted)
    }

    var formattedTotal: String {
        totalPrice.formatted(.currency(code: "USD"))
    }

    init(
        id: String = UUID().uuidString,
        customerId: String = "",
        customerName: String = "",
        providerId: String = "",
        providerName: String = "",
        serviceListingId: String = "",
        category: ServiceCategory = .carDetailing,
        serviceTitle: String = "",
        status: BookingStatus = .pending,
        scheduledDate: Date = Date(),
        scheduledTime: String = "",
        address: String = "",
        zipCode: String = "",
        notes: String = "",
        photos: [String] = [],
        basePrice: Double = 0,
        platformFee: Double = 0,
        providerEarnings: Double = 0,
        tipAmount: Double = 0,
        totalPrice: Double = 0,
        recurrence: RecurrenceType = .once,
        parentBookingId: String? = nil,
        providerRating: Double? = nil,
        reviewText: String? = nil,
        createdAt: Date = Date(),
        isTrackingEnabled: Bool = false,
        trackingStatus: TrackingStatus = .idle,
        providerLocation: Coordinate? = nil,
        jobLocation: Coordinate? = nil,
        estimatedArrivalMinutes: Int? = nil
    ) {
        self.id = id
        self.customerId = customerId
        self.customerName = customerName
        self.providerId = providerId
        self.providerName = providerName
        self.serviceListingId = serviceListingId
        self.category = category
        self.serviceTitle = serviceTitle
        self.status = status
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.address = address
        self.zipCode = zipCode
        self.notes = notes
        self.photos = photos
        self.basePrice = basePrice
        self.platformFee = platformFee
        self.providerEarnings = providerEarnings
        self.tipAmount = tipAmount
        self.totalPrice = totalPrice
        self.recurrence = recurrence
        self.parentBookingId = parentBookingId
        self.providerRating = providerRating
        self.reviewText = reviewText
        self.createdAt = createdAt
        self.isTrackingEnabled = isTrackingEnabled
        self.trackingStatus = trackingStatus
        self.providerLocation = providerLocation
        self.jobLocation = jobLocation
        self.estimatedArrivalMinutes = estimatedArrivalMinutes
    }

    static func calculateFees(basePrice: Double) -> (platformFee: Double, providerEarnings: Double) {
        let fee = basePrice * 0.20
        let earnings = basePrice - fee
        return (fee, earnings)
    }
}
