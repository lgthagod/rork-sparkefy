import SwiftUI

struct BookingDetailView: View {
    let booking: Booking
    let isProvider: Bool
    @State private var isTrackingEnabled: Bool
    @State private var showTracking = false

    init(booking: Booking, isProvider: Bool) {
        self.booking = booking
        self.isProvider = isProvider
        self._isTrackingEnabled = State(initialValue: booking.isTrackingEnabled)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statusBanner
                serviceInfoCard
                scheduleCard
                paymentCard

                if booking.status == .confirmed || booking.status == .inProgress {
                    trackingSection
                }

                if isProvider && booking.status == .confirmed {
                    providerActions
                }

                if booking.status == .completed {
                    completedSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTracking) {
            NavigationStack {
                LiveTrackingView(booking: booking)
                    .navigationTitle("Live Tracking")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showTracking = false }
                        }
                    }
            }
        }
    }

    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundStyle(statusColor)
                .symbolEffect(.pulse, isActive: booking.status == .inProgress)

            VStack(alignment: .leading, spacing: 2) {
                Text(booking.status.displayName)
                    .font(.headline)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(booking.status.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .sparkefyCard()
    }

    private var serviceInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(booking.category.color.opacity(0.12))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: booking.category.icon)
                            .font(.title3)
                            .foregroundStyle(booking.category.color)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.serviceTitle)
                        .font(.headline)
                    Text(isProvider ? booking.customerName : booking.providerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if !booking.address.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                    Text(booking.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if !booking.notes.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundStyle(SparkefyTheme.accentGreen)
                    Text(booking.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sparkefyCard()
    }

    private var scheduleCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(SparkefyTheme.primaryBlue)
                Text(booking.formattedDate)
                    .font(.subheadline.weight(.medium))
                Text("Date")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.title3)
                    .foregroundStyle(SparkefyTheme.accentGreen)
                Text(booking.scheduledTime)
                    .font(.subheadline.weight(.medium))
                Text("Time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            if booking.recurrence != .once {
                Divider().frame(height: 40)
                VStack(spacing: 4) {
                    Image(systemName: "repeat")
                        .font(.title3)
                        .foregroundStyle(SparkefyTheme.ctaOrange)
                    Text(booking.recurrence.displayName)
                        .font(.subheadline.weight(.medium))
                    Text("Frequency")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sparkefyCard()
    }

    private var paymentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Payment")
                    .font(.headline)
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.caption)
                    .foregroundStyle(SparkefyTheme.accentGreen)
            }

            Divider()

            if isProvider {
                paymentRow("Job Subtotal", value: booking.basePrice.formatted(.currency(code: "USD")))
                paymentRow("Sparkefy Service Fee (20%)", value: "\u{2212}\(booking.platformFee.formatted(.currency(code: "USD")))", color: .secondary)
                paymentRow("Your Earnings", value: booking.providerEarnings.formatted(.currency(code: "USD")), color: SparkefyTheme.accentGreen, isBold: true)

                if booking.tipAmount > 0 {
                    HStack {
                        HStack(spacing: 4) {
                            Text("Tip Received")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("100% yours")
                                .font(.caption2)
                                .foregroundStyle(SparkefyTheme.accentGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SparkefyTheme.accentGreen.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        Text("+\(booking.tipAmount.formatted(.currency(code: "USD")))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SparkefyTheme.accentGreen)
                    }
                }

                Divider()

                HStack {
                    Text("Total Payout")
                        .font(.headline)
                    Spacer()
                    Text((booking.providerEarnings + booking.tipAmount).formatted(.currency(code: "USD")))
                        .font(.title3.bold())
                        .foregroundStyle(SparkefyTheme.accentGreen)
                }

                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                    Text("Sparkefy takes 20% to run the platform. You keep 80% + 100% of all tips.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(SparkefyTheme.primaryBlue.opacity(0.05))
                .clipShape(.rect(cornerRadius: 8))
            } else {
                HStack {
                    Text("Service Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(booking.basePrice.formatted(.currency(code: "USD")))
                        .font(.subheadline.weight(.medium))
                }

                Text("Includes Sparkefy app service fee (20%)")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))

                if booking.tipAmount > 0 {
                    HStack {
                        HStack(spacing: 4) {
                            Text("Tip")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("100% to provider")
                                .font(.caption2)
                                .foregroundStyle(SparkefyTheme.accentGreen)
                        }
                        Spacer()
                        Text(booking.tipAmount.formatted(.currency(code: "USD")))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SparkefyTheme.accentGreen)
                    }
                }

                Divider()

                HStack {
                    Text("Total Paid")
                        .font(.headline)
                    Spacer()
                    Text(booking.totalPrice.formatted(.currency(code: "USD")))
                        .font(.title3.bold())
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                }
            }
        }
        .sparkefyCard()
    }

    private func paymentRow(_ label: String, value: String, color: Color = .primary, isBold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(color == .primary ? .secondary : color)
            Spacer()
            Text(value)
                .font(.subheadline.weight(isBold ? .semibold : .regular))
                .foregroundStyle(color == .primary ? .primary : color)
        }
    }

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.viewfinder")
                    .font(.title3)
                    .foregroundStyle(SparkefyTheme.primaryBlue)
                Text("Live Tracking")
                    .font(.headline)
                Spacer()
            }

            if isProvider {
                Toggle(isOn: $isTrackingEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share My Location")
                            .font(.subheadline.weight(.medium))
                        Text("Customers can see your real-time location during active jobs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(SparkefyTheme.accentGreen)
                .sensoryFeedback(.impact(weight: .light), trigger: isTrackingEnabled)
                .onChange(of: isTrackingEnabled) { _, _ in
                    DataStore.shared.toggleTracking(id: booking.id)
                }

                HStack(spacing: 6) {
                    Image(systemName: "shield.checkered")
                        .font(.caption)
                        .foregroundStyle(SparkefyTheme.accentGreen)
                    Text("Live tracking helps customers know when you'll arrive. Location shared only during active jobs.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(SparkefyTheme.accentGreen.opacity(0.05))
                .clipShape(.rect(cornerRadius: 8))
            } else {
                if isTrackingEnabled || booking.isTrackingEnabled {
                    Button {
                        showTracking = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "map.fill")
                            Text("View Live Location")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(SparkefyTheme.primaryBlue)
                        .clipShape(.rect(cornerRadius: 12))
                    }

                    HStack(spacing: 8) {
                        Circle()
                            .fill(SparkefyTheme.accentGreen)
                            .frame(width: 8, height: 8)
                        Text("Provider is sharing their location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(.tertiaryLabel))
                            .frame(width: 8, height: 8)
                        Text("Tracking not enabled yet — provider will enable when en route")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sparkefyCard()
    }

    private var providerActions: some View {
        VStack(spacing: 10) {
            Button {
                DataStore.shared.completeBooking(id: booking.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Mark as Complete")
                }
            }
            .buttonStyle(GreenButtonStyle())
            .sensoryFeedback(.success, trigger: booking.status)
        }
    }

    private var completedSection: some View {
        VStack(spacing: 12) {
            if let rating = booking.providerRating {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                }

                if let review = booking.reviewText {
                    Text("\"\(review)\"")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .multilineTextAlignment(.center)
                }
            }

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32))
                .foregroundStyle(SparkefyTheme.accentGreen)

            Text("Job Completed")
                .font(.headline)
                .foregroundStyle(SparkefyTheme.accentGreen)
        }
        .frame(maxWidth: .infinity)
        .sparkefyCard()
    }

    private var statusIcon: String {
        switch booking.status {
        case .pending: "clock.fill"
        case .confirmed: "checkmark.circle.fill"
        case .inProgress: "bolt.fill"
        case .completed: "checkmark.seal.fill"
        case .cancelled: "xmark.circle.fill"
        case .disputed: "exclamationmark.triangle.fill"
        }
    }

    private var statusSubtitle: String {
        switch booking.status {
        case .pending: "Awaiting provider confirmation"
        case .confirmed: "Provider has confirmed the job"
        case .inProgress: "Service is being performed"
        case .completed: "Service has been completed"
        case .cancelled: "This booking was cancelled"
        case .disputed: "Under review by our team"
        }
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
