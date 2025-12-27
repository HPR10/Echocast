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

    func loadFeed(currentHistory: [FeedHistoryItem]) async {
        guard let url = URL(string: inputText) else {
            errorMessage = FeedError.invalidURL.errorDescription
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let podcast = try await loadPodcastUseCase.execute(from: url)
            await manageHistoryUseCase.addURL(inputText, currentHistory: currentHistory)
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
        guard !url.isEmpty else { return false }
        guard url.hasPrefix("http://") || url.hasPrefix("https://") else {
            return false
        }

        guard let urlObject = URL(string: url),
              let host = urlObject.host,
              host.contains(".") else {
            return false
        }

        let components = host.components(separatedBy: ".")
        guard components.count >= 2,
              let tld = components.last,
              tld.count >= 2 else {
            return false
        }

        return true
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

        if !value.hasPrefix("http://") && !value.hasPrefix("https://") {
            return "URL deve começar com http:// ou https://"
        }

        if !isValidURL(value) {
            return "URL inválida. Exemplo: https://podcast.com/feed"
        }

        return nil
    }
}
