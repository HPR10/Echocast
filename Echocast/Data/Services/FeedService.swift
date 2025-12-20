//
//  FeedService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation
import FeedKit

final class FeedService: FeedServiceProtocol {
    private let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func fetchFeed(from url: URL) async throws -> Podcast {
        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FeedError.networkError(URLError(.badServerResponse))
        }

        let parser = FeedParser(data: data)
        let result = parser.parse()

        switch result {
        case .success(let feed):
            return try mapFeedToPodcast(feed, feedURL: url)
        case .failure(let error):
            throw FeedError.parsingError(error.localizedDescription)
        }
    }

    // MARK: - Mapping

    private func mapFeedToPodcast(_ feed: Feed, feedURL: URL) throws -> Podcast {
        switch feed {
        case .rss(let rssFeed):
            return mapRSSFeed(rssFeed, feedURL: feedURL)
        case .atom(let atomFeed):
            return mapAtomFeed(atomFeed, feedURL: feedURL)
        case .json(let jsonFeed):
            return mapJSONFeed(jsonFeed, feedURL: feedURL)
        }
    }

    private func mapRSSFeed(_ rss: RSSFeed, feedURL: URL) -> Podcast {
        let episodes = rss.items?.compactMap { item -> Episode? in
            guard let title = item.title else { return nil }

            let audioURL = item.enclosure?.attributes?.url.flatMap(URL.init)
            let duration = parseDuration(item.iTunes?.iTunesDuration)

            return Episode(
                title: title,
                description: item.description,
                audioURL: audioURL,
                duration: duration,
                publishedAt: item.pubDate
            )
        } ?? []

        let imageURL = rss.iTunes?.iTunesImage?.attributes?.href.flatMap(URL.init)
            ?? rss.image?.url.flatMap(URL.init)

        return Podcast(
            title: rss.title ?? "Sem titulo",
            description: rss.description,
            author: rss.iTunes?.iTunesAuthor ?? rss.managingEditor,
            imageURL: imageURL,
            feedURL: feedURL,
            episodes: episodes
        )
    }

    private func mapAtomFeed(_ atom: AtomFeed, feedURL: URL) -> Podcast {
        let episodes = atom.entries?.compactMap { entry -> Episode? in
            guard let title = entry.title else { return nil }

            let audioURL = entry.links?
                .first { $0.attributes?.type?.contains("audio") == true }?
                .attributes?.href
                .flatMap(URL.init)

            return Episode(
                title: title,
                description: entry.summary?.value,
                audioURL: audioURL,
                publishedAt: entry.published
            )
        } ?? []

        return Podcast(
            title: atom.title ?? "Sem titulo",
            description: atom.subtitle?.value,
            author: atom.authors?.first?.name,
            imageURL: atom.logo.flatMap(URL.init),
            feedURL: feedURL,
            episodes: episodes
        )
    }

    private func mapJSONFeed(_ json: JSONFeed, feedURL: URL) -> Podcast {
        let episodes = json.items?.compactMap { item -> Episode? in
            guard let title = item.title else { return nil }

            let audioURL = item.attachments?
                .first { $0.mimeType?.contains("audio") == true }?
                .url
                .flatMap(URL.init)

            return Episode(
                title: title,
                description: item.contentHtml ?? item.contentText,
                audioURL: audioURL,
                publishedAt: item.datePublished
            )
        } ?? []

        return Podcast(
            title: json.title ?? "Sem titulo",
            description: json.description,
            author: json.author?.name,
            imageURL: json.icon.flatMap(URL.init),
            feedURL: feedURL,
            episodes: episodes
        )
    }

    // MARK: - Helpers

    private func parseDuration(_ duration: TimeInterval?) -> TimeInterval? {
        return duration
    }
}
