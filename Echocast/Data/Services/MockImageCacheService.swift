//
//  MockImageCacheService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import Foundation

@MainActor
final class MockImageCacheService: ImageCacheServiceProtocol {
    func clearCache() async {}
}
