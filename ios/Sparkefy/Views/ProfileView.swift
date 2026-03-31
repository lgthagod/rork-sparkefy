import SwiftUI

struct ProfileView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showStripeOnboarding = false
    @State private var stripeService = StripeService()

    private var user: UserProfile? { appVM.currentUser }

    var body: some View {
        NavigationStack {
            List {
                profileHeader
                roleSection
                if user?.role == .provider {
                    providerSection
                }
                accountSection
                trustSection
                supportSection
                signOutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
        }
    }

    private var profileHeader: some View {
        Section {
            HStack(spacing: 14) {
                Circle()
                    .fill(SparkefyTheme.blueGreenGradient)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(String(user?.name.prefix(1) ?? "?"))
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                    .shadow(color: SparkefyTheme.primaryBlue.opacity(0.2), radius: 6, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.name ?? "Guest")
                        .font(.title3.bold())
                    Text(user?.email ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let user {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(user.rating, format: .number.precision(.fractionLength(1)))
                                .font(.caption.weight(.semibold))
                            Text("(\(user.reviewCount) reviews)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private var roleSection: some View {
        Section {
            Button {
                appVM.switchRole()
            } label: {
                HStack {
                    Label(
                        user?.role == .customer ? "Switch to Provider" : "Switch to Customer",
                        systemImage: user?.role == .customer ? "wrench.and.screwdriver.fill" : "hand.tap.fill"
                    )
                    Spacer()
                    Text(user?.role == .customer ? "Customer" : "Provider")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(SparkefyTheme.primaryBlue.opacity(0.1))
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                        .clipShape(Capsule())
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: user?.role)
        } header: {
            Text("Role")
        }
    }

    private var providerSection: some View {
        Section("Provider Tools") {
            NavigationLink {
                AvailabilityView()
            } label: {
                Label("My Availability", systemImage: "calendar.badge.clock")
            }

            NavigationLink {
                ProviderEarningsView()
            } label: {
                HStack {
                    Label("My Earnings", systemImage: "dollarsign.circle.fill")
                    Spacer()
                    Text("$2,059.50")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SparkefyTheme.accentGreen)
                }
            }

            if stripeService.isConfigured {
                if user?.stripeOnboardingComplete == true {
                    HStack {
                        Label("Bank Account", systemImage: "building.columns.fill")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(SparkefyTheme.accentGreen)
                                .frame(width: 8, height: 8)
                            Text("Connected")
                                .font(.caption)
                                .foregroundStyle(SparkefyTheme.accentGreen)
                        }
                    }
                } else {
                    Button {
                        Task { await startStripeOnboarding() }
                    } label: {
                        HStack {
                            Label("Connect Bank Account", systemImage: "link.badge.plus")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                    Text("Bank payouts will be available when Stripe keys are configured.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(SparkefyTheme.primaryBlue)
                Text("20% platform fee applies. Tips are 100% yours.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            NavigationLink {
                EditProfileView()
            } label: {
                Label("Edit Profile", systemImage: "person.fill")
            }
            NavigationLink { Text("Payment Methods") } label: {
                Label("Payment Methods", systemImage: "creditcard.fill")
            }
            NavigationLink { Text("Addresses") } label: {
                Label("Saved Addresses", systemImage: "mappin.circle.fill")
            }
            NavigationLink { Text("Notifications") } label: {
                Label("Notifications", systemImage: "bell.fill")
            }
        }
    }

    private var trustSection: some View {
        Section("Trust & Safety") {
            HStack {
                Label("ID Verification", systemImage: "person.badge.shield.checkmark.fill")
                Spacer()
                statusIndicator(user?.verificationStatus ?? .unverified)
            }
            HStack {
                Label("2FA Authentication", systemImage: "lock.shield.fill")
                Spacer()
                statusIndicator(user?.twoFactorEnabled == true ? .verified : .unverified)
            }
            if user?.role == .provider {
                HStack {
                    Label("Phone Verified", systemImage: "phone.badge.checkmark")
                    Spacer()
                    statusIndicator(user?.phoneVerified == true ? .verified : .unverified)
                }
                HStack {
                    Label("Insurance", systemImage: "doc.badge.gearshape.fill")
                    Spacer()
                    statusIndicator(user?.insuranceUploaded == true ? .verified : .unverified)
                }
                HStack {
                    Label("Background Check", systemImage: "checkmark.shield.fill")
                    Spacer()
                    statusIndicator(user?.backgroundCheckPassed == true ? .verified : .unverified)
                }
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink { Text("Help Center") } label: {
                Label("Help Center", systemImage: "questionmark.circle.fill")
            }
            NavigationLink { Text("Dispute Resolution") } label: {
                Label("Dispute Resolution", systemImage: "exclamationmark.bubble.fill")
            }
            NavigationLink {
                DatabaseSetupView()
            } label: {
                Label("Database Setup Guide", systemImage: "server.rack")
            }
            NavigationLink { Text("About") } label: {
                Label("About Sparkefy", systemImage: "sparkles")
            }
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                appVM.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func statusIndicator(_ status: VerificationStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status == .verified ? SparkefyTheme.accentGreen : status == .pending ? .orange : Color(.systemFill))
                .frame(width: 8, height: 8)
            Text(status.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func startStripeOnboarding() async {
        guard let email = user?.email else { return }
        if let accountId = await stripeService.createConnectAccount(email: email) {
            if let onboardingURL = await stripeService.getConnectOnboardingURL(accountId: accountId) {
                await MainActor.run {
                    UIApplication.shared.open(onboardingURL)
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var zipCode = ""
    @State private var bio = ""

    var body: some View {
        Form {
            Section("Personal Info") {
                TextField("Full Name", text: $name)
                    .textContentType(.name)
                TextField("Phone", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                TextField("ZIP Code", text: $zipCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numberPad)
            }
            Section("Bio") {
                TextField("Tell customers about yourself...", text: $bio, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    appVM.updateProfile(name: name, phone: phone, zipCode: zipCode, bio: bio)
                    dismiss()
                }
            }
        }
        .onAppear {
            if let user = appVM.currentUser {
                name = user.name
                phone = user.phone
                zipCode = user.zipCode
                bio = user.bio ?? ""
            }
        }
    }
}
