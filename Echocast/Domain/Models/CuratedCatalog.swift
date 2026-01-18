//
//  CuratedCatalog.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct CuratedCatalog: Hashable, Sendable {
    let podcasts: [CuratedPodcast]
    let stacks: [StudyStack]
}
