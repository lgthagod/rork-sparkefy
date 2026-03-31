import Foundation

nonisolated struct Review: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var bookingId: String
    var reviewerId: String
    var reviewerName: String
    var reviewerAvatarURL: String?
    var providerId: String
    var rating: Double
    var text: String
    var category: ServiceCategory
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        bookingId: String = "",
        reviewerId: String = "",
        reviewerName: String = "",
        reviewerAvatarURL: String? = nil,
        providerId: String = "",
        rating: Double = 5,
        text: String = "",
        category: ServiceCategory = .carDetailing,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookingId = bookingId
        self.reviewerId = reviewerId
        self.reviewerName = reviewerName
        self.reviewerAvatarURL = reviewerAvatarURL
        self.providerId = providerId
        self.rating = rating
        self.text = text
        self.category = category
        self.createdAt = createdAt
    }
}
