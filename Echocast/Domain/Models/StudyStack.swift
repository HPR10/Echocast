//
//  StudyStack.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct StudyStack: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String
    let theme: StudyTheme
    let level: StudyLevel
    let podcastIDs: [String]
}
