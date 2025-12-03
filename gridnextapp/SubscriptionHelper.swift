import Foundation

enum SubscriptionHelper {
    static let appGroupId = "group.com.giorgiogunawan.f1races"
    static let subscriptionStatusKey = "isProUser"
    #if DEBUG
    static let developmentProKey = "developmentProEnabled"
    #endif
    
    static var isProUser: Bool {
        get {
            guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
                return false
            }
            return userDefaults.bool(forKey: subscriptionStatusKey)
        }
        set {
            guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
                return
            }
            userDefaults.set(newValue, forKey: subscriptionStatusKey)
        }
    }
    
    static func upgradeURL() -> URL {
        // Deep link URL to open the app's upgrade screen
        return URL(string: "gridbox://upgrade")!
    }
} 