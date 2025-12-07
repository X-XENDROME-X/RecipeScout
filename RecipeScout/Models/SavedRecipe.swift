//
//  SavedRecipe.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 11/10/25.
//

// Name: Shorya Raj
// Description: This file is the SwiftData model for storing saved recipes persistently in the database


import Foundation

import SwiftData

@Model
class SavedRecipe {
    
    @Attribute(.unique) var id : String
    
    var name : String
    
    var category : String
    
    var cuisine : String
    
    var imageURL : String?
    
    var dateSaved : Date

    init(from R : Recipe) {
        
        self.id = R.id
        
        self.name = R.name
        
        self.category = R.category
        
        self.cuisine = R.cuisine
        
        self.imageURL = R.imageURL
        
        self.dateSaved = Date()
    }
}


