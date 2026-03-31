import SwiftUI

struct HomeView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var viewModel = HomeViewModel()
    @State private var animateCards = false
    @State private var showZipEditor = false
    @State private var zipInput = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        shimmerContent
                    } else {
                        headerSection
                        zipAndRadiusBar
                        searchBar
                        categoriesSection
                        featuredSection
                        nearbySection
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                            .symbolEffect(.pulse, options: .repeating.speed(0.5))
                        Text("Sparkefy")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                    }
                }
            }
            .task {
                if let zip = appVM.currentUser?.zipCode, !zip.isEmpty {
                    viewModel.zipCode = zip
                }
                await viewModel.loadData()
                withAnimation(.spring(duration: 0.5)) {
                    animateCards = true
                }
            }
            .alert("Change ZIP Code", isPresented: $showZipEditor) {
                TextField("ZIP Code", text: $zipInput)
                    .keyboardType(.numberPad)
                Button("Update") {
                    if !zipInput.isEmpty {
                        viewModel.updateZipCode(zipInput)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private var shimmerContent: some View {
        VStack(spacing: 20) {
            ShimmerView().frame(height: 50).padding(.horizontal)
            ShimmerView().frame(height: 44).padding(.horizontal)
            ShimmerView().frame(height: 80).padding(.horizontal)
            ShimmerListView(count: 3).padding(.horizontal)
        }
        .padding(.top, 8)
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(appVM.currentUser?.name.components(separatedBy: " ").first ?? "there") \u{1F44B}")
                        .font(.title2.bold())
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(SparkefyTheme.accentGreen)
                        Text("ZIP: \(viewModel.zipCode)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if appVM.currentUser?.role == .provider {
                    NavigationLink {
                        ProviderEarningsView()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                            Text("Earnings")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(SparkefyTheme.accentGreen)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var zipAndRadiusBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    zipInput = viewModel.zipCode
                    showZipEditor = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                        Text(viewModel.zipCode)
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "pencil")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
                }

                Spacer()

                Menu {
                    ForEach(DiscoverySortOption.allCases, id: \.self) { sort in
                        Button {
                            viewModel.selectedSort = sort
                        } label: {
                            Label(sort.rawValue, systemImage: viewModel.selectedSort == sort ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(viewModel.selectedSort.rawValue)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(SparkefyTheme.primaryBlue)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(RadiusOption.allCases) { radius in
                        Button {
                            viewModel.selectedRadius = radius
                        } label: {
                            Text(radius.label)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(viewModel.selectedRadius == radius ? SparkefyTheme.primaryBlue : Color(.tertiarySystemGroupedBackground))
                                .foregroundStyle(viewModel.selectedRadius == radius ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .sensoryFeedback(.selection, trigger: viewModel.selectedRadius)
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            .scrollIndicators(.hidden)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search services, providers...", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3.bold())
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(ServiceCategory.allCases) { category in
                        NavigationLink(value: category) {
                            CategoryCard(category: category)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            .scrollIndicators(.hidden)
        }
        .navigationDestination(for: ServiceCategory.self) { category in
            ServiceListView(category: category)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Pros")
                    .font(.title3.bold())
                Spacer()
                Text("\(viewModel.filteredListings.count) results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if viewModel.filteredListings.isEmpty {
                SparkefyEmptyStateView(
                    icon: "magnifyingglass",
                    title: "No Providers Found",
                    message: "Try expanding your search radius or changing ZIP code."
                )
                .frame(height: 200)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.filteredListings) { listing in
                            NavigationLink(value: listing) {
                                FeaturedCard(listing: listing)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }
        .navigationDestination(for: ServiceListing.self) { listing in
            ServiceDetailView(listing: listing)
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Near You")
                .font(.title3.bold())
                .padding(.horizontal)

            if viewModel.nearbyProviders.isEmpty {
                SparkefyEmptyStateView(
                    icon: "mappin.slash",
                    title: "No Providers Nearby",
                    message: "No providers in your area yet. Invite one!",
                    actionTitle: "Invite a Provider"
                ) { }
                .frame(height: 200)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.nearbyProviders) { listing in
                        NavigationLink(value: listing) {
                            NearbyRow(listing: listing)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CategoryCard: View {
    let category: ServiceCategory

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(category.color.opacity(0.12))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(category.color)
                }

            Text(category.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
}

struct FeaturedCard: View {
    let listing: ServiceListing

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Color(listing.category.color.opacity(0.15))
                .frame(width: 260, height: 140)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: listing.category.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(listing.category.color)
                        Text(listing.category.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(listing.category.color)
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 14))
                .overlay(alignment: .topTrailing) {
                    if listing.isVerified {
                        Label("Verified", systemImage: "checkmark.seal.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SparkefyTheme.accentGreen)
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(listing.providerName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(listing.providerRating, format: .number.precision(.fractionLength(1)))
                            .font(.caption.weight(.semibold))
                    }
                    Text("(\(listing.providerReviewCount))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let dist = listing.distanceMiles {
                        Text("\u{2022}")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(String(format: "%.1f mi", dist))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    Text(listing.basePrice, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 260)
        .sparkefyCard()
    }
}

struct NearbyRow: View {
    let listing: ServiceListing

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(listing.category.color.opacity(0.12))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: listing.category.icon)
                        .foregroundStyle(listing.category.color)
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(listing.providerName)
                        .font(.subheadline.weight(.semibold))
                    if listing.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(SparkefyTheme.accentGreen)
                    }
                }
                HStack(spacing: 6) {
                    Text(listing.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let dist = listing.distanceMiles {
                        Text(String(format: "%.1f mi", dist))
                            .font(.caption2)
                            .foregroundStyle(SparkefyTheme.primaryBlue)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(listing.basePrice, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(SparkefyTheme.primaryBlue)
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(listing.providerRating, format: .number.precision(.fractionLength(1)))
                        .font(.caption2.weight(.medium))
                }
            }
        }
        .sparkefyCard()
    }
}
