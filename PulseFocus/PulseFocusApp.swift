//
//  PulseFocusApp.swift
//  PulseFocus
//
//  Created by Tuple on 2025/11/12.
//

import SwiftUI
import SwiftData

@main
struct PulseFocusApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Session.self])
    }
}
