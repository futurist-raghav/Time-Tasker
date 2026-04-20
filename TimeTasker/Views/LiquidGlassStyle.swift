import SwiftUI

struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var drift = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                baseGradient
                    .ignoresSafeArea()

                if !reduceTransparency {
                    Circle()
                        .fill(Color.cyan.opacity(colorScheme == .dark ? 0.24 : 0.18))
                        .frame(width: geometry.size.width * 0.85)
                        .blur(radius: 90)
                        .offset(x: drift ? -120 : -40, y: drift ? -220 : -160)

                    Circle()
                        .fill(Color.teal.opacity(colorScheme == .dark ? 0.24 : 0.16))
                        .frame(width: geometry.size.width * 0.75)
                        .blur(radius: 110)
                        .offset(x: drift ? 170 : 90, y: drift ? 130 : 210)

                    Circle()
                        .fill(Color.indigo.opacity(colorScheme == .dark ? 0.18 : 0.12))
                        .frame(width: geometry.size.width * 0.55)
                        .blur(radius: 100)
                        .offset(x: drift ? 250 : 170, y: drift ? -140 : -90)
                }
            }
            .onAppear {
                guard !reduceMotion else {
                    drift = true
                    return
                }

                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                    drift.toggle()
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var baseGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.11, blue: 0.16),
                    Color(red: 0.08, green: 0.17, blue: 0.2),
                    Color(red: 0.04, green: 0.1, blue: 0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.84, green: 0.95, blue: 0.97),
                Color(red: 0.8, green: 0.9, blue: 0.95),
                Color(red: 0.9, green: 0.96, blue: 0.98)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct LiquidGlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let cornerRadius: CGFloat
    let tint: Color
    let tintOpacity: Double
    let strokeOpacity: Double
    let shadowOpacity: Double

    func body(content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.45) : Color.white.opacity(0.8))
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(max(0.16, tintOpacity * 2)))
                        }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(tint.opacity(tintOpacity))
                        }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.55 : 0.75),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .opacity(strokeOpacity)
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? shadowOpacity * 1.4 : shadowOpacity),
                radius: 18,
                x: 0,
                y: 10
            )
    }
}

extension View {
    func liquidGlassCard(
        cornerRadius: CGFloat = 16,
        tint: Color = .white,
        tintOpacity: Double = 0.07,
        strokeOpacity: Double = 0.58,
        shadowOpacity: Double = 0.18
    ) -> some View {
        modifier(
            LiquidGlassCardModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                tintOpacity: tintOpacity,
                strokeOpacity: strokeOpacity,
                shadowOpacity: shadowOpacity
            )
        )
    }
}
