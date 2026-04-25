import SwiftUI
import Observation

@Observable
@MainActor
class ChatViewModel {
    var isLoading = false
    var messageText = ""

    private var dataStore: DataStore { DataStore.shared }

    var conversations: [ChatConversation] { dataStore.conversations }

    func messages(for conversationId: String) -> [ChatMessage] {
        dataStore.messages[conversationId] ?? []
    }

    func loadConversations() async {
        isLoading = true
        defer { isLoading = false }
        try? await Task.sleep(for: .seconds(0.3))
    }

    func sendMessage(conversationId: String, senderId: String, senderName: String) {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let msg = ChatMessage(
            conversationId: conversationId,
            senderId: senderId,
            senderName: senderName,
            text: messageText,
            timestamp: Date(),
            isRead: true
        )
        dataStore.addMessage(msg, to: conversationId)
        messageText = ""
    }

    static let sampleConversations: [ChatConversation] = [
        ChatConversation(
            id: "c1",
            participantIds: ["u1", "p1"],
            participantNames: ["u1": "Alex Johnson", "p1": "Mike's Auto Spa"],
            lastMessage: "I'll be there at 10 AM sharp! 🚗",
            lastMessageDate: Date().addingTimeInterval(-3600),
            unreadCount: 1,
            bookingId: "b1",
            serviceCategory: .carDetailing
        ),
        ChatConversation(
            id: "c2",
            participantIds: ["u1", "p2"],
            participantNames: ["u1": "Alex Johnson", "p2": "GreenScape Pro"],
            lastMessage: "Confirmed for Saturday morning.",
            lastMessageDate: Date().addingTimeInterval(-86400),
            unreadCount: 0,
            bookingId: "b2",
            serviceCategory: .yardMaintenance
        )
    ]

    static let sampleMessages: [String: [ChatMessage]] = [
        "c1": [
            ChatMessage(id: "m1", conversationId: "c1", senderId: "u1", senderName: "Alex Johnson", text: "Hi! I just booked the premium detail. Is the driveway okay to work in?", timestamp: Date().addingTimeInterval(-7200)),
            ChatMessage(id: "m2", conversationId: "c1", senderId: "p1", senderName: "Mike's Auto Spa", text: "Absolutely! A flat driveway is perfect. I'll bring all the equipment and water.", timestamp: Date().addingTimeInterval(-5400)),
            ChatMessage(id: "m3", conversationId: "c1", senderId: "u1", senderName: "Alex Johnson", text: "Great, see you Tuesday!", timestamp: Date().addingTimeInterval(-3700)),
            ChatMessage(id: "m4", conversationId: "c1", senderId: "p1", senderName: "Mike's Auto Spa", text: "I'll be there at 10 AM sharp! 🚗", timestamp: Date().addingTimeInterval(-3600))
        ],
        "c2": [
            ChatMessage(id: "m5", conversationId: "c2", senderId: "p2", senderName: "GreenScape Pro", text: "Hey Alex! Just confirming your weekly lawn service starts this Saturday at 8 AM.", timestamp: Date().addingTimeInterval(-90000)),
            ChatMessage(id: "m6", conversationId: "c2", senderId: "u1", senderName: "Alex Johnson", text: "Perfect, thank you!", timestamp: Date().addingTimeInterval(-87000)),
            ChatMessage(id: "m7", conversationId: "c2", senderId: "p2", senderName: "GreenScape Pro", text: "Confirmed for Saturday morning.", timestamp: Date().addingTimeInterval(-86400))
        ]
    ]
}
