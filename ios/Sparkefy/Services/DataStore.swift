import Foundation
import Observation

@Observable
@MainActor
class DataStore {
    static let shared = DataStore()

    var bookings: [Booking] = []
    var listings: [ServiceListing] = []
    var conversations: [ChatConversation] = []
    var messages: [String: [ChatMessage]] = [:]
    var availabilitySlots: [AvailabilitySlot] = []

    private let bookingsKey = "sparkefy_bookings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var supabase: SupabaseService { SupabaseService.shared }

    private init() {
        loadLocalBookings()
        listings = HomeViewModel.sampleListings
        conversations = ChatViewModel.sampleConversations
        messages = ChatViewModel.sampleMessages
    }

    func addBooking(_ booking: Booking) {
        bookings.insert(booking, at: 0)
        saveLocalBookings()

        if supabase.isConfigured {
            Task {
                try? await supabase.insertBooking(bookingToSupabase(booking))
            }
        }
    }

    func updateBooking(_ booking: Booking) {
        if let idx = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[idx] = booking
            saveLocalBookings()

            if supabase.isConfigured {
                Task {
                    try? await supabase.updateBookingStatus(id: booking.id, status: booking.status.rawValue)
                }
            }
        }
    }

    func cancelBooking(id: String) {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].status = .cancelled
            saveLocalBookings()

            if supabase.isConfigured {
                Task {
                    try? await supabase.updateBookingStatus(id: id, status: "cancelled")
                }
            }
        }
    }

    func acceptBooking(id: String) {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].status = .confirmed
            saveLocalBookings()

            if supabase.isConfigured {
                Task {
                    try? await supabase.updateBookingStatus(id: id, status: "confirmed")
                }
            }
        }
    }

    func completeBooking(id: String) {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].status = .completed
            saveLocalBookings()

            if supabase.isConfigured {
                Task {
                    try? await supabase.updateBookingStatus(id: id, status: "completed")
                }
            }
        }
    }

    func toggleTracking(id: String) {
        if let idx = bookings.firstIndex(where: { $0.id == id }) {
            bookings[idx].isTrackingEnabled.toggle()
            if bookings[idx].isTrackingEnabled {
                bookings[idx].trackingStatus = .enRoute
                bookings[idx].estimatedArrivalMinutes = 12
                bookings[idx].providerLocation = Coordinate(latitude: 34.0722, longitude: -118.4041)
                bookings[idx].jobLocation = Coordinate(latitude: 34.0736, longitude: -118.4004)
            } else {
                bookings[idx].trackingStatus = .idle
                bookings[idx].estimatedArrivalMinutes = nil
                bookings[idx].providerLocation = nil
            }
            saveLocalBookings()
        }
    }

    func addMessage(_ message: ChatMessage, to conversationId: String) {
        messages[conversationId, default: []].append(message)
        if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[idx].lastMessage = message.text
            conversations[idx].lastMessageDate = Date()
        }

        if supabase.isConfigured {
            Task {
                try? await supabase.insertMessage(SupabaseMessage(
                    id: message.id,
                    conversationId: conversationId,
                    senderId: message.senderId,
                    text: message.text
                ))
            }
        }
    }

    func loadSampleBookingsIfNeeded() {
        if bookings.isEmpty {
            bookings = BookingViewModel.sampleBookings
            saveLocalBookings()
        }
    }

    func loadRemoteBookings(userId: String, role: String) async {
        guard supabase.isConfigured else { return }
        do {
            let remote = try await supabase.fetchBookings(userId: userId, role: role)
            let mapped = remote.compactMap { supabaseBookingToLocal($0) }
            if !mapped.isEmpty {
                bookings = mapped
                saveLocalBookings()
            }
        } catch { }
    }

    func loadRemoteListings(category: String? = nil, zipCode: String? = nil) async {
        guard supabase.isConfigured else { return }
        do {
            let remote = try await supabase.fetchServiceListings(category: category, zipCode: zipCode)
            let mapped = remote.compactMap { supabaseListingToLocal($0) }
            if !mapped.isEmpty {
                listings = mapped
            }
        } catch { }
    }

    func saveAvailabilitySlots(_ slots: [AvailabilitySlot], providerId: String) {
        availabilitySlots = slots

        if supabase.isConfigured {
            Task {
                let supaSlots = slots.map { slot in
                    SupabaseAvailabilitySlot(
                        id: slot.id,
                        providerId: providerId,
                        dayOfWeek: slot.dayOfWeek,
                        startTime: slot.startTime,
                        endTime: slot.endTime,
                        isRecurring: slot.isRecurring,
                        isBlocked: slot.isBlocked
                    )
                }
                try? await supabase.upsertAvailabilitySlots(supaSlots)
            }
        }
    }

    func loadAvailabilitySlots(providerId: String) async {
        if supabase.isConfigured {
            do {
                let remote = try await supabase.fetchAvailabilitySlots(providerId: providerId)
                availabilitySlots = remote.map { slot in
                    AvailabilitySlot(
                        id: slot.id ?? UUID().uuidString,
                        providerId: slot.providerId ?? providerId,
                        dayOfWeek: slot.dayOfWeek ?? 1,
                        startTime: slot.startTime ?? "08:00",
                        endTime: slot.endTime ?? "17:00",
                        isRecurring: slot.isRecurring ?? true,
                        isBlocked: slot.isBlocked ?? false
                    )
                }
            } catch { }
        }

        if availabilitySlots.isEmpty {
            availabilitySlots = defaultAvailabilitySlots(providerId: providerId)
        }
    }

    private func defaultAvailabilitySlots(providerId: String) -> [AvailabilitySlot] {
        (2...6).map { day in
            AvailabilitySlot(
                providerId: providerId,
                dayOfWeek: day,
                startTime: "08:00",
                endTime: "17:00",
                isRecurring: true
            )
        }
    }

    private func saveLocalBookings() {
        if let data = try? encoder.encode(bookings) {
            UserDefaults.standard.set(data, forKey: bookingsKey)
        }
    }

    private func loadLocalBookings() {
        guard let data = UserDefaults.standard.data(forKey: bookingsKey),
              let saved = try? decoder.decode([Booking].self, from: data) else {
            return
        }
        bookings = saved
    }

    private func bookingToSupabase(_ booking: Booking) -> SupabaseBooking {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return SupabaseBooking(
            id: booking.id,
            customerId: booking.customerId,
            customerName: booking.customerName,
            providerId: booking.providerId,
            providerName: booking.providerName,
            serviceListingId: booking.serviceListingId,
            category: booking.category.rawValue,
            serviceTitle: booking.serviceTitle,
            status: booking.status.rawValue,
            scheduledDate: dateFormatter.string(from: booking.scheduledDate),
            scheduledTime: booking.scheduledTime,
            address: booking.address,
            zipCode: booking.zipCode,
            notes: booking.notes,
            basePrice: booking.basePrice,
            platformFee: booking.platformFee,
            providerEarnings: booking.providerEarnings,
            tipAmount: booking.tipAmount,
            totalPrice: booking.totalPrice,
            recurrence: booking.recurrence.rawValue
        )
    }

    private func supabaseBookingToLocal(_ sb: SupabaseBooking) -> Booking? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: sb.scheduledDate ?? "") ?? Date()

        return Booking(
            id: sb.id ?? UUID().uuidString,
            customerId: sb.customerId ?? "",
            customerName: sb.customerName ?? "",
            providerId: sb.providerId ?? "",
            providerName: sb.providerName ?? "",
            serviceListingId: sb.serviceListingId ?? "",
            category: ServiceCategory(rawValue: sb.category ?? "") ?? .carDetailing,
            serviceTitle: sb.serviceTitle ?? "",
            status: BookingStatus(rawValue: sb.status ?? "") ?? .pending,
            scheduledDate: date,
            scheduledTime: sb.scheduledTime ?? "",
            address: sb.address ?? "",
            zipCode: sb.zipCode ?? "",
            notes: sb.notes ?? "",
            basePrice: sb.basePrice ?? 0,
            platformFee: sb.platformFee ?? 0,
            providerEarnings: sb.providerEarnings ?? 0,
            tipAmount: sb.tipAmount ?? 0,
            totalPrice: sb.totalPrice ?? 0,
            recurrence: RecurrenceType(rawValue: sb.recurrence ?? "") ?? .once,
            createdAt: Date()
        )
    }

    private func supabaseListingToLocal(_ sl: SupabaseServiceListing) -> ServiceListing? {
        ServiceListing(
            id: sl.id ?? UUID().uuidString,
            providerId: sl.providerId ?? "",
            providerName: sl.providerName ?? "",
            providerRating: sl.providerRating ?? 0,
            providerReviewCount: sl.providerReviewCount ?? 0,
            isVerified: sl.isVerified ?? false,
            category: ServiceCategory(rawValue: sl.category ?? "") ?? .carDetailing,
            title: sl.title ?? "",
            description: sl.description ?? "",
            basePrice: sl.basePrice ?? 0,
            priceUnit: sl.priceUnit ?? "per service",
            zipCode: sl.zipCode ?? "",
            latitude: sl.latitude,
            longitude: sl.longitude,
            serviceRadius: sl.serviceRadius ?? 15,
            imageURLs: sl.imageUrls ?? [],
            tags: sl.tags ?? [],
            estimatedDuration: sl.estimatedDuration ?? "",
            isAvailable: sl.isAvailable ?? true,
            createdAt: Date()
        )
    }
}
