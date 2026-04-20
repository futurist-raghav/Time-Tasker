import SwiftUI

struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                baseGradient
                    .ignoresSafeArea()

                if !reduceTransparency {
                    radialAccent(
                        color: Color(red: 0.18, green: 0.42, blue: 0.82).opacity(colorScheme == .dark ? 0.16 : 0.12),
                        width: geometry.size.width * 0.82,
                        height: geometry.size.height * 0.56,
                        x: -geometry.size.width * 0.22,
                        y: -geometry.size.height * 0.34
                    )

                    radialAccent(
                        color: Color(red: 0.14, green: 0.26, blue: 0.52).opacity(colorScheme == .dark ? 0.14 : 0.1),
                        width: geometry.size.width * 0.92,
                        height: geometry.size.height * 0.72,
                        x: geometry.size.width * 0.24,
                        y: -geometry.size.height * 0.08
                    )

                    radialAccent(
                        color: Color(red: 0.2, green: 0.24, blue: 0.32).opacity(colorScheme == .dark ? 0.2 : 0.08),
                        width: geometry.size.width * 0.8,
                        height: geometry.size.height * 0.6,
                        x: geometry.size.width * 0.22,
                        y: geometry.size.height * 0.36
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var baseGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.11),
                    Color(red: 0.1, green: 0.11, blue: 0.14),
                    Color(red: 0.07, green: 0.08, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.97, blue: 0.98),
                Color(red: 0.93, green: 0.95, blue: 0.97),
                Color(red: 0.95, green: 0.97, blue: 0.99)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func radialAccent(
        color: Color,
        width: CGFloat,
        height: CGFloat,
        x: CGFloat,
        y: CGFloat
    ) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [color, .clear],
                    center: .center,
                    startRadius: 8,
                    endRadius: max(width, height) * 0.55
                )
            )
            .frame(width: width, height: height)
            .offset(x: x, y: y)
    }
}

private struct ContentSurfaceModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let tint: Color
    let emphasis: Double
    let strokeOpacity: Double
    let shadowOpacity: Double

    func body(content: Content) -> some View {
        let baseFill = colorScheme == .dark
            ? Color(red: 0.12, green: 0.14, blue: 0.17)
            : Color(red: 0.99, green: 0.99, blue: 1.0)

        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(baseFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(max(0, min(0.16, emphasis))))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        Color.primary.opacity(colorScheme == .dark ? 0.3 : 0.16),
                        lineWidth: 1.1
                    )
                    .opacity(strokeOpacity)
            }
            .shadow(
                color: .black.opacity(colorScheme == .dark ? shadowOpacity * 1.4 : shadowOpacity),
                radius: 10,
                x: 0,
                y: 6
            )
    }
}

extension View {
    func contentSurface(
        cornerRadius: CGFloat = 16,
        tint: Color = .accentColor,
        emphasis: Double = 0.05,
        strokeOpacity: Double = 1,
        shadowOpacity: Double = 0.16
    ) -> some View {
        modifier(
            ContentSurfaceModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                emphasis: emphasis,
                strokeOpacity: strokeOpacity,
                shadowOpacity: shadowOpacity
            )
        )
    }

    func liquidGlassCard(
        cornerRadius: CGFloat = 16,
        tint: Color = .accentColor,
        tintOpacity: Double = 0.08,
        strokeOpacity: Double = 1,
        shadowOpacity: Double = 0.16
    ) -> some View {
        contentSurface(
            cornerRadius: cornerRadius,
            tint: tint,
            emphasis: tintOpacity,
            strokeOpacity: strokeOpacity,
            shadowOpacity: shadowOpacity
        )
    }
}
