//
//  PlayerState.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 23/12/25.
//

import Foundation

struct PlayerState: Sendable {
    var isPlaying: Bool
    var isBuffering: Bool
    var bufferingReason: PlayerBufferingReason?
    var currentTime: TimeInterval
    var duration: TimeInterval
    var playbackRate: Float

    static let idle = PlayerState(
        isPlaying: false,
        isBuffering: false,
        bufferingReason: nil,
        currentTime: 0,
        duration: 0,
        playbackRate: 1.0
    )
}

enum PlayerBufferingReason: Sendable {
    case insufficientBuffer
    case minimizeStalls
    case evaluatingBufferingRate
    case noItem
    case noNetwork
    case stalled
    case unknown
}

enum PlayerEvent: Sendable {
    case didFinish
    case didFail(PlayerError)
}
