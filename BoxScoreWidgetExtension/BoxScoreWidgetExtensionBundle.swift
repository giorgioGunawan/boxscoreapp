//
//  BoxScoreWidgetExtensionBundle.swift
//  BoxScoreWidgetExtension
//
//  Created by Giorgio Gunawan on 8/12/2025.
//

import WidgetKit
import SwiftUI

@main
struct BoxScoreWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // All 6 NBA widgets
        NextGamesWidget()
        SeasonAverageWidget()
        LastGamesWidget()
        TeamStandingWidget()
        PlayerLastGameWidget()
        CountdownWidget()
    }
}
