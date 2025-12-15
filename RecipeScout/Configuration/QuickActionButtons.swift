//
//  QuickActionButtons.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Suggested query buttons for quick interaction with AI assistant

import SwiftUI

struct QuickActionButtons: View {
    let suggestions: [String]
    let onTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.orange)
                
                Text("Try asking:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: { 
                            onTap(suggestion)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: iconForSuggestion(suggestion))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                
                                Text(suggestion)
                                    .font(.subheadline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            )
                            .foregroundStyle(.primary)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(.orange.opacity(0.2), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
        .padding(.bottom, 4)
    }
    
    // Helper to assign icons based on suggestion content
    private func iconForSuggestion(_ suggestion: String) -> String {
        let lowercased = suggestion.lowercased()
        
        if lowercased.contains("recipe") || lowercased.contains("cook") {
            return "fork.knife"
        } else if lowercased.contains("meal plan") || lowercased.contains("week") {
            return "calendar"
        } else if lowercased.contains("shopping") || lowercased.contains("groceries") {
            return "cart"
        } else if lowercased.contains("substitute") || lowercased.contains("replace") {
            return "arrow.triangle.2.circlepath"
        } else if lowercased.contains("healthy") || lowercased.contains("nutrition") {
            return "leaf"
        } else {
            return "lightbulb"
        }
    }
}
