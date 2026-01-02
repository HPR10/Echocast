//
//  PlaybackSource.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

enum PlaybackSource: Sendable, Equatable {
    case remote(URL)
    case local(URL)

    var url: URL {
        switch self {
        case .remote(let url):
            return url
        case .local(let url):
            return url
        }
    }
}
