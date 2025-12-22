//
//  PodcastDetailViewModel.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 20/12/25.
//

import Foundation
import Observation

@Observable
@MainActor
final class PodcastDetailViewModel {
    let podcast: Podcast

    init(podcast: Podcast) {
        self.podcast = podcast
    }
}
