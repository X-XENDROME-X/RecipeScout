//
//  AIInputBar.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Message input bar with send button and loading state

import SwiftUI

struct AIInputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    
    @State private var characterCount = 0
    @FocusState private var isFocused: Bool
    
    private let maxCharacters = 1000
    
    var body: some View {
        VStack(spacing: 8) {
            // Character count indicator (shown when approaching limit)
            if characterCount > maxCharacters * 3 / 4 {
                HStack {
                    Spacer()
                    Text("\(characterCount)/\(maxCharacters)")
                        .font(.caption2)
                        .foregroundStyle(characterCount >= maxCharacters ? .red : .secondary)
                        .padding(.horizontal, 4)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                // Text input
                TextField("Ask me anything...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .lineLimit(1...5)
                    .disabled(isLoading)
                    .focused($isFocused)
                    .onChange(of: text) { _, newValue in
                        characterCount = newValue.count
                        // Prevent typing beyond max
                        if newValue.count > maxCharacters {
                            text = String(newValue.prefix(maxCharacters))
                        }
                    }
                    .onSubmit {
                        if canSend {
                            onSend()
                        }
                    }
                    .overlay(alignment: .trailing) {
                        // Clear button
                        if !text.isEmpty && !isLoading {
                            Button(action: {
                                text = ""
                                isFocused = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 8)
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                
                // Send button
                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(
                                canSend ?
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [.gray.opacity(0.3), .gray.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(!canSend)
                .sensoryFeedback(.impact(weight: .light), trigger: canSend)
            }
        }
        .animation(.spring(duration: 0.3), value: characterCount > maxCharacters * 3 / 4)
        .animation(.spring(duration: 0.2), value: text.isEmpty)
    }
    
    private var canSend: Bool {
        !isLoading && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
