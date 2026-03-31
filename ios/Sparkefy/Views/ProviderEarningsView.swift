import SwiftUI

struct ProviderEarningsView: View {
    @State private var selectedPeriod: EarningsPeriod = .thisWeek
    @State private var isLoading = true
    @State private var showStripeOnboarding = false
    @State private var stripeService = StripeService()

    private let earnings = EarningsData.sample

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !stripeService.isConfigured {
                    stripeSetupBanner
                }
                earningsSummaryCard
                periodPicker
                breakdownCard
                recentJobsList
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Earnings")
        .navigationBarTitleDisplayMode(.large)
        .task {
            try? await Task.sleep(for: .seconds(0.4))
            isLoading = false
        }
    }

    private var stripeSetupBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "banknote.fill")
                    .font(.title3)
                    .foregroundStyle(SparkefyTheme.ctaOrange)
                Text("Set Up Payouts")
                    .font(.headline)
            }

            Text("Connect your bank account to receive payouts directly. You'll get paid after each completed job.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                showStripeOnboarding = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "link.badge.plus")
                    Text("Connect Bank Account")
                }
            }
            .buttonStyle(SparkefyButtonStyle())
        }
        .sparkefyCard()
    }

    private var earningsSummaryCard: some View {
        VStack(spacing: 16) {
            Text("Your Earnings")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Text(earnings.netEarnings.formatted(.currency(code: "USD")))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Divider()
                .background(.white.opacity(0.2))

            HStack(spacing: 24) {
                earningsMetric(title: "Jobs", value: "\(earnings.jobCount)", icon: "briefcase.fill")
                earningsMetric(title: "Tips", value: earnings.totalTips.formatted(.currency(code: "USD")), icon: "heart.fill")
                earningsMetric(title: "Avg/Job", value: earnings.averagePerJob.formatted(.currency(code: "USD")), icon: "chart.line.uptrend.xyaxis")
            }
        }
        .padding(20)
        .background(SparkefyTheme.blueGreenGradient)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: SparkefyTheme.primaryBlue.opacity(0.3), radius: 12, y: 6)
    }

    private func earningsMetric(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(EarningsPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.snappy) { selectedPeriod = period }
                } label: {
                    Text(period.rawValue)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedPeriod == period ? SparkefyTheme.primaryBlue : Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(selectedPeriod == period ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earnings Breakdown")
                .font(.headline)

            Divider()

            earningsRow("Job Subtotal", value: earnings.grossRevenue.formatted(.currency(code: "USD")))
            earningsRow("Sparkefy Service Fee (20%)", value: "−\(earnings.platformFees.formatted(.currency(code: "USD")))", color: .secondary)
            earningsRow("Tips Received", value: "+\(earnings.totalTips.formatted(.currency(code: "USD")))", color: SparkefyTheme.accentGreen)

            Divider()

            HStack {
                Text("Your Earnings")
                    .font(.headline)
                Spacer()
                Text(earnings.netEarnings.formatted(.currency(code: "USD")))
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
        }
        .sparkefyCard()
    }

    private func earningsRow(_ label: String, value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color ?? .primary)
        }
    }

    private var recentJobsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Jobs")
                .font(.headline)

            ForEach(earnings.recentJobs, id: \.title) { job in
                HStack(spacing: 12) {
                    Circle()
                        .fill(job.categoryColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: job.categoryIcon)
                                .font(.body)
                                .foregroundStyle(job.categoryColor)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(job.title)
                            .font(.subheadline.weight(.medium))
                        Text(job.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(job.earnings.formatted(.currency(code: "USD")))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SparkefyTheme.accentGreen)
                        if job.tip > 0 {
                            Text("+\(job.tip.formatted(.currency(code: "USD"))) tip")
                                .font(.caption2)
                                .foregroundStyle(SparkefyTheme.accentGreen.opacity(0.7))
                        }
                    }
                }
            }
        }
        .sparkefyCard()
    }
}

nonisolated enum EarningsPeriod: String, CaseIterable, Sendable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case allTime = "All Time"
}

struct EarningsData {
    let grossRevenue: Double
    let platformFees: Double
    let totalTips: Double
    let jobCount: Int
    let recentJobs: [JobEarning]

    var netEarnings: Double { grossRevenue - platformFees + totalTips }
    var averagePerJob: Double { jobCount > 0 ? netEarnings / Double(jobCount) : 0 }

    static let sample = EarningsData(
        grossRevenue: 2340,
        platformFees: 468,
        totalTips: 187.50,
        jobCount: 18,
        recentJobs: [
            JobEarning(title: "Premium Detail", date: "Today", earnings: 119.99, tip: 22.50, categoryIcon: "car.fill", categoryColor: SparkefyTheme.primaryBlue),
            JobEarning(title: "Lawn Care", date: "Yesterday", earnings: 52, tip: 9.75, categoryIcon: "leaf.fill", categoryColor: SparkefyTheme.accentGreen),
            JobEarning(title: "Power Wash", date: "2 days ago", earnings: 159.20, tip: 30, categoryIcon: "water.waves", categoryColor: Color(red: 0.4, green: 0.7, blue: 0.95)),
            JobEarning(title: "Home Cleaning", date: "3 days ago", earnings: 96, tip: 18, categoryIcon: "house.fill", categoryColor: Color(red: 0.6, green: 0.4, blue: 0.8)),
        ]
    )
}

struct JobEarning {
    let title: String
    let date: String
    let earnings: Double
    let tip: Double
    let categoryIcon: String
    let categoryColor: Color
}
