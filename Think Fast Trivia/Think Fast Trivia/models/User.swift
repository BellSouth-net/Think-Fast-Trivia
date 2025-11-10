//
//  User.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import Foundation
import ParseSwift

struct User: ParseUser {
    // These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // These are required by `ParseUser`.
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    // Custom properties for Think Fast Trivia
    var totalGamesPlayed: Int?
    var highScore: Int?
    var averageScore: Double?
}
