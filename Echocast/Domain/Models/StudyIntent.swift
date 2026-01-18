//
//  StudyIntent.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct StudyIntent: Hashable, Sendable {
    var themes: Set<StudyTheme>
    var levels: Set<StudyLevel>
    var types: Set<StudyType>

    init(
        themes: Set<StudyTheme> = [],
        levels: Set<StudyLevel> = [],
        types: Set<StudyType> = []
    ) {
        self.themes = themes
        self.levels = levels
        self.types = types
    }

    static let empty = StudyIntent()
}
