//
//  FeedService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation
import FeedKit
import XMLKit

final class FeedService: FeedServiceProtocol {
    private let urlSession: URLSession
    private let cache: RSSCache

    init(
        urlSession: URLSession = FeedService.defaultSession(),
        cache: RSSCache = RSSCache()
    ) {
        self.urlSession = urlSession
        self.cache = cache
    }

    func fetchFeed(from url: URL) async throws -> Podcast {
        if let cachedData = await cache.load(for: url) {
            do {
                let feed = try RSSFeed(data: cachedData)
                return mapRSSFeed(feed, feedURL: url)
            } catch {
                await cache.remove(for: url)
            }
        }

        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FeedError.networkError(URLError(.badServerResponse))
        }

        do {
            let feed = try RSSFeed(data: data)
            await cache.save(data, for: url)
            return mapRSSFeed(feed, feedURL: url)
        } catch {
            throw FeedError.parsingError(error.localizedDescription)
        }
    }

    func clearCache() async {
        await cache.clear()
    }

    // MARK: - Private

    private static func defaultSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Echocast/1.0 (iOS)"
        ]
        return URLSession(configuration: configuration)
    }

    private func mapRSSFeed(_ rss: RSSFeed, feedURL: URL) -> Podcast {
        guard let channel = rss.channel else {
            return Podcast(title: "Sem titulo", feedURL: feedURL)
        }

        let episodes = channel.items?.compactMap { item -> Episode? in
            guard let title = item.title else { return nil }

            return Episode(
                title: title,
                description: plainText(from: item.description),
                audioURL: item.enclosure?.attributes?.url.flatMap(URL.init),
                duration: item.iTunes?.duration,
                publishedAt: item.pubDate
            )
        } ?? []

        return Podcast(
            title: channel.title ?? "Sem titulo",
            description: plainText(from: channel.description),
            author: channel.iTunes?.author ?? channel.managingEditor,
            imageURL: channel.iTunes?.image?.attributes?.href.flatMap(URL.init)
                ?? channel.image?.url.flatMap(URL.init),
            feedURL: feedURL,
            episodes: episodes
        )
    }

    private func plainText(from html: String?) -> String? {
        guard let html, !html.isEmpty else { return nil }
        let stripped = html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let decoded = stripped
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
        let normalized = decoded
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }
}
