import SwiftUI

struct ServicesView: View {
    @State private var searchText = ""

    var filteredCategories: [ServiceCategory] {
        guard !searchText.isEmpty else { return ServiceCategory.allCases }
        return ServiceCategory.allCases.filter { $0.displayName.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if filteredCategories.isEmpty {
                        SparkefyEmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Results",
                            message: "Try a different search term"
                        )
                        .frame(height: 300)
                    } else {
                        ForEach(filteredCategories) { category in
                            NavigationLink(value: category) {
                                ServiceCategoryRow(category: category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Services")
            .searchable(text: $searchText, prompt: "Search categories")
            .navigationDestination(for: ServiceCategory.self) { category in
                ServiceListView(category: category)
            }
        }
    }
}

struct ServiceCategoryRow: View {
    let category: ServiceCategory

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14)
                .fill(category.color.opacity(0.1))
                .frame(width: 72, height: 72)
                .overlay {
                    Image(systemName: category.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(category.color)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.headline)
                Text(category.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .sparkefyCard()
    }
}
