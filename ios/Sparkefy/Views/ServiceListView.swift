import SwiftUI

struct ServiceListView: View {
    let category: ServiceCategory
    @State private var listings: [ServiceListing] = []
    @State private var sortOption: SortOption = .rating
    @State private var isLoading = true

    var sortedListings: [ServiceListing] {
        switch sortOption {
        case .rating: listings.sorted { $0.providerRating > $1.providerRating }
        case .priceLow: listings.sorted { $0.basePrice < $1.basePrice }
        case .priceHigh: listings.sorted { $0.basePrice > $1.basePrice }
        case .reviews: listings.sorted { $0.providerReviewCount > $1.providerReviewCount }
        case .distance: listings.sorted { ($0.distanceMiles ?? 999) < ($1.distanceMiles ?? 999) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ShimmerListView(count: 3)
                        .padding(.horizontal)
                } else {
                    HStack {
                        Text("\(sortedListings.count) providers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    Label(option.rawValue, systemImage: sortOption == option ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(sortOption.rawValue)
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                        }
                    }
                    .padding(.horizontal)

                    if sortedListings.isEmpty {
                        SparkefyEmptyStateView(
                            icon: "person.2.slash",
                            title: "No Providers Yet",
                            message: "No \(category.displayName.lowercased()) providers in your area yet. Check back soon!",
                            actionTitle: "Invite a Provider"
                        ) { }
                        .frame(height: 300)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(sortedListings) { listing in
                                NavigationLink(value: listing) {
                                    ServiceListCard(listing: listing)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: ServiceListing.self) { listing in
            ServiceDetailView(listing: listing)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.5))
            let loc = LocationService.shared
            listings = HomeViewModel.sampleListings
                .filter { $0.category == category }
                .map { listing in
                    var l = listing
                    if let lat = listing.latitude, let lon = listing.longitude {
                        l.distanceMiles = LocationService.distanceMiles(
                            lat1: loc.currentLatitude, lon1: loc.currentLongitude,
                            lat2: lat, lon2: lon
                        )
                    } else {
                        l.distanceMiles = Double.random(in: 2...20)
                    }
                    return l
                }
            isLoading = false
        }
    }
}

struct ServiceListCard: View {
    let listing: ServiceListing

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(listing.category.color.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: listing.category.icon)
                            .font(.title3)
                            .foregroundStyle(listing.category.color)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(listing.providerName)
                            .font(.headline)
                        if listing.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(SparkefyTheme.accentGreen)
                        }
                    }
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.orange)
                            Text(listing.providerRating, format: .number.precision(.fractionLength(1)))
                                .fontWeight(.semibold)
                        }
                        .font(.caption)
                        Text("(\(listing.providerReviewCount) reviews)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let dist = listing.distanceMiles {
                            Text("\u{2022} \(String(format: "%.1f mi", dist))")
                                .font(.caption)
                                .foregroundStyle(SparkefyTheme.primaryBlue)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(listing.basePrice, format: .currency(code: "USD"))
                        .font(.title3.bold())
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                    Text(listing.priceUnit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(listing.title)
                .font(.subheadline.weight(.medium))

            Text(listing.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(listing.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(SparkefyTheme.primaryBlue.opacity(0.08))
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                            .clipShape(Capsule())
                    }
                    if !listing.estimatedDuration.isEmpty {
                        Label(listing.estimatedDuration, systemImage: "clock")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .sparkefyCard()
    }
}

nonisolated enum SortOption: String, CaseIterable, Sendable {
    case rating = "Top Rated"
    case priceLow = "Price: Low"
    case priceHigh = "Price: High"
    case reviews = "Most Reviews"
    case distance = "Nearest"
}
