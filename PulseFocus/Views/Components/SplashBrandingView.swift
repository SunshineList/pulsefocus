import SwiftUI

struct SplashBrandingView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.green.opacity(0.35), Color.purple.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 16) {
                Image("LaunchArt")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .shadow(radius: 12, x: 0, y: 6)
                    .opacity(0.96)
                Text("PulseFocus").font(.system(size: 28, weight: .bold))
                Text("心率自适应番茄钟").font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
