import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        Rectangle()
            .fill(Color(.tertiarySystemGroupedBackground))
            .overlay {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                SparkefyTheme.primaryBlue.opacity(0.08),
                                SparkefyTheme.accentGreen.opacity(0.1),
                                SparkefyTheme.primaryBlue.opacity(0.08),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase * 300)
            }
            .clipShape(.rect(cornerRadius: 8))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct ShimmerCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ShimmerView()
                .frame(height: 20)
                .frame(maxWidth: 180)

            ShimmerView()
                .frame(height: 14)

            ShimmerView()
                .frame(height: 14)
                .frame(maxWidth: 220)

            HStack(spacing: 12) {
                ShimmerView()
                    .frame(width: 60, height: 14)
                ShimmerView()
                    .frame(width: 80, height: 14)
                Spacer()
                ShimmerView()
                    .frame(width: 50, height: 20)
            }
        }
        .sparkefyCard()
    }
}

struct ShimmerListView: View {
    let count: Int

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { _ in
                ShimmerCardView()
            }
        }
    }
}

struct SparkefyEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(SparkefyTheme.primaryBlue.opacity(0.08))
                    .frame(width: 96, height: 96)

                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(SparkefyTheme.blueGreenGradient)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.bold())

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(SparkefyButtonStyle(isWide: false))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
