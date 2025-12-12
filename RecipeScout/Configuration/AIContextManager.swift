//
//  AIContextManager.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Manages user context data for AI assistant, aggregating data from SwiftData models in a privacy-aware manner

import Foundation
import SwiftData

@MainActor
final class AIContextManager {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Context Building
    
    /// Build complete context string for AI assistant
    func buildContext(includeShoppingList: Bool = true, includeSavedRecipes: Bool = true, includeMealPlan: Bool = true) -> String {
        var contextParts: [String] = []
        
        // App overview
        contextParts.append("""
        You are a helpful AI assistant for RecipeScout, a recipe and meal planning app.
        You help users with:
        - Finding and understanding recipes
        - Meal planning and preparation advice
        - Shopping list management
        - Food and cooking questions
        - Nutritional information
        - Ingredient substitutions
        """)
        
        // User's current data
        if includeSavedRecipes {
            if let savedRecipesContext = getSavedRecipesContext() {
                contextParts.append(savedRecipesContext)
            }
        }
        
        if includeMealPlan {
            if let mealPlanContext = getMealPlanContext() {
                contextParts.append(mealPlanContext)
            }
        }
        
        if includeShoppingList {
            if let shoppingListContext = getShoppingListContext() {
                contextParts.append(shoppingListContext)
            }
        }
        
        return contextParts.joined(separator: "\n\n")
    }
    
    // MARK: - Saved Recipes Context
    
    func getSavedRecipesContext() -> String? {
        do {
            let descriptor = FetchDescriptor<SavedRecipe>(
                sortBy: [SortDescriptor(\.dateSaved, order: .reverse)]
            )
            let savedRecipes = try modelContext.fetch(descriptor)
            
            guard !savedRecipes.isEmpty else {
                return "USER DATA: The user has not saved any recipes yet."
            }
            
            let recipeList = savedRecipes.prefix(10).map { recipe in
                "- \(recipe.name) (\(recipe.cuisine) - \(recipe.category))"
            }.joined(separator: "\n")
            
            let summary = """
            USER DATA - SAVED RECIPES:
            The user has \(savedRecipes.count) saved recipe(s). Here are their recent favorites:
            \(recipeList)
            """
            
            // Add cuisine preferences
            let cuisineStats = analyzeCuisinePreferences(savedRecipes)
            if !cuisineStats.isEmpty {
                return summary + "\n\nFavorite cuisines: \(cuisineStats)"
            }
            
            return summary
            
        } catch {
            return nil
        }
    }
    
    func getSavedRecipes() -> [SavedRecipe] {
        do {
            let descriptor = FetchDescriptor<SavedRecipe>(
                sortBy: [SortDescriptor(\.dateSaved, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    // MARK: - Shopping List Context
    
    func getShoppingListContext() -> String? {
        do {
            let descriptor = FetchDescriptor<ShoppingItem>(
                sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
            )
            let items = try modelContext.fetch(descriptor)
            
            guard !items.isEmpty else {
                return "USER DATA: The user's shopping list is currently empty."
            }
            
            let uncheckedItems = items.filter { !$0.isChecked }
            let checkedItems = items.filter { $0.isChecked }
            
            var context = """
            USER DATA - SHOPPING LIST:
            The user has \(items.count) item(s) in their shopping list.
            """
            
            if !uncheckedItems.isEmpty {
                let itemList = uncheckedItems.prefix(15).map { item in
                    var line = "- \(item.name) (\(item.quantity))"
                    if let recipeName = item.sourceRecipeName {
                        line += " [for \(recipeName)]"
                    }
                    return line
                }.joined(separator: "\n")
                
                context += "\n\nItems to buy:\n\(itemList)"
            }
            
            if !checkedItems.isEmpty {
                context += "\n\n\(checkedItems.count) item(s) already checked off."
            }
            
            return context
            
        } catch {
            return nil
        }
    }
    
    func getShoppingItems() -> [ShoppingItem] {
        do {
            let descriptor = FetchDescriptor<ShoppingItem>(
                sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    // MARK: - Meal Plan Context
    
    func getMealPlanContext() -> String? {
        do {
            let now = Date()
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfToday)!
            
            let descriptor = FetchDescriptor<MealPlanEntry>(
                predicate: #Predicate { entry in
                    entry.date >= startOfToday && entry.date <= endOfWeek
                },
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            
            let entries = try modelContext.fetch(descriptor)
            
            guard !entries.isEmpty else {
                return "USER DATA: The user has no upcoming meals planned."
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            let mealList = entries.map { entry in
                let dateStr = dateFormatter.string(from: entry.date)
                return "- \(entry.recipeName) (\(entry.mealType.rawValue.capitalized) on \(dateStr))"
            }.joined(separator: "\n")
            
            let context = """
            USER DATA - MEAL PLAN:
            The user has \(entries.count) meal(s) planned for the next 7 days:
            \(mealList)
            """
            
            return context
            
        } catch {
            return nil
        }
    }
    
    func getMealPlanEntries() -> [MealPlanEntry] {
        do {
            let descriptor = FetchDescriptor<MealPlanEntry>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    // MARK: - Analytics
    
    private func analyzeCuisinePreferences(_ recipes: [SavedRecipe]) -> String {
        let cuisineCounts = Dictionary(grouping: recipes, by: { $0.cuisine })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let topCuisines = cuisineCounts.prefix(3).map { $0.key }
        return topCuisines.joined(separator: ", ")
    }
    
    func getUserStatistics() -> UserStatistics {
        let savedRecipes = getSavedRecipes()
        let shoppingItems = getShoppingItems()
        let mealPlanEntries = getMealPlanEntries()
        
        return UserStatistics(
            savedRecipeCount: savedRecipes.count,
            shoppingItemCount: shoppingItems.count,
            upcomingMealsCount: mealPlanEntries.count,
            favoriteCuisines: analyzeCuisinePreferences(savedRecipes).components(separatedBy: ", ")
        )
    }
}

// MARK: - Supporting Types

struct UserStatistics {
    let savedRecipeCount: Int
    let shoppingItemCount: Int
    let upcomingMealsCount: Int
    let favoriteCuisines: [String]
    
    var hasAnyData: Bool {
        return savedRecipeCount > 0 || shoppingItemCount > 0 || upcomingMealsCount > 0
    }
}
