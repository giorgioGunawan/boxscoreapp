//
//  GridBoxApp.swift
//  GridBox
//
//  Created by Giorgio Gunawan on 22/5/2025.
//

import SwiftUI
import RevenueCat

@main
struct GridBoxApp: App {
    
    init() {
        // Configure RevenueCat
        Purchases.configure(withAPIKey: "appl_DJuiGyaIXrOydVnxXJuxBhDpmix")
        Purchases.logLevel = .debug
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
        if url.scheme == "gridbox" && url.host == "upgrade" {
            // Post notification to show upgrade screen
            NotificationCenter.default.post(name: NSNotification.Name("ShowUpgradeScreen"), object: nil)
        }
    }
}
