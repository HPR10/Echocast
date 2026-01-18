//
//  CuratedCatalogRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct CuratedCatalogRepository: CuratedCatalogRepositoryProtocol {
    private let dataSource: CuratedCatalogDataSource

    init(dataSource: CuratedCatalogDataSource = CuratedCatalogDataSource()) {
        self.dataSource = dataSource
    }

    func fetchCatalog() async throws -> CuratedCatalog {
        let record = try dataSource.loadCatalog()
        let podcasts = record.podcasts.compactMap(mapPodcast)
        let stacks = record.stacks.compactMap(mapStack)
        return CuratedCatalog(podcasts: podcasts, stacks: stacks)
    }

    private func mapPodcast(_ record: CuratedPodcastRecord) -> CuratedPodcast? {
        guard let feedURL = URL(string: record.feedURL) else { return nil }
        let imageURL = record.imageURL.flatMap(URL.init(string:))
        let themes = Set(record.themes.compactMap(StudyTheme.init(rawValue:)))
        let levels = Set(record.levels.compactMap(StudyLevel.init(rawValue:)))
        let types = Set(record.types.compactMap(StudyType.init(rawValue:)))

        return CuratedPodcast(
            id: record.id,
            title: record.title,
            author: record.author,
            imageURL: imageURL,
            feedURL: feedURL,
            themes: themes,
            levels: levels,
            types: types
        )
    }

    private func mapStack(_ record: StudyStackRecord) -> StudyStack? {
        guard let theme = StudyTheme(rawValue: record.theme),
              let level = StudyLevel(rawValue: record.level) else {
            return nil
        }

        return StudyStack(
            id: record.id,
            title: record.title,
            summary: record.summary,
            theme: theme,
            level: level,
            podcastIDs: record.podcastIDs
        )
    }
}
