//
//  CuratedCatalogRepositoryProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

protocol CuratedCatalogRepositoryProtocol {
    func fetchCatalog() async throws -> CuratedCatalog
}
