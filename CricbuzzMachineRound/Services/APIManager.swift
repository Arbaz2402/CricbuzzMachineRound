//
//  APIManager.swift
//  CricbuzzMachineRound
//
//  Central API aggregator for services.
//

import Foundation

final class APIManager {
    static let shared = APIManager()

    let network: NetworkService
    let movies: MovieServicing
    let favorites: FavoritesStoring

    private init(network: NetworkService = NetworkService()) {
        self.network = network
        self.movies = MovieService(network: network)
        self.favorites = FavoritesStore()
    }
}
