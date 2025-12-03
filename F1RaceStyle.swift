import SwiftUI

enum F1RaceStyle {
    static let backgroundColor = Color.black
    static let widgetBackgroundColor = Color.black
    static let accentColor = Color(red: 1.0, green: 0.2, blue: 0.2)
    static let textColor = Color.white
    static let secondaryTextColor = Color(white: 0.8)
    static let tertiaryTextColor = Color(white: 0.6)
    
    struct CardStyle: ViewModifier {
        let isWidget: Bool
        
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, isWidget ? 4 : 12)
                .padding(.vertical, isWidget ? 12 : 16)
                .background(widgetBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    
    struct CardWithTrackBackgroundStyle: ViewModifier {
        let isWidget: Bool
        
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, isWidget ? 4 : 12)
                .padding(.vertical, isWidget ? 12 : 16)
                .background {
                    ZStack {
                        // Base background color
                        widgetBackgroundColor
                        
                        // Track outline background
                        Image("10_f1_2024_can_outline")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(0.2) // Very subtle opacity
                            .clipped()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    
    struct CardWithRaceSpecificBackgroundStyle: ViewModifier {
        let isWidget: Bool
        let race: F1Race
        @Environment(\.widgetFamily) var family
        
        func body(content: Content) -> some View {
            content
                .padding(.horizontal, isWidget ? 4 : 12)
                .padding(.vertical, isWidget ? 12 : 16)
                .background {
                    ZStack {
                        // Base background color
                        widgetBackgroundColor
                        
                        // Track outline background (only if track image exists)
                        if let trackImageName = F1RaceStyle.getTrackImageName(for: race) {
                            Image(trackImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(0.2) // Very subtle opacity
                                .scaleEffect(family == .systemMedium ? 1.4 : 1)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    
    struct LockScreenWithRaceSpecificBackgroundStyle: ViewModifier {
        let race: F1Race
        
        func body(content: Content) -> some View {
            content
                .background {
                    ZStack {
                        // Base background color (clear for lock screen)
                        Color.clear
                        
                        // Track outline background (only if track image exists)
                        if let trackImageName = F1RaceStyle.getTrackImageName(for: race) {
                            Image(trackImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(0.15) // Even more subtle for lock screen
                                .scaleEffect(1.6) // Bigger for lock screen
                        }
                    }
                }
        }
    }
    
    struct TitleStyle: ViewModifier {
        let isWidget: Bool
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Bold", size: isWidget ? 24 : 32))
                .foregroundColor(textColor)
                .lineLimit(1)
        }
    }
    
    struct DateStyle: ViewModifier {
        let isWidget: Bool
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Regular", size: isWidget ? 13 : 15))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
    }
    
    struct SubtitleStyle: ViewModifier {
        let isWidget: Bool
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Regular", size: isWidget ? 13 : 16))
                .foregroundColor(tertiaryTextColor)
                .lineLimit(1)
        }
    }
    
    struct SessionStyle: ViewModifier {
        let isWidget: Bool
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Regular", size: isWidget ? 14 : 18))
                .foregroundColor(accentColor)
                .lineLimit(1)
        }
    }
    
    struct TimeStyle: ViewModifier {
        let isWidget: Bool
        
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Bold", size: isWidget ? 22 : 26))
                .foregroundColor(textColor)
                .lineLimit(1)
        }
    }
    
    struct EventTitleStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Regular", size: 11))
                .foregroundColor(tertiaryTextColor)
                .lineLimit(1)
        }
    }
    
    struct SessionTimeStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Regular", size: 13))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
    }
    
    struct SessionNameStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.custom("Formula1-Display-Regular", size: 13))
                .foregroundColor(textColor)
                .lineLimit(1)
        }
    }
    
    // Helper function to get track image name based on race
    static func getTrackImageName(for race: F1Race) -> String? {
        // Map race shortnames to track image names
        let trackMapping: [String: String] = [
            // 2024 F1 Calendar
            "Bahrain": "f1-track-bhr",
            "Saudi Arabia": "f1-track-sau", 
            "Australia": "f1-track-aus",
            "Japan": "f1-track-jpn",
            "China": "f1-track-chn",
            "Miami": "f1-track-mia",
            "Emilia Romagna": "f1-track-ita", // Imola
            "Monaco": "f1-track-mon",
            "Canada": "f1-track-can",
            "Spain": "f1-track-esp",
            "Austria": "f1-track-aut",
            "Great Britain": "f1-track-gbr",
            "Hungary": "f1-track-hun",
            "Belgium": "f1-track-bel",
            "Netherlands": "f1-track-ned",
            "Italy": "f1-track-ita-monza", // Monza
            "Azerbaijan": "f1-track-aze",
            "Singapore": "f1-track-sgp",
            "United States": "f1-track-usa", // Austin
            "Mexico": "f1-track-mex",
            "Brazil": "f1-track-bra",
            "Las Vegas": "f1-track-lv",
            "Qatar": "f1-track-qat",
            "Abu Dhabi": "f1-track-are"
        ]
        
        return trackMapping[race.shortname]
    }
    
    // Helper function to get flag name based on race
    static func getFlagName(for race: F1Race) -> String? {
        // Map race shortnames to country flag names
        let flagMapping: [String: String] = [
            // 2024 F1 Calendar
            "Bahrain": "flag-bh",
            "Saudi Arabia": "flag-sa", 
            "Australia": "flag-au",
            "Japan": "flag-jp",
            "China": "flag-cn",
            "Miami": "flag-us",
            "Emilia Romagna": "flag-it", // Imola
            "Monaco": "flag-mc",
            "Canada": "flag-ca",
            "Spain": "flag-es",
            "Austria": "flag-at",
            "Great Britain": "flag-gb",
            "Hungary": "flag-hu",
            "Belgium": "flag-be",
            "Netherlands": "flag-nl",
            "Italy": "flag-it", // Monza
            "Azerbaijan": "flag-az",
            "Singapore": "flag-sg",
            "United States": "flag-us", // Austin
            "Mexico": "flag-mx",
            "Brazil": "flag-br",
            "Las Vegas": "flag-us",
            "Qatar": "flag-qa",
            "Abu Dhabi": "flag-ae"
        ]
        
        return flagMapping[race.shortname]
    }
} 