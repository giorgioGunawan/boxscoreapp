//
//  LastGamesWidget.swift
//  BoxScoreWidget
//
//  Widget 3: Team's Last 3 Results
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct LastGamesProvider: AppIntentTimelineProvider {
    typealias Entry = LastGamesEntry
    typealias Intent = ConfigureTeamIntent
    
    func placeholder(in context: Context) -> LastGamesEntry {
        LastGamesEntry(
            date: Date(),
            games: [],
            error: nil,
            isPreview: true
        )
    }
    
    func snapshot(for configuration: ConfigureTeamIntent, in context: Context) async -> LastGamesEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigureTeamIntent, in context: Context) async -> Timeline<LastGamesEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigureTeamIntent) async -> LastGamesEntry {
        guard let teamAbbr = configuration.team?.id else {
            return LastGamesEntry(date: Date(), games: [], error: "No team selected", isPreview: false)
        }
        do {
            let teamID = try await NBAAPIService.shared.getTeamID(for: teamAbbr)
            let gamesResponse = try await NBAAPIService.shared.getLastGames(teamID: teamID, count: 3)
            return LastGamesEntry(
                date: Date(),
                games: gamesResponse.games,
                error: nil,
                isPreview: false
            )
        } catch {
            return LastGamesEntry(
                date: Date(),
                games: [],
                error: error.localizedDescription,
                isPreview: false
            )
        }
    }
}

struct LastGamesEntry: TimelineEntry {
    let date: Date
    let games: [NBAGame]
    let error: String?
    let isPreview: Bool
}

struct LastGamesWidgetEntryView: View {
    var entry: LastGamesProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let error = entry.error {
            ErrorView(error: error)
        } else if entry.games.isEmpty && !entry.isPreview {
            EmptyView(message: "No recent games")
        } else {
            switch family {
            case .systemSmall:
                SmallLastGamesView(entry: entry)
            case .systemMedium:
                MediumLastGamesView(entry: entry)
            default:
                SmallLastGamesView(entry: entry)
            }
        }
    }
}

struct SmallLastGamesView: View {
    let entry: LastGamesEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Last 3 Results")
                .font(.system(size: 13, weight: .bold))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    CompactResultRow(game: game)
                }
            }
        }
        .padding(6)
    }
}

struct MediumLastGamesView: View {
    let entry: LastGamesEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recent Results")
                .font(.system(size: 16, weight: .bold))
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    DetailedResultRow(game: game)
                }
            }
        }
        .padding(6)
    }
}

struct LastGameRow: View {
    let game: NBAGame
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if let date = NBAAPIService.parseUTCDate(game.datetime_utc) {
                Text(formatDate(date))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .leading)
            }
            
            Text(game.is_home ? "vs" : "@")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(game.opponent)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            if let teamScore = game.team_score, let opponentScore = game.opponent_score {
                HStack(spacing: 4) {
                    Text("\(teamScore) - \(opponentScore)")
                        .font(isCompact ? .caption : .subheadline)
                        .foregroundColor(.white)
                    
                    if let result = game.result {
                        Text(result)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(result == "W" ? .green : .red)
                            .frame(width: 20)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct CompactResultRow: View {
    let game: NBAGame
    
    var body: some View {
        HStack(spacing: 4) {
            if let result = game.result {
                Text(result)
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(result == "W" ? .green : .red)
                    .frame(width: 16)
            }
            
            Text(game.is_home ? "vs" : "@")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(game.opponent)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
            
            Spacer()
            
            if let teamScore = game.team_score, let opponentScore = game.opponent_score {
                Text("\(teamScore)-\(opponentScore)")
                    .font(.system(size: 15, weight: .bold))
            }
        }
    }
}

struct DetailedResultRow: View {
    let game: NBAGame
    
    var body: some View {
        HStack(spacing: 10) {
            if let result = game.result {
                Text(result)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(result == "W" ? .green : .red)
                    .frame(width: 22)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(game.is_home ? "vs" : "@")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(game.is_home ? .green : .blue)
                    Text(game.opponent)
                        .font(.system(size: 14, weight: .bold))
                }
                
                if let date = NBAAPIService.parseUTCDate(game.datetime_utc) {
                    Text(formatDate(date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let teamScore = game.team_score, let opponentScore = game.opponent_score {
                Text("\(teamScore)-\(opponentScore)")
                    .font(.system(size: 18, weight: .bold))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "E MMM d"
        return formatter.string(from: date)
    }
}

@available(iOS 17.0, *)
struct LastGamesWidget: Widget {
    let kind: String = "LastGamesWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTeamIntent.self, provider: LastGamesProvider()) { entry in
            if #available(iOS 17.0, *) {
                LastGamesWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {}
            }
        }
        .configurationDisplayName("Last 3 Results")
        .description("Shows your team's last 3 game results.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    LastGamesWidget()
} timeline: {
    LastGamesEntry(
        date: Date(),
        games: [
            NBAGame(
                game_id: 1,
                nba_game_id: "001",
                date: "2025-12-05",
                time: nil,
                datetime_utc: "2025-12-05T03:00:00+00:00",
                opponent: "LAL",
                opponent_name: "Los Angeles Lakers",
                is_home: false,
                venue: nil,
                team_score: 108,
                opponent_score: 102,
                result: "W",
                score_display: "108-102"
            )
        ],
        error: nil,
        isPreview: true
    )
}

