//
//  Credits.swift
//  CricbuzzMachineRound
//
//  Created by Arbaz Kaladiya on 22/11/25.
//

import Foundation

struct Credits: Codable, Equatable {
    let id: Int
    let cast: [CastMember]
}

struct CastMember: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
}
