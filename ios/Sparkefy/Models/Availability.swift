import Foundation

nonisolated struct AvailabilitySlot: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var providerId: String
    var dayOfWeek: Int
    var startTime: String
    var endTime: String
    var isRecurring: Bool
    var specificDate: Date?
    var isBlocked: Bool

    init(
        id: String = UUID().uuidString,
        providerId: String = "",
        dayOfWeek: Int = 1,
        startTime: String = "08:00",
        endTime: String = "17:00",
        isRecurring: Bool = true,
        specificDate: Date? = nil,
        isBlocked: Bool = false
    ) {
        self.id = id
        self.providerId = providerId
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.isRecurring = isRecurring
        self.specificDate = specificDate
        self.isBlocked = isBlocked
    }

    var dayName: String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        guard dayOfWeek >= 1, dayOfWeek <= 7 else { return "Unknown" }
        return days[dayOfWeek]
    }

    var shortDayName: String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard dayOfWeek >= 1, dayOfWeek <= 7 else { return "?" }
        return days[dayOfWeek]
    }

    var displayTimeRange: String {
        "\(formatTime(startTime)) – \(formatTime(endTime))"
    }

    private func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count >= 2, let hour = Int(parts[0]) else { return time }
        let minute = parts[1]
        let ampm = hour >= 12 ? "PM" : "AM"
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h):\(minute) \(ampm)"
    }
}

nonisolated struct BlockedDate: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var providerId: String
    var date: Date
    var reason: String?

    init(
        id: String = UUID().uuidString,
        providerId: String = "",
        date: Date = Date(),
        reason: String? = nil
    ) {
        self.id = id
        self.providerId = providerId
        self.date = date
        self.reason = reason
    }
}
