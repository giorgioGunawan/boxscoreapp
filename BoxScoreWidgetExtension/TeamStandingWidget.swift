//
//  TeamStandingWidget.swift
//  BoxScoreWidget
//
//  Widget 4: Team Standing
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct TeamStandingProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TeamStandingEntry {
        TeamStandingEntry(
            date: Date(),
            standings: nil,
            error: nil,
            isPreview: true
        )
    }
    
    func snapshot(for configuration: ConfigureTeamIntent, in context: Context) async -> TeamStandingEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        return await loadData(for: configuration)
    }
    
    func timeline(for configuration: ConfigureTeamIntent, in context: Context) async -> Timeline<TeamStandingEntry> {
        let entry = await loadData(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func loadData(for configuration: ConfigureTeamIntent) async -> TeamStandingEntry {
        guard let teamAbbr = configuration.team?.id else {
            return TeamStandingEntry(date: Date(), standings: nil, error: "No team selected", isPreview: false)
        }
        do {
            let teamID = try await NBAAPIService.shared.getTeamID(for: teamAbbr)
            let standings = try await NBAAPIService.shared.getTeamStandings(teamID: teamID)
            return TeamStandingEntry(
                date: Date(),
                standings: standings,
                error: nil,
                isPreview: false
            )
        } catch {
            return TeamStandingEntry(
                date: Date(),
                standings: nil,
                error: error.localizedDescription,
                isPreview: false
            )
        }
    }
}

struct TeamStandingEntry: TimelineEntry {
    let date: Date
    let standings: TeamStandings?
    let error: String?
    let isPreview: Bool
}

struct TeamStandingWidgetEntryView: View {
    var entry: TeamStandingProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let error = entry.error {
            ErrorView(error: error)
        } else if let standings = entry.standings {
            switch family {
            case .systemSmall:
                SmallTeamStandingView(standings: standings)
            case .systemMedium:
                MediumTeamStandingView(standings: standings)
            default:
                SmallTeamStandingView(standings: standings)
            }
        } else {
            EmptyView(message: "No standings data")
        }
    }
}

struct SmallTeamStandingView: View {
    let standings: TeamStandings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(standings.abbreviation)
                .font(.system(size: 16, weight: .black))
            
            Divider()
            
            HStack(alignment: .center, spacing: 3) {
                Text("\(standings.wins)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.green)
                Text("-")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.secondary)
                Text("\(standings.losses)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.red)
            }
            
            Divider()
            
            HStack {
                Text("#\(standings.conference_rank)")
                    .font(.system(size: 16, weight: .bold))
                Text(standings.conference)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
        }
        .padding(6)
    }
}

struct MediumTeamStandingView: View {
    let standings: TeamStandings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(standings.team_name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Record - large display
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(standings.wins)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                Text("-")
                    .font(.title)
                    .foregroundColor(.gray)
                Text("\(standings.losses)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Conference Rank")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(standings.conference_rank)th")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Conference")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text(standings.conference)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                if !standings.streak.isEmpty {
                    HStack {
                        Text("Streak")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(standings.streak)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(standings.streak.hasPrefix("W") ? .green : .red)
                    }
                }
            }
        }
        .padding(6)
    }
}

@available(iOS 17.0, *)
struct TeamStandingWidget: Widget {
    let kind: String = "TeamStandingWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigureTeamIntent.self, provider: TeamStandingProvider()) { entry in
            if #available(iOS 17.0, *) {
                TeamStandingWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {}
            }
        }
        .configurationDisplayName("Team Standing")
        .description("Shows your team's current standing and record.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TeamStandingWidget()
} timeline: {
    TeamStandingEntry(
        date: Date(),
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

