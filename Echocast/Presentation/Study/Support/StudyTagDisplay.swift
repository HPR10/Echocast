//
//  StudyTagDisplay.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

extension StudyTheme {
    var displayName: String {
        switch self {
        case .swiftIos:
            return "Swift/iOS"
        case .backend:
            return "Backend"
        case .architecture:
            return "Arquitetura"
        case .career:
            return "Carreira"
        case .computerScience:
            return "Ciência da Computação"
        case .technicalEnglish:
            return "Inglês técnico"
        }
    }
}

extension StudyLevel {
    var displayName: String {
        switch self {
        case .beginner:
            return "Iniciante"
        case .intermediate:
            return "Intermediário"
        case .advanced:
            return "Avançado"
        }
    }
}

extension StudyType {
    var displayName: String {
        switch self {
        case .theoretical:
            return "Teórico"
        case .practical:
            return "Prático"
        case .career:
            return "Carreira"
        case .conceptual:
            return "Conceitual"
        }
    }
}
