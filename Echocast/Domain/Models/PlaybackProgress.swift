//
//  PlaybackProgress.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

struct PlaybackProgress: Sendable {
    let key: String
    let position: TimeInterval
    let duration: TimeInterval?
    let updatedAt: Date

    init(
        key: String,
        position: TimeInterval,
        duration: TimeInterval? = nil,
        updatedAt: Date = .now
    ) {
        self.key = key
        self.position = position
        self.duration = duration
        self.updatedAt = updatedAt
    }
}
