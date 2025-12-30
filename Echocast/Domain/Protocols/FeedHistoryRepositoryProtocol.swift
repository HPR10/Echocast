//
//  FeedHistoryRepositoryProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 14/12/25.
//

import Foundation

protocol FeedHistoryRepositoryProtocol: Sendable {
    func add(_ url: String) async
    func deleteByURL(_ url: String) async
    func exists(_ url: String) async -> Bool
    func deleteOldestExceeding(limit: Int) async
}
