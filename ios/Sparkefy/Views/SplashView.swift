import SwiftUI

struct SplashView: View {
    @State private var sparkleScale: CGFloat = 0.3
    @State private var sparkleOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ],
                colors: [
                    SparkefyTheme.darkNavy, SparkefyTheme.primaryBlue.opacity(0.8), SparkefyTheme.darkNavy,
                    SparkefyTheme.primaryBlue.opacity(0.6), SparkefyTheme.accentGreen.opacity(0.4), SparkefyTheme.primaryBlue.opacity(0.6),
                    SparkefyTheme.darkNavy, SparkefyTheme.accentGreen.opacity(0.5), SparkefyTheme.darkNavy
                ]
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(.white)
                    .scaleEffect(sparkleScale)
                    .opacity(sparkleOpacity)

                Text("Sparkefy")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)

                Text("Services that shine")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.4)) {
                sparkleScale = 1
                sparkleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                taglineOpacity = 1
            }
        }
    }
}
