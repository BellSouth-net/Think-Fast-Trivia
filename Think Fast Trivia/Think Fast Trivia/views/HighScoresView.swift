//
//  HighScoresView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI
import ParseSwift

struct HighScoresView: View {
    @State private var highScores: [GameScore] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading high scores...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                } else if highScores.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No High Scores Yet")
                            .font(.title2)
                            .bold()
                        
                        Text("Be the first to set a high score!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Title
                            VStack(spacing: 8) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.yellow)
                                
                                Text("High Scores")
                                    .font(.largeTitle)
                                    .bold()
                                
                                Text("Top 10 Players")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 20)
                            
                            // High Scores List
                            VStack(spacing: 12) {
                                ForEach(Array(highScores.enumerated()), id: \.element.objectId) { index, score in
                                    HighScoreRow(rank: index + 1, score: score)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { loadHighScores() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHighScores()
            }
            .alert("Error Loading High Scores", isPresented: $showError) {
                Button("Try Again") {
                    loadHighScores()
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func loadHighScores() {
        isLoading = true
        errorMessage = nil
        showError = false
        
        Task {
            do {
                print("🏆 Loading high scores...")
                let scores = try await ParseService.shared.fetchHighScores()
                
                await MainActor.run {
                    print("🏆 Successfully loaded \(scores.count) high scores")
                    self.highScores = scores
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("❌ Error loading high scores: \(error)")
                    self.errorMessage = "Failed to load high scores: \(error.localizedDescription)"
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
}

struct HighScoreRow: View {
    let rank: Int
    let score: GameScore
    
    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
    
    private var isCurrentUser: Bool {
        guard let currentUser = User.current,
              let scoreUser = score.user else { return false }
        return currentUser.objectId == scoreUser.objectId
    }
    
    private var formattedDate: String {
        guard let date = score.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            // Rank
            Text(rankEmoji)
                .font(rank <= 3 ? .title : .title2)
                .frame(width: 40)
            
            // User and Score Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(score.user?.username ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(isCurrentUser ? .purple : .primary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("\(score.score ?? 0) pts")
                        .font(.subheadline)
                        .bold()
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.0f%%", score.percentage ?? 0))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let category = score.category, category != "Any" {
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // Date
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? 
                      Color.purple.opacity(0.1) : 
                      Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.purple : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    HighScoresView()
}
