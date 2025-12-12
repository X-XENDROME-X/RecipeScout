//
//  ClaudePromptBuilder.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Builds intelligent prompts for Claude AI with context injection and query classification

import Foundation

struct ClaudePromptBuilder {
    
    // MARK: - System Prompt
    
    static func buildSystemPrompt(userContext: String) -> String {
        return """
        You are RecipeScout Assistant, a friendly and knowledgeable AI helper built into the RecipeScout app.
        
        YOUR ROLE:
        - Help users discover and understand recipes
        - Provide cooking tips, techniques, and advice
        - Answer questions about food, nutrition, and meal planning
        - Assist with ingredient substitutions and dietary adaptations
        - Help users make the most of their saved recipes, meal plans, and shopping lists
        
        YOUR PERSONALITY:
        - Friendly, encouraging, and enthusiastic about food
        - Clear and concise in explanations
        - Supportive of all skill levels from beginners to experts
        - Culturally aware and respectful of different cuisines
        
        GUIDELINES:
        - Keep responses focused and helpful
        - Use conversational language, not overly formal
        - When suggesting recipes, consider what the user has saved
        - If the user has items on their shopping list, you can reference them
        - Provide practical, actionable advice
        - If you don't know something, be honest about it
        - Use emojis occasionally to be friendly (but don't overdo it)
        
        \(userContext)
        
        Remember: You're here to make cooking and meal planning easier and more enjoyable!
        """
    }
    
    // MARK: - Query Classification
    
    enum QueryType {
        case recipeSearch
        case cookingAdvice
        case nutritionQuestion
        case ingredientSubstitution
        case mealPlanningHelp
        case shoppingListHelp
        case appNavigation
        case general
    }
    
    static func classifyQuery(_ query: String) -> QueryType {
        let lowercased = query.lowercased()
        
        // Recipe search patterns
        if lowercased.contains("recipe for") ||
           lowercased.contains("how to make") ||
           lowercased.contains("how do i cook") ||
           lowercased.contains("find recipe") {
            return .recipeSearch
        }
        
        // Cooking advice patterns
        if lowercased.contains("how to cook") ||
           lowercased.contains("cooking technique") ||
           lowercased.contains("what temperature") ||
           lowercased.contains("how long") {
            return .cookingAdvice
        }
        
        // Nutrition patterns
        if lowercased.contains("calorie") ||
           lowercased.contains("nutrition") ||
           lowercased.contains("healthy") ||
           lowercased.contains("protein") ||
           lowercased.contains("vitamin") {
            return .nutritionQuestion
        }
        
        // Substitution patterns
        if lowercased.contains("substitute") ||
           lowercased.contains("instead of") ||
           lowercased.contains("replace") ||
           lowercased.contains("alternative to") {
            return .ingredientSubstitution
        }
        
        // Meal planning patterns
        if lowercased.contains("meal plan") ||
           lowercased.contains("what should i cook") ||
           lowercased.contains("dinner idea") ||
           lowercased.contains("lunch suggestion") {
            return .mealPlanningHelp
        }
        
        // Shopping list patterns
        if lowercased.contains("shopping list") ||
           lowercased.contains("ingredients i need") ||
           lowercased.contains("what to buy") {
            return .shoppingListHelp
        }
        
        // App navigation patterns
        if lowercased.contains("how do i") ||
           lowercased.contains("where can i find") ||
           lowercased.contains("how to use") {
            return .appNavigation
        }
        
        return .general
    }
    
    // MARK: - Suggested Queries
    
    static func getSuggestedQueries(hasData: Bool, statistics: UserStatistics) -> [String] {
        var suggestions: [String] = []
        
        if statistics.savedRecipeCount > 0 {
            suggestions.append("What can I make with my saved recipes?")
            suggestions.append("Suggest a meal plan based on my favorites")
        } else {
            suggestions.append("What are some easy dinner ideas?")
            suggestions.append("How do I get started with meal planning?")
        }
        
        if statistics.shoppingItemCount > 0 {
            suggestions.append("What recipes use items from my shopping list?")
        } else {
            suggestions.append("Help me create a shopping list for the week")
        }
        
        if statistics.upcomingMealsCount > 0 {
            suggestions.append("Review my upcoming meal plan")
        }
        
        // Always include general suggestions
        suggestions.append("What's a good substitute for eggs?")
        suggestions.append("How do I store fresh herbs?")
        suggestions.append("What are some quick breakfast ideas?")
        
        return Array(suggestions.prefix(4))
    }
    
    // MARK: - Welcome Message
    
    static func getWelcomeMessage(statistics: UserStatistics) -> String {
        if statistics.hasAnyData {
            var message = "👋 Hi! I'm your RecipeScout Assistant. "
            
            if statistics.savedRecipeCount > 0 {
                message += "I see you have \(statistics.savedRecipeCount) saved recipe\(statistics.savedRecipeCount == 1 ? "" : "s"). "
            }
            
            if statistics.shoppingItemCount > 0 {
                message += "You have \(statistics.shoppingItemCount) item\(statistics.shoppingItemCount == 1 ? "" : "s") on your shopping list. "
            }
            
            if statistics.upcomingMealsCount > 0 {
                message += "And \(statistics.upcomingMealsCount) meal\(statistics.upcomingMealsCount == 1 ? "" : "s") planned! "
            }
            
            message += "\n\nI can help you with recipes, cooking tips, meal planning, and more. What would you like to know?"
            
            return message
        } else {
            return """
            👋 Hi! I'm your RecipeScout Assistant!
            
            I'm here to help you with:
            🍳 Recipe ideas and cooking tips
            🥗 Meal planning advice
            🛒 Shopping list suggestions
            🔄 Ingredient substitutions
            📚 Food and nutrition questions
            
            Start exploring recipes in the app, and I'll be able to give you personalized suggestions based on what you save!
            
            What can I help you with today?
            """
        }
    }
}
