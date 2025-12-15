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
}
