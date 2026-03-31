import SwiftUI

struct BookingsView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = BookingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                bookingsList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Bookings")
            .task {
                await viewModel.loadBookings(
                    userId: appVM.currentUser?.id,
                    role: appVM.currentUser?.role.rawValue
                )
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(BookingFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(duration: 0.3)) { viewModel.selectedFilter = filter }
                } label: {
                    Text(filter.rawValue)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedFilter == filter ? SparkefyTheme.primaryBlue : Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(viewModel.selectedFilter == filter ? .white : .primary)
                        .clipShape(Capsule())
                }
                .sensoryFeedback(.selection, trigger: viewModel.selectedFilter)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var bookingsList: some View {
        ScrollView {
            if viewModel.isLoading {
                ShimmerListView(count: 3)
                    .padding(.horizontal)
                    .padding(.top, 4)
            } else if viewModel.filteredBookings.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredBookings) { booking in
                        NavigationLink(value: booking) {
                            BookingCard(
                                booking: booking,
                                isProvider: appVM.currentUser?.role == .provider,
                                onCancel: { viewModel.cancelBooking(booking) },
                                onAccept: appVM.currentUser?.role == .provider ? { viewModel.acceptBooking(booking) } : nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }
        }
        .navigationDestination(for: Booking.self) { booking in
            BookingDetailView(booking: booking, isProvider: appVM.currentUser?.role == .provider)
        }
    }

    private var emptyState: some View {
        SparkefyEmptyStateView(
            icon: emptyStateIcon,
            title: emptyStateTitle,
            message: emptyStateMessage,
            actionTitle: viewModel.selectedFilter == .upcoming ? "Browse Services" : nil,
            action: viewModel.selectedFilter == .upcoming ? { appVM.selectedTab = .services } : nil
        )
        .frame(minHeight: 400)
    }

    private var emptyStateIcon: String {
        switch viewModel.selectedFilter {
        case .upcoming: "calendar.badge.plus"
        case .completed: "checkmark.circle"
        case .cancelled: "xmark.circle"
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .upcoming: "No Upcoming Jobs"
        case .completed: "No Completed Jobs"
        case .cancelled: "No Cancelled Jobs"
        }
    }

    private var emptyStateMessage: String {
        switch viewModel.selectedFilter {
        case .upcoming: "Browse services and book your first job — it only takes 3 taps!"
        case .completed: "Completed jobs will appear here after your service is done."
        case .cancelled: "No cancellations — that's great!"
        }
    }
}

struct BookingCard: View {
    let booking: Booking
    let isProvider: Bool
    let onCancel: () -> Void
    var onAccept: (() -> Void)? = nil
    @State private var showCancel = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(booking.category.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: booking.category.icon)
                            .foregroundStyle(booking.category.color)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.serviceTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(isProvider ? booking.customerName : booking.providerName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge
            }

            Divider()

            HStack(spacing: 16) {
                Label(booking.formattedDate, systemImage: "calendar")
                Label(booking.scheduledTime, systemImage: "clock")
                Spacer()
                Text(booking.formattedTotal)
                    .font(.subheadline.bold())
                    .foregroundStyle(SparkefyTheme.primaryBlue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if booking.recurrence != .once {
                Label(booking.recurrence.displayName, systemImage: "repeat")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SparkefyTheme.accentGreen)
            }

            if booking.isTrackingEnabled && (booking.status == .confirmed || booking.status == .inProgress) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(SparkefyTheme.accentGreen)
                        .frame(width: 6, height: 6)
                    Text("Live tracking active")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(SparkefyTheme.accentGreen)
                }
            }

            if booking.status == .completed, let rating = booking.providerRating {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if let review = booking.reviewText {
                        Text("— \(review)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            if isProvider && booking.status == .pending {
                HStack(spacing: 8) {
                    Button {
                        onAccept?()
                    } label: {
                        Label("Accept", systemImage: "checkmark")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(SparkefyTheme.accentGreen)

                    Button(role: .destructive) {
                        showCancel = true
                    } label: {
                        Label("Decline", systemImage: "xmark")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
            } else if booking.status == .pending || booking.status == .confirmed {
                HStack(spacing: 8) {
                    Button { } label: {
                        Label("Message", systemImage: "message")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(SparkefyTheme.primaryBlue)

                    Button(role: .destructive) {
                        showCancel = true
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.caption.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .sparkefyCard()
        .confirmationDialog("Cancel Booking?", isPresented: $showCancel, titleVisibility: .visible) {
            Button("Cancel Booking", role: .destructive, action: onCancel)
            Button("Keep Booking", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: showCancel)
    }

    private var statusBadge: some View {
        Text(booking.status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.12))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending: .orange
        case .confirmed: SparkefyTheme.primaryBlue
        case .inProgress: SparkefyTheme.accentGreen
        case .completed: SparkefyTheme.accentGreen
        case .cancelled: .secondary
        case .disputed: SparkefyTheme.errorRed
        }
    }
}
