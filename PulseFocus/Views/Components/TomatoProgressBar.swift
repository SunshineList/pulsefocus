import SwiftUI

struct TomatoProgressBar: View {
    let progress: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本段进度").font(.system(size: 17, weight: .semibold))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.15))
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [.green, .purple], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(0, min(1, progress)) * UIScreen.main.bounds.width * 0.8)
            }
            .frame(height: 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.linearGradient(colors: [.green.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 8, x: 0, y: 4)
    }
}

