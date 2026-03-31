import Foundation

nonisolated struct ServiceListing: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var providerId: String
    var providerName: String
    var providerAvatarURL: String?
    var providerRating: Double
    var providerReviewCount: Int
    var isVerified: Bool
    var category: ServiceCategory
    var title: String
    var description: String
    var basePrice: Double
    var priceUnit: String
    var zipCode: String
    var latitude: Double?
    var longitude: Double?
    var serviceRadius: Int
    var imageURLs: [String]
    var tags: [String]
    var estimatedDuration: String
    var isAvailable: Bool
    var availabilitySlots: [AvailabilitySlot]
    var createdAt: Date
    var distanceMiles: Double?

    init(
        id: String = UUID().uuidString,
        providerId: String = "",
        providerName: String = "",
        providerAvatarURL: String? = nil,
        providerRating: Double = 0,
        providerReviewCount: Int = 0,
        isVerified: Bool = false,
        category: ServiceCategory = .carDetailing,
        title: String = "",
        description: String = "",
        basePrice: Double = 0,
        priceUnit: String = "per service",
        zipCode: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        serviceRadius: Int = 15,
        imageURLs: [String] = [],
        tags: [String] = [],
        estimatedDuration: String = "",
        isAvailable: Bool = true,
        availabilitySlots: [AvailabilitySlot] = [],
        createdAt: Date = Date(),
        distanceMiles: Double? = nil
    ) {
        self.id = id
        self.providerId = providerId
        self.providerName = providerName
        self.providerAvatarURL = providerAvatarURL
        self.providerRating = providerRating
        self.providerReviewCount = providerReviewCount
        self.isVerified = isVerified
        self.category = category
        self.title = title
        self.description = description
        self.basePrice = basePrice
        self.priceUnit = priceUnit
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.serviceRadius = serviceRadius
        self.imageURLs = imageURLs
        self.tags = tags
        self.estimatedDuration = estimatedDuration
        self.isAvailable = isAvailable
        self.availabilitySlots = availabilitySlots
        self.createdAt = createdAt
        self.distanceMiles = distanceMiles
    }
}
