import Foundation
import SwiftUI

struct BoxScoreSharedData {
    static let appGroupIdentifier = "group.com.giorgiogunawan.boxscore"
    
    static func saveTeams(_ teams: [NBATeam]) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return }
        guard let encoded = try? JSONEncoder().encode(teams) else { return }
        sharedDefaults.set(encoded, forKey: "teams")
    }
    
    static func loadTeams() -> [NBATeam]? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else { return nil }
        guard let data = sharedDefaults.data(forKey: "teams") else { return nil }
        return try? JSONDecoder().decode([NBATeam].self, from: data)
    }
} 