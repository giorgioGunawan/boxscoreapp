//
//  NextGamesWidget.swift
//  BoxScoreWidget
//
//  Widget 1: Next 3 Games
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct NextGamesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NextGamesEntry {
        NextGamesEntry(
            date: Date(),
            games: [],
            standings: nil,
            error: nil,
            isPreview: true
        )
    }
    
    func snapshot(for configuration: ConfigureTeamIntent, in context: Context) async -> NextGamesEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigureTeamIntent, in context: Context) async -> Timeline<NextGamesEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigureTeamIntent) async -> NextGamesEntry {
        guard let teamAbbr = configuration.team?.id else {
            return NextGamesEntry(date: Date(), games: [], standings: nil, error: "No team selected", isPreview: false)
        }
        do {
            let teamID = try await NBAAPIService.shared.getTeamID(for: teamAbbr)
            let gamesResponse = try await NBAAPIService.shared.getNextGames(teamID: teamID, count: 3)
            let standings = try? await NBAAPIService.shared.getTeamStandings(teamID: teamID)
            
            return NextGamesEntry(
                date: Date(),
                games: gamesResponse.games,
                standings: standings,
                error: nil,
                isPreview: false
            )
        } catch {
            return NextGamesEntry(
                date: Date(),
                games: [],
                standings: nil,
                error: error.localizedDescription,
                isPreview: false
            )
        }
    }
}

struct NextGamesEntry: TimelineEntry {
    let date: Date
    let games: [NBAGame]
    let standings: TeamStandings?
    let error: String?
    let isPreview: Bool
}

struct NextGamesWidgetEntryView: View {
    var entry: NextGamesProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let error = entry.error {
            ErrorView(error: error)
        } else if entry.games.isEmpty && !entry.isPreview {
            EmptyView(message: "No upcoming games")
        } else {
            switch family {
            case .systemSmall:
                SmallNextGamesView(entry: entry)
            case .systemMedium:
                MediumNextGamesView(entry: entry)
            default:
                SmallNextGamesView(entry: entry)
            }
        }
    }
}

struct SmallNextGamesView: View {
    let entry: NextGamesEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Compact header
            if let standings = entry.standings {
                HStack(alignment: .center, spacing: 6) {
                    Text(standings.abbreviation)
                        .font(.system(size: 17, weight: .black))
                    Text("\(standings.wins)-\(standings.losses)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            
            Divider()
            
            // Compact game list
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    CompactGameRow(game: game)
                }
            }
        }
        .padding(6)
    }
}

struct MediumNextGamesView: View {
    let entry: NextGamesEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Compact header with more info
            if let standings = entry.standings {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(standings.abbreviation)
                            .font(.system(size: 19, weight: .black))
                        Text("#\(standings.conference_rank) \(standings.conference)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Text("\(standings.wins)")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.green)
                        Text("-")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\(standings.losses)")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.red)
                    }
                }
            }
            
            Divider()
            
            // Compact game list with more details
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    MediumGameRow(game: game)
                }
            }
        }
        .padding(6)
    }
}

struct GameRow: View {
    let game: NBAGame
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text(game.is_home ? "vs" : "@")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 25, alignment: .leading)
            
            Text(game.opponent)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            if let date = NBAAPIService.parseUTCDate(game.datetime_utc) {
                Text(formatGameDate(date, isCompact: isCompact))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func formatGameDate(_ date: Date, isCompact: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        
        if isCompact {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d h:mm a"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Compact Components

struct CompactGameRow: View {
    let game: NBAGame
    
    var body: some View {
        HStack(spacing: 4) {
            Text(game.is_home ? "vs" : "@")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(game.opponent)
                .font(.system(size: 14, weight: .bold))
                .frame(minWidth: 40, alignment: .leading)
            
            Spacer()
            
            if let date = NBAAPIService.parseUTCDate(game.datetime_utc) {
                Text(formatCompactDate(date))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatCompactDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct MediumGameRow: View {
    let game: NBAGame
    
    var body: some View {
        HStack(spacing: 6) {
            Text(game.is_home ? "vs" : "@")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(game.is_home ? .green : .blue)
                .frame(width: 24)
            
            Text(game.opponent)
                .font(.system(size: 15, weight: .bold))
                .frame(minWidth: 45, alignment: .leading)
            
            Spacer()
            
            if let date = NBAAPIService.parseUTCDate(game.datetime_utc) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(formatDate(date))
                        .font(.system(size: 12, weight: .bold))
                    Text(formatTime(date))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "E MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct ErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text("Error")
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyView: View {
    let message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

@available(iOS 17.0, *)
struct NextGamesWidget: Widget {
    let kind: String = "NextGamesWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTeamIntent.self, provider: NextGamesProvider()) { entry in
            if #available(iOS 17.0, *) {
                NextGamesWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {}
            }
        }
        .configurationDisplayName("Next 3 Games")
        .description("Shows your team's next 3 upcoming games.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    NextGamesWidget()
} timeline: {
    NextGamesEntry(
        date: Date(),
        games: [
            NBAGame(
                game_id: 1,
                nba_game_id: "001",
                date: "2025-12-09",
                time: "20:00",
                datetime_utc: "2025-12-10T01:00:00+00:00",
                opponent: "LAL",
                opponent_name: "Los Angeles Lakers",
                is_home: true,
                venue: "Home",
                team_score: nil,
                opponent_score: nil,
                result: nil,
                score_display: nil
            )
        ],
        standings: TeamStandings(
            team_id: 2,
            team_name: "Golden State Warriors",
            team_abbreviation: "GSW",
            conference: "West",
            wins: 11,
            losses: 11,
            conference_rank: 9,
            streak: "W2"
        ),
        error: nil,
        isPreview: true
    )
}

