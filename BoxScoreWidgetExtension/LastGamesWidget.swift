//
//  LastGamesWidget.swift
//  BoxScoreWidget
//
//  Widget 3: Team's Last 3 Results
//

import WidgetKit
import SwiftUI

struct LastGamesProvider: TimelineProvider {
    let teamID: Int
    
    func placeholder(in context: Context) -> LastGamesEntry {
        LastGamesEntry(
            date: Date(),
            games: [],
            error: nil,
            isPreview: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LastGamesEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        Task {
            let entry = await loadData()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LastGamesEntry>) -> Void) {
        Task {
            let entry = await loadData()
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func loadData() async -> LastGamesEntry {
        do {
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 3 Games")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    LastGameRow(game: game, isCompact: true)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct MediumLastGamesView: View {
    let entry: LastGamesEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 3 Games")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(entry.games.prefix(3).enumerated()), id: \.element.game_id) { index, game in
                    LastGameRow(game: game, isCompact: false)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct LastGameRow: View {
    let game: NBAGame
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Date
            if let date = NBAAPIService.parseUTCDate(game.datetime_utc) {
                Text(formatDate(date))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .leading)
            }
            
            // VS indicator
            Text(game.is_home ? "vs" : "@")
                .font(.caption)
                .foregroundColor(.gray)
            
            // Opponent
            Text(game.opponent)
                .font(isCompact ? .caption : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Score and result
            if let teamScore = game.team_score, let opponentScore = game.opponent_score {
                HStack(spacing: 4) {
                    Text("\(teamScore) - \(opponentScore)")
                        .font(isCompact ? .caption : .subheadline)
                        .foregroundColor(.white)
                    
                    // Win/Loss indicator
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

struct LastGamesWidget: Widget {
    let kind: String = "LastGamesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastGamesProvider(teamID: 2)) { entry in
            if #available(iOS 17.0, *) {
                LastGamesWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                LastGamesWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
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

