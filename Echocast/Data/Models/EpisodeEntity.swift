//
//  EpisodeEntity.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation
import SwiftData

@Model
final class EpisodeEntity {
    var id: UUID
    var title: String
    var summary: String?
    var audioURL: String?
    var duration: TimeInterval?
    var publishedAt: Date?
    var dedupKey: String
    var podcastID: UUID

    var podcast: PodcastEntity?

    init(
        id: UUID = UUID(),
        title: String,
        summary: String? = nil,
        audioURL: String? = nil,
        duration: TimeInterval? = nil,
        publishedAt: Date? = nil,
        dedupKey: String,
        podcastID: UUID,
        podcast: PodcastEntity? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.audioURL = audioURL
        self.duration = duration
        self.publishedAt = publishedAt
        self.dedupKey = dedupKey
        self.podcastID = podcastID
        self.podcast = podcast
    }
}
