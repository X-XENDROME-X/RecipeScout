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
        
        // Add time context
        contextParts.append(TimeContextHelper.buildTimeContext())
        
        // Privacy notice - what data you can see
        var privacyNotice = "\nDATA ACCESS PERMISSIONS:"
        
        // User's current data
        if includeSavedRecipes {
            if let savedRecipesContext = getSavedRecipesContext() {
                contextParts.append(savedRecipesContext)
                privacyNotice += "\n✓ You CAN see the user's saved recipes"
            } else {
                privacyNotice += "\n✓ Saved recipes access is enabled, but the user has no saved recipes"
            }
        } else {
            privacyNotice += "\n✗ You CANNOT see saved recipes (user has disabled this data source)"
        }
        
        if includeMealPlan {
            if let mealPlanContext = getMealPlanContext() {
                contextParts.append(mealPlanContext)
                privacyNotice += "\n✓ You CAN see the user's meal plan"
            } else {
                privacyNotice += "\n✓ Meal plan access is enabled, but the user has no planned meals"
            }
        } else {
            privacyNotice += "\n✗ You CANNOT see the meal plan (user has disabled this data source)"
        }
        
        if includeShoppingList {
            if let shoppingListContext = getShoppingListContext() {
                contextParts.append(shoppingListContext)
                privacyNotice += "\n✓ You CAN see the user's shopping list"
            } else {
                privacyNotice += "\n✓ Shopping list access is enabled, but the user has no items"
            }
        } else {
            privacyNotice += "\n✗ You CANNOT see the shopping list (user has disabled this data source)"
        }
        
        privacyNotice += "\n\nIMPORTANT: If you cannot see a data source, do NOT make up information about it. Tell the user you don't have access to that information."
        
        contextParts.append(privacyNotice)
        
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
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            let recipeList = savedRecipes.map { recipe in
                let dateStr = dateFormatter.string(from: recipe.dateSaved)
                var line = "- \(recipe.name)"
                line += " [Cuisine: \(recipe.cuisine), Category: \(recipe.category)]"
                line += " (saved on \(dateStr))"
                return line
            }.joined(separator: "\n")
            
            var summary = """
            USER DATA - SAVED RECIPES:
            The user has \(savedRecipes.count) saved recipe(s) in their collection.
            Here are all their saved recipes:
            \(recipeList)
            """
            
            // Add cuisine preferences
            let cuisineStats = analyzeCuisinePreferences(savedRecipes)
            if !cuisineStats.isEmpty {
                summary += "\n\nThe user's favorite cuisines (based on saved recipes): \(cuisineStats)"
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
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            
            var context = """
            USER DATA - SHOPPING LIST:
            The user has \(items.count) total item(s) in their shopping list.
            - \(uncheckedItems.count) item(s) still need to be purchased (unchecked ☐)
            - \(checkedItems.count) item(s) already obtained (checked off ☑)
            """
            
            if !uncheckedItems.isEmpty {
                let itemList = uncheckedItems.map { item in
                    var line = "☐ \(item.name)"
                    if !item.quantity.isEmpty {
                        line += " - Quantity: \(item.quantity)"
                    }
                    if let recipeName = item.sourceRecipeName, !recipeName.isEmpty {
                        line += " (needed for recipe: '\(recipeName)')"
                    }
                    if let plannedDate = item.plannedDate {
                        let dateStr = dateFormatter.string(from: plannedDate)
                        line += " [planned for: \(dateStr)]"
                    }
                    line += " [STATUS: NOT YET PURCHASED]"
                    return line
                }.joined(separator: "\n")
                
                context += "\n\nItems still needed (unchecked):\n\(itemList)"
            }
            
            if !checkedItems.isEmpty {
                let checkedList = checkedItems.map { item in
                    var line = "☑ \(item.name)"
                    if !item.quantity.isEmpty {
                        line += " - Quantity: \(item.quantity)"
                    }
                    if let recipeName = item.sourceRecipeName, !recipeName.isEmpty {
                        line += " (was for recipe: '\(recipeName)')"
                    }
                    if let plannedDate = item.plannedDate {
                        let dateStr = dateFormatter.string(from: plannedDate)
                        line += " [was planned for: \(dateStr)]"
                    }
                    line += " [STATUS: ALREADY PURCHASED/OBTAINED]"
                    return line
                }.joined(separator: "\n")
                
                context += "\n\nItems already obtained (checked off):\n\(checkedList)"
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
                return "USER DATA: The user has no upcoming meals planned for the next 7 days."
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .full
            dateFormatter.timeStyle = .none
            
            let mealList = entries.map { entry in
                let dateStr = dateFormatter.string(from: entry.date)
                let mealTypeCapitalized = entry.mealType.rawValue.capitalized
                return "- \(mealTypeCapitalized): '\(entry.recipeName)' on \(dateStr)"
            }.joined(separator: "\n")
            
            // Group by meal type to show distribution
            let mealTypeCounts = Dictionary(grouping: entries, by: { $0.mealType })
                .mapValues { $0.count }
                .sorted { $0.key.rawValue < $1.key.rawValue }
            
            let mealTypeBreakdown = mealTypeCounts.map { type, count in
                "\(type.rawValue.capitalized): \(count)"
            }.joined(separator: ", ")
            
            let context = """
            USER DATA - MEAL PLAN:
            The user has \(entries.count) meal(s) planned for the next 7 days.
            Breakdown by meal type: \(mealTypeBreakdown)
            
            Scheduled meals:
            \(mealList)
            """
            
            return context
            
        } catch {
            return nil
        }
    }
    
    func getMealPlanEntries() -> [MealPlanEntry] {
        do {
            // Match the logic from getMealPlanContext() - only next 7 days
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
