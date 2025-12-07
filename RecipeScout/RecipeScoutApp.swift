//
//  RecipeScoutApp.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file is the main swift entry file for RecipeScout and this configures SwiftData for persistent storage

import SwiftUI

import SwiftData

@main
struct RecipeScoutApp : App {

    var sharedModelContainer: ModelContainer = {
        
        let S = Schema( [ MealPlanEntry.self , SavedRecipe.self , ShoppingItem.self ] )
        
        let C = ModelConfiguration( schema : S, isStoredInMemoryOnly : false )
        
        do {
            return try ModelContainer(for : S , configurations : [C])
        }
        catch {
            fatalError("\(error)")
        } }()
    
    var body : some Scene {
        WindowGroup {
            
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}






