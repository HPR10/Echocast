//
//  EpisodeDownloadRequest.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

struct EpisodeDownloadRequest: Sendable {
    let episode: Episode
    let podcastTitle: String
    let expectedSizeInBytes: Int64?

    init(
        episode: Episode,
        podcastTitle: String,
        expectedSizeInBytes: Int64? = nil
    ) {
        self.episode = episode
        self.podcastTitle = podcastTitle
        self.expectedSizeInBytes = expectedSizeInBytes
    }
}
