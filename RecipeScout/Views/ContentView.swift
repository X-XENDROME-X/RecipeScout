//
//  ContentView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 11/10/25.
//

// Name: Shorya Raj
// Description: This file is the main content view which manages the navigation for the Recipe Scout app using a TabView with five different sections

import SwiftUI

struct ContentView: View {

    @State private var CurrentTAB : Int = 0

    var body : some View {

        TabView(selection : $CurrentTAB) {

            HomeView(onSelectTab : { INDTAB in CurrentTAB = INDTAB })
            .tabItem { Label("Home" , systemImage : "house.fill") }
            .tag(0)

            SearchView()
                .tabItem { Label("Search" , systemImage : "magnifyingglass") }
                .tag(1)

            MealPlannerView(PreselectedRECID: nil)
                .tabItem { Label("Meal Plan" , systemImage : "calendar") }
                .tag(2)

            ShoppingListView()
                .tabItem { Label("List" , systemImage : "cart.fill") }
                .tag(3)

            MapView()
                .tabItem { Label("Map" , systemImage : "map.fill") }
                .tag(4)
        }
        .tint(.orange)
    }
}


