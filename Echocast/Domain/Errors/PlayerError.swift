//
//  PlayerError.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 23/12/25.
//

import Foundation

enum PlayerError: Error, LocalizedError, Sendable {
    case audioUnavailable
    case audioSessionFailure
    case playbackFailed(String)

    var errorDescription: String? {
        switch self {
        case .audioUnavailable:
            return "Audio indisponivel para este episodio."
        case .audioSessionFailure:
            return "Falha ao ativar audio."
        case .playbackFailed:
            return "Falha ao reproduzir audio."
        }
    }
}
