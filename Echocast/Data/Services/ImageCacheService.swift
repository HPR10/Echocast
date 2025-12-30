//
//  ImageCacheService.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import Foundation
import Nuke

@MainActor
final class ImageCacheService: ImageCacheServiceProtocol {
    private let imageCache: ImageCache
    private let dataCache: DataCache?
    private let pipeline: ImagePipeline

    init() {
        let imageCache = ImageCache()
        imageCache.costLimit = 100 * 1024 * 1024

        let dataCache = try? DataCache(name: "com.echocast.images")
        dataCache?.sizeLimit = 200 * 1024 * 1024

        self.imageCache = imageCache
        self.dataCache = dataCache
        self.pipeline = ImagePipeline {
            $0.imageCache = imageCache
            $0.dataCache = dataCache
        }
    }

    func configureSharedPipeline() {
        ImagePipeline.shared = pipeline
    }

    func clearCache() async {
        imageCache.removeAll()
        dataCache?.removeAll()
    }
}
