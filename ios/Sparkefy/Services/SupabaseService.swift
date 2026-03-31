import Foundation
import Supabase
import Auth

@Observable
@MainActor
class SupabaseService {
    static let shared = SupabaseService()

    private(set) var client: SupabaseClient?
    private(set) var isConfigured = false
    private(set) var currentSession: Session?
    private var authStateTask: Task<Void, Never>?

    var isAuthenticated: Bool { currentSession != nil }
    var currentUserId: String? { currentSession?.user.id.uuidString }
    var currentUserEmail: String? { currentSession?.user.email }
    var currentUserPhone: String? { currentSession?.user.phone }

    private init() {
        setupClient()
    }

    private func setupClient() {
        let urlString = Config.allValues["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
        let anonKey = Config.allValues["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""

        guard !urlString.isEmpty, !anonKey.isEmpty, let url = URL(string: urlString) else {
            isConfigured = false
            return
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
        isConfigured = true
        listenForAuthChanges()
    }

    private func listenForAuthChanges() {
        guard let client else { return }
        authStateTask = Task { [weak self] in
            for await (event, session) in client.auth.authStateChanges {
                guard let self else { return }
                self.currentSession = session
                if event == .signedOut {
                    self.currentSession = nil
                }
            }
        }
    }

    func signUp(email: String, password: String, name: String) async throws -> String {
        guard let client else { throw SparkefyError.notConfigured }
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(name)]
        )
        if let session = response.session {
            currentSession = session
            return session.user.id.uuidString
        }
        return response.user.id.uuidString
    }

    func signIn(email: String, password: String) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        let session = try await client.auth.signIn(email: email, password: password)
        currentSession = session
    }

    func signOut() async throws {
        guard let client else { return }
        try await client.auth.signOut()
        currentSession = nil
    }

    func restoreSession() async {
        guard let client else { return }
        do {
            currentSession = try await client.auth.session
        } catch {
            currentSession = nil
        }
    }

