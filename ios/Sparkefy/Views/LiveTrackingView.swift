import SwiftUI
import MapKit

struct LiveTrackingView: View {
    let booking: Booking
    @State private var trackingStatus: TrackingStatus = .enRoute
    @State private var providerPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 34.0722, longitude: -118.4041)
    @State private var estimatedMinutes: Int = 12
    @State private var mapCamera: MapCameraPosition = .automatic

    private let jobLocation = CLLocationCoordinate2D(latitude: 34.0736, longitude: -118.4004)

    var body: some View {
        VStack(spacing: 0) {
            mapSection

            VStack(spacing: 16) {
                statusHeader
                trackingTimeline
                providerInfoBar
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
            .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        }
        .ignoresSafeArea(edges: .top)
        .task { await simulateMovement() }
    }

    private var mapSection: some View {
        Map(position: $mapCamera) {
            Annotation("Provider", coordinate: providerPosition) {
                ZStack {
                    Circle()
                        .fill(SparkefyTheme.primaryBlue)
                        .frame(width: 36, height: 36)
                        .shadow(color: SparkefyTheme.primaryBlue.opacity(0.4), radius: 6)
                    Image(systemName: "car.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }

            Annotation("Job Site", coordinate: jobLocation) {
                ZStack {
                    Circle()
                        .fill(SparkefyTheme.accentGreen)
                        .frame(width: 32, height: 32)
                        .shadow(color: SparkefyTheme.accentGreen.opacity(0.4), radius: 6)
                    Image(systemName: "mappin")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 280)
        .allowsHitTesting(true)
    }

    private var statusHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: trackingStatus.icon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .symbolEffect(.pulse, isActive: trackingStatus == .enRoute)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(trackingStatus.displayName)
                    .font(.headline)
                if trackingStatus == .enRoute || trackingStatus == .arriving {
                    Text("ETA: ~\(estimatedMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                }
            }

            Spacer()

            if trackingStatus != .onSite {
                Text("\(estimatedMinutes) min")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(SparkefyTheme.primaryBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(SparkefyTheme.primaryBlue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }

    private var trackingTimeline: some View {
        VStack(spacing: 0) {
            timelineRow(icon: "circle.fill", title: "Job Accepted", subtitle: "Provider confirmed", isActive: true, isCompleted: true)
            timelineConnector(isActive: trackingStatus.rawValue >= TrackingStatus.enRoute.rawValue)
            timelineRow(icon: "car.fill", title: "On the Way", subtitle: "Heading to your location", isActive: trackingStatus == .enRoute || trackingStatus == .arriving || trackingStatus == .onSite, isCompleted: trackingStatus == .arriving || trackingStatus == .onSite)
            timelineConnector(isActive: trackingStatus == .arriving || trackingStatus == .onSite)
            timelineRow(icon: "location.fill", title: "Arriving", subtitle: "Almost there", isActive: trackingStatus == .arriving || trackingStatus == .onSite, isCompleted: trackingStatus == .onSite)
            timelineConnector(isActive: trackingStatus == .onSite)
            timelineRow(icon: "checkmark.circle.fill", title: "At Job Site", subtitle: "Provider has arrived", isActive: trackingStatus == .onSite, isCompleted: false)
        }
        .padding()
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func timelineRow(icon: String, title: String, subtitle: String, isActive: Bool, isCompleted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : icon)
                .font(.body)
                .foregroundStyle(isActive ? SparkefyTheme.accentGreen : Color(.tertiaryLabel))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? .primary : .secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func timelineConnector(isActive: Bool) -> some View {
        HStack {
            Rectangle()
                .fill(isActive ? SparkefyTheme.accentGreen : Color(.tertiarySystemFill))
                .frame(width: 2, height: 20)
                .padding(.leading, 11)
            Spacer()
        }
    }

    private var providerInfoBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(SparkefyTheme.primaryBlue.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(booking.providerName.prefix(1)))
                        .font(.headline)
                        .foregroundStyle(SparkefyTheme.primaryBlue)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(booking.providerName)
                    .font(.subheadline.weight(.semibold))
                Text(booking.serviceTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button { } label: {
                Image(systemName: "phone.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(SparkefyTheme.accentGreen)
                    .clipShape(Circle())
            }

            Button { } label: {
                Image(systemName: "message.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(SparkefyTheme.primaryBlue)
                    .clipShape(Circle())
            }
        }
    }

    private var statusColor: Color {
        switch trackingStatus {
        case .idle: .secondary
        case .enRoute: SparkefyTheme.primaryBlue
        case .arriving: SparkefyTheme.ctaOrange
        case .onSite: SparkefyTheme.accentGreen
        }
    }

    private func simulateMovement() async {
        let steps: [(CLLocationCoordinate2D, TrackingStatus, Int)] = [
            (CLLocationCoordinate2D(latitude: 34.0722, longitude: -118.4041), .enRoute, 12),
            (CLLocationCoordinate2D(latitude: 34.0726, longitude: -118.4032), .enRoute, 9),
            (CLLocationCoordinate2D(latitude: 34.0729, longitude: -118.4022), .enRoute, 6),
            (CLLocationCoordinate2D(latitude: 34.0732, longitude: -118.4014), .arriving, 3),
            (CLLocationCoordinate2D(latitude: 34.0734, longitude: -118.4008), .arriving, 1),
            (CLLocationCoordinate2D(latitude: 34.0736, longitude: -118.4004), .onSite, 0),
        ]

        for step in steps {
            try? await Task.sleep(for: .seconds(10))
            withAnimation(.spring(duration: 0.6)) {
                providerPosition = step.0
                trackingStatus = step.1
                estimatedMinutes = step.2
            }
        }
    }
}
