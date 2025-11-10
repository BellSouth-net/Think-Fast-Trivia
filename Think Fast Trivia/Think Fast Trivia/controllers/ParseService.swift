//
//  ParseService.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import Foundation
import ParseSwift

class ParseService {
    static let shared = ParseService()
    
    private init() {}
    
    // Initialize Parse with your Back4App credentials
    func initializeParse() {
        ParseSwift.initialize(
            applicationId: "zF6Mn30AIMceC3EJWGU3OJks0HY9rBfClhFmH6ay",
            clientKey: "iSxngu6KfiAPySRBZUxr4JaFpgctMmNmw1HfB0YJ",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
    }
    
    // Check if user is logged in
    var isLoggedIn: Bool {
        return User.current != nil
    }
    
    // Save game score
    func saveGameScore(score: Int, totalQuestions: Int, category: String, difficulty: String, timeTaken: Int) async throws {
        guard let currentUser = User.current else {
            throw ParseError(code: .usernameMissing, message: "No user logged in")
        }
        
        guard let userId = currentUser.objectId else {
            throw ParseError(code: .objectNotFound, message: "User has no objectId")
        }
        
        print("💾 Saving score for user: \(currentUser.username ?? "unknown") with ID: \(userId)")
        
        let percentage = Double(score) / Double(totalQuestions) * 100
        
        var gameScore = GameScore()
        
        // Assign the user directly - ParseSwift handles pointer conversion
        gameScore.user = currentUser
        
        gameScore.score = score
        gameScore.totalQuestions = totalQuestions
        gameScore.percentage = percentage
        gameScore.category = category
        gameScore.difficulty = difficulty
        gameScore.timeTaken = timeTaken
        
        // Set ACL to allow the user to read their own scores
        var acl = ParseACL()
        acl.publicRead = true  // Allow everyone to read (for leaderboard)
        acl.setReadAccess(user: currentUser, value: true)
        acl.setWriteAccess(user: currentUser, value: true)
        gameScore.ACL = acl
        
        let savedScore = try await gameScore.save()
        print("💾 Score saved successfully with ID: \(savedScore.objectId ?? "no-id")")
        
        // Update user statistics
        try await updateUserStatistics(score: score)
    }
    
    // Update user statistics
    private func updateUserStatistics(score: Int) async throws {
        guard var currentUser = User.current else { return }
        
        // Simple update without fetching all scores
        let gamesPlayed = (currentUser.totalGamesPlayed ?? 0) + 1
        let highScore = max(currentUser.highScore ?? 0, score)
        
        // Simple running average calculation
        let currentAverage = currentUser.averageScore ?? 0
        let currentTotal = currentAverage * Double(gamesPlayed - 1)
        let newTotal = currentTotal + Double(score)
        let averageScore = newTotal / Double(gamesPlayed)
        
        currentUser.totalGamesPlayed = gamesPlayed
        currentUser.highScore = highScore
        currentUser.averageScore = averageScore
        
        try await currentUser.save()
    }
    
    // Fetch user's game history
    func fetchUserScores() async throws -> [GameScore] {
        guard let currentUser = User.current else {
            throw ParseError(code: .usernameMissing, message: "No user logged in")
        }
        
        print("📊 ========== DEBUG: Fetching User Scores ==========")
        print("📊 Current user: \(currentUser.username ?? "unknown")")
        print("📊 Current user ID: \(currentUser.objectId ?? "no-id")")
        
        // Try multiple query approaches to debug
        
        // Approach 1: Query by user pointer (standard approach)
        do {
        guard let userId = currentUser.objectId else {
            throw ParseError(code: .objectNotFound, message: "User has no objectId")
        }
        
            let userPointer = try currentUser.toPointer()
            print("📊 Created user pointer: \(userPointer)")
            
            let query1 = GameScore.query("user" == userPointer)
                .order([.descending("createdAt")])
                .include("user")
            
            print("📊 Trying query with user pointer...")
            let scores1 = try await query1.find()
            print("📊 ✅ Pointer query found \(scores1.count) scores")
            
            if scores1.count > 0 {
                print("📊 Success! Returning pointer query results")
                return scores1
            }
        } catch {
            print("📊 ❌ Pointer query failed: \(error)")
        }
            
        // Approach 2: Debug - Get ALL recent scores to see what's in database
        print("📊 Pointer query returned 0 results. Debugging database contents...")
        
        let debugQuery = GameScore.query()
                .order([.descending("createdAt")])
                .include("user")
            .limit(20)  // Just get recent ones for debugging
        
        print("📊 Fetching recent scores for debugging...")
        let allScores = try await debugQuery.find()
        print("📊 Found \(allScores.count) recent scores in database")
        
        // Debug: Print detailed info about each score
        print("📊 ========== Score Details ==========")
        for (index, score) in allScores.enumerated() {
            let scoreUserId = score.user?.objectId ?? "nil"
            let scoreUsername = score.user?.username ?? "nil"
            let currentUserId = currentUser.objectId ?? "nil"
            
            print("📊 Score \(index + 1):")
            print("📊   - User ID: \(scoreUserId)")
            print("📊   - Username: \(scoreUsername)")
            print("📊   - Points: \(score.score ?? 0)")
            print("📊   - Created: \(score.createdAt?.description ?? "unknown")")
            print("📊   - Match with current user: \(scoreUserId == currentUserId ? "✅ YES" : "❌ NO")")
            
            // Extra debug for the user field
            if score.user == nil {
                print("📊   ⚠️ WARNING: User field is nil!")
            }
        }
        print("📊 ========================================")
        
        // Filter manually to see if we can find them
        let manuallyFiltered = allScores.filter { score in
            score.user?.objectId == currentUser.objectId
            }
        print("📊 Manually filtered results: \(manuallyFiltered.count) scores belong to current user")
        
        // If we found scores manually but not with pointer query, there's a problem
        if manuallyFiltered.count > 0 {
            print("📊 ⚠️ WARNING: Found scores manually but pointer query failed!")
            print("📊 This suggests a pointer format mismatch issue")
            return manuallyFiltered
        }
        
        print("📊 No scores found for current user in database")
        return []
    }
    
    // Fetch top 10 high scores from all users
    func fetchHighScores() async throws -> [GameScore] {
        let query = try GameScore.query()
            .order([.descending("score")])  // Order by score descending
            .limit(10)  // Get top 10
            .include("user")  // Include user data
        
        return try await query.find()
    }
    
    // Logout user
    func logout() async throws {
        try await User.logout()
    }
}
