//
//  MenuView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI
import ParseSwift

struct MenuView: View {
    @State private var navigateToGame = false
    @State private var navigateToScores = false
    @State private var navigateToHighScores = false
    @State private var showLogoutConfirmation = false
    @State private var navigateToLogin = false
    @State private var currentUser = User.current
    @State private var showAIModelSelection = false
    @State private var navigateToAIGame = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text("Think Fast Trivia")
                            .font(.largeTitle)
                            .bold()
                        
                        if let username = currentUser?.username {
                            Text("Welcome, \(username)!")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 50)
                    
                    // TEMPORARILY HIDDEN - User Statistics Card
                    /*
                    // User Stats Card
                    if let user = currentUser {
                        VStack(spacing: 12) {
                            Text("Your Statistics")
                                .font(.headline)
                            
                            HStack(spacing: 30) {
                                VStack {
                                    Text("\(user.totalGamesPlayed ?? 0)")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.purple)
                                    Text("Games")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text("\(user.highScore ?? 0)")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text("High Score")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack {
                                    Text(String(format: "%.1f", user.averageScore ?? 0))
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.green)
                                    Text("Avg Score")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 5)
                        .padding(.horizontal, 30)
                    }
                    */
                    
                    // Menu Buttons
                    VStack(spacing: 16) {
                        // Play Button
                        Button(action: { navigateToGame = true }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                Text("Play Game")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Play Against AI Button
                        Button(action: { showAIModelSelection = true }) {
                            HStack {
                                Image(systemName: "cpu")
                                    .font(.title2)
                                Text("Play vs AI")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.indigo, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // TEMPORARILY HIDDEN - Scores and High Scores features
                        /*
                        // View Scores Button
                        Button(action: { navigateToScores = true }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                Text("My Scores")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // High Scores Button
                        Button(action: { navigateToHighScores = true }) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                Text("High Scores")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        */
                        
                        // Logout Button
                        Button(action: { showLogoutConfirmation = true }) {
                            HStack {
                                Image(systemName: "arrow.left.circle")
                                    .font(.title2)
                                Text("Logout")
                                    .font(.headline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToGame) {
                OptionsView()
            }
            .navigationDestination(isPresented: $navigateToScores) {
                ScoresView()
            }
            .navigationDestination(isPresented: $navigateToHighScores) {
                HighScoresView()
            }
            .navigationDestination(isPresented: $navigateToAIGame) {
                AIGameOptionsView()
            }
            .sheet(isPresented: $showAIModelSelection) {
                AIModelSelectionView(onModelSelected: {
                    // After model is selected and loaded, navigate to AI game
                    navigateToAIGame = true
                })
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
                    .navigationBarBackButtonHidden(true)
            }
            .alert("Logout", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Logout", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
        .onAppear {
            // Refresh user data
            refreshUserData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh when app comes to foreground
            refreshUserData()
        }
    }
    
    private func refreshUserData() {
        // Get the latest user data
        if let user = User.current {
            Task {
                do {
                    // Fetch the latest user data from Parse
                    let query = User.query("objectId" == user.objectId)
                    let updatedUser = try await query.first()
                    await MainActor.run {
                        self.currentUser = updatedUser
                    }
                } catch {
                    print("Error refreshing user data: \(error)")
                    // Still use the cached user if fetch fails
                    await MainActor.run {
                        self.currentUser = user
                    }
                }
            }
        } else {
            currentUser = User.current
        }
    }
    
    private func logout() {
        Task {
            do {
                try await ParseService.shared.logout()
                await MainActor.run {
                    navigateToLogin = true
                }
            } catch {
                print("Error logging out: \(error)")
            }
        }
    }
}

#Preview {
    MenuView()
}
