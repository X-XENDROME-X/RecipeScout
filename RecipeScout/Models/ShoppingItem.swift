//
//  ShoppingItem.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 11/10/25.
//

// Name: Shorya Raj
// Description: This file defines the ShoppingItem model for storing shopping list items with SwiftData persistence

import Swift

import Foundation

import SwiftData

@Model
class ShoppingItem {
    
    @Attribute(.unique) var id : UUID
    
    var name : String
    
    var quantity : String
    
    var isChecked : Bool
    
    var sourceRecipeID : String?
    
    var sourceRecipeName : String?
    
    var plannedDate : Date?
    
    var dateAdded : Date

    init( name N : String , quantity QTY : String , sourceRecipeID SRCREC : String? = nil , sourceRecipeName SRCRECNAM : String? = nil , plannedDate PLANND : Date? = nil ) {
        
        self.id = UUID()
        
        self.name = N
        
        self.quantity = QTY
        
        self.isChecked = false
        
        self.sourceRecipeID = SRCREC
        
        self.sourceRecipeName = SRCRECNAM
        
        self.plannedDate = PLANND
        
        self.dateAdded = Date()
    }

}


