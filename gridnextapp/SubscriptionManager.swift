//
//  SubscriptionManager.swift
//  BoxScore
//
//  Created by Giorgio Gunawan on 22/5/2025.
//

import Foundation
import SwiftUI
import WidgetKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isProUser = true {
        didSet {
            // Update shared storage when subscription status changes
            SubscriptionHelper.isProUser = isProUser
            // Force refresh all widget timelines
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        // All features are free - always set to true
        isProUser = true
    }
    
    // MARK: - Public Methods (kept for compatibility but do nothing)
    
    func fetchOfferings() async {
        // No-op - all features are free
    }
    
    func purchaseLifetime() async -> Bool {
        // No-op - all features are free
        isProUser = true
        return true
    }
    
    func restorePurchases() async -> Bool {
        // No-op - all features are free
        isProUser = true
        return true
    }
    
    func checkSubscriptionStatus() async {
        // No-op - all features are free
        isProUser = true
    }
    
    // MARK: - Convenience Properties
    
    var lifetimePrice: String {
        return "$0.00" // Free
    }
    
    var effectiveProStatus: Bool {
        return true // Always free
    }
} 