//
//  ContentView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 11/10/25.
//

// Name: Shorya Raj
// Description: This file is the main content view which manages the navigation for the Recipe Scout app using a NavigationStack with HomeView as the root

import SwiftUI

struct ContentView: View {

    @State private var showTabView = false
    @State private var selectedTab : Int = 0

    var body : some View {
        ZStack {
            if !showTabView {
                HomeView(onSelectTab: { tab in
                    selectedTab = tab
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showTabView = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(0)
            }
            
            if showTabView {
                MainTabView(showTabView: $showTabView, selectedTab: $selectedTab)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .zIndex(1)
            }
        }
    }
}

struct MainTabView: View {
    
    @Binding var showTabView: Bool
    @Binding var selectedTab: Int

    var body : some View {

        TabView(selection : $selectedTab) {

            SearchView(showTabView: $showTabView)
                .tabItem { Label("Search" , systemImage : "magnifyingglass") }
                .tag(0)

            MealPlannerView(showTabView: $showTabView, PreselectedRECID: nil)
                .tabItem { Label("Meal Plan" , systemImage : "calendar") }
                .tag(1)
            
            AIAssistantView(showTabView: $showTabView)
                .tabItem { Label("Sage" , systemImage : "brain.head.profile") }
                .tag(2)

            ShoppingListView(showTabView: $showTabView)
                .tabItem { Label("Shopping" , systemImage : "cart.fill") }
                .tag(3)

            MapView(showTabView: $showTabView)
                .tabItem { Label("Map" , systemImage : "map.fill") }
                .tag(4)
        }
        .tint(.orange)
    }
}


