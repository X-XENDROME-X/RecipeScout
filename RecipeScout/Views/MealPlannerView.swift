//
//  MealPlannerView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file is the Meal Planner view that allows users to plan meals for different days and meal types , and generate shopping lists from their meal plans using SwiftData for persistence

import SwiftUI

import SwiftData

struct MealPlannerView : View {
    
    @Environment(\.modelContext) private var modelContext

    let PreselectedRECID : String?

    @Query(sort : \SavedRecipe.dateSaved , order : .reverse)
    
    private var savedRecipes : [SavedRecipe]

    @Query(sort : \MealPlanEntry.date)
    
    private var plannedMeals : [MealPlanEntry]

    @State private var selectedDate = Date()
    
    @State private var selectedMealType : MealType?
    
    @State private var showRecipePicker = false
    
    @State private var showAlert = false
    
    @State private var alertMessage : String?
    

    private var MEALSforSELECTEDDate : [MealPlanEntry] {
        plannedMeals.filter { Calendar.current.isDate($0.date , inSameDayAs : selectedDate) }
    }

    private func SavedRECIPES(for ITEM : MealPlanEntry) -> SavedRecipe? {
        savedRecipes.first { $0.id == ITEM.recipeID }
    }

    private var MISSMEALTypes : [MealType] {
        MealType.allCases.filter { T in !MEALSforSELECTEDDate.contains { $0.mealType==T } }
    }

    private var FilterSREC : [SavedRecipe] {
        
        if let PreselectedRECID {
            return savedRecipes.filter { $0.id==PreselectedRECID }
        }
        else { return savedRecipes }
    }

    private var ShopListButton : some View {
        
        Button { HGENShoppList()
        } label : {
            
            HStack {
                
                Text("🛍️ Generate Shopping List")
                    .font(.headline)
                Spacer()
                Image(systemName : "arrow.right")
                    .font(.headline)
                
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange)
            .cornerRadius(14)
        }
        .padding(.top, 12)
    }

    private func HGENShoppList() { Task { await GenShopLIstSELECTEDDATE() } }

    @MainActor
    private func GenShopLIstSELECTEDDATE() async {
        
        let ENTRIES = MEALSforSELECTEDDate

        guard !ENTRIES.isEmpty else {
            
            showAlert = true
            
            alertMessage = "You have no meals planned for this day. Add some meals before generating a Shopping List."
            
            return
        }

        let DESC = FetchDescriptor<ShoppingItem>()
        
        let EXISTITMS = (try? modelContext.fetch(DESC)) ?? []

        var COUNTER = 0
        
        var FRecipes : [String] = []

        for ITEM in ENTRIES {
            do {

                if let R = try await APIService.shared.RecipeDetails(id : ITEM.recipeID) {
                    
                    let INGREDS = R.ingredients

                    for i in INGREDS {
                        
                        let RName = i.name.trimmingCharacters(in : .whitespacesAndNewlines)
                        
                        let RQTY = i.quantity.trimmingCharacters(in : .whitespacesAndNewlines)
                        
                        guard !RName.isEmpty else { continue }

                        if let existing = EXISTITMS.first(where : {
                            $0.name.caseInsensitiveCompare(RName) == .orderedSame && $0.plannedDate.map { Calendar.current.isDate($0 , inSameDayAs : selectedDate) } == true
                        }) {
                            if !existing.quantity.contains(RQTY) && !RQTY.isEmpty { existing.quantity += " + \(RQTY)" }
                        }
                        else {
                            
                            let ITM = ShoppingItem(
                                name : RName ,
                                quantity : RQTY.isEmpty ? "1" : RQTY ,
                                sourceRecipeID : R.id ,
                                sourceRecipeName : R.name,
                                plannedDate : selectedDate
                            )
                            modelContext.insert(ITM)
                            
                            COUNTER += 1
                        }
                    }
                }
                
                else { FRecipes.append(ITEM.recipeName) }
            } catch { FRecipes.append(ITEM.recipeName) }
        }

        if COUNTER == 0 {
            
            if FRecipes.isEmpty {
                alertMessage = "No ingredients were added to the Shopping List for this day"
            }
            else {
                alertMessage = """
                Could not add ingredients because recipe details \
                could not be loaded for: \(FRecipes.joined(separator : ", ")).
                """
            }
        }
        
        else {
            var MESSAGE = "Added \(COUNTER) ingredient(s) to your Shopping List from today's meal plan."
            
            if !FRecipes.isEmpty { MESSAGE += "\n\nSome recipes could not be loaded: \(FRecipes.joined(separator : ", "))." }
            alertMessage = MESSAGE
        }
        
        showAlert = true
    }

