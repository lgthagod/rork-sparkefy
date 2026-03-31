import SwiftUI

struct ChatListView: View {
    @State private var viewModel = ChatViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ScrollView {
                        ShimmerListView(count: 4)
                            .padding()
                    }
                } else if viewModel.conversations.isEmpty {
                    SparkefyEmptyStateView(
                        icon: "message.badge.circle",
                        title: "No Messages Yet",
                        message: "Start a conversation by booking a service. Your provider will reach out!",
                        actionTitle: "Browse Services"
                    ) { }
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(value: conversation) {
                                ConversationRow(conversation: conversation, currentUserId: "u1")
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Messages")
            .navigationDestination(for: ChatConversation.self) { conversation in
                ChatDetailView(conversation: conversation, viewModel: viewModel)
            }
            .task { await viewModel.loadConversations() }
        }
    }
}

struct ConversationRow: View {
    let conversation: ChatConversation
    let currentUserId: String

    private var otherName: String {
        conversation.participantNames.first(where: { $0.key != currentUserId })?.value ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill((conversation.serviceCategory?.color ?? SparkefyTheme.primaryBlue).opacity(0.12))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(String(otherName.prefix(1)))
                        .font(.title3.bold())
                        .foregroundStyle(conversation.serviceCategory?.color ?? SparkefyTheme.primaryBlue)
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(otherName)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(conversation.lastMessageDate, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(conversation.lastMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(SparkefyTheme.primaryBlue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
