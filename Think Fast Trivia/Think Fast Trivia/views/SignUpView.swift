//
//  SignUpView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/9/25.
//

import SwiftUI
import ParseSwift

struct SignUpView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var signUpSuccessful = false
    @Environment(\.dismiss) private var dismiss
    
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
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                            
                            Text("Create Account")
                                .font(.largeTitle)
                                .bold()
                            
                            Text("Join the trivia challenge!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 30)
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Username", systemImage: "person")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("Choose a username", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email", systemImage: "envelope")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .disableAutocorrection(true)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Password", systemImage: "lock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Confirm Password", systemImage: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        // Sign Up Button
                        Button(action: signUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Sign Up")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || !isFormValid)
                        .padding(.horizontal, 30)
                        
                        // Login Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Login") {
                                dismiss()
                            }
                            .foregroundColor(.purple)
                            .bold()
                        }
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Up Failed", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Welcome!", isPresented: $signUpSuccessful) {
                Button("Let's Play!", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your account has been created successfully! You're now logged in.")
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() {
        // Validate that passwords match before proceeding
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }
        
        // Ensure password meets minimum security requirements
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        // Show loading state while creating account
        isLoading = true
        errorMessage = ""
        
        // Perform async signup operation
        Task {
            do {
                // Create new User object with provided credentials
                var newUser = User()
                newUser.username = username
                newUser.email = email
                newUser.password = password
                
                // Initialize game statistics for new user
                newUser.totalGamesPlayed = 0
                newUser.highScore = 0
                newUser.averageScore = 0
                
                // Send signup request to Back4App backend
                // This creates the user account and automatically logs them in
                let user = try await newUser.signup()
                print("✅ Successfully signed up user: \(user.username ?? "")")
                
                // Update UI on main thread after successful signup
                // ParseSwift automatically logs in the user after successful signup
                await MainActor.run {
                    isLoading = false
                    
                    // Post notification that user login status has changed
                    // This will trigger ContentView to update and show MenuView
                    NotificationCenter.default.post(name: Notification.Name("UserLoginStatusChanged"), object: nil)
                    
                    // Show success alert which will handle dismissal
                    signUpSuccessful = true
                }
            } catch {
                // Handle signup failure - show error to user
                // Common errors: username taken, invalid email, network issues
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
    SignUpView()
}
