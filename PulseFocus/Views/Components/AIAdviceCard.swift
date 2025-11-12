import SwiftUI

struct AIAdviceCard: View {
    let advice: AIAdvice
    var status: String? = nil
    var loading: Bool = false
    var onRequest: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 建议").font(.system(size: 22, weight: .semibold))
                Spacer()
                Button(action: onRequest) { Image(systemName: loading ? "hourglass" : "sparkles") }
                    .disabled(loading)
            }
            if let status {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                Label("专注 \(advice.focusMinutes) 分钟", systemImage: "hourglass")
                Label("休息 \(advice.restMinutes) 分钟", systemImage: "cup.and.saucer")
            }.font(.system(size: 17))
            Text(advice.phrase).font(.system(size: 17)).foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.linearGradient(colors: [.green.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 8, x: 0, y: 4)
    }
}
