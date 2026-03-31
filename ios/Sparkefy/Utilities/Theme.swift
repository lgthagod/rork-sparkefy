import SwiftUI

enum SparkefyTheme {
    static let primaryBlue = Color(red: 0, green: 0.635, blue: 1)
    static let accentGreen = Color(red: 0, green: 0.773, blue: 0.557)
    static let ctaOrange = Color(red: 1, green: 0.584, blue: 0)
    static let darkNavy = Color(red: 0, green: 0.169, blue: 0.357)
    static let errorRed = Color(red: 1, green: 0.231, blue: 0.188)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let screenBackground = Color(.systemGroupedBackground)

    static let blueGreenGradient = LinearGradient(
        colors: [primaryBlue, accentGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleBlueGradient = LinearGradient(
        colors: [primaryBlue.opacity(0.08), accentGreen.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let shimmerGradient = LinearGradient(
        colors: [primaryBlue.opacity(0.08), accentGreen.opacity(0.12), primaryBlue.opacity(0.08)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let cardShadow: Color = .black.opacity(0.06)
    static let cardShadowRadius: CGFloat = 8
    static let cardCornerRadius: CGFloat = 12
}

struct SparkefyButtonStyle: ButtonStyle {
    var isWide: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: isWide ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, isWide ? 0 : 32)
            .background(SparkefyTheme.ctaOrange)
            .clipShape(.rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(SparkefyTheme.primaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(SparkefyTheme.primaryBlue.opacity(0.1))
            .clipShape(.rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
    }
}

struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(SparkefyTheme.accentGreen)
            .clipShape(.rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
    }
}

extension View {
    func sparkefyCard() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: SparkefyTheme.cardCornerRadius))
            .shadow(color: SparkefyTheme.cardShadow, radius: SparkefyTheme.cardShadowRadius, y: 2)
    }

    func sparkefyCardInteractive() -> some View {
        self
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: SparkefyTheme.cardCornerRadius))
            .shadow(color: SparkefyTheme.cardShadow, radius: SparkefyTheme.cardShadowRadius, y: 2)
    }
}
