//
//  GetCuratedCatalogUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

struct GetCuratedCatalogUseCase {
    private let repository: CuratedCatalogRepositoryProtocol

    init(repository: CuratedCatalogRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> CuratedCatalog {
        try await repository.fetchCatalog()
    }
}
