//
//  RSSCache.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import CryptoKit
import Foundation

actor RSSCache {
    private struct Metadata: Codable {
        let timestamp: Date
    }

    private let ttl: TimeInterval
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        ttl: TimeInterval = 60 * 60,
        fileManager: FileManager = .default,
        cacheDirectoryName: String = "RSSCache"
    ) {
        self.ttl = ttl
        self.fileManager = fileManager
        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = baseDirectory.appendingPathComponent(cacheDirectoryName, isDirectory: true)
    }

    func load(for url: URL) -> Data? {
        let paths = cachePaths(for: url)
        guard let metaData = try? Data(contentsOf: paths.metadata),
              let metadata = try? decoder.decode(Metadata.self, from: metaData) else {
            removeCacheItem(paths)
            return nil
        }

        guard !isExpired(metadata) else {
            removeCacheItem(paths)
            return nil
        }

        return try? Data(contentsOf: paths.data)
    }

    func save(_ data: Data, for url: URL) {
        ensureDirectory()
        let paths = cachePaths(for: url)
        let metadata = Metadata(timestamp: Date())

        do {
            try data.write(to: paths.data, options: [.atomic])
            let metaData = try encoder.encode(metadata)
            try metaData.write(to: paths.metadata, options: [.atomic])
        } catch {
            removeCacheItem(paths)
        }
    }

    func remove(for url: URL) {
        let paths = cachePaths(for: url)
        removeCacheItem(paths)
    }

    func clear() {
        try? fileManager.removeItem(at: cacheDirectory)
    }

    // MARK: - Private

    private func ensureDirectory() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    private func isExpired(_ metadata: Metadata) -> Bool {
        Date().timeIntervalSince(metadata.timestamp) > ttl
    }

    private func cachePaths(for url: URL) -> (data: URL, metadata: URL) {
        let key = cacheKey(for: url)
        let dataURL = cacheDirectory.appendingPathComponent(key).appendingPathExtension("rss")
        let metadataURL = cacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
        return (data: dataURL, metadata: metadataURL)
    }

    private func cacheKey(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func removeCacheItem(_ paths: (data: URL, metadata: URL)) {
        try? fileManager.removeItem(at: paths.data)
        try? fileManager.removeItem(at: paths.metadata)
    }
}
