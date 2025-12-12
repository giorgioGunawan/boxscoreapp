//
//  BoxScoreWidgetExtensionBundle.swift
//  BoxScoreWidgetExtension
//
//  Created by Giorgio Gunawan on 8/12/2025.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Team Entity and Intent

struct TeamEntity: AppEntity {
    var id: String
    var displayString: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "NBA Team"
    static var defaultQuery = TeamQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }
}

struct TeamQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TeamEntity] {
        return allTeams().filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [TeamEntity] {
        return allTeams()
    }
    
    private func allTeams() -> [TeamEntity] {
        return [
            TeamEntity(id: "ATL", displayString: "Atlanta Hawks"),
            TeamEntity(id: "BOS", displayString: "Boston Celtics"),
            TeamEntity(id: "BKN", displayString: "Brooklyn Nets"),
            TeamEntity(id: "CHA", displayString: "Charlotte Hornets"),
            TeamEntity(id: "CHI", displayString: "Chicago Bulls"),
            TeamEntity(id: "CLE", displayString: "Cleveland Cavaliers"),
            TeamEntity(id: "DAL", displayString: "Dallas Mavericks"),
            TeamEntity(id: "DEN", displayString: "Denver Nuggets"),
            TeamEntity(id: "DET", displayString: "Detroit Pistons"),
            TeamEntity(id: "GSW", displayString: "Golden State Warriors"),
            TeamEntity(id: "HOU", displayString: "Houston Rockets"),
            TeamEntity(id: "IND", displayString: "Indiana Pacers"),
            TeamEntity(id: "LAC", displayString: "LA Clippers"),
            TeamEntity(id: "LAL", displayString: "Los Angeles Lakers"),
            TeamEntity(id: "MEM", displayString: "Memphis Grizzlies"),
            TeamEntity(id: "MIA", displayString: "Miami Heat"),
            TeamEntity(id: "MIL", displayString: "Milwaukee Bucks"),
            TeamEntity(id: "MIN", displayString: "Minnesota Timberwolves"),
            TeamEntity(id: "NOP", displayString: "New Orleans Pelicans"),
            TeamEntity(id: "NYK", displayString: "New York Knicks"),
            TeamEntity(id: "OKC", displayString: "Oklahoma City Thunder"),
            TeamEntity(id: "ORL", displayString: "Orlando Magic"),
            TeamEntity(id: "PHI", displayString: "Philadelphia 76ers"),
            TeamEntity(id: "PHX", displayString: "Phoenix Suns"),
            TeamEntity(id: "POR", displayString: "Portland Trail Blazers"),
            TeamEntity(id: "SAC", displayString: "Sacramento Kings"),
            TeamEntity(id: "SAS", displayString: "San Antonio Spurs"),
            TeamEntity(id: "TOR", displayString: "Toronto Raptors"),
            TeamEntity(id: "UTA", displayString: "Utah Jazz"),
            TeamEntity(id: "WAS", displayString: "Washington Wizards")
        ]
    }
}

struct ConfigureTeamIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Team"
    static var description: IntentDescription = IntentDescription("Choose an NBA team")
    
    @Parameter(title: "Team")
    var team: TeamEntity?
    
    init() {
        self.team = TeamEntity(id: "GSW", displayString: "Golden State Warriors")
    }
    
    init(team: TeamEntity) {
        self.team = team
    }
}

// MARK: - Player Entity and Intent

struct PlayerEntity: AppEntity {
    var id: Int
    var name: String
    var team: String
    
    var displayString: String {
        return "\(name) (\(team))"
    }
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "NBA Player"
    static var defaultQuery = PlayerQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(team)")
    }
    
    // Custom query method for team-based filtering
    static func query(for team: TeamEntity?) -> TeamFilteredPlayerQuery {
        return TeamFilteredPlayerQuery(teamFilter: team?.id)
    }
}

