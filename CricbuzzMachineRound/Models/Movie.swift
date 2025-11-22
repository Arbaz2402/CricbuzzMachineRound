//
//  Movie.swift
//  CricbuzzMachineRound
//
//  TMDb core models
//

import Foundation

struct Movie: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
    }
}

struct MoviePage: Codable {
    let page: Int
    let results: [Movie]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
    }
}

struct MovieDetail: Codable, Equatable {
    let id: Int
    let title: String
    let overview: String?
    let genres: [Genre]?
    let runtime: Int? // minutes
    let voteAverage: Double?
    let posterPath: String?
    let backdropPath: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, genres, runtime
        case voteAverage = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}

struct Genre: Codable, Equatable, Hashable { let id: Int; let name: String }

struct VideoPage: Codable {
    let id: Int
    let results: [Video]
}

struct Video: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let key: String
    let name: String
    let site: String // e.g. "YouTube"
    let type: String // e.g. "Trailer"
}
