//
//  LockScreenWidgets.swift
//  BoxScoreWidgetExtension
//
//  Lock screen widgets for NBA data
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Lock Screen Next Game Widget (Circular)

@available(iOS 17.0, *)
struct LockScreenNextGameProvider: AppIntentTimelineProvider {
    typealias Entry = LockScreenNextGameEntry
    typealias Intent = ConfigureTeamIntent
    
    func placeholder(in context: Context) -> LockScreenNextGameEntry {
        LockScreenNextGameEntry(date: Date(), gameTime: "8:30 PM", opponent: "LAL", isPreview: true)
    }
    
    func snapshot(for configuration: ConfigureTeamIntent, in context: Context) async -> LockScreenNextGameEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigureTeamIntent, in context: Context) async -> Timeline<LockScreenNextGameEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigureTeamIntent) async -> LockScreenNextGameEntry {
        // Use default team if none selected
        let teamAbbr = configuration.team?.id ?? "GSW"
        
        do {
            let teamID = try await NBAAPIService.shared.getTeamID(for: teamAbbr)
            let gamesResponse = try await NBAAPIService.shared.getNextGame(teamID: teamID)
            
            if let game = gamesResponse.games.first {
                var gameTime = game.time ?? "TBD"
                
                // Try to parse and format the date
                if let gameDate = NBAAPIService.parseUTCDate(game.datetime_utc) {
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    formatter.dateStyle = .none
                    formatter.timeZone = TimeZone.current
                    gameTime = formatter.string(from: gameDate)
                }
                
                return LockScreenNextGameEntry(
                    date: Date(),
                    gameTime: gameTime,
                    opponent: game.opponent,
                    isPreview: false
                )
            }
            
            return LockScreenNextGameEntry(date: Date(), gameTime: "TBD", opponent: "No game", isPreview: false)
        } catch {
            print("Lock screen next game error: \(error)")
            return LockScreenNextGameEntry(date: Date(), gameTime: "Error", opponent: "---", isPreview: false)
        }
    }
}

struct LockScreenNextGameEntry: TimelineEntry {
    let date: Date
    let gameTime: String?
    let opponent: String?
    let isPreview: Bool
}

@available(iOS 17.0, *)
struct LockScreenNextGameWidgetView: View {
    var entry: LockScreenNextGameEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(entry.opponent ?? "--")
                    .font(.system(size: 16, weight: .bold))
                Text(entry.gameTime ?? "--")
                    .font(.system(size: 10, weight: .medium))
            }
            
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Next Game")
                    .font(.caption2)
                    .fontWeight(.medium)
                if let opponent = entry.opponent, let time = entry.gameTime {
                    Text("vs \(opponent)")
                        .font(.headline)
                    Text(time)
                        .font(.caption)
                } else {
                    Text("No games")
                        .font(.caption)
                }
            }
            
        case .accessoryInline:
            if let opponent = entry.opponent, let time = entry.gameTime {
                Text("vs \(opponent) · \(time)")
            } else {
                Text("No upcoming game")
            }
            
        default:
            Text("Next Game")
        }
    }
}

@available(iOS 17.0, *)
struct LockScreenNextGameWidget: Widget {
    let kind: String = "LockScreenNextGameWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTeamIntent.self, provider: LockScreenNextGameProvider()) { entry in
            LockScreenNextGameWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Next Game")
        .description("Shows your team's next game time.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Lock Screen Player Stats Widget (Rectangular)

@available(iOS 17.0, *)
struct LockScreenPlayerStatsProvider: AppIntentTimelineProvider {
    typealias Entry = LockScreenPlayerStatsEntry
    typealias Intent = ConfigurePlayerIntent
    
    func placeholder(in context: Context) -> LockScreenPlayerStatsEntry {
        LockScreenPlayerStatsEntry(date: Date(), playerName: "S. Curry", pts: 30, ast: 6, reb: 5, isPreview: true)
    }
    
    func snapshot(for configuration: ConfigurePlayerIntent, in context: Context) async -> LockScreenPlayerStatsEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigurePlayerIntent, in context: Context) async -> Timeline<LockScreenPlayerStatsEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigurePlayerIntent) async -> LockScreenPlayerStatsEntry {
        // Use default player if none selected (Stephen Curry)
        let nbaPlayerID = configuration.player?.id ?? 201939
        
        do {
            let game = try await NBAAPIService.shared.getPlayerLatestGame(nbaPlayerID: nbaPlayerID)
            
            // Get first initial and last name
            let nameParts = game.player_name.split(separator: " ")
            let shortName = nameParts.count > 1 
                ? "\(nameParts.first?.prefix(1) ?? ""). \(nameParts.last ?? "")"
                : String(game.player_name.prefix(10))
            
            return LockScreenPlayerStatsEntry(
                date: Date(),
                playerName: shortName,
                pts: game.pts,
                ast: game.ast,
                reb: game.reb,
                isPreview: false
            )
        } catch {
            print("Lock screen player stats error: \(error)")
            return LockScreenPlayerStatsEntry(date: Date(), playerName: "Error", pts: 0, ast: 0, reb: 0, isPreview: false)
        }
    }
}

