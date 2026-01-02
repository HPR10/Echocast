//
//  ListDownloadedEpisodesUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation

@MainActor
final class ListDownloadedEpisodesUseCase {
    private let repository: DownloadedEpisodesRepositoryProtocol
    private let timeToLive: TimeInterval

    init(
        repository: DownloadedEpisodesRepositoryProtocol,
        timeToLive: TimeInterval = 30 * 24 * 60 * 60
    ) {
        self.repository = repository
        self.timeToLive = timeToLive
    }

    func execute() async -> [DownloadedEpisode] {
        let now = Date()
        await repository.deleteExpired(before: now)
        return await repository
            .fetchAll()
            .filter { !$0.isExpired(referenceDate: now, ttl: timeToLive) }
    }
}
