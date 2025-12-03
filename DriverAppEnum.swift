//
//  DriverAppEnum.swift
//  gridnextapp
//
//  Created by Giorgio Gunawan on 1/6/2025.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum DriverAppEnum: String, AppEnum {
    case ver
    case pia
    case nor
    case rus
    case lec
    case ham
    case ant
    case alb
    case oco
    case had
    case str
    case sai
    case tsu
    case gas
    case hul
    case bea
    case law
    case alo
    case col
    case bor

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Driver")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .ver: "Max Verstappen",
        .pia: "Oscar Piastri",
        .nor: "Lando Norris",
        .rus: "George Russell",
        .lec: "Charles Leclerc",
        .ham: "Lewis Hamilton",
        .ant: "Kimi Antonelli",
        .alb: "Alexander Albon",
        .oco: "Esteban Ocon",
        .had: "Isack Hadjar",
        .str: "Lance Stroll",
        .sai: "Carlos Sainz",
        .tsu: "Yuki Tsunoda",
        .gas: "Pierre Gasly",
        .hul: "Nico Hulkenberg",
        .bea: "Oliver Bearman",
        .law: "Liam Lawson",
        .alo: "Fernando Alonso",
        .col: "Franco Colapinto",
        .bor: "Gabriel Bortoleto"
    ]
}

