//
//  AddPodcastViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class AddPodcastViewModel {
    private let manageHistoryUseCase: ManageFeedHistoryUseCase
    private let loadPodcastUseCase: LoadPodcastFromRSSUseCase

    var inputText = ""
    var isLoading = false
    var loadedPodcast: Podcast?
    var errorMessage: String?

    init(
        manageHistoryUseCase: ManageFeedHistoryUseCase,
        loadPodcastUseCase: LoadPodcastFromRSSUseCase
    ) {
        self.manageHistoryUseCase = manageHistoryUseCase
        self.loadPodcastUseCase = loadPodcastUseCase
    }

    func loadFeed() async {
        guard let url = normalizedFeedURL(from: inputText) else {
            errorMessage = FeedError.invalidURL.errorDescription
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let podcast = try await loadPodcastUseCase.execute(from: url)
            await manageHistoryUseCase.addURL(url.absoluteString)
            loadedPodcast = podcast
        } catch let error as FeedError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearLoadedPodcast() {
        loadedPodcast = nil
    }

    // MARK: - Validation

    func isValidURL(_ url: String) -> Bool {
        normalizedFeedURL(from: url) != nil
    }

    func shouldShowError(for url: String? = nil) -> Bool {
        let value = url ?? inputText
        return !value.isEmpty &&
        value.count > 8 &&
        !isValidURL(value)
    }

    func validationError(for url: String? = nil) -> String? {
        let value = url ?? inputText
        guard !value.isEmpty else { return nil }

        if !isValidURL(value) {
            return "URL inválida. Use http(s):// ou feed:// e inclua o caminho do feed."
        }

        return nil
    }

    private func normalizedFeedURL(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var components = URLComponents(string: candidate) else { return nil }

        if let scheme = components.scheme?.lowercased() {
            switch scheme {
            case "http", "https":
                break
            case "feed":
                components.scheme = "https"
            case "feed+http":
                components.scheme = "http"
            case "feed+https":
                components.scheme = "https"
            default:
                return nil
            }
        } else {
            components.scheme = "https"
        }

        guard let url = components.url,
              let host = components.host,
              !host.isEmpty else {
            return nil
        }

        let hasPath = !(url.path.isEmpty || url.path == "/")
        let hasQuery = !(url.query?.isEmpty ?? true)
        guard hasPath || hasQuery else { return nil }

        return url
    }
}
