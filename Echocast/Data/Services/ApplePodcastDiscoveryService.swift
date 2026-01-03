//
//  ApplePodcastDiscoveryService.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import Foundation

struct ApplePodcastDiscoveryService: PodcastDiscoveryServiceProtocol {
    private struct SearchResponse: Decodable {
        let results: [Result]
    }

    private struct Result: Decodable {
        let trackId: Int
        let trackName: String
        let artistName: String?
        let feedUrl: String?
        let artworkUrl100: String?
        let artworkUrl600: String?
    }

    func fetchTechnologyPodcasts() async throws -> [DiscoveredPodcast] {
        guard let url = buildURL() else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        return response.results.compactMap { result in
            guard let feedURLString = result.feedUrl, let feedURL = URL(string: feedURLString) else {
                return nil
            }

            let imageURLString = result.artworkUrl600 ?? result.artworkUrl100
            let imageURL = imageURLString.flatMap(URL.init)

            return DiscoveredPodcast(
                id: result.trackId,
                title: result.trackName,
                author: result.artistName,
                imageURL: imageURL,
                feedURL: feedURL
            )
        }
    }

    private func buildURL() -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "term", value: "technology"),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "genreId", value: "1318")
        ]
        return components?.url
    }
}
