import Foundation

nonisolated struct ChatConversation: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var participantIds: [String]
    var participantNames: [String: String]
    var participantAvatars: [String: String]
    var lastMessage: String
    var lastMessageDate: Date
    var unreadCount: Int
    var bookingId: String?
    var serviceCategory: ServiceCategory?

    init(
        id: String = UUID().uuidString,
        participantIds: [String] = [],
        participantNames: [String: String] = [:],
        participantAvatars: [String: String] = [:],
        lastMessage: String = "",
        lastMessageDate: Date = Date(),
        unreadCount: Int = 0,
        bookingId: String? = nil,
        serviceCategory: ServiceCategory? = nil
    ) {
        self.id = id
        self.participantIds = participantIds
        self.participantNames = participantNames
        self.participantAvatars = participantAvatars
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.bookingId = bookingId
        self.serviceCategory = serviceCategory
    }
}

nonisolated struct ChatMessage: Codable, Sendable, Identifiable, Hashable {
    let id: String
    var conversationId: String
    var senderId: String
    var senderName: String
    var text: String
    var imageURL: String?
    var timestamp: Date
    var isRead: Bool

    init(
        id: String = UUID().uuidString,
        conversationId: String = "",
        senderId: String = "",
        senderName: String = "",
        text: String = "",
        imageURL: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.imageURL = imageURL
        self.timestamp = timestamp
        self.isRead = isRead
    }
}
