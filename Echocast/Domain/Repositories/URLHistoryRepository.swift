//
//  URLHistoryRepository.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 10/12/25.
//

protocol URLHistoryRepository {
    func save(url: String)
    func getHistory() -> [String]
}
