//
//  CountdownWidget.swift
//  BoxScoreWidget
//
//  Widget 6: Countdown to Next Game
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct CountdownProvider: AppIntentTimelineProvider {
    typealias Entry = CountdownEntry      // your TimelineEntry type
    typealias Intent = ConfigureTeamIntent  // or whatever AppIntent you use
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            game: nil,
            teamAbbr: "GSW",
            error: nil,
            isPreview: true
        )
    }
    
    func snapshot(for configuration: ConfigureTeamIntent, in context: Context) async -> CountdownEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigureTeamIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigureTeamIntent) async -> CountdownEntry {
        guard let teamAbbr = configuration.team?.id else {
            return CountdownEntry(date: Date(), game: nil, teamAbbr: nil, error: "No team selected", isPreview: false)
        }
        do {
            let teamID = try await NBAAPIService.shared.getTeamID(for: teamAbbr)
            let gamesResponse = try await NBAAPIService.shared.getNextGame(teamID: teamID)
            let game = gamesResponse.games.first
            return CountdownEntry(
                date: Date(),
                game: game,
                teamAbbr: teamAbbr,
                error: nil,
                isPreview: false
            )
        } catch {
            return CountdownEntry(
                date: Date(),
                game: nil,
                teamAbbr: teamAbbr,
                error: error.localizedDescription,
                isPreview: false
            )
        }
    }
}

struct CountdownEntry: TimelineEntry {
    let date: Date
    let game: NBAGame?
    let teamAbbr: String?
    let error: String?
    let isPreview: Bool
}

struct CountdownWidgetEntryView: View {
    var entry: CountdownProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let error = entry.error {
            ErrorView(error: error)
        } else if let game = entry.game {
            switch family {
            case .systemSmall:
                SmallCountdownView(entry: entry, game: game, currentDate: entry.date)
            case .systemMedium:
                MediumCountdownView(entry: entry, game: game, currentDate: entry.date)
            default:
                SmallCountdownView(entry: entry, game: game, currentDate: entry.date)
            }
        } else {
            EmptyView(message: "No upcoming game")
        }
    }
}

struct SmallCountdownView: View {
    let entry: CountdownEntry
    let game: NBAGame
    let currentDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(entry.teamAbbr ?? "TBD")
                    .font(.system(size: 14, weight: .black))
                Text(game.is_home ? "vs" : "@")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(game.is_home ? .green : .blue)
                Text(game.opponent)
                    .font(.system(size: 14, weight: .black))
            }
            
            Divider()
            
            if let gameDate = NBAAPIService.parseUTCDate(game.datetime_utc) {
                let timeUntil = gameDate.timeIntervalSince(currentDate)
                
                if timeUntil > 0 {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(formatCountdown(timeUntil))
                            .font(.system(size: 32, weight: .black))
                        Text("until tip-off")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("LIVE")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(formatGameDate(gameDate))
                        .font(.system(size: 11, weight: .semibold))
                    Text(formatGameTime(gameDate))
                        .font(.system(size: 13, weight: .bold))
                }
            }
        }
        .padding(6)
    }
    
    private func formatGameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "E MMM d"
        return formatter.string(from: date)
    }
}

struct MediumCountdownView: View {
    let entry: CountdownEntry
    let game: NBAGame
    let currentDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Show both teams
            HStack(spacing: 6) {
                Text(entry.teamAbbr ?? "TBD")
                    .font(.system(size: 16, weight: .black))
                Text(game.is_home ? "vs" : "@")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(game.is_home ? .green : .blue)
                Text(game.opponent)
                    .font(.system(size: 16, weight: .black))
            }
            
            Divider()
            
            if let gameDate = NBAAPIService.parseUTCDate(game.datetime_utc) {
                let timeUntil = gameDate.timeIntervalSince(currentDate)
                
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        if timeUntil > 0 {
                            Text(formatCountdown(timeUntil))
                                .font(.system(size: 42, weight: .black))
                            Text("until tip-off")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            Text("LIVE NOW")
                                .font(.system(size: 32, weight: .black))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatFullDate(gameDate))
                            .font(.system(size: 12, weight: .semibold))
                        Text(formatGameTime(gameDate))
                            .font(.system(size: 18, weight: .black))
                        Text(game.is_home ? "Home" : "Away")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(game.is_home ? .green : .blue)
                    }
                }
            }
        }
        .padding(6)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

func formatCountdown(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = (Int(timeInterval) % 3600) / 60
    
    if hours > 24 {
        let days = hours / 24
        return "\(days)d \(hours % 24)h"
    } else if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

func formatGameTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

@available(iOS 17.0, *)
struct CountdownWidget: Widget {
    let kind: String = "CountdownWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTeamIntent.self, provider: CountdownProvider()) { entry in
            if #available(iOS 17.0, *) {
                CountdownWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {}
            }
        }
        .configurationDisplayName("Countdown to Next Game")
        .description("Shows countdown until your team's next game.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    CountdownEntry(
        date: Date(),
        game: NBAGame(
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
        ),
        teamAbbr: "GSW",
        error: nil,
        isPreview: true
    )
}

