//
//  Recipe.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file defines the Recipe model and Ingredient model structures which are used throughout the RecipeScout app for showing the recipe data which is being  fetched from the API


import Swift

import Foundation

struct Recipe : Identifiable {

    let id : String

    let name : String

    let category : String

    let cuisine : String

    let imageURL : String?

    let prepTime : String

    let cookTime : String

    let servings : Int

    let difficulty : String

    let ingredients : [Ingredient]

    let instructions : [String]

    let youtubeURL : String?
}

struct Ingredient : Identifiable {

    var id = UUID()

    let name : String

    let quantity : String
}


