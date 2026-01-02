//
//  DownloadedFileProvider.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 01/03/25.
//

import Foundation
import CryptoKit

struct DownloadedFileProvider: Sendable {
    let baseURL: URL

    init(baseURL: URL? = nil) {
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let fm = FileManager.default
            let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let supportCache = support?
                .appendingPathComponent("Caches", isDirectory: true)
                .appendingPathComponent("Downloads", isDirectory: true)
            let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Downloads", isDirectory: true)
            self.baseURL = supportCache
                ?? caches
                ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Downloads", isDirectory: true)
        }
        ensureDirectoryExists()
    }

    func localURL(for playbackKey: String, fileExtension: String?) -> URL {
        ensureDirectoryExists()
        let fileName = Self.safeFileName(for: playbackKey)
        if let fileExtension, !fileExtension.isEmpty {
            return baseURL.appendingPathComponent("\(fileName).\(fileExtension)")
        }
        return baseURL.appendingPathComponent(fileName)
    }

    func removeFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    func fileSize(at url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber else {
            return nil
        }
        return size.int64Value
    }

    func availableDiskSpaceInBytes() -> Int64? {
        guard let values = try? baseURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let capacity = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }
        return capacity
    }

    func excludeFromBackup(at url: URL) {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try? mutableURL.setResourceValues(values)
    }

    func ensureDirectoryExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseURL.path) {
            try? fm.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
        excludeFromBackup(at: baseURL)
    }

    private static func safeFileName(for playbackKey: String) -> String {
        let digest = SHA256.hash(data: Data(playbackKey.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
