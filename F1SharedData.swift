import Foundation
import SwiftUI

struct F1SharedData {
    static let appGroupIdentifier = "group.com.giorgiogunawan.f1races"
    
    static func saveRaces(_ races: [F1Race]) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        guard let encoded = try? JSONEncoder().encode(races) else { return }
        sharedDefaults.set(encoded, forKey: "races")
    }
    
    static func loadRaces() -> [F1Race]? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        guard let data = sharedDefaults.data(forKey: "races") else { return nil }
        return try? JSONDecoder().decode([F1Race].self, from: data)
    }
} 