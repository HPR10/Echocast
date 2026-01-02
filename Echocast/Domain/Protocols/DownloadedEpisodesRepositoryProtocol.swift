//
//  DownloadedEpisodesRepositoryProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

protocol DownloadedEpisodesRepositoryProtocol: Sendable {
    func fetch(playbackKey: String) async -> DownloadedEpisode?
    func fetchAll() async -> [DownloadedEpisode]
    func save(_ episode: DownloadedEpisode) async
    func delete(playbackKey: String) async
    func deleteExpired(before date: Date) async
    func totalSizeInBytes() async -> Int64
}
