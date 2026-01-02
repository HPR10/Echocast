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

    init(
        repository: DownloadedEpisodesRepositoryProtocol
    ) {
        self.repository = repository
    }

    func execute() async -> [DownloadedEpisode] {
        return await repository.fetchAll()
    }
}
