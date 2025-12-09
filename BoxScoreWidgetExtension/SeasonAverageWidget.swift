//
//  SeasonAverageWidget.swift
//  BoxScoreWidget
//
//  Widget 2: Season Average
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct SeasonAverageProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SeasonAverageEntry {
        SeasonAverageEntry(
            date: Date(),
            averages: nil,
            error: nil,
            isPreview: true
        )
    }
    
    func snapshot(for configuration: ConfigurePlayerIntent, in context: Context) async -> SeasonAverageEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigurePlayerIntent, in context: Context) async -> Timeline<SeasonAverageEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigurePlayerIntent) async -> SeasonAverageEntry {
        guard let nbaPlayerID = configuration.player?.id else {
            return SeasonAverageEntry(date: Date(), averages: nil, error: "No player selected", isPreview: false)
        }
        do {
            let averages = try await NBAAPIService.shared.getSeasonAverages(nbaPlayerID: nbaPlayerID)
            return SeasonAverageEntry(
                date: Date(),
                averages: averages,
                error: nil,
                isPreview: false
            )
        } catch {
            return SeasonAverageEntry(
                date: Date(),
                averages: nil,
                error: error.localizedDescription,
                isPreview: false
            )
        }
    }
}

struct SeasonAverageEntry: TimelineEntry {
    let date: Date
    let averages: SeasonAverages?
    let error: String?
    let isPreview: Bool
}

struct SeasonAverageWidgetEntryView: View {
    var entry: SeasonAverageProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let error = entry.error {
            ErrorView(error: error)
        } else if let averages = entry.averages {
            switch family {
            case .systemSmall:
                SmallSeasonAverageView(averages: averages)
            case .systemMedium:
                MediumSeasonAverageView(averages: averages)
            default:
                SmallSeasonAverageView(averages: averages)
            }
        } else {
            EmptyView(message: "No data available")
        }
    }
}

struct SmallSeasonAverageView: View {
    let averages: SeasonAverages
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Player name and jersey
            HStack {
                Text(averages.player_name)
                    .font(.headline)
                    .foregroundColor(.white)
                if let jersey = averages.jersey_number {
                    Text("| \(jersey)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Main stats
            VStack(alignment: .leading, spacing: 4) {
                StatRow(label: "PTS", value: String(format: "%.1f", averages.pts))
                StatRow(label: "AST", value: String(format: "%.1f", averages.ast))
                StatRow(label: "REB", value: String(format: "%.1f", averages.reb))
            }
            
            Spacer()
            
            // Percentages
            HStack(spacing: 8) {
                Text("\(Int(averages.fg_pct * 100))% FG")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(Int(averages.fg3_pct * 100))% 3FG")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("\(Int(averages.ft_pct * 100))% FT")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct MediumSeasonAverageView: View {
    let averages: SeasonAverages
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(averages.player_name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                if let jersey = averages.jersey_number {
                    Text("#\(jersey)")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            
            // Main stats grid
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(label: "PTS", value: String(format: "%.1f", averages.pts))
                    StatRow(label: "AST", value: String(format: "%.1f", averages.ast))
                    StatRow(label: "REB", value: String(format: "%.1f", averages.reb))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(label: "STL", value: String(format: "%.1f", averages.stl))
                    StatRow(label: "BLK", value: String(format: "%.1f", averages.blk))
                    StatRow(label: "MIN", value: String(format: "%.1f", averages.minutes))
                }
            }
            
            Spacer()
            
            // Percentages
            HStack(spacing: 12) {
                Text("\(Int(averages.fg_pct * 100))% FG")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(averages.fg3_pct * 100))% 3FG")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(Int(averages.ft_pct * 100))% FT")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Games played
            Text("\(averages.games_played) games")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

@available(iOS 17.0, *)
struct SeasonAverageWidget: Widget {
    let kind: String = "SeasonAverageWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurePlayerIntent.self, provider: SeasonAverageProvider()) { entry in
            if #available(iOS 17.0, *) {
                SeasonAverageWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                SeasonAverageWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
            }
        }
        .configurationDisplayName("Season Average")
        .description("Shows a player's season averages.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SeasonAverageWidget()
} timeline: {
    SeasonAverageEntry(
        date: Date(),
        averages: SeasonAverages(
            player_id: 1,
            nba_player_id: 201939,
            player_name: "Stephen Curry",
            jersey_number: 30,
            season: "2025-26",
            pts: 28.5,
            reb: 5.2,
            ast: 6.8,
            stl: 1.2,
            blk: 0.3,
            fg_pct: 0.45,
            fg3_pct: 0.40,
            ft_pct: 0.90,
            games_played: 22,
            minutes: 34.5
        ),
        error: nil,
        isPreview: true
    )
}

