//
//  CuratedCatalogRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

enum CuratedCatalogRepositoryError: Error {
    case invalidFeedURL(String)
    case invalidStack(String)
}

struct CuratedCatalogRepository: CuratedCatalogRepositoryProtocol {
    private let dataSource: CuratedCatalogDataSource

    init(dataSource: CuratedCatalogDataSource = CuratedCatalogDataSource()) {
        self.dataSource = dataSource
    }

    func fetchCatalog() async throws -> CuratedCatalog {
        let record = try dataSource.loadCatalog()
        let podcasts = try record.podcasts.map(mapPodcast)
        let stacks = try record.stacks.map(mapStack)
        return CuratedCatalog(podcasts: podcasts, stacks: stacks)
    }

    private func mapPodcast(_ record: CuratedPodcastRecord) throws -> CuratedPodcast {
        guard let feedURL = URL(string: record.feedURL) else {
            throw CuratedCatalogRepositoryError.invalidFeedURL(record.id)
        }
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

    private func mapStack(_ record: StudyStackRecord) throws -> StudyStack {
        guard let theme = StudyTheme(rawValue: record.theme),
              let level = StudyLevel(rawValue: record.level) else {
            throw CuratedCatalogRepositoryError.invalidStack(record.id)
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
