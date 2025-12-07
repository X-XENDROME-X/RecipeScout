//
//  RecipeViewModel.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file is the ViewModel for managing recipe data using the MVVM architecture pattern and handles API communication for searching and loading recipes

import Swift

import Foundation

import Combine

@MainActor
class RecipeViewModel : ObservableObject {

    @Published var recipes : [Recipe] = []

    @Published var isLoading : Bool = false

    @Published var errorMessage : String?

    @Published var searchQuery : String = ""

    private let APISERVICE = APIService.shared

    init() { Task { await RandomRecipesLoader() } }

    func RandomRecipesLoader() async {
        
            isLoading = true
        
            do {
                recipes = try await APIService.shared.RandomRecipes(count : 10)
                
            } catch {
                
                print("There is an error to load random recipes => \(error)")
                
                recipes = []
            }
        
            isLoading = false
    }

    func RecipesSearch(query : String) async {
        
            isLoading = true
        
            do {
                
                recipes = try await APIService.shared.RecipesSearch(query : query)
                
            } catch {
                
                print("There is an error to search recipes => \(error)")
                
                recipes = []
            }
        
            isLoading = false
        }

    func RecipesByCategory(category : String) async {
        
            isLoading = true
        
            do {
                
                recipes = try await APIService.shared.RecipesByCategory(category : category)
                
            } catch {
                
                print("There is an error to fetch the category recipes => \(error)")
                
                recipes = []
            }
            isLoading = false
    }
    
}




