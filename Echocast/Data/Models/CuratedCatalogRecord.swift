//
//  CuratedCatalogRecord.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct CuratedCatalogRecord: Decodable {
    let podcasts: [CuratedPodcastRecord]
    let stacks: [StudyStackRecord]
}

struct CuratedPodcastRecord: Decodable {
    let id: String
    let title: String
    let author: String?
    let imageURL: String?
    let feedURL: String
    let themes: [String]
    let levels: [String]
    let types: [String]
}

struct StudyStackRecord: Decodable {
    let id: String
    let title: String
    let summary: String
    let theme: String
    let level: String
    let podcastIDs: [String]
}
