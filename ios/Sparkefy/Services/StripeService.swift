import Foundation
import StripePaymentSheet
import UIKit

@Observable
@MainActor
class StripeService {
    var paymentSheet: PaymentSheet?
    var paymentResult: PaymentSheetResult?
    var isLoading = false
    var errorMessage: String?

    private let publishableKey: String
    private let backendURL: String

    var isConfigured: Bool {
        !publishableKey.isEmpty && !backendURL.isEmpty
    }

    init() {
        self.publishableKey = StripeConfig.publishableKey
        self.backendURL = StripeConfig.backendURL

        if !publishableKey.isEmpty {
            StripeAPI.defaultPublishableKey = publishableKey
        }
    }

    func preparePaymentSheet(
        customerTotal: Int,
        platformFee: Int,
        providerStripeAccountId: String,
        customerId: String?,
        customerEphemeralKeySecret: String? = nil
    ) async {
        guard isConfigured else {
            errorMessage = "Stripe is not configured. Set your API keys to enable payments."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let params = try await fetchPaymentIntentFromBackend(
                amount: customerTotal,
                applicationFee: platformFee,
                destinationAccount: providerStripeAccountId,
                customerId: customerId
            )

            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Sparkefy"
            configuration.allowsDelayedPaymentMethods = false
            configuration.returnURL = "sparkefy://stripe-redirect"

            if let customerId = params.customerId,
               let ephemeralKey = params.ephemeralKeySecret {
                configuration.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
            }

            var appearance = PaymentSheet.Appearance()
            appearance.colors.primary = UIColor(red: 0, green: 0.635, blue: 1, alpha: 1)
            appearance.colors.componentBackground = .secondarySystemGroupedBackground
            appearance.cornerRadius = 12
            configuration.appearance = appearance

            paymentSheet = PaymentSheet(
                paymentIntentClientSecret: params.clientSecret,
                configuration: configuration
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func presentPaymentSheet() async -> Bool {
        guard let sheet = paymentSheet else {
            errorMessage = "Payment sheet not ready"
            return false
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to present payment sheet"
            return false
        }

        let topVC = Self.topViewController(from: rootVC)

        return await withCheckedContinuation { continuation in
            sheet.present(from: topVC) { result in
                Task { @MainActor in
                    self.paymentResult = result
                    switch result {
                    case .completed:
                        self.paymentSheet = nil
                        continuation.resume(returning: true)
                    case .canceled:
                        continuation.resume(returning: false)
                    case .failed(let error):
                        self.errorMessage = error.localizedDescription
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    func getConnectOnboardingURL(accountId: String) async -> URL? {
        guard isConfigured else { return nil }
        guard let url = URL(string: "\(backendURL)/create-connect-onboarding") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "account_id": accountId,
            "return_url": "sparkefy://stripe-connect-return",
            "refresh_url": "sparkefy://stripe-connect-refresh"
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let urlString = json?["url"] as? String {
                return URL(string: urlString)
            }
        } catch { }
        return nil
    }

    func createConnectAccount(email: String) async -> String? {
        guard isConfigured else { return nil }
        guard let url = URL(string: "\(backendURL)/create-connect-account") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "email": email,
            "type": "express"
        ])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["account_id"] as? String
        } catch { }
        return nil
    }

    private nonisolated static func topViewController(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return vc
    }

    private func fetchPaymentIntentFromBackend(
        amount: Int,
        applicationFee: Int,
        destinationAccount: String,
        customerId: String?
    ) async throws -> PaymentIntentResponse {
        guard let url = URL(string: "\(backendURL)/create-payment-intent") else {
            throw StripeServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "amount": amount,
            "currency": "usd",
            "application_fee_amount": applicationFee,
            "transfer_data": ["destination": destinationAccount]
        ]
        if let customerId {
            body["customer"] = customerId
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StripeServiceError.serverError
        }

        return try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
    }
}

nonisolated struct PaymentIntentResponse: Codable, Sendable {
    let clientSecret: String
    let customerId: String?
    let ephemeralKeySecret: String?

    nonisolated enum CodingKeys: String, CodingKey {
        case clientSecret = "client_secret"
        case customerId = "customer_id"
        case ephemeralKeySecret = "ephemeral_key_secret"
    }
}

nonisolated enum StripeServiceError: Error, LocalizedError, Sendable {
    case invalidURL
    case serverError
    case missingClientSecret

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid server URL"
        case .serverError: "Payment server error. Please try again."
        case .missingClientSecret: "Could not initialize payment"
        }
    }
}

nonisolated enum StripeConfig: Sendable {
    static var publishableKey: String {
        Config.allValues["EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY"] ?? ""
    }
    static var backendURL: String {
        Config.allValues["EXPO_PUBLIC_STRIPE_BACKEND_URL"] ?? ""
    }
}
