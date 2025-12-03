//
//  F1RaceResultLiveActivity.swift
//  F1RaceResult
//
//  Created by Giorgio Gunawan on 31/5/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct F1RaceResultAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct F1RaceResultLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: F1RaceResultAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension F1RaceResultAttributes {
    fileprivate static var preview: F1RaceResultAttributes {
        F1RaceResultAttributes(name: "World")
    }
}

extension F1RaceResultAttributes.ContentState {
    fileprivate static var smiley: F1RaceResultAttributes.ContentState {
        F1RaceResultAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: F1RaceResultAttributes.ContentState {
         F1RaceResultAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: F1RaceResultAttributes.preview) {
   F1RaceResultLiveActivity()
} contentStates: {
    F1RaceResultAttributes.ContentState.smiley
    F1RaceResultAttributes.ContentState.starEyes
}
