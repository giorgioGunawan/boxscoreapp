import WidgetKit
import SwiftUI
import Intents
import AppIntents

struct Provider: TimelineProvider {
    private let isPremiumWidget: Bool
    
    init(isPremiumWidget: Bool = false) {
        self.isPremiumWidget = isPremiumWidget
    }

    func placeholder(in context: Context) -> F1RaceEntry {
        // Always show real content in placeholders (for widget gallery previews)
        F1RaceEntry(date: Date(), race: nil, sessionInfo: nil, isPremiumContent: false, isPreview: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (F1RaceEntry) -> ()) {
        // For previews in widget gallery, always show real content to entice users
        if context.isPreview {
            Task {
                await loadData(isPreview: true) { entry in
                    completion(entry)
                }
            }
            return
        }
        
        // Check if this is a premium widget family and user is not pro
        let isPremium = context.family == .systemMedium
        #if DEBUG
        if (isPremiumWidget || isPremium) && !SubscriptionHelper.isProUser {
            let entry = F1RaceEntry(date: Date(), race: nil, sessionInfo: nil, isPremiumContent: true, isPreview: false)
            completion(entry)
            return
        }
        #else
        if (isPremiumWidget || isPremium) && !SubscriptionHelper.isProUser {
            let entry = F1RaceEntry(date: Date(), race: nil, sessionInfo: nil, isPremiumContent: true, isPreview: false)
            completion(entry)
            return
        }
        #endif
        
        Task {
            await loadData(isPreview: false) { entry in
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Check if this is a premium widget family and user is not pro
        let isPremium = context.family == .systemMedium
            if (isPremiumWidget || isPremium) && !SubscriptionHelper.isProUser {
            let entry = F1RaceEntry(date: Date(), race: nil, sessionInfo: nil, isPremiumContent: true, isPreview: false)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
            completion(timeline)
            return
        }
        
        WidgetCenter.shared.reloadTimelines(ofKind: "F1DriverStandingWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "F1ConstructorStandingWidget")
        Task {
            await loadData(isPreview: false) { entry in
                let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
                completion(timeline)
            }
        }
    }
    
    private func loadData(isPreview: Bool = false, completion: @escaping (F1RaceEntry) -> Void) async {
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/upcoming-races")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let races = try JSONDecoder().decode([F1Race].self, from: data)
            
            let now = Date().timeIntervalSince1970
            let nextRace = findNextRace(races: races, currentTime: now)
            
            let entry = F1RaceEntry(date: Date(), race: nextRace.race, sessionInfo: nextRace.sessionInfo, isPremiumContent: false, isPreview: isPreview)
            completion(entry)
        } catch {
            completion(F1RaceEntry(date: Date(), race: nil, sessionInfo: nil, isPremiumContent: false, isPreview: isPreview))
        }
    }
    
    private func findNextRace(races: [F1Race], currentTime: TimeInterval) -> (race: F1Race?, sessionInfo: SessionInfo?) {
        for race in races {
            // Check if race has ended
            if let raceEnd = race.datetime_race_end, Double(raceEnd) <= currentTime {
                continue
            }
            
            // Check each session in sequence
            let sessions: [(String, Int64?, Int64?)] = [
                ("FP1", race.datetime_fp1, race.datetime_fp1_end),
                ("FP2", race.datetime_fp2, race.datetime_fp2_end),
                ("FP3", race.datetime_fp3, race.datetime_fp3_end),
                ("SPRINT", race.datetime_sprint, race.datetime_sprint_end),
                ("Quali", race.datetime_qualifying, race.datetime_qualifying_end),
                ("Race", race.datetime_race, race.datetime_race_end)
            ]
            
            for (name, start, end) in sessions {
                guard let startTime = start else { continue }
                guard let endTime = end else { continue }
                
                let startDouble = Double(startTime)
                let endDouble = Double(endTime)
                
                if currentTime < startDouble {
                    // Session hasn't started
                    return (race, SessionInfo(name: name, timestamp: startDouble, isEnding: false))
                } else if currentTime >= startDouble && currentTime < endDouble {
                    // Session is ongoing
                    return (race, SessionInfo(name: name, timestamp: endDouble, isEnding: true))
                }
                // If session has ended, continue to next session
            }
        }
        return (nil, nil)
    }
}

struct SessionInfo {
    let name: String
    let timestamp: Double
    let isEnding: Bool
}

struct F1RaceEntry: TimelineEntry {
    let date: Date
    let race: F1Race?
    let sessionInfo: SessionInfo?
    let isPremiumContent: Bool
    let isPreview: Bool
    
    init(date: Date, race: F1Race?, sessionInfo: SessionInfo?, isPremiumContent: Bool = false, isPreview: Bool = false) {
        self.date = date
        self.race = race
        self.sessionInfo = sessionInfo
        self.isPremiumContent = isPremiumContent
        self.isPreview = isPreview
    }
}

struct F1RaceWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        // Show premium gate only for actual widgets (not previews) when content is premium
        if entry.isPremiumContent && !entry.isPreview {
            PremiumWidgetView(widgetFamily: family)
                .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
        } else {
            if let race = entry.race {
                switch family {
                case .systemSmall:
                    if let sessionInfo = entry.sessionInfo {
                        smallWidget(race: race, sessionInfo: sessionInfo)
                            .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
                    } else {
                        Text("No session info")
                            .modifier(F1RaceStyle.SubtitleStyle(isWidget: true))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
                    }
                case .systemMedium:
                    if let sessionInfo = entry.sessionInfo {
                        mediumWidget(race: race, sessionInfo: sessionInfo)
                            .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
                    } else {
                        Text("No session info")
                            .modifier(F1RaceStyle.SubtitleStyle(isWidget: true))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
                    }
                default:
                    if let sessionInfo = entry.sessionInfo {
                        smallWidget(race: race, sessionInfo: sessionInfo)
                            .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
                    } else {
                        Text("No session info")
                            .modifier(F1RaceStyle.SubtitleStyle(isWidget: true))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
                    }
                }
            } else {
                Text("No race info")
                    .modifier(F1RaceStyle.SubtitleStyle(isWidget: true))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
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
    
    // [WIDGET] Next Race Small Widget
    private func smallWidget(race: F1Race, sessionInfo: SessionInfo) -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Round \(race.round)")
                        .modifier(F1RaceStyle.EventTitleStyle())
                    
                    if let flagName = F1RaceStyle.getFlagName(for: race) {
                        Image(flagName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 12)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .offset(y: 2)
                    }
                }
                
                Text(race.shortname)
                    .font(getShortnameFont(for: race.shortname, baseSize: 22))
                    .foregroundColor(F1RaceStyle.textColor)
                
                if let fp1Start = race.datetime_fp1, let raceEnd = race.datetime_race_end {
                    Text(formatDateRange(start: Double(fp1Start), end: Double(raceEnd)))
                        .font(.custom("Formula1-Display-Bold", size: 13))
                        .foregroundColor(F1RaceStyle.secondaryTextColor)
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(sessionInfo.name) \(sessionInfo.isEnding ? "ends" : "starts") in")
                    .font(.custom("Formula1-Display-Bold", size: 14))
                    .foregroundColor(F1RaceStyle.accentColor)
                
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    ForEach(formatTimeRemaining(until: sessionInfo.timestamp), id: \.unit) { time in
                        VStack(alignment: .center, spacing: -2) {
                            Text(time.number)
                                .font(.custom("Formula1-Display-Bold", size: 22))
                                .foregroundColor(F1RaceStyle.textColor)
                            Text(time.unit)
                                .font(.custom("Formula1-Display-Regular", size: 12))
                                .foregroundColor(F1RaceStyle.secondaryTextColor)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .modifier(F1RaceStyle.CardWithRaceSpecificBackgroundStyle(isWidget: true, race: race))
    }
    
    // [WIDGET] Next Race Medium Widget
    private func mediumWidget(race: F1Race, sessionInfo: SessionInfo) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side - similar to small widget but more compact
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Round \(race.round)")
                            .modifier(F1RaceStyle.EventTitleStyle())
                        
                        if let flagName = F1RaceStyle.getFlagName(for: race) {
                            Image(flagName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 12)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .offset(y: 2)
                        }
                    }
                    
                    Text(race.shortname)
                        .font(getShortnameFont(for: race.shortname, baseSize: 24))
                        .foregroundColor(F1RaceStyle.textColor)
                    
                    if let fp1Start = race.datetime_fp1, let raceEnd = race.datetime_race_end {
                        Text(formatDateRange(start: Double(fp1Start), end: Double(raceEnd)))
                            .font(.custom("Formula1-Display-Bold", size: 13))
                            .foregroundColor(F1RaceStyle.secondaryTextColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sessionInfo.name) \(sessionInfo.isEnding ? "ends" : "starts") in")
                        .modifier(F1RaceStyle.SessionStyle(isWidget: true))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        ForEach(formatTimeRemaining(until: sessionInfo.timestamp), id: \.unit) { time in
                            VStack(alignment: .center, spacing: -2) {
                                Text(time.number)
                                    .font(.custom("Formula1-Display-Bold", size: 22))
                                    .foregroundColor(F1RaceStyle.textColor)
                                Text(time.unit)
                                    .font(.custom("Formula1-Display-Regular", size: 12))
                                    .foregroundColor(F1RaceStyle.secondaryTextColor)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            
            // Right side with sessions - fixed width to prevent shifting
            HStack(alignment: .top, spacing: 0) {
                
                // Session names - fixed width
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(getSessionTimes(race: race), id: \.name) { session in
                        Text(session.name)
                            .foregroundColor(F1RaceStyle.textColor)
                            .font(.custom("Formula1-Display-Regular", size: 12))
                            .frame(width: 45, alignment: .leading)
                    }
                }
                .frame(width: 45)
                
                // Divider - fixed position
                Rectangle()
                    .fill(F1RaceStyle.accentColor.opacity(0.8))
                    .frame(width: 2)
                    .frame(maxHeight: 95)
                    .clipShape(RoundedRectangle(cornerRadius: 1))
                    .padding(.leading, -6)
                
                // Days and Times combined - fixed width
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(getSessionTimes(race: race), id: \.name) { session in
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(session.day)
                                .foregroundColor(F1RaceStyle.textColor)
                                .font(.custom("Formula1-Display-Regular", size: 12))
                                .frame(width: 35, alignment: .leading)
                            
                            Text(session.time)
                                .foregroundColor(F1RaceStyle.textColor)
                                .font(.custom("Formula1-Display-Regular", size: 12))
                                .frame(alignment: .leading)
                        }
                    }
                }
                .frame(width: 110)
            }
            .frame(width: 157) // Fixed total width: 45 + 2 + 110 = 157
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.vertical, 4)
            .padding(.top, 11)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .modifier(F1RaceStyle.CardWithRaceSpecificBackgroundStyle(isWidget: true, race: race))
    }
    
    private func getSessionTimes(race: F1Race) -> [(name: String, day: String, time: String)] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"
        
        var sessions: [(name: String, day: String, time: String)] = []
        
        if let fp1 = race.datetime_fp1 {
            let date = Date(timeIntervalSince1970: Double(fp1))
            sessions.append(("FP1", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let fp2 = race.datetime_fp2 {
            let date = Date(timeIntervalSince1970: Double(fp2))
            sessions.append(("FP2", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let fp3 = race.datetime_fp3 {
            let date = Date(timeIntervalSince1970: Double(fp3))
            sessions.append(("FP3", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let sprint = race.datetime_sprint {
            let date = Date(timeIntervalSince1970: Double(sprint))
            sessions.append(("SPRINT", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let quali = race.datetime_qualifying {
            let date = Date(timeIntervalSince1970: Double(quali))
            sessions.append(("Quali", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let race = race.datetime_race {
            let date = Date(timeIntervalSince1970: Double(race))
            sessions.append(("Race", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        
        return sessions
    }
    
    func formatDateRange(start: Double, end: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMM"
        
        let startDate = Date(timeIntervalSince1970: start)
        let endDate = Date(timeIntervalSince1970: end)
        
        let startDay = dateFormatter.string(from: startDate)
        let endFormatted = dayFormatter.string(from: endDate)
        
        // If dates are in the same month
        if Calendar.current.isDate(startDate, equalTo: endDate, toGranularity: .month) {
            return "\(startDay) - \(endFormatted)"
        } else {
            let startFormatted = dayFormatter.string(from: startDate)
            return "\(startFormatted) - \(endFormatted)"
        }
    }
    
    func formatTimeRemaining(until timestamp: Double) -> [(number: String, unit: String)] {
        let timeRemaining = timestamp - Date().timeIntervalSince1970
        let days = Int(timeRemaining / (24 * 3600))
        let hours = Int((timeRemaining.truncatingRemainder(dividingBy: 24 * 3600)) / 3600)
        let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return [
                (String(format: "%02d", days), "days"),
                (String(format: "%02d", hours), "hrs")
            ]
        } else if hours > 0 {
            return [
                (String(format: "%02d", hours), "hrs"),
                (String(format: "%02d", minutes), "mins")
            ]
        } else {
            return [
                (String(format: "%02d", minutes), "mins")
            ]
        }
    }
    
    // [WIDGET] Complete Lock Screen Widget
    @ViewBuilder
    private func completeLockScreenWidget(race: F1Race) -> some View {
        ZStack {
            // Side borders
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
            }
            .padding(.horizontal, -4)
            
            // Content
            VStack(alignment: .leading, spacing: 1) {
                // Header
                HStack(alignment: .firstTextBaseline) {  // Changed from .top
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text("Round \(race.round)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text(race.shortname)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .scaleEffect(x: 1.1)
                    }
                    
                    Spacer()
                    
                    if let fp1Start = race.datetime_fp1, let raceEnd = race.datetime_race_end {
                        Text(formatDateRange(start: Double(fp1Start), end: Double(raceEnd)))
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .scaleEffect(x: 1.1)
                    }
                }
                .padding(.bottom, 1)
                
                // Sessions list with flag overlay
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(getSessionTimes(race: race), id: \.name) { session in
                            HStack(spacing: 0) {
                                Text(session.name)
                                    .font(.custom("Formula1-Display-Regular", size: 10))
                                    .foregroundColor(.white)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text(session.day)
                                    .font(.custom("Formula1-Display-Regular", size: 10))
                                    .foregroundColor(.white)
                                    .frame(width: 35, alignment: .leading)
                                
                                Spacer()
                                
                                Text(session.time)
                                    .font(.custom("Formula1-Display-Regular", size: 10))
                                    .foregroundColor(.white)
                                    .frame(alignment: .trailing)
                            }
                        }
                    }
                    
                    // Large flag in bottom right
                    if let flagName = F1RaceStyle.getFlagName(for: race) {
                        Image(flagName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 22)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .opacity(0.9)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
        }
        .modifier(F1RaceStyle.LockScreenWithRaceSpecificBackgroundStyle(race: race))
    }
}

struct F1RaceWidget: Widget {
    let kind: String = "F1RaceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                F1RaceWidgetEntryView(entry: entry)
                    .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
            } else {
                F1RaceWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("F1 Next Race")
        .description("Shows the next Formula 1 race.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct F1CompleteLockScreenWidget: Widget {
    let kind: String = "F1CompleteLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                F1CompleteLockScreenWidgetView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                F1CompleteLockScreenWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("F1 Race Schedule (Complete)")
        .description("Shows all sessions with times.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct F1CompactLockScreenWidget: Widget {
    let kind: String = "F1CompactLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(isPremiumWidget: true)) { entry in
            if #available(iOS 17.0, *) {
                F1CompactLockScreenWidgetView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                F1CompactLockScreenWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("F1 Race Schedule (Compact)")
        .description("Shows only Sprint, Qualifying and Race sessions.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct F1CountdownLockScreenWidget: Widget {
    let kind: String = "F1CountdownLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(isPremiumWidget: true)) { entry in
            if #available(iOS 17.0, *) {
                if entry.isPremiumContent && !entry.isPreview {
                    PremiumLockScreenWidgetView()
                        .containerBackground(.clear, for: .widget)
                } else {
                    F1CountdownLockScreenWidgetView(entry: entry)
                        .containerBackground(.clear, for: .widget)
                }
            } else {
                if entry.isPremiumContent && !entry.isPreview {
                    PremiumLockScreenWidgetView()
                } else {
                    F1CountdownLockScreenWidgetView(entry: entry)
                }
            }
        }
        .configurationDisplayName("F1 Race Schedule (Countdown)")
        .description("Shows countdown to each session.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// [WIDGET] Complete Lock Screen Widget
struct F1CompleteLockScreenWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let race = entry.race {
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, alignment: .top)
                
                // Content
                VStack(alignment: .leading, spacing: 1) {
                    // Header
                    HStack(alignment: .firstTextBaseline) {  // Changed from .top
                        Text(race.shortname)
                            .font(.custom("Formula1-Display-Bold", size: 11))
                            .foregroundColor(.white)
                        
                        Spacer(minLength: 0)
                        
                        if let fp1Start = race.datetime_fp1, let raceEnd = race.datetime_race_end {
                            Text(formatDateRange(start: Double(fp1Start), end: Double(raceEnd)))
                                .font(.custom("Formula1-Display-Bold", size: 9))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 1)
                    
                    // Sessions list
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(getSessionTimes(race: race), id: \.name) { session in
                            HStack(spacing: 0) {
                                Text(session.name)
                                    .font(.custom("Formula1-Display-Regular", size: 9))
                                    .foregroundColor(.white)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text(session.day)
                                    .font(.custom("Formula1-Display-Regular", size: 9))
                                    .foregroundColor(.white)
                                    .frame(width: 25, alignment: .leading)
                                
                                Spacer()
                                
                                Text(session.time)
                                    .font(.custom("Formula1-Display-Regular", size: 9))
                                    .foregroundColor(.white)
                                    .frame(alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .modifier(F1RaceStyle.LockScreenWithRaceSpecificBackgroundStyle(race: race))
        }
    }
    
    private func getSessionTimes(race: F1Race) -> [(name: String, day: String, time: String)] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"
        
        var sessions: [(name: String, day: String, time: String)] = []
        
        if let fp1 = race.datetime_fp1 {
            let date = Date(timeIntervalSince1970: Double(fp1))
            sessions.append(("FP1", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let fp2 = race.datetime_fp2 {
            let date = Date(timeIntervalSince1970: Double(fp2))
            sessions.append(("FP2", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let fp3 = race.datetime_fp3 {
            let date = Date(timeIntervalSince1970: Double(fp3))
            sessions.append(("FP3", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let sprint = race.datetime_sprint {
            let date = Date(timeIntervalSince1970: Double(sprint))
            sessions.append(("SPRINT", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let quali = race.datetime_qualifying {
            let date = Date(timeIntervalSince1970: Double(quali))
            sessions.append(("Quali", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let race = race.datetime_race {
            let date = Date(timeIntervalSince1970: Double(race))
            sessions.append(("Race", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        
        return sessions
    }
    
    private func formatDateRange(start: Double, end: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMM"
        
        let startDate = Date(timeIntervalSince1970: start)
        let endDate = Date(timeIntervalSince1970: end)
        
        let startDay = dateFormatter.string(from: startDate)
        let endFormatted = dayFormatter.string(from: endDate)
        
        // If dates are in the same month
        if Calendar.current.isDate(startDate, equalTo: endDate, toGranularity: .month) {
            return "\(startDay)-\(endFormatted)"
        } else {
            let startFormatted = dayFormatter.string(from: startDate)
            return "\(startFormatted)-\(endFormatted)"
        }
    }
}

// [WIDGET] Compact Lock Screen Widget
struct F1CompactLockScreenWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if entry.isPremiumContent && !entry.isPreview {
            if family == .accessoryRectangular {
                PremiumLockScreenWidgetView()
            } else {
                PremiumWidgetView(widgetFamily: family)
            }
        } else if let race = entry.race {
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, alignment: .top)
                
                // Content
                VStack(alignment: .leading, spacing: 1) {
                    // Header
                    HStack(alignment: .firstTextBaseline) {  // Changed from .top
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Text("R\(race.round)")
                                    .font(.custom("Formula1-Display-Regular", size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Text(race.shortname)
                                .font(.custom("Formula1-Display-Bold", size: 11))
                                .foregroundColor(.white)
                        }
                        
                        Spacer(minLength: 0)
                        
                        if let fp1Start = race.datetime_fp1, let raceEnd = race.datetime_race_end {
                            Text(formatDateRange(start: Double(fp1Start), end: Double(raceEnd)))
                                .font(.custom("Formula1-Display-Bold", size: 9))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.bottom, 1)
                    
                    // Sessions list
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(getSessionTimes(race: race).filter { $0.name == "SPRINT" || $0.name == "Quali" || $0.name == "Race" }, id: \.name) { session in
                            HStack(spacing: 0) {
                                Text(session.name)
                                    .font(.custom("Formula1-Display-Regular", size: 9))
                                    .foregroundColor(.white)
                                    .frame(width: 40, alignment: .leading)
                                
                                Text(session.day)
                                    .font(.custom("Formula1-Display-Regular", size: 9))
                                    .foregroundColor(.white)
                                    .frame(width: 25, alignment: .leading)
                                
                                Spacer()
                                
                                Text(session.time)
                                    .font(.custom("Formula1-Display-Regular", size: 9))
                                    .foregroundColor(.white)
                                    .frame(alignment: .trailing)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
            .modifier(F1RaceStyle.LockScreenWithRaceSpecificBackgroundStyle(race: race))
        } else {
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
                
                Text("Loading next race...")
                    .font(.custom("Formula1-Display-Regular", size: 11))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
    
    private func getSessionTimes(race: F1Race) -> [(name: String, day: String, time: String)] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"
        
        var sessions: [(name: String, day: String, time: String)] = []
        
        if let sprint = race.datetime_sprint {
            let date = Date(timeIntervalSince1970: Double(sprint))
            sessions.append(("SPRINT", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let quali = race.datetime_qualifying {
            let date = Date(timeIntervalSince1970: Double(quali))
            sessions.append(("Quali", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let race = race.datetime_race {
            let date = Date(timeIntervalSince1970: Double(race))
            sessions.append(("Race", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        
        return sessions
    }
    
    private func formatDateRange(start: Double, end: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMM"
        
        let startDate = Date(timeIntervalSince1970: start)
        let endDate = Date(timeIntervalSince1970: end)
        
        let startDay = dateFormatter.string(from: startDate)
        let endFormatted = dayFormatter.string(from: endDate)
        
        // If dates are in the same month
        if Calendar.current.isDate(startDate, equalTo: endDate, toGranularity: .month) {
            return "\(startDay) - \(endFormatted)"
        } else {
            let startFormatted = dayFormatter.string(from: startDate)
            return "\(startFormatted) - \(endFormatted)"
        }
    }
}

// [WIDGET] Countdown Lock Screen Widget
struct F1CountdownLockScreenWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if entry.isPremiumContent && !entry.isPreview {
            PremiumWidgetView(widgetFamily: family)
        } else if let race = entry.race, let sessionInfo = entry.sessionInfo {
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, alignment: .top)
                
                // Content
                VStack(alignment: .leading, spacing: 1) {
                    // Header
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text(race.shortname)
                                .font(.custom("Formula1-Display-Bold", size: 12))
                                .foregroundColor(.white)
                            
                            Text("•")
                                .font(.custom("Formula1-Display-Bold", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("R\(race.round)")
                                .font(.custom("Formula1-Display-Bold", size: 12))
                                .foregroundColor(.white)
                            
                            Spacer(minLength: 0)
                        }
                        
                        if let raceDate = race.datetime_race {
                            Text(formatDate(from: Double(raceDate)))
                                .font(.custom("Formula1-Display-Regular", size: 11))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.bottom, 0)
                    
                    // Session countdown with flag overlay
                    ZStack(alignment: .bottomTrailing) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(sessionInfo.name) \(sessionInfo.isEnding ? "ends" : "starts") in")
                                .font(.custom("Formula1-Display-Regular", size: 10))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 4) {
                                ForEach(formatTimeRemaining(until: sessionInfo.timestamp), id: \.unit) { time in
                                    Text("\(time.number)\(time.unit)")
                                        .font(.custom("Formula1-Display-Bold", size: 14))
                                        .foregroundColor(.white)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        
                        // Large flag in bottom right with padding
                        if let flagName = F1RaceStyle.getFlagName(for: race) {
                            Image(flagName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .opacity(1)
                                .padding(.trailing, 10)
                                .padding(.bottom, 10)
                                .scaleEffect(1.3)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .modifier(F1RaceStyle.LockScreenWithRaceSpecificBackgroundStyle(race: race))
        } else {
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
                
                Text("No upcoming sessions")
                    .font(.custom("Formula1-Display-Regular", size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
    
    func formatDate(from timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    func formatTimeRemaining(until timestamp: Double) -> [(number: String, unit: String)] {
        let timeRemaining = timestamp - Date().timeIntervalSince1970
        let days = Int(timeRemaining / (24 * 3600))
        let hours = Int((timeRemaining.truncatingRemainder(dividingBy: 24 * 3600)) / 3600)
        let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return [
                (String(format: "%d", days), "d"),
                (String(format: "%d", hours), "h")
            ]
        } else if hours > 0 {
            return [
                (String(format: "%d", hours), "h"),
                (String(format: "%d", minutes), "m")
            ]
        } else {
            return [
                (String(format: "%d", minutes), "m")
            ]
        }
    }
}

// [WIDGET] Large Widget
struct F1LargeWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let race = entry.race, let sessionInfo = entry.sessionInfo {
            VStack(alignment: .leading, spacing: 16) {
                // Header section
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Round \(race.round)")
                            .font(.custom("Formula1-Display-Regular", size: 15))
                            .foregroundColor(F1RaceStyle.textColor)
                        
                        if let flagName = F1RaceStyle.getFlagName(for: race) {
                            Image(flagName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 15)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                    
                    Text(race.shortname)
                        .font(.custom("Formula1-Display-Bold", size: 32))
                        .foregroundColor(F1RaceStyle.textColor)
                        .scaleEffect(x: 1.1)
                    
                    if let fp1Start = race.datetime_fp1, let raceEnd = race.datetime_race_end {
                        Text(formatDateRange(start: Double(fp1Start), end: Double(raceEnd)))
                            .font(.custom("Formula1-Display-Bold", size: 15))
                            .foregroundColor(F1RaceStyle.secondaryTextColor)
                            .scaleEffect(x: 1.1)
                    }
                }
                
                // Countdown section
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sessionInfo.name) \(sessionInfo.isEnding ? "ends" : "starts") in")
                        .font(.custom("Formula1-Display-Bold", size: 15))
                        .foregroundColor(Color.red)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        ForEach(formatTimeRemaining(until: sessionInfo.timestamp), id: \.unit) { time in
                            VStack(alignment: .center, spacing: -2) {
                                Text(time.number)
                                    .font(.custom("Formula1-Display-Bold", size: 28))
                                    .foregroundColor(F1RaceStyle.textColor)
                                    .scaleEffect(x: 1.1)
                                Text(time.unit)
                                    .font(.custom("Formula1-Display-Regular", size: 14))
                                    .foregroundColor(F1RaceStyle.secondaryTextColor)
                            }
                        }
                    }
                }
                
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
                    .padding(.vertical, 4)
                
                // Sessions list
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(getSessionTimes(race: race), id: \.name) { session in
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text(session.name)
                                .font(.custom("Formula1-Display-Bold", size: 15))
                                .foregroundColor(F1RaceStyle.textColor)
                                .frame(width: 60, alignment: .leading)
                            
                            Text(session.day)
                                .font(.custom("Formula1-Display-Regular", size: 15))
                                .foregroundColor(F1RaceStyle.secondaryTextColor)
                                .frame(width: 100, alignment: .leading)
                            
                            Spacer()
                            
                            Text(session.time)
                                .font(.custom("Formula1-Display-Regular", size: 15))
                                .foregroundColor(F1RaceStyle.secondaryTextColor)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(16)
            .modifier(F1RaceStyle.CardWithRaceSpecificBackgroundStyle(isWidget: true, race: race))
        } else {
            Text("No upcoming races")
                .font(.custom("Formula1-Display-Regular", size: 15))
                .foregroundColor(F1RaceStyle.textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .containerBackground(F1RaceStyle.widgetBackgroundColor, for: .widget)
        }
    }
    
    private func formatTimeRemaining(until timestamp: Double) -> [(number: String, unit: String)] {
        let timeRemaining = timestamp - Date().timeIntervalSince1970
        let days = Int(timeRemaining / (24 * 3600))
        let hours = Int((timeRemaining.truncatingRemainder(dividingBy: 24 * 3600)) / 3600)
        let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            return [
                (String(format: "%02d", days), "days"),
                (String(format: "%02d", hours), "hrs")
            ]
        } else if hours > 0 {
            return [
                (String(format: "%02d", hours), "hrs"),
                (String(format: "%02d", minutes), "mins")
            ]
        } else {
            return [
                (String(format: "%02d", minutes), "mins")
            ]
        }
    }
    
    private func getSessionTimes(race: F1Race) -> [(name: String, day: String, time: String)] {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"
        
        var sessions: [(name: String, day: String, time: String)] = []
        
        if let fp1 = race.datetime_fp1 {
            let date = Date(timeIntervalSince1970: Double(fp1))
            sessions.append(("FP1", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let fp2 = race.datetime_fp2 {
            let date = Date(timeIntervalSince1970: Double(fp2))
            sessions.append(("FP2", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let fp3 = race.datetime_fp3 {
            let date = Date(timeIntervalSince1970: Double(fp3))
            sessions.append(("FP3", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let sprint = race.datetime_sprint {
            let date = Date(timeIntervalSince1970: Double(sprint))
            sessions.append(("SPRINT", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let quali = race.datetime_qualifying {
            let date = Date(timeIntervalSince1970: Double(quali))
            sessions.append(("Quali", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        if let race = race.datetime_race {
            let date = Date(timeIntervalSince1970: Double(race))
            sessions.append(("Race", dayFormatter.string(from: date), timeFormatter.string(from: date)))
        }
        
        return sessions
    }
    
    private func formatDateRange(start: Double, end: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMM"
        
        let startDate = Date(timeIntervalSince1970: start)
        let endDate = Date(timeIntervalSince1970: end)
        
        let startDay = dateFormatter.string(from: startDate)
        let endFormatted = dayFormatter.string(from: endDate)
        
        // If dates are in the same month
        if Calendar.current.isDate(startDate, equalTo: endDate, toGranularity: .month) {
            return "\(startDay) - \(endFormatted)"
        } else {
            let startFormatted = dayFormatter.string(from: startDate)
            return "\(startFormatted) - \(endFormatted)"
        }
    }
}

struct F1DriverStanding: Codable {
    let id: Int
    let driver_name: String
    let team_name: String
    let points: Int
    let driver_number: Int
    let display_name: String
}

struct DriverWithPosition {
    let driver: F1DriverStanding
    let position: Int
}

struct F1DriverEntry: TimelineEntry {
    let date: Date
    let driverStanding: DriverWithPosition?
    let configuration: ConfigureDriver
    let isPremiumContent: Bool
    let isPreview: Bool
    
    init(date: Date, driverStanding: DriverWithPosition?, configuration: ConfigureDriver, isPremiumContent: Bool = false, isPreview: Bool = false) {
        self.date = date
        self.driverStanding = driverStanding
        self.configuration = configuration
        self.isPremiumContent = isPremiumContent
        self.isPreview = isPreview
    }
}

struct F1DriverStandingWidget: Widget {
    let kind: String = "F1DriverStandingWidget"
    
    var body: some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return AppIntentConfiguration(kind: kind,
                              intent: ConfigureDriver.self,
                              provider: F1DriverStandingAppIntentProvider()) { entry in
                F1DriverStandingWidgetView(entry: entry)
                    .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
            }
            .configurationDisplayName("F1 Driver Standing")
            .description("Shows selected driver's current standing and points.")
            .supportedFamilies([.systemSmall, .systemMedium])
            .contentMarginsDisabled()
        } else {
            return IntentConfiguration(kind: kind,
                              intent: ConfigureDriverIntent.self,
                              provider: F1DriverStandingLegacyProvider()) { entry in
                F1DriverStandingWidgetView(entry: entry)
                    .padding()
                    .background()
            }
            .configurationDisplayName("F1 Driver Standing")
            .description("Shows selected driver's current standing and points.")
            .supportedFamilies([.systemSmall, .systemMedium])
            .contentMarginsDisabled()
        }
    }
}

// AppIntent provider for iOS 17+
@available(iOS 17.0, *)
class F1DriverStandingAppIntentProvider: AppIntentTimelineProvider {
    typealias Entry = F1DriverEntry
    typealias Intent = ConfigureDriver
    
    private let isPremiumWidget: Bool
    
    init(isPremiumWidget: Bool = true) {
        self.isPremiumWidget = isPremiumWidget
    }

    func placeholder(in context: Context) -> F1DriverEntry {
        // Always show real content in placeholders (for widget gallery previews)
        F1DriverEntry(date: Date(), driverStanding: nil, configuration: ConfigureDriver(), isPremiumContent: false, isPreview: false)
    }
    
    func snapshot(for configuration: ConfigureDriver, in context: Context) async -> F1DriverEntry {
        // For previews in widget gallery, always show real content to entice users
        if context.isPreview {
            return await reloadWidget(for: configuration, isPremium: false, isPreview: true)
        }
        
        // Check if this is a premium widget and user is not pro
        if isPremiumWidget && !SubscriptionHelper.isProUser {
            return F1DriverEntry(date: Date(), driverStanding: nil, configuration: configuration, isPremiumContent: true, isPreview: false)
        }
        return await reloadWidget(for: configuration, isPremium: false, isPreview: false)
    }
    
    func timeline(for configuration: ConfigureDriver, in context: Context) async -> Timeline<F1DriverEntry> {
        // Check if this is a premium widget and user is not pro
        if isPremiumWidget  && !SubscriptionHelper.isProUser {
            let entry = F1DriverEntry(date: Date(), driverStanding: nil, configuration: configuration, isPremiumContent: true, isPreview: false)
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15))) // Check every 15 minutes
        }
        
        print("Getting timeline for driver: \(configuration.selectedDriver)")
        
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/driver-standings")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let drivers = try JSONDecoder().decode([F1DriverStanding].self, from: data)
            
            // Find driver and get position from array index
            var selectedDriverWithPosition: DriverWithPosition?
            for (index, driver) in drivers.enumerated() {
                let matches = switch configuration.selectedDriver {
                case .ver: driver.display_name.uppercased() == "VER"
                case .pia: driver.display_name.uppercased() == "PIA"
                case .nor: driver.display_name.uppercased() == "NOR"
                case .rus: driver.display_name.uppercased() == "RUS"
                case .lec: driver.display_name.uppercased() == "LEC"
                case .ham: driver.display_name.uppercased() == "HAM"
                case .ant: driver.display_name.uppercased() == "ANT"
                case .alb: driver.display_name.uppercased() == "ALB"
                case .oco: driver.display_name.uppercased() == "OCO"
                case .had: driver.display_name.uppercased() == "HAD"
                case .str: driver.display_name.uppercased() == "STR"
                case .sai: driver.display_name.uppercased() == "SAI"
                case .tsu: driver.display_name.uppercased() == "TSU"
                case .gas: driver.display_name.uppercased() == "GAS"
                case .hul: driver.display_name.uppercased() == "HUL"
                case .bea: driver.display_name.uppercased() == "BEA"
                case .law: driver.display_name.uppercased() == "LAW"
                case .alo: driver.display_name.uppercased() == "ALO"
                case .col: driver.display_name.uppercased() == "COL"
                case .bor: driver.display_name.uppercased() == "BOR"
                }
                
                if matches {
                    selectedDriverWithPosition = DriverWithPosition(driver: driver, position: index + 1)
                    break
                }
            }
            
            let entry = F1DriverEntry(date: Date(), driverStanding: selectedDriverWithPosition, configuration: configuration, isPremiumContent: false, isPreview: false)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        } catch {
            print("Error loading data: \(error)")
            let loadingEntry = F1DriverEntry(date: Date(), driverStanding: nil, configuration: configuration, isPremiumContent: false, isPreview: false)
            return Timeline(entries: [loadingEntry], policy: .after(Date().addingTimeInterval(60)))
        }
    }
    
    private func reloadWidget(for configuration: ConfigureDriver, isPremium: Bool = false, isPreview: Bool = false) async -> F1DriverEntry {
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/driver-standings")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let drivers = try JSONDecoder().decode([F1DriverStanding].self, from: data)
            
            // Find driver and get position from array index
            var selectedDriverWithPosition: DriverWithPosition?
            for (index, driver) in drivers.enumerated() {
                let matches = switch configuration.selectedDriver {
                case .ver: driver.display_name.uppercased() == "VER"
                case .pia: driver.display_name.uppercased() == "PIA"
                case .nor: driver.display_name.uppercased() == "NOR"
                case .rus: driver.display_name.uppercased() == "RUS"
                case .lec: driver.display_name.uppercased() == "LEC"
                case .ham: driver.display_name.uppercased() == "HAM"
                case .ant: driver.display_name.uppercased() == "ANT"
                case .alb: driver.display_name.uppercased() == "ALB"
                case .oco: driver.display_name.uppercased() == "OCO"
                case .had: driver.display_name.uppercased() == "HAD"
                case .str: driver.display_name.uppercased() == "STR"
                case .sai: driver.display_name.uppercased() == "SAI"
                case .tsu: driver.display_name.uppercased() == "TSU"
                case .gas: driver.display_name.uppercased() == "GAS"
                case .hul: driver.display_name.uppercased() == "HUL"
                case .bea: driver.display_name.uppercased() == "BEA"
                case .law: driver.display_name.uppercased() == "LAW"
                case .alo: driver.display_name.uppercased() == "ALO"
                case .col: driver.display_name.uppercased() == "COL"
                case .bor: driver.display_name.uppercased() == "BOR"
                }
                
                if matches {
                    selectedDriverWithPosition = DriverWithPosition(driver: driver, position: index + 1)
                    break
                }
            }
            
            return F1DriverEntry(date: Date(), driverStanding: selectedDriverWithPosition, configuration: configuration, isPremiumContent: isPremium, isPreview: isPreview)
        } catch {
            print("Error loading data: \(error)")
            return F1DriverEntry(date: Date(), driverStanding: nil, configuration: configuration, isPremiumContent: isPremium, isPreview: isPreview)
        }
    }
}

// Legacy provider for iOS 16 and below
class F1DriverStandingLegacyProvider: IntentTimelineProvider {
    typealias Entry = F1DriverEntry
    typealias Intent = ConfigureDriverIntent
    
    private let isPremiumWidget: Bool
    
    init(isPremiumWidget: Bool = false) {
        self.isPremiumWidget = isPremiumWidget
    }

    func placeholder(in context: Context) -> F1DriverEntry {
        // Create a default ConfigureDriver for the entry
        F1DriverEntry(date: Date(), driverStanding: nil, configuration: ConfigureDriver(), isPremiumContent: false, isPreview: false)
    }
    
    func getSnapshot(for configuration: ConfigureDriverIntent, in context: Context, completion: @escaping (F1DriverEntry) -> ()) {
        // For previews in widget gallery, always show real content to entice users
        if context.isPreview {
            Task {
                let entry = await reloadWidget(for: configuration, isPremiumContent: false, isPreview: true)
                completion(entry)
            }
            return
        }
        
        // Check if this is a premium widget and user is not pro
        if isPremiumWidget  && !SubscriptionHelper.isProUser {
            let entry = F1DriverEntry(date: Date(), driverStanding: nil, configuration: ConfigureDriver(), isPremiumContent: true, isPreview: false)
            completion(entry)
            return
        }
        
        Task {
            let entry = await reloadWidget(for: configuration, isPremiumContent: false, isPreview: false)
            completion(entry)
        }
    }
    
    
    func getTimeline(for configuration: ConfigureDriverIntent, in context: Context, completion: @escaping (Timeline<F1DriverEntry>) -> ()) {
        // Check if this is a premium widget and user is not pro
        if isPremiumWidget  && !SubscriptionHelper.isProUser {
            let entry = F1DriverEntry(date: Date(), driverStanding: nil, configuration: ConfigureDriver(), isPremiumContent: true, isPreview: false)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
            completion(timeline)
            return
        }
        
        print("Getting timeline for legacy driver intent")
        
        Task {
            do {
                let url = URL(string: "https://f1apibackend-1.onrender.com/api/driver-standings")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let drivers = try JSONDecoder().decode([F1DriverStanding].self, from: data)
                
                // Convert legacy intent to new format
                let configureDriver = ConfigureDriver()
                switch configuration.selectedDriver {
                case .ver: configureDriver.selectedDriver = .ver
                case .pia: configureDriver.selectedDriver = .pia
                case .nor: configureDriver.selectedDriver = .nor
                case .rus: configureDriver.selectedDriver = .rus
                case .lec: configureDriver.selectedDriver = .lec
                case .ham: configureDriver.selectedDriver = .ham
                case .ant: configureDriver.selectedDriver = .ant
                case .alb: configureDriver.selectedDriver = .alb
                case .oco: configureDriver.selectedDriver = .oco
                case .had: configureDriver.selectedDriver = .had
                case .str: configureDriver.selectedDriver = .str
                case .sai: configureDriver.selectedDriver = .sai
                case .tsu: configureDriver.selectedDriver = .tsu
                case .gas: configureDriver.selectedDriver = .gas
                case .hul: configureDriver.selectedDriver = .hul
                case .bea: configureDriver.selectedDriver = .bea
                case .law: configureDriver.selectedDriver = .law
                case .alo: configureDriver.selectedDriver = .alo
                case .col: configureDriver.selectedDriver = .col
                case .bor: configureDriver.selectedDriver = .bor
                case .unknown: configureDriver.selectedDriver = .ver
                @unknown default: configureDriver.selectedDriver = .ver
                }
                
                // Find driver and get position from array index
                var selectedDriverWithPosition: DriverWithPosition?
                for (index, driver) in drivers.enumerated() {
                    let matches = switch configureDriver.selectedDriver {
                    case .ver: driver.display_name.uppercased() == "VER"
                    case .pia: driver.display_name.uppercased() == "PIA"
                    case .nor: driver.display_name.uppercased() == "NOR"
                    case .rus: driver.display_name.uppercased() == "RUS"
                    case .lec: driver.display_name.uppercased() == "LEC"
                    case .ham: driver.display_name.uppercased() == "HAM"
                    case .ant: driver.display_name.uppercased() == "ANT"
                    case .alb: driver.display_name.uppercased() == "ALB"
                    case .oco: driver.display_name.uppercased() == "OCO"
                    case .had: driver.display_name.uppercased() == "HAD"
                    case .str: driver.display_name.uppercased() == "STR"
                    case .sai: driver.display_name.uppercased() == "SAI"
                    case .tsu: driver.display_name.uppercased() == "TSU"
                    case .gas: driver.display_name.uppercased() == "GAS"
                    case .hul: driver.display_name.uppercased() == "HUL"
                    case .bea: driver.display_name.uppercased() == "BEA"
                    case .law: driver.display_name.uppercased() == "LAW"
                    case .alo: driver.display_name.uppercased() == "ALO"
                    case .col: driver.display_name.uppercased() == "COL"
                    case .bor: driver.display_name.uppercased() == "BOR"
                    }
                    
                    if matches {
                        selectedDriverWithPosition = DriverWithPosition(driver: driver, position: index + 1)
                        break
                    }
                }
                
                let entry = F1DriverEntry(date: Date(), driverStanding: selectedDriverWithPosition, configuration: configureDriver, isPremiumContent: false, isPreview: false)
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
                
                await MainActor.run {
                    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                    completion(timeline)
                }
            } catch {
                print("Error loading data: \(error)")
                let loadingEntry = F1DriverEntry(date: Date(), driverStanding: nil, configuration: ConfigureDriver(), isPremiumContent: false, isPreview: false)
                await MainActor.run {
                    let timeline = Timeline(entries: [loadingEntry], policy: .after(Date().addingTimeInterval(60)))
                    completion(timeline)
                }
            }
        }
    }
    
    private func reloadWidget(for configuration: ConfigureDriverIntent, isPremiumContent: Bool = false, isPreview: Bool = false) async -> F1DriverEntry {
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/driver-standings")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let drivers = try JSONDecoder().decode([F1DriverStanding].self, from: data)
            
            // Convert legacy intent to new format
            let configureDriver = ConfigureDriver()
            switch configuration.selectedDriver {
            case .ver: configureDriver.selectedDriver = .ver
            case .pia: configureDriver.selectedDriver = .pia
            case .nor: configureDriver.selectedDriver = .nor
            case .rus: configureDriver.selectedDriver = .rus
            case .lec: configureDriver.selectedDriver = .lec
            case .ham: configureDriver.selectedDriver = .ham
            case .ant: configureDriver.selectedDriver = .ant
            case .alb: configureDriver.selectedDriver = .alb
            case .oco: configureDriver.selectedDriver = .oco
            case .had: configureDriver.selectedDriver = .had
            case .str: configureDriver.selectedDriver = .str
            case .sai: configureDriver.selectedDriver = .sai
            case .tsu: configureDriver.selectedDriver = .tsu
            case .gas: configureDriver.selectedDriver = .gas
            case .hul: configureDriver.selectedDriver = .hul
            case .bea: configureDriver.selectedDriver = .bea
            case .law: configureDriver.selectedDriver = .law
            case .alo: configureDriver.selectedDriver = .alo
            case .col: configureDriver.selectedDriver = .col
            case .bor: configureDriver.selectedDriver = .bor
            case .unknown: configureDriver.selectedDriver = .ver
            @unknown default: configureDriver.selectedDriver = .ver
            }
            
            // Find driver and get position from array index
            var selectedDriverWithPosition: DriverWithPosition?
            for (index, driver) in drivers.enumerated() {
                let matches = switch configureDriver.selectedDriver {
                case .ver: driver.display_name.uppercased() == "VER"
                case .pia: driver.display_name.uppercased() == "PIA"
                case .nor: driver.display_name.uppercased() == "NOR"
                case .rus: driver.display_name.uppercased() == "RUS"
                case .lec: driver.display_name.uppercased() == "LEC"
                case .ham: driver.display_name.uppercased() == "HAM"
                case .ant: driver.display_name.uppercased() == "ANT"
                case .alb: driver.display_name.uppercased() == "ALB"
                case .oco: driver.display_name.uppercased() == "OCO"
                case .had: driver.display_name.uppercased() == "HAD"
                case .str: driver.display_name.uppercased() == "STR"
                case .sai: driver.display_name.uppercased() == "SAI"
                case .tsu: driver.display_name.uppercased() == "TSU"
                case .gas: driver.display_name.uppercased() == "GAS"
                case .hul: driver.display_name.uppercased() == "HUL"
                case .bea: driver.display_name.uppercased() == "BEA"
                case .law: driver.display_name.uppercased() == "LAW"
                case .alo: driver.display_name.uppercased() == "ALO"
                case .col: driver.display_name.uppercased() == "COL"
                case .bor: driver.display_name.uppercased() == "BOR"
                }
                
                if matches {
                    selectedDriverWithPosition = DriverWithPosition(driver: driver, position: index + 1)
                    break
                }
            }
            
            return F1DriverEntry(date: Date(), driverStanding: selectedDriverWithPosition, configuration: configureDriver, isPremiumContent: isPremiumContent, isPreview: isPreview)
        } catch {
            print("Error loading data: \(error)")
            return F1DriverEntry(date: Date(), driverStanding: nil, configuration: ConfigureDriver(), isPremiumContent: isPremiumContent, isPreview: isPreview)
        }
    }
}

struct F1DriverStandingWidgetView: View {
    var entry: F1DriverEntry
    @Environment(\.widgetFamily) var family
    
    private func driverString(_ driver: DriverAppEnum) -> String {
        switch driver {
        case .ver: return "VER"
        case .pia: return "PIA"
        case .nor: return "NOR"
        case .rus: return "RUS"
        case .lec: return "LEC"
        case .ham: return "HAM"
        case .ant: return "ANT"
        case .alb: return "ALB"
        case .oco: return "OCO"
        case .had: return "HAD"
        case .str: return "STR"
        case .sai: return "SAI"
        case .tsu: return "TSU"
        case .gas: return "GAS"
        case .hul: return "HUL"
        case .bea: return "BEA"
        case .law: return "LAW"
        case .alo: return "ALO"
        case .col: return "COL"
        case .bor: return "BOR"
        }
    }
    
    private func getDriverHelmetImageName(for displayName: String) -> String? {
        switch displayName.uppercased() {
        case "PIA": return "driver-helmet-piastri"
        case "NOR": return "driver-helmet-norris"
        case "VER": return "driver-helmet-verstappen"
        case "RUS": return "driver-helmet-russell"
        case "LEC": return "driver-helmet-leclerc"
        case "HAM": return "driver-helmet-hamilton"
        case "ANT": return "driver-helmet-antonelli"
        case "ALB": return "driver-helmet-albon"
        case "HAD": return "driver-helmet-hadjar"
        case "OCO": return "driver-helmet-ocon"
        case "HUL": return "driver-helmet-hulkenberg"
        case "STR": return "driver-helmet-stroll"
        case "SAI": return "driver-helmet-sainz"
        case "GAS": return "driver-helmet-gasly"
        case "TSU": return "driver-helmet-tsunoda"
        case "BEA": return "driver-helmet-bearman"
        case "LAW": return "driver-helmet-lawson"
        case "ALO": return "driver-helmet-alonso"
        case "COL": return "driver-helmet-colapinto"
        case "BOR": return "driver-helmet-bortoleto"
        default: return nil
        }
    }

    var body: some View {
        if entry.isPremiumContent && !entry.isPreview {
            PremiumWidgetView(widgetFamily: family)
                .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
        } else {
            if let driverWithPosition = entry.driverStanding {
                switch family {
                case .systemSmall:
                    smallDriverWidget(driverWithPosition: driverWithPosition)
                        .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
                case .systemMedium:
                    mediumDriverWidget(driverWithPosition: driverWithPosition)
                        .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
                default:
                    smallDriverWidget(driverWithPosition: driverWithPosition)
                        .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
                }
            } else {
                loadingView()
                    .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
            }
        }
    }
    
    // [WIDGET] Driver Small Widget
    @ViewBuilder
    private func smallDriverWidget(driverWithPosition: DriverWithPosition) -> some View {
        let driver = driverWithPosition.driver
        let teamName = driver.team_name
        let logoName = F1RaceStyle.getTeamLogo(for: teamName)
        
        // Split the driver name into first and last name
        let nameParts = driver.driver_name.components(separatedBy: " ")
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.dropFirst().joined(separator: " ")
        
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    F1RaceStyle.getTeamColor(for: driver.team_name).opacity(0.35),
                    Color.black
                ]),
                startPoint: .leading,
                endPoint: .init(x: 0.4, y: 0)
            )

            // Main content
            VStack(alignment: .leading, spacing: 8) {
                
                // Driver name (moved down)
                VStack(alignment: .leading, spacing: 0) {
                    Text(firstName)
                        .font(.custom("Formula1-Display-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    
                    Text(lastName)
                        .font(.custom("Formula1-Display-Bold", size: 18.5))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
                
                // Bottom section with position and points (vertically arranged)
                VStack(alignment: .leading, spacing: 8) {
                    // Position column on top
                    VStack(alignment: .leading, spacing: 2) {
                        Text("P\(driverWithPosition.position)")
                            .font(.custom("Formula1-Display-Bold", size: 24))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Text("POS")
                            .font(.custom("Formula1-Display-Bold", size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Points column below
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(driver.points)")
                            .font(.custom("Formula1-Display-Bold", size: 24))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Text("PTS")
                            .font(.custom("Formula1-Display-Bold", size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            
            // Helmet overlay with silver glow (absolute position)
            if let helmetImageName = getDriverHelmetImageName(for: driver.display_name) {
                Image(helmetImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 0)
                    .offset(x: 45, y: 30)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // [WIDGET] Driver Medium Widget
    @ViewBuilder
    private func mediumDriverWidget(driverWithPosition: DriverWithPosition) -> some View {
        let driver = driverWithPosition.driver
        let teamName = driver.team_name
        let logoName = F1RaceStyle.getTeamLogo(for: teamName)
        
        // Split the driver name into first and last name
        let nameParts = driver.driver_name.components(separatedBy: " ")
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.dropFirst().joined(separator: " ")
        
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    F1RaceStyle.getTeamColor(for: driver.team_name).opacity(0.35),
                    Color.black
                ]),
                startPoint: .leading,
                endPoint: .init(x: 0.4, y: 0)
            )
            
            HStack(spacing: 0) {
                // Left side - Driver info
                VStack(alignment: .leading, spacing: 4) {
                    // Team logo at the top
                    if let logoName = logoName {
                        Image(logoName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 30)
                    } else {
                        Text("Logo not found: \(teamName)")
                            .font(.custom("Formula1-Display-Regular", size: 10))
                            .foregroundColor(.red)
                    }
                    
                    // Driver info
                    VStack(alignment: .leading, spacing: 0) {
                        Text(firstName)
                            .font(.custom("Formula1-Display-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        
                        Text(lastName)
                            .font(.custom("Formula1-Display-Bold", size: 24))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 180, alignment: .leading)

                    Spacer()
                        .frame(height: 2)
                    
                    // Position and points
                    HStack {
                        VStack(alignment: .leading, spacing: -1) {
                            
                            Text("P\(driverWithPosition.position)")
                                .font(.custom("Formula1-Display-Regular", size: 28))
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                            
                            Text("POS")
                                .font(.custom("Formula1-Display-Bold", size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: -1) {
                            
                            Text("\(driver.points)")
                                .font(.custom("Formula1-Display-Regular", size: 28))
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                            
                            Text("PTS")
                                .font(.custom("Formula1-Display-Bold", size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                // Right side - Helmet
                if let helmetImageName = getDriverHelmetImageName(for: driver.display_name) {
                    Image(helmetImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .shadow(color: .white.opacity(0.4), radius: 8, x: 0, y: 0)
                        .shadow(color: .white.opacity(0.2), radius: 15, x: 0, y: 0)
                        .offset(x: 10, y: 10)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 4) {
            Text("Loading driver")
                .font(.custom("Formula1-Display-Regular", size: 14))
                .foregroundColor(F1RaceStyle.textColor)
            Text(driverString(entry.configuration.selectedDriver))
                .font(.custom("Formula1-Display-Regular", size: 16))
                .foregroundColor(F1RaceStyle.textColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(F1RaceStyle.SubtitleStyle(isWidget: true))
    }
}

// [WIDGET] Driver Lock Screen Widget
struct F1DriverStandingLockScreenWidget: Widget {
    let kind: String = "F1DriverStandingLockScreenWidget"
    
    var body: some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return AppIntentConfiguration(kind: kind,
                              intent: ConfigureDriver.self,
                              provider: F1DriverStandingAppIntentProvider(isPremiumWidget: true)) { entry in
                if entry.isPremiumContent && !entry.isPreview {
                    PremiumLockScreenWidgetView()
                        .containerBackground(.clear, for: .widget)
                } else {
                    F1DriverStandingLockScreenWidgetView(entry: entry)
                        .containerBackground(.clear, for: .widget)
                }
            }
            .configurationDisplayName("F1 Driver Standing (Lock Screen)")
            .description("Shows selected driver's position and points on lock screen.")
            .supportedFamilies([.accessoryRectangular])
            .contentMarginsDisabled()
        } else {
            return IntentConfiguration(kind: kind,
                              intent: ConfigureDriverIntent.self,
                              provider: F1DriverStandingLegacyProvider(isPremiumWidget: true)) { entry in
                if entry.isPremiumContent && !entry.isPreview {
                    PremiumLockScreenWidgetView()
                } else {
                    F1DriverStandingLockScreenWidgetView(entry: entry)
                }
            }
            .configurationDisplayName("F1 Driver Standing (Lock Screen)")
            .description("Shows selected driver's position and points on lock screen.")
            .supportedFamilies([.accessoryRectangular])
            .contentMarginsDisabled()
        }
    }
}

// [WIDGET] Driver Lock Screen Widget
struct F1DriverStandingLockScreenWidgetView: View {
    var entry: F1DriverEntry
    @Environment(\.widgetFamily) var family
    
    private func driverString(_ driver: DriverAppEnum) -> String {
        switch driver {
        case .ver: return "VER"
        case .pia: return "PIA"
        case .nor: return "NOR"
        case .rus: return "RUS"
        case .lec: return "LEC"
        case .ham: return "HAM"
        case .ant: return "ANT"
        case .alb: return "ALB"
        case .oco: return "OCO"
        case .had: return "HAD"
        case .str: return "STR"
        case .sai: return "SAI"
        case .tsu: return "TSU"
        case .gas: return "GAS"
        case .hul: return "HUL"
        case .bea: return "BEA"
        case .law: return "LAW"
        case .alo: return "ALO"
        case .col: return "COL"
        case .bor: return "BOR"
        }
    }
    
    var body: some View {
        if let driverWithPosition = entry.driverStanding {
            let driver = driverWithPosition.driver
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
                
                // Content with overlay
                ZStack {
                    // Background: Large team logo in bottom right
                    if let logoName = F1RaceStyle.getTeamLogo(for: driver.team_name) {
                        HStack {
                            Spacer()
                            VStack {
                                Spacer()
                                Image(logoName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .opacity(0.7) // More visible overlay
                            }
                        }
                    }
                    
                    // Foreground: Driver info
                    VStack(alignment: .leading, spacing: 6) {
                        // Driver name on its own line (top)
                        Text(driver.driver_name)
                            .font(.custom("Formula1-Display-Bold", size: 12))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Bottom row: Points and Position (moved lower)
                        HStack(spacing: 12) {
                            // Points column
                            VStack(alignment: .leading, spacing: 0) {
                                Text("\(driver.points)")
                                    .font(.custom("Formula1-Display-Bold", size: 14))
                                    .foregroundColor(.white)
                                
                                Text("PTS")
                                    .font(.custom("Formula1-Display-Regular", size: 8))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            // Position column
                            VStack(alignment: .leading, spacing: 0) {
                                Text("P\(driverWithPosition.position)")
                                    .font(.custom("Formula1-Display-Bold", size: 14))
                                    .foregroundColor(.white)
                                
                                Text("POS")
                                    .font(.custom("Formula1-Display-Regular", size: 8))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            HStack(spacing: 0) {
                // Left border
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Loading...")
                        .font(.custom("Formula1-Display-Regular", size: 11))
                        .foregroundColor(.white)
                    
                    Text(driverString(entry.configuration.selectedDriver))
                        .font(.custom("Formula1-Display-Regular", size: 13))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

#Preview(as: .accessoryRectangular) {
    F1DriverStandingLockScreenWidget()
} timeline: {
    F1DriverEntry(
        date: Date(),
        driverStanding: DriverWithPosition(
            driver: F1DriverStanding(
                id: 1,
                driver_name: "Max Verstappen",
                team_name: "Red Bull",
                points: 136,
                driver_number: 1,
                display_name: "VER"
            ),
            position: 1
        ),
        configuration: ConfigureDriver(),
        isPremiumContent: false,
        isPreview: true
    )
}

#Preview(as: .systemMedium) {
    F1DriverStandingWidget()
} timeline: {
    F1DriverEntry(
        date: Date(),
        driverStanding: DriverWithPosition(
            driver: F1DriverStanding(
                id: 1,
                driver_name: "Max Verstappen",
                team_name: "Red Bull",
                points: 136,
                driver_number: 1,
                display_name: "VER"
            ),
            position: 1
        ),
        configuration: ConfigureDriver(),
        isPremiumContent: false,
        isPreview: true
    )
}

#Preview(as: .systemSmall) {
    F1DriverStandingWidget()
} timeline: {
    F1DriverEntry(
        date: Date(),
        driverStanding: DriverWithPosition(
            driver: F1DriverStanding(
                id: 1,
                driver_name: "Max Verstappen",
                team_name: "Red Bull",
                points: 136,
                driver_number: 1,
                display_name: "VER"
            ),
            position: 1
        ),
        configuration: ConfigureDriver(),
        isPremiumContent: false,
        isPreview: true
    )
}

// MARK: - Constructor Widget Implementation

struct F1ConstructorStanding: Codable {
    let id: Int
    let constructor_name: String
    let points: Int
    let driver_id_1: Int
    let driver_id_2: Int
    let driver_id_3: Int?
    let driver_1_display_name: String
    let driver_1_name: String
    let driver_1_team: String
    let driver_2_display_name: String
    let driver_2_name: String
    let driver_2_team: String
    let driver_3_display_name: String?
    let driver_3_name: String?
    let driver_3_team: String?
}

struct ConstructorWithPosition {
    let constructor: F1ConstructorStanding
    let position: Int
}

struct F1ConstructorEntry: TimelineEntry {
    let date: Date
    let constructorStanding: ConstructorWithPosition?
    let configuration: ConfigureConstructor
    let isPremiumContent: Bool
    let isPreview: Bool
    
    init(date: Date, constructorStanding: ConstructorWithPosition?, configuration: ConfigureConstructor, isPremiumContent: Bool = false, isPreview: Bool = false) {
        self.date = date
        self.constructorStanding = constructorStanding
        self.configuration = configuration
        self.isPremiumContent = isPremiumContent
        self.isPreview = isPreview
    }
}

struct F1ConstructorStandingWidget: Widget {
    let kind: String = "F1ConstructorStandingWidget"

    var body: some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return AppIntentConfiguration(kind: kind, intent: ConfigureConstructor.self, provider: ConstructorWidgetProvider(isPremiumWidget: true)) { entry in
                F1ConstructorStandingWidgetView(entry: entry)
                    .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
            }
            .configurationDisplayName("Constructor Standing")
            .description("Shows constructor championship standings.")
            .supportedFamilies([.systemSmall]) // TEMPORARILY HIDDEN: .systemMedium
            .contentMarginsDisabled()
        } else {
            return AppIntentConfiguration(kind: kind, intent: ConfigureConstructor.self, provider: ConstructorWidgetProvider(isPremiumWidget: true)) { entry in
                F1ConstructorStandingWidgetView(entry: entry)
                    .padding()
                    .background()
            }
            .configurationDisplayName("Constructor Standing")
            .description("Shows constructor championship standings.")
            .supportedFamilies([.systemSmall]) // TEMPORARILY HIDDEN: .systemMedium
            .contentMarginsDisabled()
        }
    }
}

struct F1ConstructorStandingLockScreenWidget: Widget {
    let kind: String = "F1ConstructorStandingLockScreenWidget"

    var body: some WidgetConfiguration {
        if #available(iOS 17.0, *) {
            return AppIntentConfiguration(kind: kind, intent: ConfigureConstructor.self, provider: ConstructorWidgetProvider(isPremiumWidget: true)) { entry in
                F1ConstructorStandingWidgetView(entry: entry)
                    .containerBackground(Color(F1RaceStyle.widgetBackgroundColor), for: .widget)
            }
            .configurationDisplayName("Constructor Standing")
            .description("Shows constructor championship standings.")
            .supportedFamilies([.accessoryRectangular])
        } else {
            return AppIntentConfiguration(kind: kind, intent: ConfigureConstructor.self, provider: ConstructorWidgetProvider(isPremiumWidget: true)) { entry in
                F1ConstructorStandingWidgetView(entry: entry)
                    .padding()
                    .background()
            }
            .configurationDisplayName("Constructor Standing")
            .description("Shows constructor championship standings.")
            .supportedFamilies([.accessoryRectangular])
        }
    }
}

// Provider implementation
class ConstructorWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = F1ConstructorEntry
    typealias Intent = ConfigureConstructor
    
    private let isPremiumWidget: Bool
    
    init(isPremiumWidget: Bool = false) {
        self.isPremiumWidget = isPremiumWidget
    }

    func placeholder(in context: Context) -> F1ConstructorEntry {
        F1ConstructorEntry(date: Date(), constructorStanding: nil, configuration: ConfigureConstructor(), isPremiumContent: false)
    }
    
    func snapshot(for configuration: ConfigureConstructor, in context: Context) async -> F1ConstructorEntry {
        // For previews in widget gallery, always show real content to entice users
        if context.isPreview {
            return await reloadWidget(for: configuration, isPremium: false, isPreview: true)
        }
        
        if isPremiumWidget  && !SubscriptionHelper.isProUser {
            return F1ConstructorEntry(date: Date(), constructorStanding: nil, configuration: configuration, isPremiumContent: true)
        }
        return await reloadWidget(for: configuration)
    }
    
    func timeline(for configuration: ConfigureConstructor, in context: Context) async -> Timeline<F1ConstructorEntry> {
        // For previews in widget gallery, always show real content to entice users
        if context.isPreview {
            let entry = await reloadWidget(for: configuration, isPremium: false, isPreview: true)
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
        }
        
        if isPremiumWidget  && !SubscriptionHelper.isProUser {
            let entry = F1ConstructorEntry(date: Date(), constructorStanding: nil, configuration: configuration, isPremiumContent: true)
            return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15))) // Check every 15 minutes
        }
        
        print("Getting timeline for constructor: \(configuration.selectedConstructor)")
        
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/constructor-standings")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let constructors = try JSONDecoder().decode([F1ConstructorStanding].self, from: data)
            
            // Find constructor and get position from array index
            var selectedConstructorWithPosition: ConstructorWithPosition?
            for (index, constructor) in constructors.enumerated() {
                let matches = switch configuration.selectedConstructor {
                case .mclaren: constructor.constructor_name.lowercased() == "mclaren"
                case .ferrari: constructor.constructor_name.lowercased() == "ferrari"
                case .mercedes: constructor.constructor_name.lowercased() == "mercedes"
                case .redbull: constructor.constructor_name.lowercased() == "red bull"
                case .williams: constructor.constructor_name.lowercased() == "williams"
                case .rb: constructor.constructor_name.lowercased() == "rb"
                case .haas: constructor.constructor_name.lowercased() == "haas"
                case .astonmartin: constructor.constructor_name.lowercased() == "aston martin"
                case .kicksauber: constructor.constructor_name.lowercased() == "kick sauber"
                case .alpine: constructor.constructor_name.lowercased() == "alpine"
                }
                
                if matches {
                    selectedConstructorWithPosition = ConstructorWithPosition(constructor: constructor, position: index + 1)
                    break
                }
            }
            
            let entry = F1ConstructorEntry(date: Date(), constructorStanding: selectedConstructorWithPosition, configuration: configuration, isPremiumContent: false)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            
            return Timeline(entries: [entry], policy: .after(nextUpdate))
        } catch {
            print("Error loading constructor data: \(error)")
            let loadingEntry = F1ConstructorEntry(date: Date(), constructorStanding: nil, configuration: configuration, isPremiumContent: false)
            return Timeline(entries: [loadingEntry], policy: .after(Date().addingTimeInterval(60)))
        }
    }
    
    private func reloadWidget(for configuration: ConfigureConstructor, isPremium: Bool = false, isPreview: Bool = false) async -> F1ConstructorEntry {
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/constructor-standings")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let constructors = try JSONDecoder().decode([F1ConstructorStanding].self, from: data)
            
            // Find constructor and get position from array index
            var selectedConstructorWithPosition: ConstructorWithPosition?
            for (index, constructor) in constructors.enumerated() {
                let matches = switch configuration.selectedConstructor {
                case .mclaren: constructor.constructor_name.lowercased() == "mclaren"
                case .ferrari: constructor.constructor_name.lowercased() == "ferrari"
                case .mercedes: constructor.constructor_name.lowercased() == "mercedes"
                case .redbull: constructor.constructor_name.lowercased() == "red bull"
                case .williams: constructor.constructor_name.lowercased() == "williams"
                case .rb: constructor.constructor_name.lowercased() == "rb"
                case .haas: constructor.constructor_name.lowercased() == "haas"
                case .astonmartin: constructor.constructor_name.lowercased() == "aston martin"
                case .kicksauber: constructor.constructor_name.lowercased() == "kick sauber"
                case .alpine: constructor.constructor_name.lowercased() == "alpine"
                }
                
                if matches {
                    selectedConstructorWithPosition = ConstructorWithPosition(constructor: constructor, position: index + 1)
                    break
                }
            }
            
            return F1ConstructorEntry(date: Date(), constructorStanding: selectedConstructorWithPosition, configuration: configuration, isPremiumContent: isPremium, isPreview: isPreview)
        } catch {
            print("Error loading data: \(error)")
            return F1ConstructorEntry(date: Date(), constructorStanding: nil, configuration: configuration, isPremiumContent: isPremium, isPreview: isPreview)
        }
    }
}

struct F1ConstructorStandingWidgetView: View {
    var entry: F1ConstructorEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if entry.isPremiumContent  && !entry.isPreview {
            if family == .accessoryRectangular {
                PremiumLockScreenWidgetView()
            } else {
                PremiumWidgetView(widgetFamily: family)
            }
        } else {
            if let constructorWithPosition = entry.constructorStanding {
                let constructor = constructorWithPosition.constructor
                ZStack {
                    constructorWidget(constructor: constructor, position: constructorWithPosition.position)
                }
            } else {
                loadingView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 8) {
            Text("Loading...")
                .font(.custom("Formula1-Display-Regular", size: 14))
                .foregroundColor(.white)
            
            Text(constructorString(entry.configuration.selectedConstructor))
                .font(.custom("Formula1-Display-Regular", size: 16))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    private func constructorString(_ constructor: ConstructorAppEnum) -> String {
        switch constructor {
        case .mclaren: return "McLaren"
        case .ferrari: return "Ferrari"
        case .mercedes: return "Mercedes"
        case .redbull: return "Red Bull"
        case .williams: return "Williams"
        case .rb: return "RB"
        case .haas: return "Haas"
        case .astonmartin: return "Aston Martin"
        case .kicksauber: return "Kick Sauber"
        case .alpine: return "Alpine"
        }
    }
    
    @ViewBuilder
    private func constructorWidget(constructor: F1ConstructorStanding, position: Int) -> some View {
        switch family {
        case .systemSmall:
            smallConstructorWidget(constructor: constructor, position: position)
        case .systemMedium:
            mediumConstructorWidget(constructor: constructor, position: position)
        case .accessoryRectangular:
            lockScreenWidget(constructor: constructor, position: position)
        default:
            EmptyView()
        }
    }
    
    private func smallConstructorWidget(constructor: F1ConstructorStanding, position: Int) -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    F1RaceStyle.getTeamColor(for: constructor.constructor_name).opacity(0.35),
                    Color.black
                ]),
                startPoint: .leading,
                endPoint: .init(x: 0.4, y: 0)
            )
            
            // Main content
            VStack(alignment: .leading, spacing: 8) {
                // Constructor name at the top with adaptive font size
                Text(constructor.constructor_name)
                    .font(.custom("Formula1-Display-Bold", size: constructor.constructor_name.count > 8 ? 16 : 18.5))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Drivers with dot separator
                Text("\(constructor.driver_1_display_name ?? "") · \(constructor.driver_2_display_name ?? "")")
                    .font(.custom("Formula1-Display-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                
                Spacer()
                
                // Bottom section with position and points (horizontal layout)
                HStack(spacing: 13) {
                    // Position column
                    VStack(alignment: .leading, spacing: 2) {
                        Text("P\(position)")
                            .font(.custom("Formula1-Display-Bold", size: 25))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Text("POS")
                            .font(.custom("Formula1-Display-Bold", size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Points column
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(constructor.points)")
                            .font(.custom("Formula1-Display-Bold", size: 25))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Text("PTS")
                            .font(.custom("Formula1-Display-Bold", size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func mediumConstructorWidget(constructor: F1ConstructorStanding, position: Int) -> some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    F1RaceStyle.getTeamColor(for: constructor.constructor_name).opacity(0.35),
                    Color.black
                ]),
                startPoint: .leading,
                endPoint: .init(x: 0.4, y: 0)
            )
            
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Constructor info
                Text(constructor.constructor_name)
                    .font(.custom("Formula1-Display-Bold", size: 28))
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Drivers with dot separator
                Text("\(constructor.driver_1_display_name ?? "") · \(constructor.driver_2_display_name ?? "")")
                    .font(.custom("Formula1-Display-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                    .frame(height: 2)
                
                // Position and points
                HStack {
                    VStack(alignment: .leading, spacing: -1) {
                        Text("P\(position)")
                            .font(.custom("Formula1-Display-Regular", size: 28))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Text("POS")
                            .font(.custom("Formula1-Display-Bold", size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: -1) {
                        Text("\(constructor.points)")
                            .font(.custom("Formula1-Display-Regular", size: 28))
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Text("PTS")
                            .font(.custom("Formula1-Display-Bold", size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func lockScreenWidget(constructor: F1ConstructorStanding, position: Int) -> some View {
        HStack(spacing: 0) {
            // Left border
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 2)
            
            // Content with overlay
            ZStack {
                // Background: Large team logo in bottom right
                if let logoName = F1RaceStyle.getTeamLogo(for: constructor.constructor_name) {
                    HStack {
                        Spacer()
                        VStack {
                            Spacer()
                            Image(logoName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .opacity(0.7)
                        }
                    }
                }
                
                // Foreground: Constructor info
                VStack(alignment: .leading, spacing: 6) {
                    // Constructor name on its own line (top)
                    Text(constructor.constructor_name)
                        .font(.custom("Formula1-Display-Bold", size: 12))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Bottom row: Points and Position
                    HStack(spacing: 12) {
                        // Points column
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(constructor.points)")
                                .font(.custom("Formula1-Display-Bold", size: 14))
                                .foregroundColor(.white)
                            
                            Text("PTS")
                                .font(.custom("Formula1-Display-Regular", size: 8))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Position column
                        VStack(alignment: .leading, spacing: 0) {
                            Text("P\(position)")
                                .font(.custom("Formula1-Display-Bold", size: 14))
                                .foregroundColor(.white)
                            
                            Text("POS")
                                .font(.custom("Formula1-Display-Regular", size: 8))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Add before F1TopDriversLockScreenWidget

struct TopDriversEntry: TimelineEntry {
    let date: Date
    let drivers: [DriverWithPosition]?
}

class F1TopDriversProvider: TimelineProvider {
    func placeholder(in context: Context) -> TopDriversEntry {
        TopDriversEntry(date: Date(), drivers: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TopDriversEntry) -> ()) {
        Task {
            await loadData { entry in
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            await loadData { entry in
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
    
    private func loadData(completion: @escaping (TopDriversEntry) -> Void) async {
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/driver-standings")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let drivers = try JSONDecoder().decode([F1DriverStanding].self, from: data)
            
            // Get top 3 drivers with positions
            let top3Drivers = drivers.prefix(3).enumerated().map { index, driver in
                DriverWithPosition(driver: driver, position: index + 1)
            }
            
            let entry = TopDriversEntry(date: Date(), drivers: top3Drivers)
            completion(entry)
        } catch {
            print("Error loading data: \(error)")
            completion(TopDriversEntry(date: Date(), drivers: nil))
        }
    }
}

struct F1TopDriversLockScreenWidget: Widget {
    let kind: String = "F1TopDriversLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: F1TopDriversProvider()) { entry in
            F1TopDriversLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("F1 Top 3 Drivers")
        .description("Shows the top 3 drivers in the championship.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// [WIDGET] Top 3 Drivers Lock Screen Widget View
struct F1TopDriversLockScreenWidgetView: View {
    var entry: TopDriversEntry
    
    var body: some View {
        Group {
            if let drivers = entry.drivers {
                HStack(spacing: 0) {
                    ForEach(0..<3) { i in
                        if i > 0 {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1.5)
                        }
                        
                        let driver = drivers[i].driver
                        
                        VStack(spacing: 3) {
                            if let logoName = F1RaceStyle.getTeamLogo(for: driver.team_name) {
                                Image(logoName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(minWidth: 30, minHeight: 18)
                            }
                            Text(driver.display_name)
                                .font(.custom("Formula1-Display-Bold", size: 13))
                                .foregroundColor(.white)
                            Text("\(driver.points)")
                                .font(.custom("Formula1-Display-Regular", size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            } else {
                Text("Loading...")
                    .font(.custom("Formula1-Display-Regular", size: 12))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

#Preview(as: .accessoryRectangular) {
    F1TopDriversLockScreenWidget()
} timeline: {
    TopDriversEntry(
        date: Date(),
        drivers: [
            DriverWithPosition(
                driver: F1DriverStanding(
                    id: 1,
                    driver_name: "Charles Leclerc",
                    team_name: "Ferrari",
                    points: 136,
                    driver_number: 16,
                    display_name: "LEC"
                ),
                position: 1
            ),
            DriverWithPosition(
                driver: F1DriverStanding(
                    id: 2,
                    driver_name: "Oscar Piastri",
                    team_name: "McLaren",
                    points: 102,
                    driver_number: 81,
                    display_name: "PIA"
                ),
                position: 2
            ),
            DriverWithPosition(
                driver: F1DriverStanding(
                    id: 3,
                    driver_name: "Lando Norris",
                    team_name: "McLaren",
                    points: 98,
                    driver_number: 4,
                    display_name: "NOR"
                ),
                position: 3
            )
        ]
    )
}

// Add after F1TopDriversLockScreenWidget

struct TopConstructorsEntry: TimelineEntry {
    let date: Date
    let constructors: [ConstructorWithPosition]?
    let isPremiumContent: Bool
    let isPreview: Bool
    
    init(date: Date, constructors: [ConstructorWithPosition]?, isPremiumContent: Bool = false, isPreview: Bool = false) {
        self.date = date
        self.constructors = constructors
        self.isPremiumContent = isPremiumContent
        self.isPreview = isPreview
    }
}

class F1TopConstructorsProvider: TimelineProvider {
    typealias Entry = TopConstructorsEntry
    
    private let isPremiumWidget: Bool
    
    init(isPremiumWidget: Bool = false) {
        self.isPremiumWidget = isPremiumWidget
    }

    func placeholder(in context: Context) -> TopConstructorsEntry {
        TopConstructorsEntry(date: Date(), constructors: nil, isPremiumContent: false, isPreview: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (TopConstructorsEntry) -> ()) {
        // For previews in widget gallery, always show real content to entice users
        if context.isPreview {
            Task {
                await loadData(isPreview: true) { entry in
                    completion(entry)
                }
            }
            return
        }
        
        // Check if this is a premium widget and user is not pro
        if isPremiumWidget  && !SubscriptionHelper.isProUser {
            let entry = TopConstructorsEntry(date: Date(), constructors: nil, isPremiumContent: true, isPreview: false)
            completion(entry)
            return
        }
        
        Task {
            await loadData(isPreview: false) { entry in
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopConstructorsEntry>) -> ()) {
        // Check if this is a premium widget and user is not pro
        if isPremiumWidget  && !SubscriptionHelper.isProUser {
            let entry = TopConstructorsEntry(date: Date(), constructors: nil, isPremiumContent: true, isPreview: false)
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 15)))
            completion(timeline)
            return
        }
        
        Task {
            await loadData(isPreview: false) { entry in
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
                let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
                completion(timeline)
            }
        }
    }
    
    private func loadData(isPreview: Bool = false, completion: @escaping (TopConstructorsEntry) -> Void) async {
        do {
            let url = URL(string: "https://f1apibackend-1.onrender.com/api/constructor-standings")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let constructors = try JSONDecoder().decode([F1ConstructorStanding].self, from: data)
            
            // Get top 3 constructors with positions
            let top3Constructors = constructors.prefix(3).enumerated().map { index, constructor in
                ConstructorWithPosition(constructor: constructor, position: index + 1)
            }
            
            let entry = TopConstructorsEntry(date: Date(), constructors: top3Constructors, isPremiumContent: false, isPreview: isPreview)
            completion(entry)
        } catch {
            print("Error loading data: \(error)")
            completion(TopConstructorsEntry(date: Date(), constructors: nil, isPremiumContent: false, isPreview: isPreview))
        }
    }
}

struct F1TopConstructorsLockScreenWidget: Widget {
    let kind: String = "F1TopConstructorsLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: F1TopConstructorsProvider(isPremiumWidget: true)) { entry in
            if #available(iOS 17.0, *) {
                if entry.isPremiumContent && !entry.isPreview {
                    PremiumLockScreenWidgetView()
                        .containerBackground(.clear, for: .widget)
                } else {
                    F1TopConstructorsLockScreenWidgetView(entry: entry)
                        .containerBackground(.clear, for: .widget)
                }
            } else {
                if entry.isPremiumContent && !entry.isPreview {
                    PremiumLockScreenWidgetView()
                } else {
                    F1TopConstructorsLockScreenWidgetView(entry: entry)
                }
            }
        }
        .configurationDisplayName("F1 Top 3 Constructors")
        .description("Shows the top 3 constructors in the championship.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// [WIDGET] Top 3 Constructors Lock Screen Widget View
struct F1TopConstructorsLockScreenWidgetView: View {
    var entry: TopConstructorsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            if let constructors = entry.constructors {
                HStack(spacing: 0) {
                    ForEach(0..<3) { i in
                        if i > 0 {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1.5)
                        }
                        
                        let constructor = constructors[i].constructor
                        
                        VStack(spacing: 4) {
                            if let logoName = F1RaceStyle.getTeamLogo(for: constructor.constructor_name) {
                                Image(logoName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(minWidth: 35, minHeight: 25)
                                    .frame(maxHeight: 25)
                            }
                            Text("\(constructor.points)")
                                .font(.custom("Formula1-Display-Regular", size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            } else {
                Text("Loading...")
                    .font(.custom("Formula1-Display-Regular", size: 12))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

#Preview(as: .accessoryRectangular) {
    F1TopConstructorsLockScreenWidget()
} timeline: {
    TopConstructorsEntry(
        date: Date(),
        constructors: [
            ConstructorWithPosition(
                constructor: F1ConstructorStanding(
                    id: 1,
                    constructor_name: "McLaren",
                    points: 152,
                    driver_id_1: 1,
                    driver_id_2: 2,
                    driver_id_3: nil,
                    driver_1_display_name: "NOR",
                    driver_1_name: "Lando Norris",
                    driver_1_team: "McLaren",
                    driver_2_display_name: "PIA",
                    driver_2_name: "Oscar Piastri",
                    driver_2_team: "McLaren",
                    driver_3_display_name: nil,
                    driver_3_name: nil,
                    driver_3_team: nil
                ),
                position: 1
            ),
            ConstructorWithPosition(
                constructor: F1ConstructorStanding(
                    id: 2,
                    constructor_name: "Ferrari",
                    points: 142,
                    driver_id_1: 3,
                    driver_id_2: 4,
                    driver_id_3: nil,
                    driver_1_display_name: "LEC",
                    driver_1_name: "Charles Leclerc",
                    driver_1_team: "Ferrari",
                    driver_2_display_name: "SAI",
                    driver_2_name: "Carlos Sainz",
                    driver_2_team: "Ferrari",
                    driver_3_display_name: nil,
                    driver_3_name: nil,
                    driver_3_team: nil
                ),
                position: 2
            ),
            ConstructorWithPosition(
                constructor: F1ConstructorStanding(
                    id: 3,
                    constructor_name: "Red Bull",
                    points: 138,
                    driver_id_1: 5,
                    driver_id_2: 6,
                    driver_id_3: nil,
                    driver_1_display_name: "VER",
                    driver_1_name: "Max Verstappen",
                    driver_1_team: "Red Bull",
                    driver_2_display_name: "PER",
                    driver_2_name: "Sergio Perez",
                    driver_2_team: "Red Bull",
                    driver_3_display_name: nil,
                    driver_3_name: nil,
                    driver_3_team: nil
                ),
                position: 3
            )
        ],
        isPremiumContent: false,
        isPreview: false
    )
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

// [WIDGET] Premium Lock Screen Widget View
struct PremiumLockScreenWidgetView: View {
    var body: some View {
        HStack(spacing: 0) {
            // Left border
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 2)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("Upgrade to Pro")
                        .font(.custom("Formula1-Display-Bold", size: 12))
                        .foregroundColor(.white)
                }
                
                Text("Tap to Upgrade")
                    .font(.custom("Formula1-Display-Regular", size: 11))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

