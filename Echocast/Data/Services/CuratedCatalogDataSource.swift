//
//  CuratedCatalogDataSource.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 18/01/26.
//

import Foundation

enum CuratedCatalogDataSourceError: Error {
    case resourceNotFound
    case invalidData
}

struct CuratedCatalogDataSource {
    private let bundle: Bundle
    private let resourceName: String

    init(bundle: Bundle = .main, resourceName: String = "CuratedCatalog") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func loadCatalog() throws -> CuratedCatalogRecord {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw CuratedCatalogDataSourceError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(CuratedCatalogRecord.self, from: data)
        } catch {
            throw CuratedCatalogDataSourceError.invalidData
        }
    }
}
