//
//  AddPodcastViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import Foundation
import Observation

@Observable
final class AddPodcastViewModel {
    var feedURL: String?

    private let manageHistoryUseCase: ManageFeedHistoryUseCase

    init(manageHistoryUseCase: ManageFeedHistoryUseCase) {
        self.manageHistoryUseCase = manageHistoryUseCase
    }

    func addURL(currentHistory: [FeedHistoryItem]) {
        manageHistoryUseCase.addURL(feedURL, currentHistory: currentHistory)
    }

    func selectURL(_ url: String) {
        feedURL = url
    }
}
