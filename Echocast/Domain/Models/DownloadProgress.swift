//
//  DownloadProgress.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

struct DownloadProgress: Sendable, Hashable, Identifiable {
    let id: UUID
    let playbackKey: String
    let state: DownloadState
    let bytesDownloaded: Int64
    let bytesExpected: Int64?

    init(
        id: UUID = UUID(),
        playbackKey: String,
        state: DownloadState,
        bytesDownloaded: Int64,
        bytesExpected: Int64?
    ) {
        self.id = id
        self.playbackKey = playbackKey
        self.state = state
        self.bytesDownloaded = bytesDownloaded
        self.bytesExpected = bytesExpected
    }

    var fractionCompleted: Double? {
        guard let bytesExpected, bytesExpected > 0 else { return nil }
        let value = Double(bytesDownloaded) / Double(bytesExpected)
        return max(0, min(value, 1))
    }
}

enum DownloadState: Sendable, Hashable {
    case queued
    case running
    case finished
    case failed(String)
    case cancelled
}
