import Foundation

@Observable
@MainActor
class PaymentService {
    static let platformFeeRate: Double = 0.20
    static let maxTipRate: Double = 0.25

    var isProcessing = false
    var lastPaymentSuccess = false

    func calculateBreakdown(servicePrice: Double, tipPercentage: Int) -> PaymentBreakdown {
        let tipAmount = servicePrice * Double(tipPercentage) / 100.0
        let customerTotal = servicePrice + tipAmount
        let platformFee = servicePrice * Self.platformFeeRate
        let providerEarnings = servicePrice - platformFee
        let providerTotal = providerEarnings + tipAmount

        return PaymentBreakdown(
            servicePrice: servicePrice,
            platformFee: platformFee,
            providerEarnings: providerEarnings,
            tipPercentage: tipPercentage,
            tipAmount: tipAmount,
            customerTotal: customerTotal,
            providerTotal: providerTotal
        )
    }

    func processPayment(breakdown: PaymentBreakdown, stripeService: StripeService) async -> Bool {
        isProcessing = true
        defer { isProcessing = false }

        if stripeService.isConfigured {
            let result = await stripeService.presentPaymentSheet()
            lastPaymentSuccess = result
            return result
        }

        try? await Task.sleep(for: .seconds(1.5))
        lastPaymentSuccess = true
        return true
    }
}

nonisolated struct PaymentBreakdown: Sendable {
    let servicePrice: Double
    let platformFee: Double
    let providerEarnings: Double
    let tipPercentage: Int
    let tipAmount: Double
    let customerTotal: Double
    let providerTotal: Double

    var formattedServicePrice: String { servicePrice.formatted(.currency(code: "USD")) }
    var formattedPlatformFee: String { platformFee.formatted(.currency(code: "USD")) }
    var formattedProviderEarnings: String { providerEarnings.formatted(.currency(code: "USD")) }
    var formattedTipAmount: String { tipAmount.formatted(.currency(code: "USD")) }
    var formattedCustomerTotal: String { customerTotal.formatted(.currency(code: "USD")) }
    var formattedProviderTotal: String { providerTotal.formatted(.currency(code: "USD")) }
}