    var body : some View {
        
        NavigationStack {
            
            VStack(spacing : 16) {

                VStack(spacing : 8) {
                    
                    HStack(spacing : 8) {
                        
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width : 40 , height : 40)
                        
                        Text("Meal Planner")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.orange)
                    }

                    DatePicker(
                        "Select the Day",
                        selection : $selectedDate ,
                        displayedComponents : .date
                    )
                    .datePickerStyle(.compact)
                    
                }
                .padding(.horizontal)

                List {
                    
                    Section {

                        ForEach(MEALSforSELECTEDDate) { ITEM in
                            
                            if let S = SavedRECIPES(for: ITEM) {
                                
                                NavigationLink {

                                    SavedRecipesView.SavedRecipeDetailLoader(saved: S)
                                    
                                } label : {
                                    
                                    HStack {
                                        
                                        Text(TTITLE(ITEM.mealType))
                                        
                                        Spacer()
                                        
                                        Text(ITEM.recipeName)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            else {

                                HStack {
                                    
                                    Text(TTITLE(ITEM.mealType))
                                    
                                    Spacer()
                                    
                                    Text(ITEM.recipeName)
                                        .foregroundColor(.orange)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    
                                    showAlert=true
                                    
                                    alertMessage = "This planned recipe is no longer in your Saved Recipes. Please save it again or choose another meal."
                                    
                                }
                            }
                        }
                        .onDelete(perform : DELMEALS)

                        ForEach(MISSMEALTypes , id: \.self) { T in
                            
                            HStack {
                                
                                Text(TTITLE(T))
                                
                                Spacer()
                                
                                Text("Tap to choose")
                                    .foregroundColor(.secondary)
                                
                            }
                            
                            .contentShape(Rectangle())
                            .onTapGesture { HANMeal(type : T) }
                        }
                    }
                    footer : { ShopListButton }
                }
            }
            .padding(.bottom , 8)
            .sheet(isPresented : $showRecipePicker) { RPickSheet }
            .alert(alertMessage ?? "" , isPresented : $showAlert) { Button("OK" , role : .cancel) { } }
        }
    }

    private var RPickSheet : some View {
        
        NavigationStack {
            
            List {
                
                if FilterSREC.isEmpty {
                    
                    Text("No saved recipes yet.\nGo to Saved tab to add some recipes.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                
                else {
                    ForEach(FilterSREC) { S in
                        
                        Button { ASSIGINREC(SavedRECIPES: S)
                        } label : {
                            Text(S.name)
                        }
                    }
                }
            }
            .navigationTitle("Choose Recipe")
            
            .toolbar {
                ToolbarItem(placement : .cancellationAction) {
                    Button("Close") { showRecipePicker=false }
                }
            }
        }
    }

    private func TTITLE(_ T : MealType) -> String {
        
        switch T {
            
        case .breakfast : return "Breakfast"
            
        case .lunch :     return "Lunch"
            
        case .dinner :    return "Dinner"
             
        case .snack :     return "Snack"
            
        }
    }

    private func HANMeal(type : MealType) {
        
        guard !savedRecipes.isEmpty else {
            
            showAlert = true
            
            alertMessage = "You have no saved recipes yet. Save a few favorites before planning meals."
            
            return
        }
        
        selectedMealType = type
        
        showRecipePicker = true
    }

    private func ASSIGINREC(SavedRECIPES : SavedRecipe) {
        
        guard let T = selectedMealType else { return }

        if let EXIST = MEALSforSELECTEDDate.first(where: { $0.mealType==T }) { modelContext.delete(EXIST) }

        let ITEM = MealPlanEntry(D : selectedDate , MEALTYPE : T , from : SavedRECIPES)
        
        modelContext.insert(ITEM)
        
        showRecipePicker = false
        
        selectedMealType = nil
    }

    private func DELMEALS(at OFFS : IndexSet) {
        
           for i in OFFS {
               
               let ITEM=MEALSforSELECTEDDate[i]
               
               modelContext.delete(ITEM)
               
           }
    }
}

