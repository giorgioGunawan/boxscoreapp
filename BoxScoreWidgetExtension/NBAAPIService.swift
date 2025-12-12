import Foundation

class NBAAPIService {
    static let shared = NBAAPIService()
    private let baseURL = "https://boxscore-backend.onrender.com/api"
    
    // Cache for team ID mapping
    private var teamIDMapping: [String: Int] = [:]
    private var teamsCache: [NBATeam] = []
    private var lastTeamsFetch: Date?
    private let teamsCacheTimeout: TimeInterval = 3600 // 1 hour
    
    // Cache for player database (bundled JSON - fallback)
    private var playerDatabase: PlayerDatabase?
    private var playerNameToIDMapping: [String: Int] = [:]
    
    // Cache for live player roster (API-based, 24hr TTL)
    private let appGroupDefaults: UserDefaults?
    private let rosterCacheKey = "cachedPlayerRoster"
    private let rosterCacheTimeout: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {
        // Initialize App Group UserDefaults for sharing between app and widgets
        appGroupDefaults = UserDefaults(suiteName: "group.com.giorgiogunawan.boxscore")
        
        loadPlayerDatabase() // Load bundled JSON as fallback
    }
    
    // MARK: - Team ID Mapping
    
    func fetchTeams() async throws -> [NBATeam] {
        // Check cache first
        if let lastFetch = lastTeamsFetch,
           Date().timeIntervalSince(lastFetch) < teamsCacheTimeout,
           !teamsCache.isEmpty {
            return teamsCache
        }
        
        guard let url = URL(string: "\(baseURL)/teams") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let teamsResponse = try JSONDecoder().decode(TeamsResponse.self, from: data)
        
        // Update cache
        teamsCache = teamsResponse.teams
        lastTeamsFetch = Date()
        
        // Update mapping
        teamIDMapping.removeAll()
        for team in teamsResponse.teams {
            teamIDMapping[team.abbreviation.uppercased()] = team.id
        }
        
        return teamsResponse.teams
    }
    
    func getTeamID(for abbreviation: String) async throws -> Int {
        // Check cache first
        if let teamID = teamIDMapping[abbreviation.uppercased()] {
            return teamID
        }
        
        // Fetch teams if not cached
        _ = try await fetchTeams()
        
        guard let teamID = teamIDMapping[abbreviation.uppercased()] else {
            throw APIError.teamNotFound
        }
        
        return teamID
    }
    
