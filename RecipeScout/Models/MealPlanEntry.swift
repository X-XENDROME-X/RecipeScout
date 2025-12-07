//
//  MealPlanEntry.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 11/10/25.
//

// Name: Shorya Raj
// Description: This file is the the model for the meal planning entries , storing scheduled recipes for specific dates and meal types using SwiftData for persistent storage


import Swift

import Foundation

import SwiftData

enum MealType : String , Codable , CaseIterable {
    
    case breakfast
    
    case lunch
    
    case dinner
    
    case snack
}

@Model
class MealPlanEntry {
    
    @Attribute(.unique) var id : UUID
    
    var date : Date
    
    var mealType : MealType

    var recipeID : String
    
    var recipeName : String
    
    var imageURL : String?

    init(D : Date , MEALTYPE : MealType , from SAVE : SavedRecipe) {
        
        self.id = UUID()
        
        self.date = D
        
        self.mealType = MEALTYPE
        
        self.recipeID = SAVE.id
        
        self.recipeName = SAVE.name
        
        self.imageURL = SAVE.imageURL
    }
}