struct PlayerQuery: EntityQuery {
    func entities(for identifiers: [PlayerEntity.ID]) async throws -> [PlayerEntity] {
        let allPlayers = await loadPlayersFromRoster()
        return allPlayers.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [PlayerEntity] {
        let allPlayers = await loadPlayersFromRoster()
        // Return all players
        return allPlayers
    }
    
    func entities(matching string: String) async throws -> [PlayerEntity] {
        let allPlayers = await loadPlayersFromRoster()
        let lowercased = string.lowercased()
        return allPlayers.filter { player in
            player.name.lowercased().contains(lowercased) ||
            player.team.lowercased().contains(lowercased)
        }
    }
    
    /// Load players from cached roster (24hr TTL) or fall back to static JSON
    private func loadPlayersFromRoster() async -> [PlayerEntity] {
        // Try to load from App Group cache first
        if let cachedPlayers = loadFromCache() {
            return cachedPlayers
        }
        
        // Fall back to static JSON
        return loadPlayersFromDatabase()
    }
    
    /// Load from App Group UserDefaults cache
    private func loadFromCache() -> [PlayerEntity]? {
        guard let defaults = UserDefaults(suiteName: "group.com.giorgiogunawan.boxscore"),
              let data = defaults.data(forKey: "cachedPlayerRoster"),
              let cached = try? JSONDecoder().decode(CachedPlayerRoster.self, from: data) else {
            return nil
        }
        
        // Check if expired
        if cached.isExpired {
            return nil
        }
        
        // Convert to PlayerEntity
        return cached.roster.players.map { player in
            PlayerEntity(
                id: player.nba_player_id,
                name: player.name,
                team: player.team_abbreviation
            )
        }
    }
    
    /// Fall back to static JSON database
    private func loadPlayersFromDatabase() -> [PlayerEntity] {
        guard let url = Bundle.main.url(forResource: "players_db", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let playersArray = json["players"] as? [[String: Any]] else {
            return []
        }
        
        return playersArray.compactMap { dict -> PlayerEntity? in
            guard let id = dict["nba_player_id"] as? Int,
                  let name = dict["name"] as? String,
                  let team = dict["team"] as? String else {
                return nil
            }
            return PlayerEntity(id: id, name: name, team: team)
        }
    }
}

struct ConfigurePlayerIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Player"
    static var description: IntentDescription = IntentDescription("Choose an NBA player")
    
    @Parameter(title: "Player")
    var player: PlayerEntity?
    
    init() {
        self.player = PlayerEntity(id: 201939, name: "Stephen Curry", team: "GSW")
    }
    
    init(player: PlayerEntity) {
        self.player = player
    }
}



// MARK: - Team-Filtered Player Query

struct TeamFilteredPlayerQuery: EntityQuery {
    var teamFilter: String?
    
    func entities(for identifiers: [PlayerEntity.ID]) async throws -> [PlayerEntity] {
        let allPlayers = await loadPlayersFromRoster()
        return allPlayers.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [PlayerEntity] {
        let allPlayers = await loadPlayersFromRoster()
        
        // Filter by team if specified
        if let teamFilter = teamFilter {
            let filtered = allPlayers.filter { $0.team.uppercased() == teamFilter.uppercased() }
            return filtered
        }
        
        // Return first 50 if no team filter
        return Array(allPlayers.prefix(50))
    }
    
    func entities(matching string: String) async throws -> [PlayerEntity] {
        let allPlayers = await loadPlayersFromRoster()
        let lowercased = string.lowercased()
        
        var filtered = allPlayers.filter { player in
            player.name.lowercased().contains(lowercased)
        }
        
        // Apply team filter if specified
        if let teamFilter = teamFilter {
            filtered = filtered.filter { $0.team.uppercased() == teamFilter.uppercased() }
        }
        
        return Array(filtered.prefix(100))
    }
    
    /// Load players from cached roster (24hr TTL) or fall back to static JSON
    private func loadPlayersFromRoster() async -> [PlayerEntity] {
        // Try to load from App Group cache first
        if let cachedPlayers = loadFromCache() {
            return cachedPlayers
        }
        
        // Fall back to static JSON
        return loadPlayersFromDatabase()
    }
    
    /// Load from App Group UserDefaults cache
    private func loadFromCache() -> [PlayerEntity]? {
        guard let defaults = UserDefaults(suiteName: "group.com.giorgiogunawan.boxscore"),
              let data = defaults.data(forKey: "cachedPlayerRoster"),
              let cached = try? JSONDecoder().decode(CachedPlayerRoster.self, from: data) else {
            return nil
        }
        
        // Check if expired
        if cached.isExpired {
            return nil
        }
        
        // Convert to PlayerEntity
        return cached.roster.players.map { player in
            PlayerEntity(
                id: player.nba_player_id,
                name: player.name,
                team: player.team_abbreviation
            )
        }
    }
    
    /// Fall back to static JSON database
    private func loadPlayersFromDatabase() -> [PlayerEntity] {
        guard let url = Bundle.main.url(forResource: "players_db", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let playersArray = json["players"] as? [[String: Any]] else {
            return []
        }
        
        return playersArray.compactMap { dict -> PlayerEntity? in
            guard let id = dict["nba_player_id"] as? Int,
                  let name = dict["name"] as? String,
                  let team = dict["team"] as? String else {
                return nil
            }
            return PlayerEntity(id: id, name: name, team: team)
        }
    }
}

// MARK: - Widget Bundle

@main
struct BoxScoreWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widgets
        NextGamesWidget()
        SeasonAverageWidget()
        LastGamesWidget()
        TeamStandingWidget()
        PlayerLastGameWidget()
        CountdownWidget()
        
        // Lock Screen Widgets
        if #available(iOS 17.0, *) {
            LockScreenNextGameWidget()
            LockScreenPlayerStatsWidget()
            LockScreenTeamRecordWidget()
        }
    }
}
