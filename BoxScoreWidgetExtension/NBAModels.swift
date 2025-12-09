import Foundation

// MARK: - Team Models

struct NBATeam: Codable {
    let id: Int
    let nba_team_id: Int
    let name: String
    let abbreviation: String
    let conference: String
    let division: String
}

struct TeamsResponse: Codable {
    let teams: [NBATeam]
    let count: Int
}

struct TeamStandings: Codable {
    let team_id: Int
    let team_name: String
    let team_abbreviation: String  // API returns team_abbreviation, not abbreviation
    let conference: String
    let wins: Int
    let losses: Int
    let conference_rank: Int
    let streak: String
    
    // Convenience accessor for compatibility
    var abbreviation: String { team_abbreviation }
}

// MARK: - Game Models

struct NBAGame: Codable {
    let game_id: Int
    let nba_game_id: String
    let date: String
    let time: String?
    let datetime_utc: String
    let opponent: String
    let opponent_name: String
    let is_home: Bool
    let venue: String?
    let team_score: Int?
    let opponent_score: Int?
    let result: String?
    let score_display: String?
}

struct NextGamesResponse: Codable {
    let team_id: Int
    let games: [NBAGame]
    let count: Int
}

struct LastGamesResponse: Codable {
    let team_id: Int
    let games: [NBAGame]
    let count: Int
}

// MARK: - Player Models

struct PlayerInfo: Codable {
    let nba_player_id: Int
    let full_name: String  // API returns full_name
    let position: String?
    let team_id: Int?
    
    // Convenience accessor
    var player_name: String { full_name }
}

struct SeasonAverages: Codable {
    let player_id: Int?
    let player_name: String
    let jersey_number: String?  // API returns String, not Int
    let season: String
    let ppg: Double  // API uses ppg not pts
    let rpg: Double  // API uses rpg not reb
    let apg: Double  // API uses apg not ast
    let spg: Double  // API uses spg not stl
    let bpg: Double  // API uses bpg not blk
    let fg_pct: Double
    let fg3_pct: Double
    let ft_pct: Double
    let games_played: Int
    let minutes: Double
    
    // Convenience accessors for compatibility
    var pts: Double { ppg }
    var reb: Double { rpg }
    var ast: Double { apg }
    var stl: Double { spg }
    var blk: Double { bpg }
}

struct PlayerLatestGame: Codable {
    let player_id: Int?
    let player_name: String
    let jersey_number: String?  // API returns String, not Int
    let season: String
    let game_date: String
    let datetime_utc: String
    let opponent: String
    let is_home: Bool
    let pts: Int
    let reb: Int
    let ast: Int
    let stl: Int
    let blk: Int
    let fg_pct: Double?  // May be null
    let fg3_pct: Double?  // May be null
    let ft_pct: Double?  // May be null
}

// MARK: - Player Database Model

struct PlayerDatabase: Codable {
    let season: String
    let generated_at: String
    let total_players: Int
    let players: [PlayerDBEntry]
}

struct PlayerDBEntry: Codable {
    let nba_player_id: Int
    let name: String
    let team: String
    let team_name: String
    let number: String
    let position: String
    let height: String?
    let weight: String?
    let age: Double?
    let experience: String?
    let school: String?
}

