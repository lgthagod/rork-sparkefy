import SwiftUI

struct ChatDetailView: View {
    let conversation: ChatConversation
    @Bindable var viewModel: ChatViewModel
    private let currentUserId = "u1"

    private var otherName: String {
        conversation.participantNames.first(where: { $0.key != currentUserId })?.value ?? "Unknown"
    }

    private var messages: [ChatMessage] {
        viewModel.messages(for: conversation.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            isCurrentUser: message.senderId == currentUserId
                        )
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)

            Divider()
            inputBar
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $viewModel.messageText, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 20))

            Button {
                viewModel.sendMessage(
                    conversationId: conversation.id,
                    senderId: currentUserId,
                    senderName: "Alex Johnson"
                )
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SparkefyTheme.primaryBlue)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .sensoryFeedback(.impact(weight: .light), trigger: messages.count)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer(minLength: 60) }

            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? SparkefyTheme.primaryBlue : Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadii: .init(
                        topLeading: 16,
                        bottomLeading: isCurrentUser ? 16 : 4,
                        bottomTrailing: isCurrentUser ? 4 : 16,
                        topTrailing: 16
                    )))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}
