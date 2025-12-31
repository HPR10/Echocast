//
//  Episode.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation

struct Episode: Sendable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String?
    let audioURL: URL?
    let duration: TimeInterval?
    let publishedAt: Date?
    let playbackKey: String

    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        audioURL: URL? = nil,
        duration: TimeInterval? = nil,
        publishedAt: Date? = nil,
        playbackKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.audioURL = audioURL
        self.duration = duration
        self.publishedAt = publishedAt
        self.playbackKey = playbackKey ?? Self.makePlaybackKey(
            title: title,
            audioURL: audioURL,
            publishedAt: publishedAt
        )
    }

    static func makePlaybackKey(
        title: String,
        audioURL: URL?,
        publishedAt: Date?,
        podcastSeed: String? = nil
    ) -> String {
        let base: String
        if let audioURL = audioURL?.absoluteString, !audioURL.isEmpty {
            base = "audio:\(audioURL)"
        } else if let publishedAt {
            let timestamp = Int(publishedAt.timeIntervalSince1970)
            base = "title-date:\(title)|\(timestamp)"
        } else {
            base = "title:\(title)"
        }

        if let podcastSeed, !podcastSeed.isEmpty {
            return "podcast:\(podcastSeed)|\(base)"
        }

        return base
    }
}
