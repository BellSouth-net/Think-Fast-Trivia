//
//  LoginView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI
import ParseSwift

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToMenu = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient with tap gesture for keyboard dismissal
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when user taps outside of text fields
                    // This improves UX by allowing users to easily hide the keyboard
                    // sendAction sends the resignFirstResponder message to the current first responder (keyboard)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)
                        
                        Text("Think Fast Trivia")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Test your knowledge!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Username", systemImage: "person")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Password", systemImage: "lock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            SecureField("Enter password", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Login Button
                    Button(action: login) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Login")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
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
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    .padding(.horizontal, 30)
                    
                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.secondary)
                        
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .foregroundColor(.purple)
                        .bold()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Login Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func login() {
        // Show loading state while authenticating
        isLoading = true
        errorMessage = ""
        
        // Perform async login operation
        Task {
            do {
                // Attempt to login with ParseSwift/Back4App
                // This sends credentials to the backend and returns a User object if successful
                let user = try await User.login(username: username, password: password)
                print("✅ Successfully logged in as user: \(user.username ?? "")")
                
                // Update UI on main thread after successful login
                await MainActor.run {
                    isLoading = false
                    
                    // Post notification that user login status has changed
                    // This ensures ContentView updates to show MenuView
                    NotificationCenter.default.post(name: Notification.Name("UserLoginStatusChanged"), object: nil)
                    
                    navigateToMenu = true  // Navigate to main menu screen
                }
            } catch {
                // Handle login failure - show error to user
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true  // Triggers alert dialog
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
