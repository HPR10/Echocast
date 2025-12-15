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

    init(manageHistoryUseCase: ManageFeedHistoryUseCase) {
        self.manageHistoryUseCase = manageHistoryUseCase
    }

    func addURL(_ url: String, currentHistory: [FeedHistoryItem]) async {
        await manageHistoryUseCase.addURL(url, currentHistory: currentHistory)
    }

    // MARK: - Validation

    func isValidURL(_ url: String) -> Bool {
        guard !url.isEmpty else { return false }
        guard url.hasPrefix("http://") || url.hasPrefix("https://") else {
            return false
        }

        guard let urlObject = URL(string: url),
              let host = urlObject.host,
              host.contains(".") else {  // Precisa ter ponto (TLD)
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

    func shouldShowError(for url: String) -> Bool {
        !url.isEmpty &&
        url.count > 8 &&
        !isValidURL(url)
    }

    func validationError(for url: String) -> String? {
        guard !url.isEmpty else { return nil }

        if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
            return "URL deve começar com http:// ou https://"
        }

        if !isValidURL(url) {
            return "URL inválida. Exemplo: https://podcast.com/feed"
        }

        return nil
    }
}
