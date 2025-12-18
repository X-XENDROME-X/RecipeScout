//
//  SavedRecipesView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file displays the saved recipes view where users can view , manage , and plan their favorite recipes stored in SwiftData

import SwiftUI

import SwiftData

struct SavedRecipesView : View {
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(sort : \SavedRecipe.dateSaved , order : .reverse)
    
    private var savedRecipes : [SavedRecipe]
    
    @State private var MealPlannerDisplay=false
    
    @State private var PlannedRecipe : SavedRecipe?
    
    @State private var showTabView = false
    
    struct SavedRecipeRow : View {
        
        let saved : SavedRecipe
        
        var body : some View {
            
            HStack(spacing : 12) {
                
                if let URLSTR = saved.imageURL , let url = URL(string : URLSTR) {
                    
                    AsyncImage(url : url) { PH in
                        
                        switch PH {
                            
                        case .empty:
                            ProgressView()
                                .frame(width : 70 , height : 70)
                            
                        case .success(let IMG):
                            IMG
                                .resizable()
                                .scaledToFill()
                                .frame(width : 70 , height : 70)
                                .clipped()
                                .cornerRadius(10)
                            
                        case .failure :
                            Image(systemName : "photo")
                                .frame(width : 70 , height : 70)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                }
                
                else {
                    Image(systemName : "photo")
                        .frame(width : 70 , height : 70)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
                
                VStack(alignment : .leading , spacing : 4) {
                    
                    Text(saved.name)
                        .font(.headline)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                    
                    HStack(spacing : 6) {
                        Text(saved.category)
                        Text("•")
                        Text(saved.cuisine)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text("Saved on \(saved.dateSaved.formatted(date : .abbreviated , time : .shortened) )")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical , 6)
        }
    }
    
    struct SavedRecipeDetailLoader : View {
        
        let saved : SavedRecipe
        
        @State private var loadedRecipe : Recipe?
        
        @State private var isLoading = true
        
        @State private var errorMessage : String?
        
        var body : some View {
            
            Group {
                
                if let R = loadedRecipe {
                    RecipeDetailView(recipe : R)
                }
                else if isLoading {
                    VStack(spacing : 16) {
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.orange)
                        
                        Text("Loading the recipes....")
                            .foregroundColor(.gray)
                    }
                }
                
                else {
                    VStack(spacing : 12) {
                        
                        Image(systemName : "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        
                        Text(errorMessage ?? "Unable to load recipe(s)")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .task { await RecipeLoad() }
        }
        
        private func RecipeLoad() async {
            
            do {
                
                let R = try await APIService.shared.RecipesSearch(query : saved.name)
                
                if let F = R.first {
                    
                    loadedRecipe = F
                    
                }
                
                else { errorMessage = "No recipe details found from the API" }
            }
            
            catch { errorMessage = "There is an error fetching the recipe details => \(error.localizedDescription)" }
            
            isLoading = false
        }
    }
    
    var body : some View {
        
        VStack {
            
            if savedRecipes.isEmpty {
                
                Spacer()
                
                Image(systemName: "heart.slash")
                    .font(.system(size : 60))
                    .foregroundColor(.orange)
                
                Text("No saved recipes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("Tap the the heart button on any recipe to add it here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal , 40)
                
                Spacer()
                
            }
            
            else {
                
                List {
                    ForEach(savedRecipes) { SAVE in
                        
                        NavigationLink( destination : SavedRecipeDetailLoader(saved : SAVE) ) {
                            SavedRecipeRow(saved: SAVE)
                        }
                        
                        .swipeActions(edge : .leading) {
                            Button {
                                PlannedRecipe = SAVE
                                MealPlannerDisplay=true
                            } label : {
                                Label("Plan" , systemImage : "calendar")
                            }
                            .tint(.orange)
                        }
                        
                        .swipeActions(edge : .trailing) {
                            Button(role : .destructive) { SingleDEL(saved : SAVE)
                            } label : {
                                Label("Delete" , systemImage : "trash")
                            }
                            .tint(.red)
                        }
                    }
                    .onDelete(perform : DELSAVED)
                }
                .listStyle(.plain)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden , for : .tabBar)
        .toolbarBackground(colorScheme == .light ? Color.white : Color(UIColor.systemBackground) , for : .navigationBar)
        .toolbarBackground(.visible , for : .navigationBar)
        .background(Color(UIColor.systemBackground))
        .toolbar {
            
            ToolbarItem(placement : .navigationBarLeading) {
                
                Button(action : { dismiss() }) {
                    
                    HStack(spacing : 1) {
                        Image(systemName : "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.orange)
                }
            }
            
            ToolbarItem(placement : .principal) {
                
                HStack(spacing : 8) {
                    
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width : 32 , height : 32)
                    
                    Text("My Saved Recipes")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        
        .sheet(isPresented : $MealPlannerDisplay) {
            if let PlannedRecipe {
                MealPlannerView(showTabView: $showTabView, PreselectedRECID : PlannedRecipe.id)
            }
        }
    }
    
    private func DELSAVED(at OFFS : IndexSet) {
        
        for i in OFFS {
            
            let SAVE=savedRecipes[i]
            modelContext.delete(SAVE)
            
        }
    }
    
    private func SingleDEL(saved : SavedRecipe) {
        modelContext.delete(saved)
    }
}
