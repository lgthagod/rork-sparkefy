import SwiftUI

struct BookingFlowView: View {
    let listing: ServiceListing
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appVM
    @State private var selectedDate = Date()
    @State private var selectedTime = "10:00 AM"
    @State private var address = ""
    @State private var notes = ""
    @State private var recurrence: RecurrenceType = .once
    @State private var tipPercentage: Int = 0
    @State private var step: BookingStep = .schedule
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var paymentService = PaymentService()
    @State private var stripeService = StripeService()
    @State private var availableSlots: [AvailabilitySlot] = []
    @State private var availableTimesForDate: [String] = []

    private let defaultTimeSlots = ["8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM", "12:00 PM", "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM"]
    private let tipOptions = [0, 10, 15, 20, 25]

    private var breakdown: PaymentBreakdown {
        paymentService.calculateBreakdown(servicePrice: listing.basePrice, tipPercentage: tipPercentage)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                stepIndicator
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 20) {
                        switch step {
                        case .schedule: scheduleStep
                        case .details: detailsStep
                        case .confirm: confirmStep
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)

                bottomAction
            }
            .navigationTitle("Book Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationContentInteraction(.scrolls)
            .overlay {
                if showSuccess {
                    successOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .task {
                await loadAvailability()
            }
            .onChange(of: selectedDate) { _, _ in
                updateTimeSlotsForDate()
            }
        }
    }

    private func loadAvailability() async {
        await DataStore.shared.loadAvailabilitySlots(providerId: listing.providerId)
        availableSlots = DataStore.shared.availabilitySlots
        updateTimeSlotsForDate()
    }

    private func updateTimeSlotsForDate() {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: selectedDate)

        let daySlots = availableSlots.filter { $0.dayOfWeek == dayOfWeek && !$0.isBlocked }

        if daySlots.isEmpty {
            availableTimesForDate = defaultTimeSlots
            return
        }

        var times: [String] = []
        for slot in daySlots {
            let startParts = slot.startTime.split(separator: ":")
            let endParts = slot.endTime.split(separator: ":")
            guard let startHour = Int(startParts.first ?? "8"),
                  let endHour = Int(endParts.first ?? "17") else { continue }

            for hour in startHour..<endHour {
                let ampm = hour >= 12 ? "PM" : "AM"
                let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                times.append("\(h):00 \(ampm)")
            }
        }

        availableTimesForDate = times.isEmpty ? defaultTimeSlots : times

        if !availableTimesForDate.contains(selectedTime), let first = availableTimesForDate.first {
            selectedTime = first
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(BookingStep.allCases, id: \.self) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? SparkefyTheme.primaryBlue : Color(.systemFill))
                    .frame(height: 4)
                    .animation(.spring(duration: 0.3), value: step)
            }
        }
        .padding(.horizontal)
    }

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick a Date & Time")
                .font(.title3.bold())

            DatePicker("Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(SparkefyTheme.primaryBlue)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Available Times")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if availableTimesForDate.count < defaultTimeSlots.count {
                        Text("Based on provider schedule")
                            .font(.caption2)
                            .foregroundStyle(SparkefyTheme.accentGreen)
                    }
                }

                if availableTimesForDate.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundStyle(.orange)
                        Text("Provider is not available on this date. Please choose another day.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 10))
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                        ForEach(availableTimesForDate, id: \.self) { time in
                            Button {
                                selectedTime = time
                            } label: {
                                Text(time)
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedTime == time ? SparkefyTheme.primaryBlue : Color(.tertiarySystemGroupedBackground))
                                    .foregroundStyle(selectedTime == time ? .white : .primary)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                            .sensoryFeedback(.selection, trigger: selectedTime)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Frequency")
                    .font(.subheadline.weight(.medium))

                Picker("Recurrence", selection: $recurrence) {
                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Location")
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                    TextField("Street address", text: $address)
                        .textContentType(.fullStreetAddress)
                }
                .padding(14)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes for Provider")
                    .font(.subheadline.weight(.medium))
                TextField("Gate code, parking instructions, etc.", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review & Confirm")
                .font(.title3.bold())

            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(listing.category.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: listing.category.icon)
                                .foregroundStyle(listing.category.color)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(listing.title)
                            .font(.subheadline.weight(.semibold))
                        Text(listing.providerName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                infoRow("Date", value: selectedDate.formatted(date: .abbreviated, time: .omitted))
                infoRow("Time", value: selectedTime)
                infoRow("Address", value: address.isEmpty ? "Not set" : address)
                if recurrence != .once {
                    infoRow("Frequency", value: recurrence.displayName)
                }

                Divider()

                VStack(spacing: 8) {
                    HStack {
                        Text("Service Price")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(breakdown.formattedServicePrice)
                            .font(.headline)
                    }

                    Text("Includes Sparkefy app service fee (20%)")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(SparkefyTheme.accentGreen)
                        Text("Tip (100% goes directly to the provider)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        ForEach(tipOptions, id: \.self) { pct in
                            Button {
                                tipPercentage = pct
                            } label: {
                                Text(pct == 0 ? "None" : "\(pct)%")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(tipPercentage == pct ? SparkefyTheme.accentGreen : Color(.tertiarySystemGroupedBackground))
                                    .foregroundStyle(tipPercentage == pct ? .white : .primary)
                                    .clipShape(.rect(cornerRadius: 10))
                            }
                            .sensoryFeedback(.selection, trigger: tipPercentage)
                        }
                    }

                    if breakdown.tipAmount > 0 {
                        HStack {
                            Text("Tip (\(tipPercentage)%)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(breakdown.formattedTipAmount)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(SparkefyTheme.accentGreen)
                        }
                    }
                }

                Divider()

                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(breakdown.formattedCustomerTotal)
                        .font(.title3.bold())
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                }
            }
            .sparkefyCard()

            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(SparkefyTheme.accentGreen)
                Text("Secure payment powered by Stripe")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                switch step {
                case .schedule:
                    withAnimation(.spring(duration: 0.35)) { step = .details }
                case .details:
                    withAnimation(.spring(duration: 0.35)) { step = .confirm }
                case .confirm:
                    submitBooking()
                }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            if step == .confirm {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                            }
                            Text(step == .confirm ? "Pay \(breakdown.formattedCustomerTotal)" : "Continue")
                        }
                    }
                }
            }
            .buttonStyle(SparkefyButtonStyle())
            .disabled(isSubmitting || (step == .schedule && availableTimesForDate.isEmpty))
            .padding()
            .sensoryFeedback(.impact(weight: .medium), trigger: step)
        }
        .background(.bar)
    }

    private var successOverlay: some View {
        ZStack {
            Color(.systemBackground).opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(SparkefyTheme.accentGreen.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(SparkefyTheme.accentGreen)
                }

                VStack(spacing: 8) {
                    Text("Booking Confirmed!")
                        .font(.title2.bold())
                    Text("Your \(listing.category.displayName.lowercased()) service is scheduled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    receiptRow("Service Price", value: breakdown.formattedServicePrice)

                    Text("Includes Sparkefy app service fee (20%)")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                    if breakdown.tipAmount > 0 {
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
                            Text(breakdown.formattedTipAmount)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(SparkefyTheme.accentGreen)
                        }
                        .padding(.horizontal, 4)
                    }

                    Divider()
                        .padding(.horizontal, 4)

                    HStack {
                        Text("Total Paid")
                            .font(.headline)
                        Spacer()
                        Text(breakdown.formattedCustomerTotal)
                            .font(.title3.bold())
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
                .padding(.horizontal, 32)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(SparkefyButtonStyle())
                .padding(.horizontal, 40)
            }
        }
    }

    private func receiptRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 4)
    }

    private func submitBooking() {
        isSubmitting = true
        Task {
            let success = await paymentService.processPayment(breakdown: breakdown, stripeService: stripeService)
            isSubmitting = false
            if success {
                let fees = Booking.calculateFees(basePrice: listing.basePrice)
                let newBooking = Booking(
                    customerId: appVM.currentUser?.id ?? "u1",
                    customerName: appVM.currentUser?.name ?? "Customer",
                    providerId: listing.providerId,
                    providerName: listing.providerName,
                    serviceListingId: listing.id,
                    category: listing.category,
                    serviceTitle: listing.title,
                    status: .pending,
                    scheduledDate: selectedDate,
                    scheduledTime: selectedTime,
                    address: address,
                    zipCode: appVM.currentUser?.zipCode ?? "90210",
                    notes: notes,
                    basePrice: listing.basePrice,
                    platformFee: fees.platformFee,
                    providerEarnings: fees.providerEarnings,
                    tipAmount: breakdown.tipAmount,
                    totalPrice: breakdown.customerTotal,
                    recurrence: recurrence,
                    createdAt: Date()
                )
                DataStore.shared.addBooking(newBooking)

                if recurrence != .once {
                    createRecurringBookings(from: newBooking)
                }

                withAnimation(.spring(duration: 0.5)) {
                    showSuccess = true
                }
                appVM.showToast("Booking confirmed!")
            }
        }
    }

    private func createRecurringBookings(from booking: Booking) {
        let calendar = Calendar.current
        let interval: Int = {
            switch recurrence {
            case .weekly: return 7
            case .biweekly: return 14
            case .monthly: return 30
            case .once: return 0
            }
        }()
        guard interval > 0 else { return }

        for i in 1...3 {
            guard let futureDate = calendar.date(byAdding: .day, value: interval * i, to: booking.scheduledDate) else { continue }
            var recurring = booking
            recurring = Booking(
                id: UUID().uuidString,
                customerId: booking.customerId,
                customerName: booking.customerName,
                providerId: booking.providerId,
                providerName: booking.providerName,
                serviceListingId: booking.serviceListingId,
                category: booking.category,
                serviceTitle: booking.serviceTitle,
                status: .pending,
                scheduledDate: futureDate,
                scheduledTime: booking.scheduledTime,
                address: booking.address,
                zipCode: booking.zipCode,
                notes: booking.notes,
                basePrice: booking.basePrice,
                platformFee: booking.platformFee,
                providerEarnings: booking.providerEarnings,
                tipAmount: 0,
                totalPrice: booking.basePrice,
                recurrence: recurrence,
                parentBookingId: booking.id
            )
            DataStore.shared.addBooking(recurring)
        }
    }
}

nonisolated enum BookingStep: Int, CaseIterable, Sendable {
    case schedule = 0
    case details = 1
    case confirm = 2
}
