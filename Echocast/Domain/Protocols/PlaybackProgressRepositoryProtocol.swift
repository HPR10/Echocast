//
//  PlaybackProgressRepositoryProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 22/12/25.
//

import Foundation

protocol PlaybackProgressRepositoryProtocol: Sendable {
    func save(_ progress: PlaybackProgress) async
    func fetch(for key: String) async -> PlaybackProgress?
    func clear(for key: String) async
}
