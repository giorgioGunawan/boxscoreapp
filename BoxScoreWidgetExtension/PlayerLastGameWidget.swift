//
//  PlayerLastGameWidget.swift
//  BoxScoreWidget
//
//  Widget 5: Player Last Game
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct PlayerLastGameProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PlayerLastGameEntry {
        PlayerLastGameEntry(
            date: Date(),
            game: nil,
            error: nil,
            isPreview: true
        )
    }
    
    func snapshot(for configuration: ConfigurePlayerIntent, in context: Context) async -> PlayerLastGameEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigurePlayerIntent, in context: Context) async -> Timeline<PlayerLastGameEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigurePlayerIntent) async -> PlayerLastGameEntry {
        guard let nbaPlayerID = configuration.player?.id else {
            return PlayerLastGameEntry(date: Date(), game: nil, error: "No player selected", isPreview: false)
        }
        do{
            let game = try await NBAAPIService.shared.getPlayerLatestGame(nbaPlayerID: nbaPlayerID)
            return PlayerLastGameEntry(
                date: Date(),
                game: game,
                error: nil,
                isPreview: false
            )
        } catch {
            return PlayerLastGameEntry(
                date: Date(),
                game: nil,
                error: error.localizedDescription,
                isPreview: false
            )
        }
    }
}

struct PlayerLastGameEntry: TimelineEntry {
    let date: Date
    let game: PlayerLatestGame?
    let error: String?
    let isPreview: Bool
}

struct PlayerLastGameWidgetEntryView: View {
    var entry: PlayerLastGameProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let error = entry.error {
            ErrorView(error: error)
        } else if let game = entry.game {
            switch family {
            case .systemSmall:
                SmallPlayerLastGameView(game: game)
            case .systemMedium:
                MediumPlayerLastGameView(game: game)
            default:
                SmallPlayerLastGameView(game: game)
            }
        } else {
            EmptyView(message: "No game data")
        }
    }
}

struct SmallPlayerLastGameView: View {
    let game: PlayerLatestGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Player name and date
            VStack(alignment: .leading, spacing: 4) {
                Text(game.player_name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(game.game_date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Main stats
            VStack(alignment: .leading, spacing: 4) {
                StatRow(label: "PTS", value: "\(game.pts)")
                StatRow(label: "REB", value: "\(game.reb)")
                StatRow(label: "AST", value: "\(game.ast)")
            }
            
            Spacer()
            
            // Opponent
            HStack {
                Text(game.is_home ? "vs" : "@")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(game.opponent)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct MediumPlayerLastGameView: View {
    let game: PlayerLatestGame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.player_name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(game.game_date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let jersey = game.jersey_number {
                    Text("#\(jersey)")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            // Stats grid
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(label: "PTS", value: "\(game.pts)")
                    StatRow(label: "REB", value: "\(game.reb)")
                    StatRow(label: "AST", value: "\(game.ast)")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(label: "STL", value: "\(game.stl)")
                    StatRow(label: "BLK", value: "\(game.blk)")
                }
            }
            
            Spacer()
            
            // Percentages
            HStack(spacing: 12) {
                Text("\(Int((game.fg_pct ?? 0) * 100))% FG")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int((game.fg3_pct ?? 0) * 100))% 3FG")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int((game.ft_pct ?? 0) * 100))% FT")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Opponent
            HStack {
                Text(game.is_home ? "vs" : "@")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(game.opponent)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

@available(iOS 17.0, *)
struct PlayerLastGameWidget: Widget {
    let kind: String = "PlayerLastGameWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurePlayerIntent.self, provider: PlayerLastGameProvider()) { entry in
            if #available(iOS 17.0, *) {
                PlayerLastGameWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                PlayerLastGameWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
            }
        }
        .configurationDisplayName("Player Last Game")
        .description("Shows a player's last game performance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    PlayerLastGameWidget()
} timeline: {
    PlayerLastGameEntry(
        date: Date(),
        game: PlayerLatestGame(
            player_id: 1,
            player_name: "Stephen Curry",
            jersey_number: "30",
            season: "2025-26",
            game_date: "05 Dec 2025",
            datetime_utc: "2025-12-05T03:00:00+00:00",
            opponent: "LAL",
            is_home: false,
            pts: 30,
            reb: 15,
            ast: 4,
            stl: 2,
            blk: 1,
            fg_pct: 0.45,
            fg3_pct: 0.40,
            ft_pct: 0.90
        ),
        error: nil,
        isPreview: true
    )
}

