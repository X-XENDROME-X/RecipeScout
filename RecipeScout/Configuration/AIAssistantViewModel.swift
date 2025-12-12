//
//  AIAssistantViewModel.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: ViewModel managing AI assistant state, conversation flow, and interaction with Claude API

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AIAssistantViewModel {
    
    // MARK: - Properties
    
    private let claudeService = ClaudeAPIService.shared
    private let contextManager: AIContextManager
    
    var messages: [ChatMessage] = []
    var isLoading = false
    var errorMessage: String?
    var statistics: UserStatistics
    
    // Privacy settings
    var includeShoppingList = true
    var includeSavedRecipes = true
    var includeMealPlan = true
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.contextManager = AIContextManager(modelContext: modelContext)
        self.statistics = contextManager.getUserStatistics()
        
        // Add welcome message
        addWelcomeMessage()
    }
    
    // MARK: - Public Methods
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        
        // Clear any previous errors
        errorMessage = nil
        isLoading = true
        
        do {
            // Build context
            let userContext = contextManager.buildContext(
                includeShoppingList: includeShoppingList,
                includeSavedRecipes: includeSavedRecipes,
                includeMealPlan: includeMealPlan
            )
            
            let systemPrompt = ClaudePromptBuilder.buildSystemPrompt(userContext: userContext)
            
            // Convert messages to Claude format
            let claudeMessages = messages.map { message in
                ClaudeMessage(
                    id: message.id,
                    role: message.role == .user ? .user : .assistant,
                    content: message.content
                )
            }
            
            // Send to Claude
            let response = try await claudeService.sendMessage(
                messages: claudeMessages,
                systemPrompt: systemPrompt,
                temperature: 0.7
            )
            
            // Extract response text
            if let firstBlock = response.content.first {
                let assistantMessage = ChatMessage(role: .assistant, content: firstBlock.text)
                messages.append(assistantMessage)
            }
            
            isLoading = false
            
        } catch let error as ClaudeError {
            isLoading = false
            errorMessage = error.localizedDescription
            
            // Add error message to chat
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "❌ Sorry, I encountered an error: \(error.localizedDescription)\n\n\(error.recoverySuggestion ?? "Please try again.")"
            )
            messages.append(errorMsg)
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "❌ Sorry, something went wrong. Please try again."
            )
            messages.append(errorMsg)
        }
    }
    
    func refreshContext() {
        statistics = contextManager.getUserStatistics()
    }
    
    func clearConversation() {
        messages.removeAll()
        addWelcomeMessage()
        errorMessage = nil
    }
    
    func getSuggestedQueries() -> [String] {
        return ClaudePromptBuilder.getSuggestedQueries(
            hasData: statistics.hasAnyData,
            statistics: statistics
        )
    }
    
    // MARK: - Private Methods
    
    private func addWelcomeMessage() {
        let welcomeText = ClaudePromptBuilder.getWelcomeMessage(statistics: statistics)
        let welcomeMessage = ChatMessage(role: .assistant, content: welcomeText)
        messages.append(welcomeMessage)
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole {
        case user
        case assistant
    }
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
