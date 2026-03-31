import SwiftUI

struct DatabaseSetupView: View {
    @State private var showSQL = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Setup Guide", systemImage: "server.rack")
                        .font(.title2.bold())
                    Text("Follow these steps to make Sparkefy fully functional with real data.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                setupStep(
                    number: 1,
                    title: "Create Supabase Project",
                    description: "Go to supabase.com, create a new project, and copy your Project URL and anon key."
                )

                setupStep(
                    number: 2,
                    title: "Add Environment Variables",
                    description: "Set EXPO_PUBLIC_SUPABASE_URL and EXPO_PUBLIC_SUPABASE_ANON_KEY in your project settings."
                )

                setupStep(
                    number: 3,
                    title: "Run Database SQL",
                    description: "Open the Supabase SQL Editor and paste the schema below to create all tables with RLS policies."
                )

                Button {
                    withAnimation(.snappy) { showSQL.toggle() }
                } label: {
                    HStack {
                        Image(systemName: "doc.text.fill")
                        Text(showSQL ? "Hide SQL Schema" : "View SQL Schema")
                        Spacer()
                        Image(systemName: showSQL ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                }
                .buttonStyle(SecondaryButtonStyle())

                if showSQL {
                    Text(SupabaseService.setupSQL)
                        .font(.system(.caption2, design: .monospaced))
                        .padding(12)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 8))
                }

                setupStep(
                    number: 4,
                    title: "Enable Phone Auth (Optional)",
                    description: "In Supabase > Authentication > Providers, enable Phone provider for 2FA. Configure Twilio for SMS delivery."
                )

                setupStep(
                    number: 5,
                    title: "Set Up Stripe Connect",
                    description: "Add EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY and EXPO_PUBLIC_STRIPE_BACKEND_URL. Deploy a backend with /create-payment-intent, /create-connect-account, and /create-connect-onboarding endpoints."
                )

                setupStep(
                    number: 6,
                    title: "Launch!",
                    description: "With all keys configured, the app automatically uses real Supabase data and Stripe payments. Without keys, it runs in demo mode with local data."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Environment Variables Needed")
                        .font(.headline)
                    envRow("EXPO_PUBLIC_SUPABASE_URL", desc: "Supabase project URL")
                    envRow("EXPO_PUBLIC_SUPABASE_ANON_KEY", desc: "Supabase anon/public key")
                    envRow("EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY", desc: "Stripe publishable key (pk_live_...)")
                    envRow("EXPO_PUBLIC_STRIPE_BACKEND_URL", desc: "Your payment backend URL")
                }
                .sparkefyCard()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Database Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func setupStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(SparkefyTheme.primaryBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func envRow(_ key: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.caption.monospaced().weight(.semibold))
                .foregroundStyle(SparkefyTheme.primaryBlue)
            Text(desc)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
