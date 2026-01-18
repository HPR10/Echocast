//
//  PodcastIndexDiscoveryService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import CryptoKit
import Foundation

struct PodcastIndexDiscoveryService: PodcastDiscoveryServiceProtocol {
    private let apiKey: String
    private let apiSecret: String
    private let userAgent: String
    private let session: URLSession

    init(
        apiKey: String,
        apiSecret: String,
        userAgent: String = "Echocast/1.0",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.userAgent = userAgent
        self.session = session
    }

    func fetchTechnologyPodcasts(limit: Int, offset: Int) async throws -> [DiscoveredPodcast] {
        guard offset == 0 else { return [] }
        guard let request = buildRequest(limit: limit) else { return [] }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        let feeds = decoded.feeds ?? []

        return feeds.compactMap { feed in
            guard let feedURLString = feed.url,
                  let feedURL = URL(string: feedURLString) else {
                return nil
            }

            let imageURL = imageURL(for: feed)
            let identifier = feed.itunesId ?? feed.id

            return DiscoveredPodcast(
                id: identifier,
                title: feed.title,
                author: feed.author ?? feed.ownerName,
                imageURL: imageURL,
                feedURL: feedURL
            )
        }
    }

    private func buildRequest(limit: Int) -> URLRequest? {
        var components = URLComponents(string: "https://api.podcastindex.org/api/1.0/podcasts/trending")
        components?.queryItems = [
            URLQueryItem(name: "max", value: String(limit))
        ]
        guard let url = components?.url else { return nil }

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let tokenSource = apiKey + apiSecret + timestamp
        let token = sha1(tokenSource)

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.setValue(timestamp, forHTTPHeaderField: "X-Auth-Date")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        return request
    }

    private func sha1(_ value: String) -> String {
        let data = Data(value.utf8)
        let digest = Insecure.SHA1.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func imageURL(for feed: PodcastIndexFeed) -> URL? {
        let candidates = [feed.artwork, feed.image, feed.thumb, feed.favicon]

        for raw in candidates {
            guard let raw, !raw.isEmpty else { continue }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let normalized = normalizedURLString(trimmed)
            if let url = URL(string: normalized) {
                return url
            }
        }

        return nil
    }

    private func normalizedURLString(_ value: String) -> String {
        if value.hasPrefix("//") {
            return "https:\(value)"
        }
        if value.hasPrefix("http://") {
            return "https://" + value.dropFirst("http://".count)
        }
        return value
    }
}

private struct SearchResponse: Decodable {
    let feeds: [PodcastIndexFeed]?
}

private struct PodcastIndexFeed: Decodable {
    let id: Int
    let itunesId: Int?
    let title: String
    let author: String?
    let ownerName: String?
    let url: String?
    let image: String?
    let artwork: String?
    let thumb: String?
    let favicon: String?
}
