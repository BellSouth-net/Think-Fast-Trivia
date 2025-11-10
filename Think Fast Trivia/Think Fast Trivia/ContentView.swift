//
//  ContentView.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/2/25.
//

import SwiftUI
import ParseSwift

struct ContentView: View {
    @State private var isLoggedIn = ParseService.shared.isLoggedIn
    
    var body: some View {
        ZStack {
            Group {
                if isLoggedIn {
                    MenuView()
                } else {
                    LoginView()
                }
            }
            .onAppear {
                // Check login status on appear
                isLoggedIn = ParseService.shared.isLoggedIn
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("UserLoginStatusChanged"))) { _ in
                // Update login status when it changes
                isLoggedIn = ParseService.shared.isLoggedIn
            }
            
            // Global AI Model download progress overlay
            GlobalAIModelProgress()
        }
    }
}

#Preview {
    ContentView()
}
