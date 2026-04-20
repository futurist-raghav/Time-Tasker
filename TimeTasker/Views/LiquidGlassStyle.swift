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
                        .fill(Color.cyan.opacity(colorScheme == .dark ? 0.32 : 0.26))
                        .frame(width: geometry.size.width * 0.92)
                        .blur(radius: 60)
                        .offset(x: drift ? -170 : -55, y: drift ? -250 : -165)

                    Ellipse()
                        .fill(Color.blue.opacity(colorScheme == .dark ? 0.24 : 0.18))
                        .frame(width: geometry.size.width * 1.05, height: geometry.size.height * 0.65)
                        .blur(radius: 70)
                        .offset(x: drift ? 210 : 95, y: drift ? -40 : 85)

                    Circle()
                        .fill(Color.teal.opacity(colorScheme == .dark ? 0.29 : 0.2))
                        .frame(width: geometry.size.width * 0.8)
                        .blur(radius: 65)
                        .offset(x: drift ? 190 : 105, y: drift ? 165 : 230)
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
                    Color(red: 0.03, green: 0.08, blue: 0.13),
                    Color(red: 0.07, green: 0.16, blue: 0.23),
                    Color(red: 0.02, green: 0.09, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.8, green: 0.93, blue: 0.99),
                Color(red: 0.73, green: 0.88, blue: 0.98),
                Color(red: 0.88, green: 0.96, blue: 0.99)
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
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            tint.opacity(tintOpacity * 1.1),
                                            Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12),
                                            tint.opacity(tintOpacity * 0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.16 : 0.28),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.55 : 0.75),
                                tint.opacity(colorScheme == .dark ? 0.25 : 0.2),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.1
                    )
                    .opacity(strokeOpacity)
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? shadowOpacity * 1.4 : shadowOpacity),
                radius: 24,
                x: 0,
                y: 14
            )
    }
}

extension View {
    func liquidGlassCard(
        cornerRadius: CGFloat = 16,
        tint: Color = .white,
        tintOpacity: Double = 0.09,
        strokeOpacity: Double = 0.62,
        shadowOpacity: Double = 0.2
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