    func sendPhoneOTP(phone: String) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client.auth.signInWithOTP(phone: phone)
    }

    func verifyPhoneOTP(phone: String, code: String) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client.auth.verifyOTP(phone: phone, token: code, type: .sms)
    }

    func updateUserPhone(phone: String) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client.auth.update(user: UserAttributes(phone: phone))
    }

    func upsertProfile(_ profile: SupabaseProfile) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("profiles")
            .upsert(profile)
            .execute()
    }

    func fetchProfile(userId: String) async throws -> SupabaseProfile? {
        guard let client else { throw SparkefyError.notConfigured }
        let response: [SupabaseProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        return response.first
    }

    func upsertServiceListing(_ listing: SupabaseServiceListing) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("service_listings")
            .upsert(listing)
            .execute()
    }

    func fetchServiceListings(category: String? = nil, zipCode: String? = nil) async throws -> [SupabaseServiceListing] {
        guard let client else { throw SparkefyError.notConfigured }
        var query = client.from("service_listings").select()

        if let category {
            query = query.eq("category", value: category)
        }
        if let zipCode, !zipCode.isEmpty {
            query = query.eq("zip_code", value: zipCode)
        }

        let response: [SupabaseServiceListing] = try await query
            .eq("is_available", value: true)
            .order("provider_rating", ascending: false)
            .execute()
            .value
        return response
    }

    func insertBooking(_ booking: SupabaseBooking) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("bookings")
            .insert(booking)
            .execute()
    }

    func updateBookingStatus(id: String, status: String) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("bookings")
            .update(["status": status])
            .eq("id", value: id)
            .execute()
    }

    func fetchBookings(userId: String, role: String) async throws -> [SupabaseBooking] {
        guard let client else { throw SparkefyError.notConfigured }
        let column = role == "provider" ? "provider_id" : "customer_id"
        let response: [SupabaseBooking] = try await client
            .from("bookings")
            .select()
            .eq(column, value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func insertReview(_ review: SupabaseReview) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("reviews")
            .insert(review)
            .execute()
    }

    func fetchReviews(providerId: String) async throws -> [SupabaseReview] {
        guard let client else { throw SparkefyError.notConfigured }
        let response: [SupabaseReview] = try await client
            .from("reviews")
            .select()
            .eq("provider_id", value: providerId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func upsertAvailabilitySlots(_ slots: [SupabaseAvailabilitySlot]) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("availability_slots")
            .upsert(slots)
            .execute()
    }

    func fetchAvailabilitySlots(providerId: String) async throws -> [SupabaseAvailabilitySlot] {
        guard let client else { throw SparkefyError.notConfigured }
        let response: [SupabaseAvailabilitySlot] = try await client
            .from("availability_slots")
            .select()
            .eq("provider_id", value: providerId)
            .execute()
            .value
        return response
    }

    func deleteAvailabilitySlot(id: String) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("availability_slots")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func fetchConversations(userId: String) async throws -> [SupabaseConversation] {
        guard let client else { throw SparkefyError.notConfigured }
        let asCustomer: [SupabaseConversation] = try await client
            .from("conversations")
            .select()
            .eq("customer_id", value: userId)
            .execute()
            .value
        let asProvider: [SupabaseConversation] = try await client
            .from("conversations")
            .select()
            .eq("provider_id", value: userId)
            .execute()
            .value
        return (asCustomer + asProvider).sorted { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }
    }

    func fetchMessages(conversationId: String) async throws -> [SupabaseMessage] {
        guard let client else { throw SparkefyError.notConfigured }
        let response: [SupabaseMessage] = try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return response
    }

    func insertMessage(_ message: SupabaseMessage) async throws {
        guard let client else { throw SparkefyError.notConfigured }
        try await client
            .from("messages")
            .insert(message)
            .execute()
    }

    static let setupSQL = """
    -- Sparkefy Database Schema (Run in Supabase SQL Editor)

    -- 1. Profiles
    CREATE TABLE IF NOT EXISTS profiles (
        id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
        name TEXT NOT NULL DEFAULT '',
        email TEXT DEFAULT '',
        phone TEXT DEFAULT '',
        avatar_url TEXT,
        role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'provider')),
        zip_code TEXT DEFAULT '',
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        bio TEXT,
        rating DOUBLE PRECISION DEFAULT 0,
        review_count INTEGER DEFAULT 0,
        jobs_completed INTEGER DEFAULT 0,
        response_rate DOUBLE PRECISION DEFAULT 1.0,
        is_verified BOOLEAN DEFAULT false,
        verification_status TEXT DEFAULT 'unverified',
        insurance_uploaded BOOLEAN DEFAULT false,
        insurance_url TEXT,
        background_check_passed BOOLEAN DEFAULT false,
        two_factor_enabled BOOLEAN DEFAULT false,
        phone_verified BOOLEAN DEFAULT false,
        stripe_account_id TEXT,
        stripe_onboarding_complete BOOLEAN DEFAULT false,
        service_categories TEXT[] DEFAULT '{}',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Users can read all profiles" ON profiles FOR SELECT USING (true);
    CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
    CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

    -- 2. Service Listings
    CREATE TABLE IF NOT EXISTS service_listings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        provider_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
        provider_name TEXT DEFAULT '',
        provider_rating DOUBLE PRECISION DEFAULT 0,
        provider_review_count INTEGER DEFAULT 0,
        is_verified BOOLEAN DEFAULT false,
        category TEXT NOT NULL CHECK (category IN ('car_detailing','boat_detailing','pressure_washing','yard_maintenance','home_cleaning')),
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        base_price DOUBLE PRECISION NOT NULL DEFAULT 0,
        price_unit TEXT DEFAULT 'per service',
        zip_code TEXT DEFAULT '',
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        service_radius INTEGER DEFAULT 15,
        image_urls TEXT[] DEFAULT '{}',
        tags TEXT[] DEFAULT '{}',
        estimated_duration TEXT DEFAULT '',
        is_available BOOLEAN DEFAULT true,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE service_listings ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Anyone can read listings" ON service_listings FOR SELECT USING (true);
    CREATE POLICY "Providers can manage own listings" ON service_listings FOR ALL USING (auth.uid() = provider_id);

    -- 3. Availability Slots
    CREATE TABLE IF NOT EXISTS availability_slots (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        provider_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
        day_of_week INTEGER CHECK (day_of_week BETWEEN 1 AND 7),
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        is_recurring BOOLEAN DEFAULT true,
        specific_date DATE,
        is_blocked BOOLEAN DEFAULT false,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE availability_slots ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Anyone can read slots" ON availability_slots FOR SELECT USING (true);
    CREATE POLICY "Providers manage own slots" ON availability_slots FOR ALL USING (auth.uid() = provider_id);

    -- 4. Bookings
    CREATE TABLE IF NOT EXISTS bookings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id UUID REFERENCES profiles(id),
        customer_name TEXT DEFAULT '',
        provider_id UUID REFERENCES profiles(id),
        provider_name TEXT DEFAULT '',
        service_listing_id UUID REFERENCES service_listings(id),
        category TEXT NOT NULL,
        service_title TEXT DEFAULT '',
        status TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','in_progress','completed','cancelled','disputed')),
        scheduled_date DATE NOT NULL,
        scheduled_time TEXT DEFAULT '',
        address TEXT DEFAULT '',
        zip_code TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        photos TEXT[] DEFAULT '{}',
        base_price DOUBLE PRECISION DEFAULT 0,
        platform_fee DOUBLE PRECISION DEFAULT 0,
        provider_earnings DOUBLE PRECISION DEFAULT 0,
        tip_amount DOUBLE PRECISION DEFAULT 0,
        total_price DOUBLE PRECISION DEFAULT 0,
        recurrence TEXT DEFAULT 'once',
        parent_booking_id UUID,
        is_tracking_enabled BOOLEAN DEFAULT false,
        tracking_status TEXT DEFAULT 'idle',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Users see own bookings" ON bookings FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = provider_id);
    CREATE POLICY "Customers create bookings" ON bookings FOR INSERT WITH CHECK (auth.uid() = customer_id);
    CREATE POLICY "Participants update bookings" ON bookings FOR UPDATE USING (auth.uid() = customer_id OR auth.uid() = provider_id);

    -- 5. Reviews
    CREATE TABLE IF NOT EXISTS reviews (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        booking_id UUID REFERENCES bookings(id),
        customer_id UUID REFERENCES profiles(id),
        provider_id UUID REFERENCES profiles(id),
        rating DOUBLE PRECISION NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment TEXT DEFAULT '',
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Anyone can read reviews" ON reviews FOR SELECT USING (true);
    CREATE POLICY "Customers create reviews" ON reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);

    -- 6. Conversations
    CREATE TABLE IF NOT EXISTS conversations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        booking_id UUID REFERENCES bookings(id),
        customer_id UUID REFERENCES profiles(id),
        provider_id UUID REFERENCES profiles(id),
        last_message TEXT DEFAULT '',
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Participants see conversations" ON conversations FOR SELECT USING (auth.uid() = customer_id OR auth.uid() = provider_id);
    CREATE POLICY "Participants create conversations" ON conversations FOR INSERT WITH CHECK (auth.uid() = customer_id OR auth.uid() = provider_id);

    -- 7. Messages
    CREATE TABLE IF NOT EXISTS messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
        sender_id UUID REFERENCES profiles(id),
        text TEXT NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
    CREATE POLICY "Conversation participants see messages" ON messages FOR SELECT USING (
        EXISTS (SELECT 1 FROM conversations c WHERE c.id = conversation_id AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid()))
    );
    CREATE POLICY "Conversation participants send messages" ON messages FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND EXISTS (SELECT 1 FROM conversations c WHERE c.id = conversation_id AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid()))
    );
    """
}

nonisolated enum SparkefyError: Error, LocalizedError, Sendable {
    case notConfigured
    case invalidData
    case networkError(String)
    case phoneVerificationRequired
    case twoFactorRequired

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Backend not configured. Using local mode."
        case .invalidData: "Invalid data provided."
        case .networkError(let msg): msg
        case .phoneVerificationRequired: "Phone verification is required for providers."
        case .twoFactorRequired: "Two-factor authentication is required."
        }
    }
}

