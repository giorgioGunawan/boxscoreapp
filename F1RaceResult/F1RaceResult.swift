//
//  F1RaceResult.swift
//  F1RaceResult
//
//  Created by Giorgio Gunawan on 31/5/2025.
//

import WidgetKit
import SwiftUI

struct RaceResult: Codable {
    let race_id: Int
    let round: Int
    let name: String
    let location: String
    let shortname: String
    let first_place_winner_display_name: String
    let second_place_winner_display_name: String
    let third_place_winner_display_name: String
    let first_place_winner_team: String
    let second_place_winner_team: String
    let third_place_winner_team: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        // Always show real content in placeholders (for widget gallery previews)
        SimpleEntry(date: Date(), raceResult: RaceResult(
            race_id: 91,
            round: 8,
            name: "Monaco Grand Prix",
            location: "Circuit de Monaco",
            shortname: "Monaco",
            first_place_winner_display_name: "NOR",
            second_place_winner_display_name: "LEC",
            third_place_winner_display_name: "PIA",
            first_place_winner_team: "McLaren",
            second_place_winner_team: "Ferrari",
            third_place_winner_team: "McLaren"
        ), isPremiumContent: false, isPreview: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        // For previews in widget gallery, always show real content to entice users
        if context.isPreview {
            Task {
                do {
                    let url = URL(string: "https://f1apibackend-1.onrender.com/api/latest-result")!
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let raceResult = try JSONDecoder().decode(RaceResult.self, from: data)
                    
                    let entry = SimpleEntry(date: Date(), raceResult: raceResult, isPremiumContent: false, isPreview: true)
                    completion(entry)
                } catch {
                    // Fallback to placeholder data if API fails
                    let entry = placeholder(in: context)
                    completion(entry)
                }
            }
            return
        }
        
        // Check if this is a premium widget family and user is not pro
        let isPremium = context.family == .systemMedium
        if isPremium && !SubscriptionHelper.isProUser {
            let entry = SimpleEntry(date: Date(), raceResult: placeholder(in: context).raceResult, isPremiumContent: true, isPreview: false)
            completion(entry)
            return
        }
        
        Task {
            do {
                let url = URL(string: "https://f1apibackend-1.onrender.com/api/latest-result")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let raceResult = try JSONDecoder().decode(RaceResult.self, from: data)
                
                let entry = SimpleEntry(date: Date(), raceResult: raceResult, isPremiumContent: isPremium && !SubscriptionHelper.isProUser, isPreview: false)
                completion(entry)
            } catch {
                // Fallback to placeholder data if API fails
                let entry = placeholder(in: context)
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Check if this is a premium widget family and user is not pro
        let isPremium = context.family == .systemMedium
        if isPremium && !SubscriptionHelper.isProUser {
            let entry = SimpleEntry(date: Date(), raceResult: placeholder(in: context).raceResult, isPremiumContent: true, isPreview: false)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
            completion(timeline)
            return
        }
        
        Task {
            do {
                let url = URL(string: "https://f1apibackend-1.onrender.com/api/latest-result")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let raceResult = try JSONDecoder().decode(RaceResult.self, from: data)
                
                let entry = SimpleEntry(date: .now, raceResult: raceResult, isPremiumContent: isPremium && !SubscriptionHelper.isProUser, isPreview: false)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                let entry = placeholder(in: context)
                let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
                completion(timeline)
            }
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let raceResult: RaceResult
    let isPremiumContent: Bool
    let isPreview: Bool
    
    init(date: Date, raceResult: RaceResult, isPremiumContent: Bool = false, isPreview: Bool = false) {
        self.date = date
        self.raceResult = raceResult
        self.isPremiumContent = isPremiumContent
        self.isPreview = isPreview
    }
}

struct F1RaceResultEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        // Show premium gate only for actual widgets (not previews) when content is premium
        if entry.isPremiumContent && !entry.isPreview {
            PremiumWidgetView(widgetFamily: family)
        } else {
            switch family {
            case .systemSmall:
                smallWidget(entry: entry)
                    .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
            case .systemMedium:
                mediumWidget(entry: entry)
                    .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
            default:
                smallWidget(entry: entry)
                    .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
            }
        }
    }
    
    // Helper function to calculate dynamic font size based on shortname length
    private func getShortnameFont(for shortname: String, baseSize: CGFloat) -> Font {
        let length = shortname.count
        if length > 8 {
            return .custom("Formula1-Display-Bold", size: baseSize - 6)
        } else if length > 6 {
            return .custom("Formula1-Display-Bold", size: baseSize - 3)
        } else {
            return .custom("Formula1-Display-Bold", size: baseSize)
        }
    }
    
    // [WIDGET] Race Result Small Widget
    private func smallWidget(entry: SimpleEntry) -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("🏁")
                        .font(.custom("Formula1-Display-Regular", size: 11))
                    Text("Latest Result")
                        .font(.custom("Formula1-Display-Bold", size: 11))
                        .foregroundColor(.white)
                        .scaleEffect(x: 1.1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Round \(entry.raceResult.round)")
                        .modifier(F1RaceStyle.EventTitleStyle())
                }
                
                Text(entry.raceResult.shortname)
                    .font(getShortnameFont(for: entry.raceResult.shortname, baseSize: 22))
                    .foregroundColor(F1RaceStyle.textColor)
                    .scaleEffect(x: 1.1)
            }
            
            Spacer()
            
            // Podium Results
            VStack(alignment: .leading, spacing: 8) {
                PodiumRow(position: "P1", driver: entry.raceResult.first_place_winner_display_name, team: entry.raceResult.first_place_winner_team)
                PodiumRow(position: "P2", driver: entry.raceResult.second_place_winner_display_name, team: entry.raceResult.second_place_winner_team)
                PodiumRow(position: "P3", driver: entry.raceResult.third_place_winner_display_name, team: entry.raceResult.third_place_winner_team)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .modifier(F1RaceStyle.CardWithRaceSpecificBackgroundStyle(isWidget: true, race: convertToF1Race(entry.raceResult)))
    }
    
    // [WIDGET] Race Result Medium Widget
    private func mediumWidget(entry: SimpleEntry) -> some View {
        HStack(alignment: .top, spacing: 18) {
            // Left side
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("🏁")
                            .font(.custom("Formula1-Display-Regular", size: 15))
                        Text("Result")
                            .font(.custom("Formula1-Display-Bold", size: 15))
                            .foregroundColor(.white)
                            .scaleEffect(x: 1.1)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Round \(entry.raceResult.round)")
                            .modifier(F1RaceStyle.EventTitleStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.raceResult.shortname)
                            .font(getShortnameFont(for: entry.raceResult.shortname, baseSize: 22))
                            .foregroundColor(F1RaceStyle.textColor)
                            .scaleEffect(x: 1.1)
                            .offset(x: 3)
                        if let flagName = F1RaceStyle.getFlagName(for: convertToF1Race(entry.raceResult)) {
                            Image(flagName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .offset(y: 2)
                        }
                    }
                }
            }
            .frame(width: 180)
            
            // Right side with podium
            HStack(alignment: .top, spacing: 0) {
                // Position numbers
                VStack(alignment: .leading, spacing: 12) {
                    Text("P1")
                        .foregroundColor(F1RaceStyle.accentColor)
                        .font(.custom("Formula1-Display-Bold", size: 16))
                        .frame(width: 30, alignment: .leading)
                    Text("P2")
                        .foregroundColor(F1RaceStyle.accentColor)
                        .font(.custom("Formula1-Display-Bold", size: 16))
                        .frame(width: 30, alignment: .leading)
                    Text("P3")
                        .foregroundColor(F1RaceStyle.accentColor)
                        .font(.custom("Formula1-Display-Bold", size: 16))
                        .frame(width: 30, alignment: .leading)
                }
                
                // Divider
                Rectangle()
                    .fill(F1RaceStyle.accentColor.opacity(0.8))
                    .frame(width: 2)
                    .frame(maxHeight: 74)
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    .padding(.horizontal, 12)
                
                // Driver codes with team logos
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 4) {
                        Text(entry.raceResult.first_place_winner_display_name)
                            .font(.custom("Formula1-Display-Bold", size: 16))
                            .foregroundColor(F1RaceStyle.textColor)
                        if let logoName = F1RaceStyle.getTeamLogo(for: entry.raceResult.first_place_winner_team) {
                            Image(logoName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: entry.raceResult.first_place_winner_team.lowercased() == "mercedes" ? 16 : 16)
                        }
                    }
                    HStack(spacing: 4) {
                        Text(entry.raceResult.second_place_winner_display_name)
                            .font(.custom("Formula1-Display-Bold", size: 16))
                            .foregroundColor(F1RaceStyle.textColor)
                        if let logoName = F1RaceStyle.getTeamLogo(for: entry.raceResult.second_place_winner_team) {
                            Image(logoName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: entry.raceResult.second_place_winner_team.lowercased() == "mercedes" ? 16 : 16)
                        }
                    }
                    HStack(spacing: 4) {
                        Text(entry.raceResult.third_place_winner_display_name)
                            .font(.custom("Formula1-Display-Bold", size: 16))
                            .foregroundColor(F1RaceStyle.textColor)
                        if let logoName = F1RaceStyle.getTeamLogo(for: entry.raceResult.third_place_winner_team) {
                            Image(logoName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: entry.raceResult.third_place_winner_team.lowercased() == "mercedes" ? 16 : 16)
                        }
                    }
                }
                .frame(width: 120, alignment: .leading)
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(F1RaceStyle.CardWithRaceSpecificBackgroundStyle(isWidget: true, race: convertToF1Race(entry.raceResult)))
    }
    
    // Helper function to convert RaceResult to F1Race for background compatibility
    private func convertToF1Race(_ raceResult: RaceResult) -> F1Race {
        return F1Race(
            id: raceResult.race_id,
            round: raceResult.round,
            name: raceResult.name,
            location: raceResult.location,
            datetime_fp1: nil,
            datetime_fp2: nil,
            datetime_fp3: nil,
            datetime_sprint: nil,
            datetime_qualifying: nil,
            datetime_race: nil,
            first_place: raceResult.first_place_winner_display_name,
            second_place: raceResult.second_place_winner_display_name,
            third_place: raceResult.third_place_winner_display_name,
            shortname: raceResult.shortname,
            datetime_fp1_end: nil,
            datetime_fp2_end: nil,
            datetime_fp3_end: nil,
            datetime_sprint_end: nil,
            datetime_qualifying_end: nil,
            datetime_race_end: nil
        )
    }
}

