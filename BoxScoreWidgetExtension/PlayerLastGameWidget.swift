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
        ZStack(alignment: .topLeading) {
            // Big opaque jersey number as background
            if let jersey = game.jersey_number {
                Text(jersey)
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(.primary.opacity(0.08))
                    .offset(x: -10, y: -15)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                // Big player name display
                VStack(alignment: .leading, spacing: 0) {
                    let nameParts = game.player_name.split(separator: " ")
                    if nameParts.count >= 2 {
                        Text(String(nameParts.first ?? ""))
                            .font(.system(size: 16, weight: .black))
                            .lineLimit(1)
                        Text(String(nameParts.last ?? ""))
                            .font(.system(size: 16, weight: .black))
                            .lineLimit(1)
                    } else {
                        Text(game.player_name)
                            .font(.system(size: 16, weight: .black))
                            .lineLimit(2)
                    }
                }
                
                Divider()
                
                // Main stats - horizontal layout
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 0) {
                        Text("\(game.pts)")
                            .font(.system(size: 22, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(game.reb)")
                            .font(.system(size: 22, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(game.ast)")
                            .font(.system(size: 22, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack(spacing: 0) {
                        Text("pts")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("reb")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("ast")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 3) {
                    Text(game.is_home ? "vs" : "@")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(game.is_home ? .green : .blue)
                    Text(game.opponent)
                        .font(.system(size: 11, weight: .bold))
                    Text("•")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Text(game.game_date)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(6)
        }
    }
}

struct MediumPlayerLastGameView: View {
        let game: PlayerLatestGame
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                // Big opaque jersey number as background
                if let jersey = game.jersey_number {
                    Text(jersey)
                        .font(.system(size: 120, weight: .black))
                        .foregroundColor(.primary.opacity(0.06))
                        .offset(x: -15, y: -20)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    // Player name
                    VStack(alignment: .leading, spacing: 0) {
                        let nameParts = game.player_name.split(separator: " ")
                        if nameParts.count >= 2 {
                            Text(String(nameParts.first ?? ""))
                                .font(.system(size: 20, weight: .black))
                                .lineLimit(1)
                            Text(String(nameParts.last ?? ""))
                                .font(.system(size: 20, weight: .black))
                                .lineLimit(1)
                        } else {
                            Text(game.player_name)
                                .font(.system(size: 20, weight: .black))
                                .lineLimit(2)
                        }
                    }
                    
                    Divider()
                    
                    // Main stats - horizontal layout
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 0) {
                            Text("\(game.pts)")
                                .font(.system(size: 20, weight: .black))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(game.reb)")
                                .font(.system(size: 20, weight: .black))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(game.ast)")
                                .font(.system(size: 20, weight: .black))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        HStack(spacing: 0) {
                            Text("pts")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("reb")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("ast")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Secondary stats
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 0) {
                            Text("\(game.stl)")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(game.blk)")
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        HStack(spacing: 0) {
                            Text("stl")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("blk")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Divider()
                    
                    // Shooting percentages - aligned with name
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 12) {
                            Text(String(format: "%.1f%%", game.fg_pct ?? 0))
                                .font(.system(size: 11, weight: .bold))
                                .fixedSize()
                                .frame(width: 38, alignment: .leading)
                            Text(String(format: "%.1f%%", game.fg3_pct ?? 0))
                                .font(.system(size: 11, weight: .bold))
                                .fixedSize()
                                .frame(width: 38, alignment: .leading)
                            Text(String(format: "%.1f%%", game.ft_pct ?? 0))
                                .font(.system(size: 11, weight: .bold))
                                .fixedSize()
                                .frame(width: 38, alignment: .leading)
                        }
                        HStack(spacing: 12) {
                            Text("FG%")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 38, alignment: .leading)
                            Text("3P%")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 38, alignment: .leading)
                            Text("FT%")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 38, alignment: .leading)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text(game.is_home ? "vs" : "@")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(game.is_home ? .green : .blue)
                        Text(game.opponent)
                            .font(.system(size: 12, weight: .bold))
                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(game.game_date)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(6)
            }
        }
    }
    
    @available(iOS 17.0, *)
    struct PlayerLastGameWidget: Widget {
        let kind: String = "PlayerLastGameWidget"
        
        var body: some WidgetConfiguration {
            AppIntentConfiguration(kind: kind, intent: ConfigurePlayerIntent.self, provider: PlayerLastGameProvider()) { entry in
                if #available(iOS 17.0, *) {
                    PlayerLastGameWidgetEntryView(entry: entry)
                        .containerBackground(for: .widget) {}
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