struct LockScreenPlayerStatsEntry: TimelineEntry {
    let date: Date
    let playerName: String?
    let pts: Int?
    let ast: Int?
    let reb: Int?
    let isPreview: Bool
}

@available(iOS 17.0, *)
struct LockScreenPlayerStatsWidgetView: View {
    var entry: LockScreenPlayerStatsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 1) {
                Text("\(entry.pts ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                Text("PTS")
                    .font(.system(size: 9))
            }
            
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName ?? "Player")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(entry.pts ?? 0)P")
                        .font(.system(size: 15, weight: .bold))
                    Text("\(entry.reb ?? 0)R")
                        .font(.system(size: 13, weight: .semibold))
                    Text("\(entry.ast ?? 0)A")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            
        case .accessoryInline:
            if let name = entry.playerName, let pts = entry.pts {
                Text("\(name): \(pts)P \(entry.reb ?? 0)R \(entry.ast ?? 0)A")
            } else {
                Text("No stats available")
            }
            
        default:
            Text("Player Stats")
        }
    }
}

@available(iOS 17.0, *)
struct LockScreenPlayerStatsWidget: Widget {
    let kind: String = "LockScreenPlayerStatsWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurePlayerIntent.self, provider: LockScreenPlayerStatsProvider()) { entry in
            LockScreenPlayerStatsWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Player Stats")
        .description("Shows your player's latest game stats.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Lock Screen Team Record Widget (Inline)

@available(iOS 17.0, *)
struct LockScreenTeamRecordProvider: AppIntentTimelineProvider {
    typealias Entry = LockScreenTeamRecordEntry
    typealias Intent = ConfigureTeamIntent
    
    func placeholder(in context: Context) -> LockScreenTeamRecordEntry {
        LockScreenTeamRecordEntry(date: Date(), teamAbbr: "GSW", wins: 11, losses: 11, isPreview: true)
    }
    
    func snapshot(for configuration: ConfigureTeamIntent, in context: Context) async -> LockScreenTeamRecordEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigureTeamIntent, in context: Context) async -> Timeline<LockScreenTeamRecordEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigureTeamIntent) async -> LockScreenTeamRecordEntry {
        // Use default team if none selected
        let teamAbbr = configuration.team?.id ?? "GSW"
        
        do {
            let teamID = try await NBAAPIService.shared.getTeamID(for: teamAbbr)
            let standings = try await NBAAPIService.shared.getTeamStandings(teamID: teamID)
            
            return LockScreenTeamRecordEntry(
                date: Date(),
                teamAbbr: standings.abbreviation,
                wins: standings.wins,
                losses: standings.losses,
                isPreview: false
            )
        } catch {
            print("Lock screen team record error: \(error)")
            return LockScreenTeamRecordEntry(date: Date(), teamAbbr: teamAbbr, wins: 0, losses: 0, isPreview: false)
        }
    }
}

struct LockScreenTeamRecordEntry: TimelineEntry {
    let date: Date
    let teamAbbr: String?
    let wins: Int?
    let losses: Int?
    let isPreview: Bool
}

@available(iOS 17.0, *)
struct LockScreenTeamRecordWidgetView: View {
    var entry: LockScreenTeamRecordEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 1) {
                Text(entry.teamAbbr ?? "---")
                    .font(.system(size: 13, weight: .bold))
                Text("\(entry.wins ?? 0)-\(entry.losses ?? 0)")
                    .font(.system(size: 11, weight: .semibold))
            }
            
        case .accessoryRectangular:
            HStack {
                Text(entry.teamAbbr ?? "Team")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                HStack(spacing: 2) {
                    Text("\(entry.wins ?? 0)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                    Text("-")
                    Text("\(entry.losses ?? 0)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
        case .accessoryInline:
            Text("\(entry.teamAbbr ?? "Team") \(entry.wins ?? 0)-\(entry.losses ?? 0)")
            
        default:
            Text("Team Record")
        }
    }
}

@available(iOS 17.0, *)
struct LockScreenTeamRecordWidget: Widget {
    let kind: String = "LockScreenTeamRecordWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTeamIntent.self, provider: LockScreenTeamRecordProvider()) { entry in
            LockScreenTeamRecordWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Team Record")
        .description("Shows your team's win-loss record.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

