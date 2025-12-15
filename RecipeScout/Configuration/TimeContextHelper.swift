//
//  TimeContextHelper.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/14/25.
//

// Name: Shorya Raj
// Description: Provides time-aware context for AI assistant to make meal suggestions based on current time and day

import Foundation

struct TimeContextHelper {
    
    // MARK: - Meal Time Periods
    
    enum MealTime: String {
        case breakfast = "Breakfast"
        case brunch = "Brunch"
        case lunch = "Lunch"
        case snack = "Snack"
        case dinner = "Dinner"
        case lateNight = "Late Night Snack"
    }
    
    enum DayType {
        case weekday
        case weekend
    }
    
    // MARK: - Current Time Context
    
    /// Get the current meal time based on hour of day
    static func getCurrentMealTime() -> MealTime {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<10:
            return .breakfast
        case 10..<12:
            return .brunch
        case 12..<15:
            return .lunch
        case 15..<17:
            return .snack
        case 17..<21:
            return .dinner
        case 21..<24, 0..<5:
            return .lateNight
        default:
            return .lunch
        }
    }
    
    /// Get the next meal time
    static func getNextMealTime() -> MealTime {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<5:
            return .breakfast
        case 5..<10:
            return .lunch
        case 10..<12:
            return .lunch
        case 12..<15:
            return .dinner
        case 15..<17:
            return .dinner
        case 17..<24:
            return .breakfast // Next day
        default:
            return .lunch
        }
    }
    
    /// Check if it's currently a weekend
    static func isWeekend() -> Bool {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7 // Sunday or Saturday
    }
    
    /// Get the day type
    static func getDayType() -> DayType {
        return isWeekend() ? .weekend : .weekday
    }
    
    /// Get time-of-day greeting
    static func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hello"
        }
    }
    
    // MARK: - Context String Generation
    
    /// Build complete time context for AI
    static func buildTimeContext() -> String {
        let now = Date()
        let calendar = Calendar.current
        
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let weekday = calendar.component(.weekday, from: now)
        
        let weekdayName = calendar.weekdaySymbols[weekday - 1]
        let currentMeal = getCurrentMealTime()
        let nextMeal = getNextMealTime()
        let dayType = getDayType()
        
        let timeString = String(format: "%02d:%02d", hour, minute)
        
        var context = """
        CURRENT TIME CONTEXT:
        - Current time: \(timeString) (\(hour >= 12 ? "PM" : "AM"))
        - Day: \(weekdayName) (\(dayType == .weekend ? "Weekend" : "Weekday"))
        - Current meal period: \(currentMeal.rawValue)
        - Next meal: \(nextMeal.rawValue)
        """
        
        // Add context-specific notes
        if currentMeal == .breakfast {
            context += "\n- Users typically want quick, energizing breakfast ideas now"
        } else if currentMeal == .brunch && dayType == .weekend {
            context += "\n- Weekend brunch time - users may want more elaborate, leisurely recipes"
        } else if currentMeal == .lunch && dayType == .weekday {
            context += "\n- Weekday lunch - users likely want quick, easy recipes"
        } else if currentMeal == .lunch && dayType == .weekend {
            context += "\n- Weekend lunch - users have more time for cooking"
        } else if currentMeal == .snack {
            context += "\n- Afternoon snack time - users want light, quick options"
        } else if currentMeal == .dinner && dayType == .weekday {
            context += "\n- Weekday dinner - balance convenience with nutrition"
        } else if currentMeal == .dinner && dayType == .weekend {
            context += "\n- Weekend dinner - users may want special or longer recipes"
        } else if currentMeal == .lateNight {
            context += "\n- Late night - suggest light, easy options if asked"
        }
        
        context += "\n\nWhen suggesting recipes or meal ideas, prioritize options appropriate for \(currentMeal.rawValue)."
        
        return context
    }
    
    /// Get time-appropriate suggested queries
    static func getTimeBasedSuggestions(hasSavedRecipes: Bool, hasShoppingList: Bool, hasMealPlan: Bool) -> [String] {
        let currentMeal = getCurrentMealTime()
        let dayType = getDayType()
        var suggestions: [String] = []
        
        // Meal-specific suggestions
        switch currentMeal {
        case .breakfast:
            suggestions.append("What's a quick breakfast I can make?")
            suggestions.append("Suggest a healthy breakfast")
            if dayType == .weekend {
                suggestions.append("Give me a special weekend breakfast idea")
            }
            
        case .brunch:
            suggestions.append("What's a good brunch recipe?")
            if dayType == .weekend {
                suggestions.append("Suggest an impressive brunch dish")
            }
            
        case .lunch:
            if dayType == .weekday {
                suggestions.append("What's a quick lunch idea?")
                suggestions.append("Suggest a lunch I can make in 20 minutes")
            } else {
                suggestions.append("What should I make for lunch?")
                suggestions.append("Suggest a nice weekend lunch")
            }
            
        case .snack:
            suggestions.append("What's a healthy snack I can make?")
            suggestions.append("Suggest a quick afternoon pick-me-up")
            
        case .dinner:
            suggestions.append("What should I cook for dinner tonight?")
            if dayType == .weekday {
                suggestions.append("Give me an easy weeknight dinner idea")
            } else {
                suggestions.append("Suggest a special dinner recipe")
            }
            if hasMealPlan {
                suggestions.append("What's on my meal plan for tonight?")
            }
            
        case .lateNight:
            suggestions.append("What's a light late-night snack?")
            suggestions.append("Suggest something easy to make now")
        }
        
        // Add data-specific suggestions if available
        if hasSavedRecipes {
            suggestions.append("What can I make from my saved recipes?")
        }
        
        if hasShoppingList {
            suggestions.append("What recipes use my shopping list items?")
        }
        
        return Array(suggestions.prefix(4))
    }
    
    /// Get time-appropriate greeting message
    static func getTimeAwareGreeting() -> String {
        let greeting = getGreeting()
        let currentMeal = getCurrentMealTime()
        let dayType = getDayType()
        
        var message = "\(greeting)! "
        
        if currentMeal == .breakfast {
            message += "Ready to start your day with a great breakfast?"
        } else if currentMeal == .brunch && dayType == .weekend {
            message += "Perfect time for a relaxing brunch!"
        } else if currentMeal == .lunch {
            message += "What are you in the mood for lunch?"
        } else if currentMeal == .snack {
            message += "Looking for an afternoon snack?"
        } else if currentMeal == .dinner {
            message += "What would you like for dinner tonight?"
        } else if currentMeal == .lateNight {
            message += "Craving a late-night snack?"
        }
        
        return message
    }
}
