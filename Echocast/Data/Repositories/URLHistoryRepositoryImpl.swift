//
//  URLHistoryRepositoryImpl.swift
//  Echocast
//
//  Created by actdigital on 10/12/25.
//

import Foundation

final class URLHistoryRepositoryImpl: URLHistoryRepository {
    private let key = "url_history"
    
    func getHistory() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
    
    func save(url: String) {
        var history = getHistory()
        history.removeAll { $0 == url }
        history.insert(url, at: 0)
        UserDefaults.standard.set(history, forKey: key)
    }
}

