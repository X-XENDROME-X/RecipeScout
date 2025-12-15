//
//  MessageBubbleView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Chat message bubble component with distinct styling for user and assistant messages

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var showCopyFeedback = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            if message.role == .assistant {
                // Assistant avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message content with markdown rendering for assistant messages
                messageContent
                    .padding(12)
                    .background(bubbleBackground)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = message.content
                            showCopyFeedback = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopyFeedback = false
                            }
                        }) {
                            Label("Copy Message", systemImage: "doc.on.doc")
                        }
                    }
                
                HStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if showCopyFeedback {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundStyle(.green)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
            
            if message.role == .user {
                // User avatar
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                    }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var messageContent: some View {
        if message.role == .assistant {
            // Render markdown for assistant messages
            if let attributedString = try? AttributedString(
                markdown: message.content,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            ) {
                Text(attributedString)
                    .font(.body)
                    .textSelection(.enabled)
                    .tint(.orange) // Color for links if any
            } else {
                // Fallback to plain text if markdown parsing fails
                Text(message.content)
                    .font(.body)
                    .textSelection(.enabled)
            }
        } else {
            // Plain text for user messages
            Text(message.content)
                .font(.body)
                .textSelection(.enabled)
        }
    }
    
    private var bubbleBackground: some ShapeStyle {
        if message.role == .user {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.orange, .orange.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(Color(.systemGray6))
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}
