//
//  Think_Fast_TriviaApp.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/2/25.
//

import SwiftUI
import ParseSwift

@main
struct Think_Fast_TriviaApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    init() {
        // Initialize Parse with Back4App
        ParseService.shared.initializeParse()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background:
                print("App moved to background - pausing AI operations")
                // Cancel any ongoing AI operations to prevent Metal GPU errors
                Task { @MainActor in
                    AIModelManager.shared.cancelCurrentOperation()
                }
            case .active:
                print("App is active")
            case .inactive:
                print("App is inactive")
            @unknown default:
                break
            }
        }
    }
}
