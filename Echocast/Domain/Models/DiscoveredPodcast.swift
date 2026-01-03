//
//  DiscoveredPodcast.swift
//  Echocast
//
//  Created by OpenAI Assistant on 27/02/25.
//

import Foundation

struct DiscoveredPodcast: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let author: String?
    let imageURL: URL?
    let feedURL: URL
}
