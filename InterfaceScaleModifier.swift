import SwiftUI

struct InterfaceScaleModifier: ViewModifier {
    @EnvironmentObject private var displaySettings: AppDisplaySettings

    func body(content: Content) -> some View {
        GeometryReader { proxy in
            let scale = max(0.5, displaySettings.interfaceScale)
            let logicalWidth = max(proxy.size.width / scale, 1)
            let logicalHeight = max(proxy.size.height / scale, 1)

            content
                .frame(width: logicalWidth, height: logicalHeight, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .animation(nil, value: displaySettings.interfaceScale)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .clipped()
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
