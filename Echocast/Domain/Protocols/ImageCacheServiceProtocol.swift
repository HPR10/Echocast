//
//  ImageCacheServiceProtocol.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 21/12/25.
//

import Foundation

protocol ImageCacheServiceProtocol: Sendable {
    func clearCache() async
}
