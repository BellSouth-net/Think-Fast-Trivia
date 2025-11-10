//
//  GameScore.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import Foundation
import ParseSwift

struct GameScore: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Custom fields for game scores
    var user: User?
    var score: Int?
    var totalQuestions: Int?
    var percentage: Double?
    var category: String?
    var difficulty: String?
    var timeTaken: Int? // in seconds
}
