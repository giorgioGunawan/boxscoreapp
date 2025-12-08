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
    let abbreviation: String
    let conference: String
    let wins: Int
    let losses: Int
    let conference_rank: Int
    let streak: String
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
    let player_id: Int?
    let nba_player_id: Int
    let player_name: String
    let jersey_number: Int?
    let team_id: Int?
    let team_name: String?
    let team_abbreviation: String?
}

struct SeasonAverages: Codable {
    let player_id: Int?
    let nba_player_id: Int
    let player_name: String
    let jersey_number: Int?
    let season: String
    let pts: Double
    let reb: Double
    let ast: Double
    let stl: Double
    let blk: Double
    let fg_pct: Double
    let fg3_pct: Double
    let ft_pct: Double
    let games_played: Int
    let minutes: Double
}

struct PlayerLatestGame: Codable {
    let player_id: Int?
    let player_name: String
    let jersey_number: Int?
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
    let fg_pct: Double
    let fg3_pct: Double
    let ft_pct: Double
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