nonisolated struct SupabaseProfile: Codable, Sendable {
    let id: String
    var name: String?
    var email: String?
    var phone: String?
    var avatarUrl: String?
    var role: String?
    var zipCode: String?
    var latitude: Double?
    var longitude: Double?
    var bio: String?
    var rating: Double?
    var reviewCount: Int?
    var jobsCompleted: Int?
    var responseRate: Double?
    var isVerified: Bool?
    var verificationStatus: String?
    var insuranceUploaded: Bool?
    var insuranceUrl: String?
    var backgroundCheckPassed: Bool?
    var twoFactorEnabled: Bool?
    var phoneVerified: Bool?
    var stripeAccountId: String?
    var stripeOnboardingComplete: Bool?
    var serviceCategories: [String]?
    var createdAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, name, email, phone, bio, rating, latitude, longitude
        case avatarUrl = "avatar_url"
        case role
        case zipCode = "zip_code"
        case reviewCount = "review_count"
        case jobsCompleted = "jobs_completed"
        case responseRate = "response_rate"
        case isVerified = "is_verified"
        case verificationStatus = "verification_status"
        case insuranceUploaded = "insurance_uploaded"
        case insuranceUrl = "insurance_url"
        case backgroundCheckPassed = "background_check_passed"
        case twoFactorEnabled = "two_factor_enabled"
        case phoneVerified = "phone_verified"
        case stripeAccountId = "stripe_account_id"
        case stripeOnboardingComplete = "stripe_onboarding_complete"
        case serviceCategories = "service_categories"
        case createdAt = "created_at"
    }
}

