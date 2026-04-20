import SwiftUI

struct InterfaceScaleModifier: ViewModifier {
    @EnvironmentObject private var displaySettings: AppDisplaySettings

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let scale = max(0.5, displaySettings.interfaceScale)
            let width = max(proxy.size.width / scale, 1)
            let height = max(proxy.size.height / scale, 1)

            content
                .frame(width: width, height: height, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

extension View {
    func interfaceScaled() -> some View {
        modifier(InterfaceScaleModifier())
    }
}

#Preview {
    VStack(spacing: 12) {
        Text("Scaled Interface")
            .font(.title2.weight(.semibold))
        Text("This view scales with AppDisplaySettings.interfaceScale.")
            .font(.caption)
            .foregroundColor(.secondary)
        Button("Example Button") {}
            .buttonStyle(.borderedProminent)
    }
    .padding()
    .interfaceScaled()
    .environmentObject(AppDisplaySettings())
    .frame(width: 400, height: 260)
}
