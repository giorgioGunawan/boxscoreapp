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
            return CountdownEntry(date: Date(), game: nil, error: "No team selected", isPreview: false)
        }
        do {
            let teamID = try await NBAAPIService.shared.getTeamID(for: teamAbbr)
            let gamesResponse = try await NBAAPIService.shared.getNextGame(teamID: teamID)
            let game = gamesResponse.games.first
            return CountdownEntry(
                date: Date(),
                game: game,
                error: nil,
                isPreview: false
            )
        } catch {
            return CountdownEntry(
                date: Date(),
                game: nil,
                error: error.localizedDescription,
                isPreview: false
            )
        }
    }
}

struct CountdownEntry: TimelineEntry {
    let date: Date
    let game: NBAGame?
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
                SmallCountdownView(game: game, currentDate: entry.date)
            case .systemMedium:
                MediumCountdownView(game: game, currentDate: entry.date)
            default:
                SmallCountdownView(game: game, currentDate: entry.date)
            }
        } else {
            EmptyView(message: "No upcoming game")
        }
    }
}

struct SmallCountdownView: View {
    let game: NBAGame
    let currentDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Game")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Countdown or time
            if let gameDate = NBAAPIService.parseUTCDate(game.datetime_utc) {
                let timeUntil = gameDate.timeIntervalSince(currentDate)
                
                if timeUntil > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatCountdown(timeUntil))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("until tip-off")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("Game started")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Opponent
            HStack {
                Text(game.is_home ? "vs" : "@")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(game.opponent)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Game time
            if let gameDate = NBAAPIService.parseUTCDate(game.datetime_utc) {
                Text(formatGameTime(gameDate))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct MediumCountdownView: View {
    let game: NBAGame
    let currentDate: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Game")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Opponent info
            HStack {
                Text(game.is_home ? "vs" : "@")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text(game.opponent_name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Countdown or time
            if let gameDate = NBAAPIService.parseUTCDate(game.datetime_utc) {
                let timeUntil = gameDate.timeIntervalSince(currentDate)
                
                if timeUntil > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatCountdown(timeUntil))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("until tip-off")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    Text("Game started")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Game date and time
            if let gameDate = NBAAPIService.parseUTCDate(game.datetime_utc) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatGameDate(gameDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(formatGameTime(gameDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
    
    private func formatGameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "EEEE, MMMM d"
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
                    .containerBackground(Color.black, for: .widget)
            } else {
                CountdownWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
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
        error: nil,
        isPreview: true
    )
}

