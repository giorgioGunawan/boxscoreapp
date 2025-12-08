//
//  BoxScoreApp.swift
//  BoxScore
//
//  Created by Giorgio Gunawan on 22/5/2025.
//

import SwiftUI

@main
struct BoxScoreApp: App {
    
    init() {
        // No initialization needed - all features are free
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        if url.scheme == "boxscore" && url.host == "upgrade" {
            // Post notification to show upgrade screen
            NotificationCenter.default.post(name: NSNotification.Name("ShowUpgradeScreen"), object: nil)
        }
    }
}
