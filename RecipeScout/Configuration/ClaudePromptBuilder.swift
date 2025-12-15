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
        You are Sage, a friendly and knowledgeable AI helper built into the RecipeScout app.
        
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
    
    static func getSuggestedQueries(hasData: Bool, statistics: UserStatistics, includeRecipes: Bool, includeShoppingList: Bool, includeMealPlan: Bool) -> [String] {
        // Get time-aware suggestions first
        var suggestions = TimeContextHelper.getTimeBasedSuggestions(
            hasSavedRecipes: statistics.savedRecipeCount > 0 && includeRecipes,
            hasShoppingList: statistics.shoppingItemCount > 0 && includeShoppingList,
            hasMealPlan: statistics.upcomingMealsCount > 0 && includeMealPlan
        )
        
        // Add data-specific suggestions if not already included
        if statistics.savedRecipeCount > 0 && includeRecipes {
            if !suggestions.contains(where: { $0.contains("saved recipes") }) {
                suggestions.append("What can I make with my saved recipes?")
            }
        }
        
        if statistics.shoppingItemCount > 0 && includeShoppingList {
            if !suggestions.contains(where: { $0.contains("shopping list") }) {
                suggestions.append("What recipes use items from my shopping list?")
            }
        }
        
        if statistics.upcomingMealsCount > 0 && includeMealPlan {
            if !suggestions.contains(where: { $0.contains("meal plan") }) {
                suggestions.append("Review my upcoming meal plan")
            }
        }
        
        // Always include at least one general suggestion
        if !suggestions.contains(where: { $0.contains("substitute") || $0.contains("store") }) {
            suggestions.append("What's a good substitute for eggs?")
        }
        
        return Array(suggestions.prefix(4))
    }
    
    // MARK: - Welcome Message
    
    static func getWelcomeMessage(statistics: UserStatistics, includeRecipes: Bool, includeShoppingList: Bool, includeMealPlan: Bool) -> String {
        // Check if we have any data that we're allowed to see
        let hasVisibleRecipes = statistics.savedRecipeCount > 0 && includeRecipes
        let hasVisibleShopping = statistics.shoppingItemCount > 0 && includeShoppingList
        let hasVisibleMeals = statistics.upcomingMealsCount > 0 && includeMealPlan
        let hasAnyVisibleData = hasVisibleRecipes || hasVisibleShopping || hasVisibleMeals
        
        // Get time-aware greeting
        let timeGreeting = TimeContextHelper.getTimeAwareGreeting()
        
        if hasAnyVisibleData {
            var message = "👋 \(timeGreeting)\n\nI'm Sage, your cooking companion. "
            
            if hasVisibleRecipes {
                message += "I see you have \(statistics.savedRecipeCount) saved recipe\(statistics.savedRecipeCount == 1 ? "" : "s"). "
            }
            
            if hasVisibleShopping {
                message += "You have \(statistics.shoppingItemCount) item\(statistics.shoppingItemCount == 1 ? "" : "s") on your shopping list. "
            }
            
            if hasVisibleMeals {
                message += "And \(statistics.upcomingMealsCount) meal\(statistics.upcomingMealsCount == 1 ? "" : "s") planned! "
            }
            
            // Add time-specific suggestion
            let currentMeal = TimeContextHelper.getCurrentMealTime()
            if currentMeal == .dinner {
                message += "\n\nWhat would you like to cook for dinner tonight?"
            } else if currentMeal == .breakfast {
                message += "\n\nWhat sounds good for breakfast?"
            } else if currentMeal == .lunch {
                message += "\n\nWhat are you in the mood for lunch?"
            } else {
                message += "\n\nWhat can I help you with?"
            }
            
            return message
        } else {
            let greeting = TimeContextHelper.getGreeting()
            return """
            👋 \(greeting)! I'm Sage, your cooking companion!
            
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
