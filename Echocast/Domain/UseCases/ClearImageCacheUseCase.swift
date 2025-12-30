//
//  ClearImageCacheUseCase.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import Foundation

@MainActor
final class ClearImageCacheUseCase {
    private let imageCacheService: ImageCacheServiceProtocol

    init(imageCacheService: ImageCacheServiceProtocol) {
        self.imageCacheService = imageCacheService
    }

    func execute() async {
        await imageCacheService.clearCache()
    }
}
