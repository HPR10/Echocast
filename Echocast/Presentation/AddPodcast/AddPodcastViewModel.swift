//
//  AddPodcastViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

import Foundation
import Combine

final class AddPodcastViewModel: ObservableObject {

    @Published var rssURL = ""
    @Published private(set) var urlHistory: [String] = []
    
    private let repository: URLHistoryRepositoryInput

    init(repository: URLHistoryRepositoryInput = URLHistoryRepository()) {
        self.repository = repository
        loadHistory()
    }

    func addURL() {
        guard !rssURL.isEmpty else { return }
        repository.save(url: rssURL)
        loadHistory()
    }
    
    func selectURL(_ url: String) {
        rssURL = url
    }
    
    private func loadHistory() {
        urlHistory = repository.getHistory()
    }
}
