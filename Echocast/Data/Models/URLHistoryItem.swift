//
//  URLHistoryItem.swift
//  Echocast
//
//  Created by actdigital on 14/12/25.
//

import Foundation
import SwiftData

@Model
final class URLHistoryItem {
    var url: String
    var addedAt: Date

    init(url: String) {
        self.url = url
        self.addedAt = .now
    }
}
