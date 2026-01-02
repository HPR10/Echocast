//
//  DownloadError.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

enum DownloadError: Error, LocalizedError, Sendable {
    case missingAudioURL
    case alreadyDownloaded
    case inProgress
    case insufficientSpace
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .missingAudioURL:
            return "Episodio sem URL de audio para download."
        case .alreadyDownloaded:
            return "Episodio ja baixado."
        case .inProgress:
            return "Download ja esta em andamento."
        case .insufficientSpace:
            return "Espaco insuficiente para concluir o download."
        case .failed(let message):
            return message
        }
    }
}
