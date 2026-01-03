//
//  DownloadedEpisodeEntity.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation
import SwiftData

@Model
final class DownloadedEpisodeEntity {
    @Attribute(.unique) var playbackKey: String
    var title: String
    var podcastTitle: String
    var podcastImageURL: String?
    var audioURL: String
    var localFilePath: String
    var fileSize: Int64
    var downloadedAt: Date
    var expiresAt: Date?

    init(
        playbackKey: String,
        title: String,
        podcastTitle: String,
        podcastImageURL: String? = nil,
        audioURL: String,
        localFilePath: String,
        fileSize: Int64,
        downloadedAt: Date,
        expiresAt: Date? = nil
    ) {
        self.playbackKey = playbackKey
        self.title = title
        self.podcastTitle = podcastTitle
        self.podcastImageURL = podcastImageURL
        self.audioURL = audioURL
        self.localFilePath = localFilePath
        self.fileSize = fileSize
        self.downloadedAt = downloadedAt
        self.expiresAt = expiresAt
    }
}
