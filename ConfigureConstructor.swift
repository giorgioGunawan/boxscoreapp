//
//  ConfigureConstructor.swift
//  gridnextapp
//
//  Created by Giorgio Gunawan on 2/6/2025.
//

import Foundation
import AppIntents

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct ConfigureConstructor: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ConfigureConstructorIntent"

    static var title: LocalizedStringResource = "Configure Constructor Standing"
    static var description = IntentDescription("Shows F1 constructor standings")

    @Parameter(title: "Constructor", default: .mclaren)
    var selectedConstructor: ConstructorAppEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Show standings for \(\.$selectedConstructor)")
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$selectedConstructor)) { selectedConstructor in
            DisplayRepresentation(
                title: "Show \(selectedConstructor.rawValue) standings",
                subtitle: "F1 Constructor Standing"
            )
        }
    }

    func perform() async throws -> some IntentResult {
        print("Performing intent with constructor: \(selectedConstructor)")
        return .result()
    }
} 