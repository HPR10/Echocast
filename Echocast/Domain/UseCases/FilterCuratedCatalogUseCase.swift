//
//  FilterCuratedCatalogUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct FilterCuratedCatalogUseCase {
    func execute(catalog: CuratedCatalog, intent: StudyIntent) -> [CuratedPodcast] {
        catalog.podcasts.filter { podcast in
            let matchesTheme = intent.themes.isEmpty || !intent.themes.isDisjoint(with: podcast.themes)
            let matchesLevel = intent.levels.isEmpty || !intent.levels.isDisjoint(with: podcast.levels)
            let matchesType = intent.types.isEmpty || !intent.types.isDisjoint(with: podcast.types)
            return matchesTheme && matchesLevel && matchesType
        }
    }
}
