//
//  DownloadedEpisode.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

struct DownloadedEpisode: Sendable, Identifiable, Hashable {
    let id: UUID
    let playbackKey: String
    let title: String
    let podcastTitle: String
    let podcastImageURL: URL?
    let audioURL: URL
    let localFileURL: URL
    let fileSize: Int64
    let downloadedAt: Date
    let expiresAt: Date?

    init(
        id: UUID = UUID(),
        playbackKey: String,
        title: String,
        podcastTitle: String,
        podcastImageURL: URL? = nil,
        audioURL: URL,
        localFileURL: URL,
        fileSize: Int64,
        downloadedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.playbackKey = playbackKey
        self.title = title
        self.podcastTitle = podcastTitle
        self.podcastImageURL = podcastImageURL
        self.audioURL = audioURL
        self.localFileURL = localFileURL
        self.fileSize = fileSize
        self.downloadedAt = downloadedAt
        self.expiresAt = expiresAt
    }

    func isExpired(referenceDate: Date, ttl: TimeInterval) -> Bool {
        let expirationDate = expiresAt ?? downloadedAt.addingTimeInterval(ttl)
        return referenceDate >= expirationDate
    }
}
