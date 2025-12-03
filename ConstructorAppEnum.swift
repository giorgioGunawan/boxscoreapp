//
//  ConstructorAppEnum.swift
//  gridnextapp
//
//  Created by Giorgio Gunawan on 2/6/2025.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum ConstructorAppEnum: String, AppEnum {
    case mclaren
    case ferrari
    case mercedes
    case redbull
    case williams
    case rb
    case haas
    case astonmartin
    case kicksauber
    case alpine

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Constructor")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .mclaren: "McLaren",
        .ferrari: "Ferrari",
        .mercedes: "Mercedes",
        .redbull: "Red Bull",
        .williams: "Williams",
        .rb: "RB",
        .haas: "Haas",
        .astonmartin: "Aston Martin",
        .kicksauber: "Kick Sauber",
        .alpine: "Alpine"
    ]
}

