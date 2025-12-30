//
//  FeedError.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation

enum FeedError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case parsingError(String)
    case emptyFeed
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalida"
        case .networkError(let error):
            return "Erro de rede: \(error.localizedDescription)"
        case .parsingError(let message):
            return "Erro ao processar feed: \(message)"
        case .emptyFeed:
            return "Feed vazio ou invalido"
        case .timeout:
            return "Tempo de resposta esgotado"
        }
    }
}
