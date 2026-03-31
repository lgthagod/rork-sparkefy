import SwiftUI

struct ServiceDetailView: View {
    let listing: ServiceListing
    @State private var showBooking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Color(listing.category.color.opacity(0.12))
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: listing.category.icon)
                                .font(.system(size: 56))
                                .foregroundStyle(listing.category.color)
                            Text(listing.category.tagline)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(listing.category.color.opacity(0.8))
                        }
                        .allowsHitTesting(false)
                    }
                    .clipped()

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(listing.title)
                                .font(.title2.bold())
                            Spacer()
                            if listing.isVerified {
                                Label("Verified", systemImage: "checkmark.seal.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(SparkefyTheme.accentGreen)
                                    .clipShape(Capsule())
                            }
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                Text(listing.providerRating, format: .number.precision(.fractionLength(1)))
                                    .fontWeight(.semibold)
                                Text("(\(listing.providerReviewCount))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.subheadline)

                            if !listing.estimatedDuration.isEmpty {
                                Label(listing.estimatedDuration, systemImage: "clock")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    providerCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Service")
                            .font(.headline)
                        Text(listing.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    if !listing.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Includes")
                                .font(.headline)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                                ForEach(listing.tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(SparkefyTheme.accentGreen)
                                        Text(tag)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                    }

                    pricingSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .sheet(isPresented: $showBooking) {
            BookingFlowView(listing: listing)
        }
    }

    private var providerCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(SparkefyTheme.primaryBlue.opacity(0.12))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(String(listing.providerName.prefix(1)))
                        .font(.title3.bold())
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(listing.providerName)
                    .font(.subheadline.weight(.semibold))
                Text("Service radius: \(listing.serviceRadius) miles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button { } label: {
                Image(systemName: "message.fill")
                    .font(.body)
                    .foregroundStyle(SparkefyTheme.primaryBlue)
                    .padding(10)
                    .background(SparkefyTheme.primaryBlue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .sparkefyCard()
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pricing")
                .font(.headline)

            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(listing.basePrice, format: .currency(code: "USD"))
                            .font(.title.bold())
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                    }
                    Spacer()
                    Text(listing.priceUnit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(SparkefyTheme.accentGreen)
                    Text("Tips go 100% to your provider")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .sparkefyCard()
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 1) {
                Text(listing.basePrice, format: .currency(code: "USD"))
                    .font(.title3.bold())
                Text(listing.priceUnit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Book Now") {
                showBooking = true
            }
            .buttonStyle(SparkefyButtonStyle())
            .sensoryFeedback(.impact(weight: .medium), trigger: showBooking)
        }
        .padding()
        .background(.bar)
    }
}
