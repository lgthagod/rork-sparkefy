import SwiftUI

struct AvailabilityView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var slots: [AvailabilitySlot] = []
    @State private var isLoading = true
    @State private var showAddSlot = false
    @State private var blockedDates: [Date] = []
    @State private var showDatePicker = false
    @State private var dateToBlock = Date()

    private var providerId: String { appVM.currentUser?.id ?? "" }

    var body: some View {
        List {
            Section {
                ForEach(1...7, id: \.self) { day in
                    let daySlots = slots.filter { $0.dayOfWeek == day && !$0.isBlocked }
                    if !daySlots.isEmpty {
                        ForEach(daySlots) { slot in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(slot.dayName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(slot.displayTimeRange)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if slot.isRecurring {
                                    Label("Weekly", systemImage: "repeat")
                                        .font(.caption2)
                                        .foregroundStyle(SparkefyTheme.accentGreen)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    removeSlot(slot)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                if slots.filter({ !$0.isBlocked }).isEmpty && !isLoading {
                    HStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundStyle(.secondary)
                        Text("No availability set. Add your schedule below.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Weekly Schedule")
            }

            Section {
                Button {
                    showAddSlot = true
                } label: {
                    Label("Add Time Slot", systemImage: "plus.circle.fill")
                }

                Button {
                    addDefaultSchedule()
                } label: {
                    Label("Set Default Mon–Fri 8AM–5PM", systemImage: "calendar.badge.clock")
                }
            }

            Section("Block Dates") {
                Button {
                    showDatePicker = true
                } label: {
                    Label("Block a Date", systemImage: "calendar.badge.minus")
                        .foregroundStyle(SparkefyTheme.errorRed)
                }

                ForEach(blockedDates, id: \.self) { date in
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(SparkefyTheme.errorRed)
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("My Availability")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await DataStore.shared.loadAvailabilitySlots(providerId: providerId)
            slots = DataStore.shared.availabilitySlots
            isLoading = false
        }
        .sheet(isPresented: $showAddSlot) {
            AddSlotSheet(providerId: providerId) { newSlot in
                slots.append(newSlot)
                saveSlots()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker("Select Date", selection: $dateToBlock, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(SparkefyTheme.errorRed)
                    .padding()
                    .navigationTitle("Block a Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showDatePicker = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Block") {
                                blockedDates.append(dateToBlock)
                                showDatePicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    private func removeSlot(_ slot: AvailabilitySlot) {
        slots.removeAll { $0.id == slot.id }
        saveSlots()
        if SupabaseService.shared.isConfigured {
            Task { try? await SupabaseService.shared.deleteAvailabilitySlot(id: slot.id) }
        }
    }

    private func addDefaultSchedule() {
        let newSlots = (2...6).map { day in
            AvailabilitySlot(
                providerId: providerId,
                dayOfWeek: day,
                startTime: "08:00",
                endTime: "17:00",
                isRecurring: true
            )
        }
        slots = newSlots
        saveSlots()
    }

    private func saveSlots() {
        DataStore.shared.saveAvailabilitySlots(slots, providerId: providerId)
    }
}

struct AddSlotSheet: View {
    let providerId: String
    let onAdd: (AvailabilitySlot) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay = 2
    @State private var startTime = "08:00"
    @State private var endTime = "17:00"

    private let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    private let timeOptions = [
        "06:00", "07:00", "08:00", "09:00", "10:00", "11:00",
        "12:00", "13:00", "14:00", "15:00", "16:00", "17:00",
        "18:00", "19:00", "20:00"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Picker("Day", selection: $selectedDay) {
                    ForEach(1...7, id: \.self) { day in
                        Text(dayNames[day]).tag(day)
                    }
                }

                Picker("Start Time", selection: $startTime) {
                    ForEach(timeOptions, id: \.self) { time in
                        Text(formatTime(time)).tag(time)
                    }
                }

                Picker("End Time", selection: $endTime) {
                    ForEach(timeOptions, id: \.self) { time in
                        Text(formatTime(time)).tag(time)
                    }
                }
            }
            .navigationTitle("Add Time Slot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let slot = AvailabilitySlot(
                            providerId: providerId,
                            dayOfWeek: selectedDay,
                            startTime: startTime,
                            endTime: endTime,
                            isRecurring: true
                        )
                        onAdd(slot)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard let hour = Int(parts.first ?? "") else { return time }
        let ampm = hour >= 12 ? "PM" : "AM"
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h):00 \(ampm)"
    }
}
