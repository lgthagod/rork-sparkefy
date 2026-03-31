import Foundation

nonisolated enum UserRole: String, Codable, Sendable, CaseIterable {
    case customer
    case provider
}

nonisolated enum VerificationStatus: String, Codable, Sendable {
    case unverified
    case pending
    case verified
}

nonisolated struct UserProfile: Codable, Sendable, Identifiable {
    let id: String
    var name: String
    var email: String
    var phone: String
    var avatarURL: String?
    var role: UserRole
    var zipCode: String
    var latitude: Double?
    var longitude: Double?
    var rating: Double
    var reviewCount: Int
    var jobsCompleted: Int
    var responseRate: Double
    var isVerified: Bool
    var verificationStatus: VerificationStatus
    var createdAt: Date
    var bio: String?
    var insuranceUploaded: Bool
    var insuranceURL: String?
    var backgroundCheckPassed: Bool
    var twoFactorEnabled: Bool
    var phoneVerified: Bool
    var stripeAccountId: String?
    var stripeOnboardingComplete: Bool
    var serviceCategories: [ServiceCategory]

    init(
        id: String = UUID().uuidString,
        name: String = "",
        email: String = "",
        phone: String = "",
        avatarURL: String? = nil,
        role: UserRole = .customer,
        zipCode: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        rating: Double = 0,
        reviewCount: Int = 0,
        jobsCompleted: Int = 0,
        responseRate: Double = 1.0,
        isVerified: Bool = false,
        verificationStatus: VerificationStatus = .unverified,
        createdAt: Date = Date(),
        bio: String? = nil,
        insuranceUploaded: Bool = false,
        insuranceURL: String? = nil,
        backgroundCheckPassed: Bool = false,
        twoFactorEnabled: Bool = false,
        phoneVerified: Bool = false,
        stripeAccountId: String? = nil,
        stripeOnboardingComplete: Bool = false,
        serviceCategories: [ServiceCategory] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.avatarURL = avatarURL
        self.role = role
        self.zipCode = zipCode
        self.latitude = latitude
        self.longitude = longitude
        self.rating = rating
        self.reviewCount = reviewCount
        self.jobsCompleted = jobsCompleted
        self.responseRate = responseRate
        self.isVerified = isVerified
        self.verificationStatus = verificationStatus
        self.createdAt = createdAt
        self.bio = bio
        self.insuranceUploaded = insuranceUploaded
        self.insuranceURL = insuranceURL
        self.backgroundCheckPassed = backgroundCheckPassed
        self.twoFactorEnabled = twoFactorEnabled
        self.phoneVerified = phoneVerified
        self.stripeAccountId = stripeAccountId
        self.stripeOnboardingComplete = stripeOnboardingComplete
        self.serviceCategories = serviceCategories
    }
}
