//
//  ImageURL.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import Foundation

enum ImageURLBuilder {
    static func posterURL(path: String?, size: String = APIConfig.shared.defaultImageSize) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return APIConfig.shared.imagesBaseURL
            .appendingPathComponent(size)
            .appendingPathComponent(path)
    }

    static func backdropURL(path: String?, size: String = "w780") -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return APIConfig.shared.imagesBaseURL
            .appendingPathComponent(size)
            .appendingPathComponent(path)
    }
}
