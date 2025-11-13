import SwiftUI

struct SplashBrandingView: View {
    @State private var appear: Bool = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Color.green, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                VStack(spacing: 18) {
                    let targetWidth = min(geo.size.width * 0.72, 420)
                    Image("LaunchArt")
                        .resizable()
                        .scaledToFit()
                        .frame(width: targetWidth)
                        .shadow(radius: 14, x: 0, y: 8)
                        .opacity(appear ? 1 : 0.0)
                        .scaleEffect(appear ? 1.0 : 0.92)
                    Text("PulseFocus").font(.system(size: 30, weight: .bold))
                    Text("心率自适应番茄钟").font(.callout).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appear = true } }
    }
}
