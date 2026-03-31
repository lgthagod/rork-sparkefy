import SwiftUI
import StripePaymentSheet
import Supabase

@main
struct SparkefyApp: App {
    @State private var appViewModel = AppViewModel()

    init() {
        let _ = SupabaseService.shared
        let _ = DataStore.shared

        if !StripeConfig.publishableKey.isEmpty {
            StripeAPI.defaultPublishableKey = StripeConfig.publishableKey
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .onOpenURL { url in
                        SupabaseService.shared.client?.auth.handle(url)
                    let stripeHandled = StripeAPI.handleURLCallback(with: url)
                    if !stripeHandled { }
                }
        }
    }
}
