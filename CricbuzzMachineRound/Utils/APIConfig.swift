//
//  APIConfig.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import Foundation

final class APIConfig {
    static let shared = APIConfig()
    var apiKey: String = "a445f21929a25afcd5a1a0ba1ce9a2fd"

    // Base URLs
    let baseURL = URL(string: "https://api.themoviedb.org/3")!
    let imagesBaseURL = URL(string: "https://image.tmdb.org/t/p")!

    // Common
    let defaultLanguage = "en-US"
    let defaultImageSize = "w500" // image path: imagesBaseURL/appendingPathComponent(size)/appendingPathComponent(posterPath)
}
