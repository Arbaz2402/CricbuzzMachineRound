//
//  MovieService.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import Foundation

protocol MovieServicing {
    func popular(page: Int) async throws -> MoviePage
    func detail(id: Int) async throws -> MovieDetail
    func videos(id: Int) async throws -> VideoPage
    func search(query: String, page: Int) async throws -> MoviePage
    func credits(id: Int) async throws -> Credits
}

struct MovieService: MovieServicing {
    private let network: NetworkService
    private let config: APIConfig

    init(network: NetworkService = NetworkService(), config: APIConfig = .shared) {
        self.network = network
        self.config = config
    }

    func popular(page: Int = 1) async throws -> MoviePage {
        var endpoint = Endpoint(path: "/movie/popular")
        endpoint.queryItems.append(URLQueryItem(name: "page", value: String(page)))
        return try await network.request(endpoint)
    }

    func detail(id: Int) async throws -> MovieDetail {
        let endpoint = Endpoint(path: "/movie/\(id)")
        return try await network.request(endpoint)
    }

    func videos(id: Int) async throws -> VideoPage {
        let endpoint = Endpoint(path: "/movie/\(id)/videos")
        return try await network.request(endpoint)
    }

    func search(query: String, page: Int = 1) async throws -> MoviePage {
        var endpoint = Endpoint(path: "/search/movie")
        endpoint.queryItems += [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page))
        ]
        return try await network.request(endpoint)
    }

    func credits(id: Int) async throws -> Credits {
        let endpoint = Endpoint(path: "/movie/\(id)/credits")
        return try await network.request(endpoint)
    }
}
