//
//  GlobalAIModelProgress.swift
//  Think Fast Trivia
//
//  Created by Guy Morgan Beals on 11/10/25.
//

import SwiftUI

struct GlobalAIModelProgress: View {
    @ObservedObject var modelManager = AIModelManager.shared
    
    var body: some View {
        // Only show if model is preparing AND modal is NOT showing
        if modelManager.isPreparing && !modelManager.isModalShowing {
            VStack(spacing: 0) {
                // Progress bar at the very top
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.black.opacity(0.8))
                        .frame(height: 3)
                    
                    // Progress fill
                    if let progress = modelManager.downloadProgress {
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 3)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                        }
                        .frame(height: 3)
                    } else {
                        // Indeterminate progress (loading animation)
                        IndeterminateProgressBar()
                            .frame(height: 3)
                    }
                }
                
                // Small status text
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(Color.purple)
                    
                    Text(modelManager.downloadProgress != nil ? "Downloading AI model..." : "Loading AI model...")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                    
                    if let progress = modelManager.downloadProgress {
                        Text("\(Int(progress * 100))%")
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.85))
                
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: modelManager.isPreparing)
        }
    }
}

// Indeterminate progress animation
struct IndeterminateProgressBar: View {
    @State private var offset: CGFloat = -1
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.purple,
                            Color.blue,
                            Color.purple,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: geometry.size.width * 0.3)
                .offset(x: geometry.size.width * offset)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        offset = 1.2
                    }
                }
        }
        .clipped()
    }
}

#Preview {
    GlobalAIModelProgress()
}
