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
        ZStack(alignment: .topLeading) {
            // Big opaque jersey number as background
            if let jersey = averages.jersey_number {
                Text(jersey)
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(.primary.opacity(0.08))
                    .offset(x: -10, y: -15)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                // Player name
                VStack(alignment: .leading, spacing: 0) {
                    let nameParts = averages.player_name.split(separator: " ")
                    if nameParts.count >= 2 {
                        Text(String(nameParts.first ?? ""))
                            .font(.system(size: 16, weight: .black))
                            .lineLimit(1)
                        Text(String(nameParts.last ?? ""))
                            .font(.system(size: 16, weight: .black))
                            .lineLimit(1)
                    } else {
                        Text(averages.player_name)
                            .font(.system(size: 16, weight: .black))
                            .lineLimit(2)
                    }
                }
                
                Divider()
                
                // Main stats - horizontal layout with equal spacing
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Text(String(format: "%.1f", averages.pts))
                            .font(.system(size: 18, weight: .black))
                        Spacer()
                        Text(String(format: "%.1f", averages.reb))
                            .font(.system(size: 18, weight: .black))
                        Spacer()
                        Text(String(format: "%.1f", averages.ast))
                            .font(.system(size: 18, weight: .black))
                    }
                    HStack {
                        Text("ppg")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("rpg")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("apg")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Shooting percentages - aligned with name
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 10) {
                        Text(String(format: "%.1f%%", averages.fg_pct))
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()
                            .frame(width: 36, alignment: .leading)
                        Text(String(format: "%.1f%%", averages.fg3_pct))
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()
                            .frame(width: 36, alignment: .leading)
                        Text(String(format: "%.1f%%", averages.ft_pct))
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()
                            .frame(width: 36, alignment: .leading)
                    }
                    HStack(spacing: 10) {
                        Text("FG%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .leading)
                        Text("3P%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .leading)
                        Text("FT%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .leading)
                    }
                }
            }
            .padding(6)
        }
    }
}

struct MediumSeasonAverageView: View {
    let averages: SeasonAverages
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Big opaque jersey number as background
            if let jersey = averages.jersey_number {
                Text(jersey)
                    .font(.system(size: 120, weight: .black))
                    .foregroundColor(.primary.opacity(0.06))
                    .offset(x: -15, y: -20)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                // Player name
                VStack(alignment: .leading, spacing: 0) {
                    let nameParts = averages.player_name.split(separator: " ")
                    if nameParts.count >= 2 {
                        Text(String(nameParts.first ?? ""))
                            .font(.system(size: 20, weight: .black))
                            .lineLimit(1)
                        Text(String(nameParts.last ?? ""))
                            .font(.system(size: 20, weight: .black))
                            .lineLimit(1)
                    } else {
                        Text(averages.player_name)
                            .font(.system(size: 20, weight: .black))
                            .lineLimit(2)
                    }
                }
                
                Divider()
                
                // Main stats - horizontal layout
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 0) {
                        Text(String(format: "%.1f", averages.pts))
                            .font(.system(size: 20, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%.1f", averages.reb))
                            .font(.system(size: 20, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "%.1f", averages.ast))
                            .font(.system(size: 20, weight: .black))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack(spacing: 0) {
                        Text("ppg")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("rpg")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("apg")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Divider()
                
                // Shooting percentages - aligned with name
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 10) {
                        Text(String(format: "%.1f%%", averages.fg_pct))
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()
                            .frame(width: 36, alignment: .leading)
                        Text(String(format: "%.1f%%", averages.fg3_pct))
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()
                            .frame(width: 36, alignment: .leading)
                        Text(String(format: "%.1f%%", averages.ft_pct))
                            .font(.system(size: 11, weight: .bold))
                            .fixedSize()
                            .frame(width: 36, alignment: .leading)
                    }
                    HStack(spacing: 10) {
                        Text("FG%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .leading)
                        Text("3P%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .leading)
                        Text("FT%")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .leading)
                    }
                }
            }
            .padding(6)
        }
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

// MARK: - Compact Components

struct StatLabel: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 15, weight: .bold))
        }
    }
}

struct CompactStat: View {
    let value: Int
    let label: String
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.system(size: 9, weight: .medium))
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
                    .containerBackground(for: .widget) {}
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
            player_name: "Stephen Curry",
            jersey_number: "30",
            season: "2025-26",
            ppg: 28.5,
            rpg: 5.2,
            apg: 6.8,
            spg: 1.2,
            bpg: 0.3,
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

