//
//  EchocastApp.swift
//  Echocast
//
//  Created by actdigital on 10/12/25.
//

import SwiftUI
import SwiftData

@main
struct EchocastApp: App {
    var body: some Scene {
        WindowGroup {
            AddPodcastView()
        }
        .modelContainer(for: URLHistoryItem.self)
    }
}
