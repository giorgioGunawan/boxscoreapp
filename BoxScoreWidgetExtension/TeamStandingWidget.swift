//
//  TeamStandingWidget.swift
//  BoxScoreWidget
//
//  Widget 4: Team Standing
//

import WidgetKit
import SwiftUI

struct TeamStandingProvider: TimelineProvider {
    let teamID: Int
    
    func placeholder(in context: Context) -> TeamStandingEntry {
        TeamStandingEntry(
            date: Date(),
            standings: nil,
            error: nil,
            isPreview: true
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TeamStandingEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        
        Task {
            let entry = await loadData()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TeamStandingEntry>) -> Void) {
        Task {
            let entry = await loadData()
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func loadData() async -> TeamStandingEntry {
        do {
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
        VStack(alignment: .leading, spacing: 12) {
            Text(standings.team_name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            // Record
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Record")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(standings.wins)-\(standings.losses)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Conference rank
                HStack {
                    Text("Conference")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(standings.conference_rank)th in \(standings.conference)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                // Streak
                if !standings.streak.isEmpty {
                    HStack {
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(standings.streak)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(standings.streak.hasPrefix("W") ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
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
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black)
    }
}

struct TeamStandingWidget: Widget {
    let kind: String = "TeamStandingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TeamStandingProvider(teamID: 2)) { entry in
            if #available(iOS 17.0, *) {
                TeamStandingWidgetEntryView(entry: entry)
                    .containerBackground(Color.black, for: .widget)
            } else {
                TeamStandingWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
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
            abbreviation: "GSW",
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

