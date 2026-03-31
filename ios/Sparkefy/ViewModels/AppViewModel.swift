import SwiftUI
import Supabase

@Observable
@MainActor
class AppViewModel {
    var isAuthenticated = false
    var currentUser: UserProfile?
    var hasCompletedOnboarding = false
    var selectedTab: AppTab = .home
    var isLoading = false
    var toastMessage: String?
    var showToast = false
    var requires2FA = false
    var pendingPhoneForOTP: String?

    private let userKey = "sparkefy_current_user"
    private let authKey = "sparkefy_is_authenticated"

    init() {
        restoreLocalAuth()
    }

    func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.snappy) { showToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.snappy) { showToast = false }
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }

        let supabase = SupabaseService.shared
        if supabase.isConfigured {
            do {
                try await supabase.signIn(email: email, password: password)
                let userId = supabase.currentUserId ?? UUID().uuidString
                let metaName = supabase.currentSession?.user.userMetadata["full_name"]
                let displayName: String = {
                    if case .string(let n) = metaName { return n }
                    return email.components(separatedBy: "@").first ?? "User"
                }()

                var profile = UserProfile(
                    id: userId,
                    name: displayName,
                    email: email,
                    role: .customer,
                    createdAt: Date()
                )

                if let remote = try? await supabase.fetchProfile(userId: userId) {
                    profile = profileFromSupabase(remote, fallback: profile)
                }

                if profile.role == .provider && !profile.twoFactorEnabled {
                    currentUser = profile
                    requires2FA = true
                    persistAuth()
                    return
                }

                currentUser = profile
                persistAuth()
                isAuthenticated = true
                DataStore.shared.loadSampleBookingsIfNeeded()
                return
            } catch {
                showToast("Sign in failed: \(error.localizedDescription)")
            }
        }

        try? await Task.sleep(for: .seconds(0.8))
        currentUser = UserProfile(
            id: UUID().uuidString,
            name: email.components(separatedBy: "@").first?.capitalized ?? "User",
            email: email,
            phone: "(555) 123-4567",
            role: .customer,
            zipCode: "90210",
            rating: 4.8,
            reviewCount: 12,
            createdAt: Date()
        )
        persistAuth()
        isAuthenticated = true
        hasCompletedOnboarding = true
        DataStore.shared.loadSampleBookingsIfNeeded()
    }

    func signUp(name: String, email: String, password: String, role: UserRole) async {
        isLoading = true
        defer { isLoading = false }

        let supabase = SupabaseService.shared
        if supabase.isConfigured {
            do {
                let userId = try await supabase.signUp(email: email, password: password, name: name)
                let profile = UserProfile(
                    id: userId,
                    name: name,
                    email: email,
                    role: role,
                    createdAt: Date()
                )
                currentUser = profile
                persistAuth()

                try? await supabase.upsertProfile(SupabaseProfile(
                    id: userId,
                    name: name,
                    email: email,
                    role: role.rawValue
                ))

                if role == .provider {
                    requires2FA = true
                    return
                }

                isAuthenticated = true
                hasCompletedOnboarding = true
                DataStore.shared.loadSampleBookingsIfNeeded()
                showToast("Welcome to Sparkefy!")
                return
            } catch {
                showToast("Sign up failed: \(error.localizedDescription)")
            }
        }

        try? await Task.sleep(for: .seconds(0.8))
        currentUser = UserProfile(
            id: UUID().uuidString,
            name: name,
            email: email,
            role: role,
            zipCode: "",
            createdAt: Date()
        )
        persistAuth()
        isAuthenticated = true
        hasCompletedOnboarding = true
        DataStore.shared.loadSampleBookingsIfNeeded()
        showToast("Welcome to Sparkefy!")
    }

    func sendPhoneOTP(phone: String) async -> Bool {
        let supabase = SupabaseService.shared
        guard supabase.isConfigured else {
            complete2FASetup()
            return true
        }
        do {
            try await supabase.sendPhoneOTP(phone: phone)
            pendingPhoneForOTP = phone
            return true
        } catch {
            showToast("Failed to send code: \(error.localizedDescription)")
            return false
        }
    }

    func verifyPhoneOTP(code: String) async -> Bool {
        let supabase = SupabaseService.shared
        guard supabase.isConfigured, let phone = pendingPhoneForOTP else {
            complete2FASetup()
            return true
        }
        do {
            try await supabase.verifyPhoneOTP(phone: phone, code: code)
            complete2FASetup()
            return true
        } catch {
            showToast("Invalid code. Please try again.")
            return false
        }
    }

    func skip2FA() {
        complete2FASetup()
    }

    private func complete2FASetup() {
        guard var user = currentUser else { return }
        user.twoFactorEnabled = true
        user.phoneVerified = true
        currentUser = user
        requires2FA = false
        isAuthenticated = true
        hasCompletedOnboarding = true
        persistAuth()

        if SupabaseService.shared.isConfigured {
            Task {
                try? await SupabaseService.shared.upsertProfile(SupabaseProfile(
                    id: user.id,
                    twoFactorEnabled: true,
                    phoneVerified: true
                ))
            }
        }

        DataStore.shared.loadSampleBookingsIfNeeded()
        showToast("Welcome to Sparkefy!")
    }

    func signOut() {
        Task {
            try? await SupabaseService.shared.signOut()
        }
        clearAuth()
        withAnimation(.snappy) {
            isAuthenticated = false
            currentUser = nil
            selectedTab = .home
            requires2FA = false
        }
    }

    func switchRole() {
        guard var user = currentUser else { return }
        user.role = user.role == .customer ? .provider : .customer
        currentUser = user
        persistAuth()

        if SupabaseService.shared.isConfigured {
            Task {
                try? await SupabaseService.shared.upsertProfile(SupabaseProfile(
                    id: user.id,
                    role: user.role.rawValue
                ))
            }
        }

        showToast("Switched to \(user.role == .customer ? "Customer" : "Provider") mode")
    }

    func updateProfile(name: String, phone: String, zipCode: String, bio: String) {
        guard var user = currentUser else { return }
        user.name = name
        user.phone = phone
        user.zipCode = zipCode
        user.bio = bio
        currentUser = user
        persistAuth()

        LocationService.shared.updateZipCode(zipCode)

        if SupabaseService.shared.isConfigured {
            Task {
                try? await SupabaseService.shared.upsertProfile(SupabaseProfile(
                    id: user.id,
                    name: name,
                    phone: phone,
                    zipCode: zipCode,
                    bio: bio
                ))
            }
        }

        showToast("Profile updated")
    }

    func syncProfileFromRemote() async {
        guard let userId = currentUser?.id, SupabaseService.shared.isConfigured else { return }
        do {
            if let remote = try await SupabaseService.shared.fetchProfile(userId: userId) {
                currentUser = profileFromSupabase(remote, fallback: currentUser!)
                persistAuth()
            }
        } catch { }
    }

    private func profileFromSupabase(_ sp: SupabaseProfile, fallback: UserProfile) -> UserProfile {
        UserProfile(
            id: sp.id,
            name: sp.name ?? fallback.name,
            email: sp.email ?? fallback.email,
            phone: sp.phone ?? fallback.phone,
            avatarURL: sp.avatarUrl ?? fallback.avatarURL,
            role: UserRole(rawValue: sp.role ?? "") ?? fallback.role,
            zipCode: sp.zipCode ?? fallback.zipCode,
            latitude: sp.latitude ?? fallback.latitude,
            longitude: sp.longitude ?? fallback.longitude,
            rating: sp.rating ?? fallback.rating,
            reviewCount: sp.reviewCount ?? fallback.reviewCount,
            jobsCompleted: sp.jobsCompleted ?? fallback.jobsCompleted,
            responseRate: sp.responseRate ?? fallback.responseRate,
            isVerified: sp.isVerified ?? fallback.isVerified,
            verificationStatus: VerificationStatus(rawValue: sp.verificationStatus ?? "") ?? fallback.verificationStatus,
            createdAt: fallback.createdAt,
            bio: sp.bio ?? fallback.bio,
            insuranceUploaded: sp.insuranceUploaded ?? fallback.insuranceUploaded,
            insuranceURL: sp.insuranceUrl ?? fallback.insuranceURL,
            backgroundCheckPassed: sp.backgroundCheckPassed ?? fallback.backgroundCheckPassed,
            twoFactorEnabled: sp.twoFactorEnabled ?? fallback.twoFactorEnabled,
            phoneVerified: sp.phoneVerified ?? fallback.phoneVerified,
            stripeAccountId: sp.stripeAccountId ?? fallback.stripeAccountId,
            stripeOnboardingComplete: sp.stripeOnboardingComplete ?? fallback.stripeOnboardingComplete,
            serviceCategories: (sp.serviceCategories ?? []).compactMap { ServiceCategory(rawValue: $0) }
        )
    }

    private func persistAuth() {
        UserDefaults.standard.set(true, forKey: authKey)
        if let user = currentUser, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
    }

    private func clearAuth() {
        UserDefaults.standard.removeObject(forKey: authKey)
        UserDefaults.standard.removeObject(forKey: userKey)
    }

    private func restoreLocalAuth() {
        guard UserDefaults.standard.bool(forKey: authKey),
              let data = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return
        }
        currentUser = user
        isAuthenticated = true
        hasCompletedOnboarding = true

        if !user.zipCode.isEmpty {
            LocationService.shared.updateZipCode(user.zipCode)
        }

        Task {
            await SupabaseService.shared.restoreSession()
            await syncProfileFromRemote()
        }
    }
}

enum AppTab: String, CaseIterable {
    case home
    case services
    case bookings
    case chat
    case profile

    var title: String {
        switch self {
        case .home: "Home"
        case .services: "Services"
        case .bookings: "Bookings"
        case .chat: "Chat"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .services: "sparkles"
        case .bookings: "calendar"
        case .chat: "message.fill"
        case .profile: "person.fill"
        }
    }
}
