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
    var rssURL = ""

    func selectURL(_ url: String) {
        rssURL = url
    }
}
