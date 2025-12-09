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
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Next Games")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if let standings = entry.standings {
                    Text("\(standings.abbreviation) (\(standings.wins)-\(standings.losses))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Games list
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    GameRow(game: game, isCompact: true)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct MediumNextGamesView: View {
    let entry: NextGamesEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with standings
            if let standings = entry.standings {
                HStack {
                    Text(standings.team_name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(standings.wins)-\(standings.losses)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            Text("Next 3 Games")
                .font(.headline)
                .foregroundColor(.gray)
            
            // Games list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    GameRow(game: game, isCompact: false)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct GameRow: View {
    let game: NBAGame
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // VS indicator
            Text(game.is_home ? "vs" : "@")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 25, alignment: .leading)
            
            // Opponent
            Text(game.opponent)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Date/Time
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

struct ErrorView: View {
    let error: String
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text("Error")
                .font(.headline)
                .foregroundColor(.white)
            Text(error)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

struct EmptyView: View {
    let message: String
    
    var body: some View {
        VStack {
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

@available(iOS 17.0, *)
struct NextGamesWidget: Widget {
    let kind: String = "NextGamesWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTeamIntent.self, provider: NextGamesProvider()) { entry in
            if #available(iOS 17.0, *) {
                NextGamesWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                NextGamesWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
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