nonisolated struct SupabaseServiceListing: Codable, Sendable {
    let id: String?
    var providerId: String?
    var providerName: String?
    var providerRating: Double?
    var providerReviewCount: Int?
    var isVerified: Bool?
    var category: String?
    var title: String?
    var description: String?
    var basePrice: Double?
    var priceUnit: String?
    var zipCode: String?
    var latitude: Double?
    var longitude: Double?
    var serviceRadius: Int?
    var imageUrls: [String]?
    var tags: [String]?
    var estimatedDuration: String?
    var isAvailable: Bool?
    var createdAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, category, title, description, tags, latitude, longitude
        case providerId = "provider_id"
        case providerName = "provider_name"
        case providerRating = "provider_rating"
        case providerReviewCount = "provider_review_count"
        case isVerified = "is_verified"
        case basePrice = "base_price"
        case priceUnit = "price_unit"
        case zipCode = "zip_code"
        case serviceRadius = "service_radius"
        case imageUrls = "image_urls"
        case estimatedDuration = "estimated_duration"
        case isAvailable = "is_available"
        case createdAt = "created_at"
    }
}

nonisolated struct SupabaseBooking: Codable, Sendable {
    let id: String?
    var customerId: String?
    var customerName: String?
    var providerId: String?
    var providerName: String?
    var serviceListingId: String?
    var category: String?
    var serviceTitle: String?
    var status: String?
    var scheduledDate: String?
    var scheduledTime: String?
    var address: String?
    var zipCode: String?
    var notes: String?
    var photos: [String]?
    var basePrice: Double?
    var platformFee: Double?
    var providerEarnings: Double?
    var tipAmount: Double?
    var totalPrice: Double?
    var recurrence: String?
    var parentBookingId: String?
    var isTrackingEnabled: Bool?
    var trackingStatus: String?
    var createdAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, category, status, address, notes, photos, recurrence
        case customerId = "customer_id"
        case customerName = "customer_name"
        case providerId = "provider_id"
        case providerName = "provider_name"
        case serviceListingId = "service_listing_id"
        case serviceTitle = "service_title"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case zipCode = "zip_code"
        case basePrice = "base_price"
        case platformFee = "platform_fee"
        case providerEarnings = "provider_earnings"
        case tipAmount = "tip_amount"
        case totalPrice = "total_price"
        case parentBookingId = "parent_booking_id"
        case isTrackingEnabled = "is_tracking_enabled"
        case trackingStatus = "tracking_status"
        case createdAt = "created_at"
    }
}

nonisolated struct SupabaseReview: Codable, Sendable {
    let id: String?
    var bookingId: String?
    var customerId: String?
    var providerId: String?
    var rating: Double?
    var comment: String?
    var createdAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, rating, comment
        case bookingId = "booking_id"
        case customerId = "customer_id"
        case providerId = "provider_id"
        case createdAt = "created_at"
    }
}

nonisolated struct SupabaseConversation: Codable, Sendable {
    let id: String?
    var bookingId: String?
    var customerId: String?
    var providerId: String?
    var lastMessage: String?
    var updatedAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case bookingId = "booking_id"
        case customerId = "customer_id"
        case providerId = "provider_id"
        case lastMessage = "last_message"
        case updatedAt = "updated_at"
    }
}

nonisolated struct SupabaseMessage: Codable, Sendable {
    let id: String?
    var conversationId: String?
    var senderId: String?
    var text: String?
    var createdAt: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case id, text
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case createdAt = "created_at"
    }
}

nonisolated struct SupabaseAvailabilitySlot: Codable, Sendable {
    let id: String?
    var providerId: String?
    var dayOfWeek: Int?
    var startTime: String?
    var endTime: String?
    var isRecurring: Bool?
    var specificDate: String?
    var isBlocked: Bool?

    nonisolated enum CodingKeys: String, CodingKey {
        case id
        case providerId = "provider_id"
        case dayOfWeek = "day_of_week"
        case startTime = "start_time"
        case endTime = "end_time"
        case isRecurring = "is_recurring"
        case specificDate = "specific_date"
        case isBlocked = "is_blocked"
    }
}
