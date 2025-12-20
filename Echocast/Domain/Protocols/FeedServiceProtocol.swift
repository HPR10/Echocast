//
//  FeedServiceProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation

protocol FeedServiceProtocol: Sendable {
    func fetchFeed(from url: URL) async throws -> Podcast
}
