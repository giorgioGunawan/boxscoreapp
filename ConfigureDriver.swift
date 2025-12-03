//
//  ConfigureDriver.swift
//  gridnextapp
//
//  Created by Giorgio Gunawan on 1/6/2025.
//

import Foundation
import AppIntents

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct ConfigureDriver: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ConfigureDriverIntent"

    static var title: LocalizedStringResource = "Configure Driver Standing"
    static var description = IntentDescription("Shows F1 driver standings")

    @Parameter(title: "Driver", default: .ver)
    var selectedDriver: DriverAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Show standings for \(\.$selectedDriver)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$selectedDriver)) { selectedDriver in
            DisplayRepresentation(
                title: "Show \(selectedDriver.rawValue) standings",
                subtitle: "F1 Driver Standing"
            )
        }
    }

    func perform() async throws -> some IntentResult {
        print("Performing intent with driver: \(selectedDriver)")
        return .result()
    }
}