    func getTeam(byAbbreviation abbreviation: String) async throws -> NBATeam {
        guard let url = URL(string: "\(baseURL)/teams/abbr/\(abbreviation)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw APIError.teamNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(NBATeam.self, from: data)
    }
    
    // MARK: - Player Database
    
    private func loadPlayerDatabase() {
        guard let url = Bundle.main.url(forResource: "players_db", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let database = try? JSONDecoder().decode(PlayerDatabase.self, from: data) else {
            return
        }
        
        playerDatabase = database
        
        // Create name to ID mapping
        playerNameToIDMapping.removeAll()
        for player in database.players {
            playerNameToIDMapping[player.name.lowercased()] = player.nba_player_id
        }
    }
    
    func getPlayerID(for name: String) -> Int? {
        return playerNameToIDMapping[name.lowercased()]
    }
    
    func searchPlayers(query: String) -> [PlayerDBEntry] {
        guard let database = playerDatabase else { return [] }
        
        let lowerQuery = query.lowercased()
        return database.players.filter { player in
            player.name.lowercased().contains(lowerQuery)
        }
    }
    
    // MARK: - Player Roster (Live API with 24hr cache)
    
    /// Fetches the current player roster from the API or cache
    /// Returns cached data if < 24 hours old, otherwise fetches fresh data
    func getPlayerRoster() async throws -> PlayerRosterResponse {
        // Try to load from cache first
        if let cachedRoster = loadCachedRoster(), !cachedRoster.isExpired {
            print("✅ Using cached player roster (age: \(Int(Date().timeIntervalSince(cachedRoster.cachedAt) / 3600))hrs)")
            return cachedRoster.roster
        }
        
        // Cache expired or doesn't exist, fetch from API
        print("🔄 Fetching fresh player roster from API...")
        let roster = try await fetchPlayerRosterFromAPI()
        
        // Cache the result
        saveCachedRoster(roster)
        
        return roster
    }
    
    /// Fetches player roster from the backend API
    private func fetchPlayerRosterFromAPI() async throws -> PlayerRosterResponse {
        guard let url = URL(string: "\(baseURL)/players/roster") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(PlayerRosterResponse.self, from: data)
    }
    
    /// Loads cached roster from App Group UserDefaults
    private func loadCachedRoster() -> CachedPlayerRoster? {
        guard let defaults = appGroupDefaults,
              let data = defaults.data(forKey: rosterCacheKey) else {
            return nil
        }
        
        return try? JSONDecoder().decode(CachedPlayerRoster.self, from: data)
    }
    
    /// Saves roster to App Group UserDefaults
    private func saveCachedRoster(_ roster: PlayerRosterResponse) {
        guard let defaults = appGroupDefaults else { return }
        
        let cachedRoster = CachedPlayerRoster(roster: roster, cachedAt: Date())
        
        if let data = try? JSONEncoder().encode(cachedRoster) {
            defaults.set(data, forKey: rosterCacheKey)
            print("💾 Saved player roster to cache (\(roster.total_players) players)")
        }
    }
    
    /// Gets a player's current team by NBA player ID
    func getPlayerTeam(nbaPlayerID: Int) async throws -> (team: String, teamName: String) {
        let roster = try await getPlayerRoster()
        
        guard let player = roster.players.first(where: { $0.nba_player_id == nbaPlayerID }) else {
            throw APIError.playerNotFound
        }
        
        return (team: player.team_abbreviation, teamName: player.team_name)
    }
    
    /// Forces a refresh of the player roster cache
    func refreshPlayerRoster() async throws {
        print("🔄 Force refreshing player roster...")
        let roster = try await fetchPlayerRosterFromAPI()
        saveCachedRoster(roster)
    }
    
    // MARK: - Widget Endpoints
    
    // Widget 1: Next 3 Games
    func getNextGames(teamID: Int, count: Int = 3) async throws -> NextGamesResponse {
        guard let url = URL(string: "\(baseURL)/teams/\(teamID)/next-games?count=\(count)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(NextGamesResponse.self, from: data)
    }
    
    func getTeamStandings(teamID: Int) async throws -> TeamStandings {
        guard let url = URL(string: "\(baseURL)/teams/\(teamID)/standings") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(TeamStandings.self, from: data)
    }
    
    // Widget 2: Season Average
    func getSeasonAverages(nbaPlayerID: Int) async throws -> SeasonAverages {
        guard let url = URL(string: "\(baseURL)/players/\(nbaPlayerID)/season-averages") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw APIError.playerNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(SeasonAverages.self, from: data)
    }
    
    // Widget 3: Team's Last 3 Results
    func getLastGames(teamID: Int, count: Int = 3) async throws -> LastGamesResponse {
        guard let url = URL(string: "\(baseURL)/teams/\(teamID)/last-games?count=\(count)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(LastGamesResponse.self, from: data)
    }
    
    // Widget 5: Player Last Game
    func getPlayerLatestGame(nbaPlayerID: Int) async throws -> PlayerLatestGame {
        guard let url = URL(string: "\(baseURL)/players/\(nbaPlayerID)/latest-game") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw APIError.playerNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(PlayerLatestGame.self, from: data)
    }
    
    // Widget 6: Countdown to Next Game (uses same endpoint as Widget 1 with count=1)
    func getNextGame(teamID: Int) async throws -> NextGamesResponse {
        return try await getNextGames(teamID: teamID, count: 1)
    }
    
    // MARK: - Helper: Get Player Info
    func getPlayerInfo(nbaPlayerID: Int) async throws -> PlayerInfo {
        guard let url = URL(string: "\(baseURL)/players/\(nbaPlayerID)/info") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 404 {
            throw APIError.playerNotFound
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(PlayerInfo.self, from: data)
    }
}

// MARK: - API Errors

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case teamNotFound
    case playerNotFound
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .teamNotFound:
            return "Team not found"
        case .playerNotFound:
            return "Player not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Date/Time Helpers

extension NBAAPIService {
    static func parseUTCDate(_ dateString: String) -> Date? {
        // Try with fractional seconds first
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Fallback: try basic date formatter
        let basicFormatter = DateFormatter()
        basicFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        basicFormatter.locale = Locale(identifier: "en_US_POSIX")
        return basicFormatter.date(from: dateString)
    }
    
    static func formatLocalDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func formatLocalDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func formatTimeUntil(_ date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "Game started"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

