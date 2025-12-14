//
//  SearchView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file displays the search view where users can search for recipes by name or filter by category which helps showing results in a scrollable card layout

import SwiftUI

struct SearchView : View {
    
    @Binding var showTabView: Bool
    
    @StateObject private var viewModel = RecipeViewModel()
    
    @State private var textSearch = ""
    
    @State private var categorySelection = "All"
    
    @State private var isSearching = false

    let categories : [String] = ["All" , "Breakfast" , "Dessert" , "Seafood" , "Vegetarian"]
    
    init(showTabView: Binding<Bool>) {
        self._showTabView = showTabView
    }

    private var RecipesFiltered : [Recipe] {
        
        guard categorySelection != "All" else { return viewModel.recipes }
        
        return viewModel.recipes.filter { R in
                
            R.category.localizedCaseInsensitiveContains(categorySelection)

        }
    }
    
    var body : some View {
        
        NavigationStack {
            
            VStack(spacing : 0) {

                // Navigation Bar
                VStack(spacing : 0) {
                    
                    ZStack {
                        // Centered logo and title
                        HStack(spacing : 8) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width : 40 , height : 40)
                            
                            Text("Search Recipes")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        // Home button aligned to leading edge
                        HStack {
                            Button(action: { 
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    showTabView = false
                                }
                            }) {
                                Image(systemName: "house.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    HStack {
                        
                        Image(systemName : "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search for Recipes" , text : $textSearch)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onChange(of : textSearch) { OLDValue , NEWValue in

                                Task {
                                    
                                    try? await Task.sleep(nanoseconds : 500_000_000)
                                    
                                    if textSearch==NEWValue && !NEWValue.isEmpty { await viewModel.RecipesSearch(query : NEWValue) }
                                    
                                    else if NEWValue.isEmpty {
                                        
                                        categorySelection="All"
                                        
                                        await viewModel.RandomRecipesLoader()
                                        
                                    }
                                }
                            }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    ScrollView(.horizontal , showsIndicators : false) {
                        
                        HStack(spacing : 20) {
                            
                            ForEach(categories , id : \.self) { CAT in
                                
                                Button(action : {
                                    
                                    categorySelection = CAT

                                    Task {
                                        
                                        if textSearch.trimmingCharacters(in : .whitespacesAndNewlines).isEmpty {
                                            
                                            if CAT=="All" {
                                                await viewModel.RandomRecipesLoader()
                                            }
                                            
                                            else { await viewModel.RecipesByCategory(category : CAT) }
                                        }
                                    }
                                }) {
                                    Text(CAT)
                                        .font(.headline)
                                        .fontWeight(categorySelection == CAT ? .bold : .regular)
                                        .foregroundColor(categorySelection == CAT ? .orange : .gray)
                                }

                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
                .background(Color(UIColor.systemBackground))
                
                Divider()

                ZStack {

                    ScrollView {
                        
                        VStack(alignment : .leading , spacing : 20) {

                            if !viewModel.isLoading && !RecipesFiltered.isEmpty {
                                Text("Search Results")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                            }

                            if !RecipesFiltered.isEmpty && !viewModel.isLoading {
                                
                                LazyVStack(spacing : 25) {
                                    
                                    ForEach(RecipesFiltered) { R in
                                        
                                        RecipeCard(recipe: R)
                                            .padding(.horizontal)
                                        
                                    }
                                }
                                .padding(.bottom, 20)
                            }

                        }
                    }

                    if viewModel.isLoading {
                        
                        VStack(spacing : 15) {
                            
                            ProgressView()
                                .scaleEffect(1.6)
                                .tint(.orange)
                            
                            Text("Searching")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                        }
                        .frame(maxWidth : .infinity , maxHeight : .infinity)
                        .background(Color.white.opacity(0.9))
                    }

                    if !viewModel.isLoading && RecipesFiltered.isEmpty && ( !textSearch.isEmpty || categorySelection != "All" ) {

                        ContentUnavailableView {
                            
                            Label { Text("No recipes found")
                            } icon : {
                                Text("😢")
                                    .font(.system(size : 70))
                            }
                        }
                        .frame(maxWidth : .infinity , maxHeight : .infinity)
                    }

                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            
            textSearch = ""
            
            categorySelection = "All"

            Task { await viewModel.RandomRecipesLoader() }
        }
    }
}

struct RecipeCard : View {
    
    let recipe: Recipe

    var body : some View {
        
        VStack(spacing : 0) {

            GeometryReader { GEO in
                
                if let IMGURL = recipe.imageURL , let url = URL(string : IMGURL) {
                    
                    AsyncImage(url : url) { PH in
                        
                        switch PH {
                            
                        case .empty :
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width : GEO.size.width , height : 200)
                                .overlay(ProgressView())
                            
                        case .success(let IMG):
                            IMG
                                .resizable()
                                .aspectRatio(contentMode : .fill)
                                .frame(width : GEO.size.width , height : 200)
                                .clipped()
                            
                        case .failure :
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width : GEO.size.width , height : 200)
                                .overlay(
                                    Image(systemName : "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                            
                        @unknown default :
                            EmptyView()
                        }
                    }
                }
            }
            .frame(height : 200)

            VStack(spacing : 12) {
                
                Text(recipe.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)

                HStack(spacing : 12) {
                    
                    HStack(spacing : 4) {
                        
                        Image(systemName: "fork.knife")
                            .foregroundColor(.orange)
                        
                        Text(recipe.category)
                            .foregroundColor(.black)
                    }

                    Text("|")
                        .foregroundColor(.gray.opacity(0.5))

                    HStack(spacing : 4) {
                        
                        Image(systemName : "globe")
                            .foregroundColor(.orange)
                        
                        Text(recipe.cuisine)
                            .foregroundColor(.black)
                    }

                    Text("|")
                        .foregroundColor(.gray.opacity(0.5))

                    HStack(spacing : 4) {
                        
                        Image(systemName : "list.bullet")
                            .foregroundColor(.orange)
                        
                        Text("\(recipe.ingredients.count) Ingredients")
                            .foregroundColor(.black)
                            .fixedSize(horizontal : true , vertical : false)
                    }
                }
                
                .font(.system(size : 14 , weight : .medium))
                .minimumScaleFactor(0.8)
                .lineLimit(1)

                NavigationLink(destination : RecipeDetailView(recipe : recipe)) {
                    Text("See the Recipe")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth : .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .simultaneousGesture(TapGesture())
            }
            .padding()
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius : 15))
        .shadow(color : Color.black.opacity(0.1) , radius : 5 , x : 0 , y : 2)
    }
}

