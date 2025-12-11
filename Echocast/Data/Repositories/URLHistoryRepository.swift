//
//  URLHistoryRepository.swift
//  Echocast
//
//  Created by actdigital on 10/12/25.
//

import Foundation

final class URLHistoryRepository: URLHistoryRepositoryInput {
    private let key = "url_history"
    private let maxItems = 10
    
    func getHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func save(url: String) {
        var history = getHistory()
        history.removeAll { $0 == url }
        history.insert(url, at: 0)
        history = Array(history.prefix(maxItems))
        UserDefaults.standard.set(history, forKey: key)
    }
}

