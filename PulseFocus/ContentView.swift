//
//  ContentView.swift
//  PulseFocus
//
//  Created by Tuple on 2025/11/12.
//

import SwiftUI
import SwiftData
import Charts

struct RootView: View {
    @StateObject private var app = AppState()
    @StateObject private var timer = SessionTimer()
    @State private var showSplash = true
    var body: some View {
        ZStack {
            TabView {
                HomeView(app: app, timer: timer)
                    .tabItem { Image(systemName: "timer.circle"); Text("主页") }
                HistoryView(app: app)
                    .tabItem { Image(systemName: "chart.line.uptrend.xyaxis"); Text("历史") }
                SettingsView(app: app)
                    .tabItem { Image(systemName: "gearshape"); Text("设置") }
            }
            if showSplash { SplashBrandingView().transition(.opacity) }
        }
        .sheet(isPresented: $app.showSummary) { SessionSummarySheet(app: app) }
        .onAppear {
            Task { try? await HealthManager.shared.requestAuthorization() }
            Task { await NotificationManager().request() }
            ConnectivityManager.shared.activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { withAnimation(.easeInOut(duration: 0.5)) { showSplash = false } }
        }
    }
}
