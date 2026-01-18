//
//  CuratedPodcast.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct CuratedPodcast: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let author: String?
    let imageURL: URL?
    let feedURL: URL
    let themes: Set<StudyTheme>
    let levels: Set<StudyLevel>
    let types: Set<StudyType>
}
