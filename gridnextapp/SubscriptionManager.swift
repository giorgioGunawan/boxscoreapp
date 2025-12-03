//
//  SubscriptionManager.swift
//  GridBox
//
//  Created by Giorgio Gunawan on 22/5/2025.
//

import Foundation
import RevenueCat
import SwiftUI
import WidgetKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var isProUser = false {
        didSet {
            // Update shared storage when subscription status changes
            SubscriptionHelper.isProUser = isProUser
            // Force refresh all widget timelines
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    @Published var currentOffering: Offering?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        // Initialize from shared storage first
        isProUser = SubscriptionHelper.isProUser
        
        // Setup periodic subscription check
        setupSubscriptionMonitoring()
        
        // Initial subscription check
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Subscription Monitoring
    
    private func setupSubscriptionMonitoring() {
        // Check subscription status when app comes to foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkSubscriptionStatusOnForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Start periodic check timer
        startPeriodicCheck()
    }
    
    private func startPeriodicCheck() {
        // Check subscription status every 5 minutes
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000) // 5 minutes
                await checkSubscriptionStatus()
            }
        }
    }
    
    @objc private func checkSubscriptionStatusOnForeground() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func fetchOfferings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            
            // Debug logging to see what packages are available
            if let offering = currentOffering {
                print("✅ Current offering found: \(offering.identifier)")
                print("📦 Available packages:")
                for package in offering.availablePackages {
                    print("  - Package ID: '\(package.identifier)' | Product: '\(package.storeProduct.productIdentifier)' | Type: \(package.packageType)")
                }
                
                // Log the actual price to verify it's correct
                print("💰 Lifetime price after fetch: \(lifetimePrice)")
            } else {
                print("❌ No current offering found")
                print("📋 All offerings:")
                for (key, offering) in offerings.all {
                    print("  - Offering: '\(key)' with \(offering.availablePackages.count) packages")
                }
            }
        } catch {
            errorMessage = "Failed to load subscription options: \(error.localizedDescription)"
            print("Error fetching offerings: \(error)")
        }
        
        isLoading = false
    }
    
    func purchaseLifetime() async -> Bool {
        guard let offering = currentOffering,
              let lifetimePackage = offering.package(identifier: "$rc_lifetime") else {
            errorMessage = "Lifetime purchase not available"
            return false
        }
        
        return await purchase(package: lifetimePackage)
    }
    
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(customerInfo: customerInfo)
            return true
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("Error restoring purchases: \(error)")
            isLoading = false
            return false
        }
    }
    
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(customerInfo: customerInfo)
        } catch {
            print("Error checking subscription status: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func purchase(package: Package) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let customerInfo = result.customerInfo
            
            updateSubscriptionStatus(customerInfo: customerInfo)
            
            if result.userCancelled {
                errorMessage = nil // Don't show error for user cancellation
                return false
            }
            
            return isProUser
        } catch {
            // Handle RevenueCat specific errors using NSError
            let nsError = error as NSError
            
            // Check for common RevenueCat error codes
            if nsError.domain == "RCPurchasesErrorDomain" {
                switch nsError.code {
                case 1: // Purchase cancelled
                    errorMessage = nil // Don't show error for user cancellation
                case 2: // Store problem
                    errorMessage = "Store is not available. Please try again later."
                case 3: // Purchase not allowed
                    errorMessage = "Purchases are not allowed on this device."
                case 6: // Product already purchased
                    errorMessage = "You have already purchased this product."
                case 10: // Network error
                    errorMessage = "Network error. Please check your connection and try again."
                default:
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                }
            
                // Handle other errors (like StoreKit errors)
                if nsError.domain == "SKErrorDomain" {
                    switch nsError.code {
                    case 2: // SKErrorPaymentCancelled
                        errorMessage = nil // Don't show error for user cancellation
                    case 0: // SKErrorUnknown
                        errorMessage = "An unknown error occurred. Please try again."
                    case 1: // SKErrorClientInvalid
                        errorMessage = "App Store purchases are not allowed."
                    case 3: // SKErrorPaymentInvalid
                        errorMessage = "Purchase information is invalid."
                    case 4: // SKErrorPaymentNotAllowed
                        errorMessage = "This device is not allowed to make purchases."
                    case 5: // SKErrorStoreProductNotAvailable
                        errorMessage = "This product is not available."
                    default:
                        errorMessage = "Purchase failed: \(error.localizedDescription)"
                    }
                } else {
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                }
            }
            
            print("Error making purchase: \(error)")
            isLoading = false
            return false
        }
    }
    
    private func updateSubscriptionStatus(customerInfo: CustomerInfo) {
        // Only update actual subscription status, preserve development mode
        isProUser = customerInfo.entitlements["pro"]?.isActive == true
        isLoading = false
        
        print("Subscription status updated - Pro user: \(isProUser)")
    }
}

// MARK: - Convenience Extensions

extension SubscriptionManager {
    var lifetimePackage: Package? {
        currentOffering?.package(identifier: "$rc_lifetime")
    }
    
    var lifetimePrice: String {
        guard let package = lifetimePackage else {
            print("⚠️ No lifetime package found, using fallback price")
            return "$19.99"
        }
        
        let storeProduct = package.storeProduct
        let localizedPrice = storeProduct.localizedPriceString
        
        // Debug logging to see what's happening
        print("💰 Price Debug Info:")
        print("  - Product ID: \(storeProduct.productIdentifier)")
        print("  - Localized Price String: '\(localizedPrice)'")
        print("  - Price: \(storeProduct.price)")
        
        // Use the localized price string from StoreKit (this should already be properly localized)
        if !localizedPrice.isEmpty && localizedPrice != "0" && localizedPrice != "$0.00" {
            print("✅ Using localized price: \(localizedPrice)")
            return localizedPrice
        }
        
        // Fallback: try to format manually using current locale
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        // Convert Decimal to NSDecimalNumber for NumberFormatter
        let priceAsNSDecimalNumber = NSDecimalNumber(decimal: storeProduct.price)
        
        if let formattedPrice = formatter.string(from: priceAsNSDecimalNumber) {
            print("✅ Using manually formatted price with current locale: \(formattedPrice)")
            return formattedPrice
        }
        
        // Last resort fallback
        print("⚠️ All price formatting failed, using fallback")
        return "$19.99"
    }
    
    var effectiveProStatus: Bool {
        return isProUser
    }
} 