struct PodiumRow: View {
    let position: String
    let driver: String
    let team: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(position)
                .font(.custom("Formula1-Display-Bold", size: 13))
                .foregroundColor(F1RaceStyle.accentColor)
                .frame(width: 24, alignment: .leading)
            
            HStack(spacing: 4) {
                Text(driver)
                    .font(.custom("Formula1-Display-Bold", size: 13))
                    // .frame(width: 24, alignment: .leading)
                    // .modifier(F1RaceStyle.SessionNameStyle())
                
                if let logoName = F1RaceStyle.getTeamLogo(for: team) {
                    Image(logoName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: team.lowercased() == "mercedes" ? 16 : 13)
                }
            }
        }
    }
}

struct F1RaceResult: Widget {
    let kind: String = "F1RaceResult"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                F1RaceResultEntryView(entry: entry)
                    .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
            } else {
                F1RaceResultEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("F1 Latest Result")
        .description("Shows the latest Formula 1 race result.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    F1RaceResult()
} timeline: {
    SimpleEntry(date: .now, raceResult: RaceResult(
        race_id: 91,
        round: 8,
        name: "Monaco Grand Prix",
        location: "Circuit de Monaco",
        shortname: "Monaco",
        first_place_winner_display_name: "NOR",
        second_place_winner_display_name: "LEC",
        third_place_winner_display_name: "PIA",
        first_place_winner_team: "McLaren",
        second_place_winner_team: "Ferrari",
        third_place_winner_team: "McLaren"
    ), isPremiumContent: false, isPreview: false)
}

extension F1RaceStyle {
    static func getTeamColor(for teamName: String) -> Color {
        switch teamName.lowercased() {
        case "mercedes": return Color(red: 0/255, green: 215/255, blue: 182/255)
        case "red bull": return Color(red: 71/255, green: 129/255, blue: 215/255)
        case "ferrari": return Color(red: 237/255, green: 17/255, blue: 49/255)
        case "mclaren": return Color(red: 244/255, green: 118/255, blue: 0/255)
        case "alpine": return Color(red: 0/255, green: 161/255, blue: 232/255)
        case "rb": return Color(red: 108/255, green: 152/255, blue: 255/255)
        case "aston martin": return Color(red: 34/255, green: 153/255, blue: 113/255)
        case "williams": return Color(red: 24/255, green: 104/255, blue: 219/255)
        case "kick sauber": return Color(red: 1/255, green: 192/255, blue: 14/255)
        case "haas": return Color(red: 156/255, green: 159/255, blue: 162/255)
        default: return Color.gray
        }
    }

    static func getTeamLogo(for teamName: String) -> String? {
        switch teamName.lowercased() {
        case "mercedes": return "team-logo-compact-mercedes"
        case "red bull": return "team-logo-compact-redbull"
        case "ferrari": return "team-logo-compact-ferrari"
        case "mclaren": return "team-logo-compact-mclaren"
        case "alpine": return "team-logo-compact-alpine"
        case "rb": return "team-logo-compact-rb"
        case "aston martin": return "team-logo-compact-astonmartin"
        case "williams": return "team-logo-compact-williams"
        case "kick sauber": return "team-logo-compact-kicksauber"
        case "haas": return "team-logo-compact-haas"
        default: return nil
        }
    }

    static func getTeamLogoFull(for teamName: String) -> String? {
        switch teamName.lowercased() {
        case "mercedes": return "team-logo-full-mercedes"
        case "red bull": return "team-logo-full-redbull"
        case "ferrari": return "team-logo-full-ferrari"
        case "mclaren": return "team-logo-full-mclaren"
        case "alpine": return "team-logo-full-alpine"
        case "rb": return "team-logo-full-rb"
        case "aston martin": return "team-logo-full-astonmartin"
        case "williams": return "team-logo-full-williams"
        case "kick sauber": return "team-logo-full-kicksauber"
        case "haas": return "team-logo-full-haas"
        default: return nil
        }
    }

    static func getF1Car(for teamName: String) -> String? {
        switch teamName.lowercased() {
        case "mercedes": return "f1-car-mercedes"
        case "red bull": return "f1-car-redbull"
        case "ferrari": return "f1-car-ferrari"
        case "mclaren": return "f1-car-mclaren"
        case "alpine": return "f1-car-alpine"
        case "rb": return "f1-car-rb"
        case "aston martin": return "f1-car-astonmartin"
        case "williams": return "f1-car-williams"
        case "kick sauber": return "f1-car-kicksauber"
        case "haas": return "f1-car-haas"
        default: return nil
        }
    }
}
