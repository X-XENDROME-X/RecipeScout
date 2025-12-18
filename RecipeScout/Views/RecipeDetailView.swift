//
//  RecipeDetailView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//


// Name: Shorya Raj
// Description: This file displays detailed information about a recipe which is including ingredients and instructions , and it allows users to save recipes and add them to meal plans and add ingredients to shopping lists

import SwiftUI

import SwiftData

struct RecipeDetailView : View {
    
    let recipe : Recipe
    
    @State private var showAlert=false
    
    @State private var isSaved=false
    
    @State private var MealPlannerDisplay=false
    
    @State private var showTabView = false
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.modelContext) private var modelContext
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var alertMessage=""
    
    private var STEPS : [String] {
        recipe.instructions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func SavedStateUpdated() {
        
        let recipeID = recipe.id
        
        let PRED = #Predicate<SavedRecipe> { S in
            S.id==recipeID
        }
        
        let DESC = FetchDescriptor<SavedRecipe>(predicate : PRED)
        
        if let RESULTS = try? modelContext.fetch(DESC) {
            isSaved = !RESULTS.isEmpty
        }
        else {
            
            isSaved = false
        }
    }
    
    private func CorFSavedRecipe() -> SavedRecipe? {
        
        let recipeID = recipe.id
        
        let PRED = #Predicate<SavedRecipe> { saved in
            saved.id == recipeID
        }
        
        let DESC = FetchDescriptor<SavedRecipe>(predicate : PRED)
        
        if let results = try? modelContext.fetch(DESC) , let EXISTING = results.first {
            
            return EXISTING
        }
        else {
            
            let SAV = SavedRecipe(from : recipe)
            
            modelContext.insert(SAV)
            
            return SAV
        }
    }
    
    private func MealPlanner() {
        
        if let _ = CorFSavedRecipe() {
            
            isSaved = true
            
            MealPlannerDisplay = true
        }
        
        else {
            
            showAlert = true
            
            alertMessage = "Unable to open meal planner for this recipe"
            
        }
    }
    
    private func IngredientsAdder() {
        
        let ingredients = recipe.ingredients
        
        guard !ingredients.isEmpty else {
            
            showAlert = true
            
            alertMessage = "This recipe has no ingredients to add to your Shopping List"
            return
        }
        
        let DESC = FetchDescriptor<ShoppingItem>()
        
        let EXSTItems = (try? modelContext.fetch(DESC)) ?? []
        
        var addedCount = 0
        
        for ingredient in ingredients {
            
            let RName = ingredient.name.trimmingCharacters(in : .whitespacesAndNewlines)
            
            let RQTY = ingredient.quantity.trimmingCharacters(in : .whitespacesAndNewlines)
            
            guard !RName.isEmpty else { continue }
            
            if let EXISTING = EXSTItems.first(where : { $0.name.caseInsensitiveCompare(RName) == .orderedSame && $0.sourceRecipeID == recipe.id } ) {
                
                if !RQTY.isEmpty && !EXISTING.quantity.contains(RQTY) {
                    EXISTING.quantity += " + \(RQTY)"
                }
            } else {
                
                let item = ShoppingItem(
                    name : RName ,
                    quantity : RQTY.isEmpty ? "1" : RQTY ,
                    sourceRecipeID : recipe.id ,
                    sourceRecipeName : recipe.name ,
                    plannedDate: nil
                )
                
                modelContext.insert(item)
                
                addedCount+=1
            }
        }
        
        do {
            try modelContext.save()
        }
        catch {
            
            showAlert = true
            
            alertMessage = "Failed to save items to Shopping List: \(error.localizedDescription)"
            
            return
        }
        
        if addedCount == 0 {
            alertMessage = "All of this recipe's ingredients are already in your Shopping List"
        }
        
        else {
            alertMessage = "Added \(addedCount) ingredient(s) to your Shopping List"
        }
        
        showAlert=true
    }
    
    
    private func Favourite() {
        
        let recipeID = recipe.id
        
        if isSaved {
            
            alertMessage = "Removed from Saved Recipes"
            
            let PRED = #Predicate<SavedRecipe> { saved in
                saved.id == recipeID
            }
            
            let DESC = FetchDescriptor<SavedRecipe>(predicate : PRED)
            
            if let results = try? modelContext.fetch(DESC) {
                
                for saved in results { modelContext.delete(saved) }
            }
            
            isSaved = false
        }
        
        else {
            
            alertMessage = "Added to Saved Recipes"
            
            let saved = SavedRecipe(from : recipe)
            
            modelContext.insert(saved)
            
            isSaved = true
        }
        
        SavedStateUpdated()
        
        showAlert = true
    }
    
    var body : some View {
        
        ZStack(alignment: .top) {
            
            ScrollView {
                
                VStack(spacing : 0) {
                    
                    HeaderImageView(imageURL : recipe.imageURL , height : 300)
                        .frame(height: 300)
                    
                    VStack(spacing : 25) {
                        
                        VStack(spacing : 12) {
                            
                            Text(recipe.name)
                                .font(.system(size : 28 , weight : .bold))
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            HStack(spacing : 12) {
                                
                                HStack(spacing : 4) {
                                    
                                    Image(systemName : "fork.knife.circle.fill").foregroundColor(.orange)
                                    Text(recipe.category).foregroundColor(.secondary)
                                    
                                }
                                
                                Text("|").foregroundColor(.gray.opacity(0.5))
                                
                                HStack(spacing : 4) {
                                    
                                    Image(systemName : "globe").foregroundColor(.orange)
                                    
                                    Text(recipe.cuisine).foregroundColor(.secondary)
                                    
                                }
                                
                                Text("|").foregroundColor(.gray.opacity(0.5))
                                
                                HStack(spacing : 4) {
                                    
                                    Image(systemName : "list.bullet").foregroundColor(.orange)
                                    
                                    Text("\(recipe.ingredients.count) Ingredients").foregroundColor(.secondary)
                                    
                                }
                            }
                            .font(.caption)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        }
                        
                        HStack(spacing : 15) {
                            
                            Button(action : MealPlanner) {
                                
                                Label("Meal Plan" , systemImage : "calendar")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .padding()
                                    .frame(maxWidth : .infinity)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                
                            }
                            
                            Button(action : IngredientsAdder) {
                                
                                Label("Add to List" , systemImage : "cart.fill")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .padding()
                                    .frame(maxWidth : .infinity)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(12)
                                
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment : .leading , spacing : 15) {
                            
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .frame(maxWidth : .infinity , alignment : .center)
                            
                            VStack(alignment : .leading , spacing : 10) {
                                
                                ForEach(Array(recipe.ingredients.enumerated()) , id : \.offset) { _ , ingredient in
                                    
                                    HStack(alignment : .top , spacing : 10) {
                                        
                                        Image(systemName : "circle.fill")
                                            .font(.system(size : 6))
                                            .foregroundColor(.orange)
                                            .padding(.top , 6)
                                        
                                        Text("\(ingredient.quantity) \(ingredient.name)")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal : false , vertical : true)
                                        
                                    }
                                    .padding(.horizontal , 20)
                                }
                            }
                        }
                        
                        Divider().padding(.horizontal)
                        
                        VStack(alignment : .leading , spacing : 15) {
                            
                            Text("Instructions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .frame(maxWidth : .infinity , alignment : .center)
                            
                            VStack(alignment : .leading , spacing : 15) {
                                
                                ForEach(Array(STEPS.enumerated()) , id: \.offset) { index , step in
                                    
                                    HStack(alignment : .top , spacing : 12) {
                                        
                                        Image(systemName: "circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.top , 6)
                                            .frame(width : 25 , alignment : .leading)
                                        
                                        Text(step)
                                            .font(.body)
                                            .lineSpacing(4)
                                            .fixedSize(horizontal : false , vertical : true)
                                    }
                                    .padding(.horizontal , 20)
                                }
                            }
                        }
                        
                        Spacer(minLength : 40)
                    }
                    .padding(.top , 20)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(30)
                    .offset(y : -20)
                }
                .ignoresSafeArea(edges: .top)
            }
            
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(colorScheme == .light ? Color.white : Color(UIColor.systemBackground) , for : .navigationBar)
            .toolbarBackground(.visible , for : .navigationBar)
            .background(Color(UIColor.systemBackground))
            .toolbar {
                
                ToolbarItem(placement : .navigationBarLeading) {
                    
                    Button(action : { dismiss() }) {
                        
                        HStack(spacing : 4) {
                            
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
                            .frame(width : 28 , height : 28)
                        
                        Text("Recipe Details")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                
                ToolbarItem(placement : .navigationBarTrailing) {
                    
                    Button(action : Favourite) {
                        
                        Image(systemName : isSaved ? "heart.circle.fill" : "heart.circle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                    }
                }
            }
            .alert(alertMessage , isPresented : $showAlert) { Button("OK" , role : .cancel) { } }
            
            .onAppear { SavedStateUpdated() }
            
            .sheet(isPresented : $MealPlannerDisplay) { MealPlannerView(showTabView: $showTabView, PreselectedRECID : recipe.id) }
        }
    }
    
    private struct HeaderImageView : View {
        
        let imageURL : String?
        
        let height : CGFloat
        
        var body : some View {
            
            GeometryReader { GEO in
                
                Group {
                    
                    if let imageURL , let url = URL(string : imageURL) {
                        
                        AsyncImage(url : url) { PH in
                            
                            switch PH {
                                
                            case .empty :
                                Area(width : GEO.size.width , height : height) {
                                    ProgressView()
                                }
                                
                            case .success(let IMG) :
                                IMG
                                    .resizable()
                                    .aspectRatio(contentMode : .fill)
                                    .frame(width : GEO.size.width , height : height)
                                    .clipped()
                                
                            case .failure :
                                Area(width : GEO.size.width , height : height) {
                                    Image(systemName : "photo")
                                        .font(.system(size : 60))
                                        .foregroundColor(.gray)
                                }
                                
                            @unknown default :
                                Color.clear
                                    .frame(width : GEO.size.width , height : height)
                            }
                        }
                    }
                    
                    else {
                        
                        Area(width : GEO.size.width , height : height) {
                            
                            Image(systemName : "photo")
                                .font(.system(size : 60))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height : height)
        }
        
        @ViewBuilder
        private func Area<T : View>(width : CGFloat , height : CGFloat , @ViewBuilder content:()->T)->some View {
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width : width , height : height)
                .overlay(content())
        }
    }
}
