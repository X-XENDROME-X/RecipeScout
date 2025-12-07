//
//  HomeView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//

// Name: Shorya Raj
// Description: This file shows the main home view with the app logo and menu buttons to navigate to different sections of Recipe Scout

import SwiftUI

struct HomeView : View {
    
    @State private var navigationPath = NavigationPath()
    var onSelectTab : (Int) -> Void = { _ in }

    var body : some View {
        
        NavigationStack(path : $navigationPath) {
            
            VStack(spacing : 22) {
                
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width : 100 , height : 100)
                    .foregroundColor(.orange)

                Text("Recipe Scout")
                    .font(.system(size : 48 , weight : .bold))
                    .foregroundColor(.orange)

                Text("Meals Made Easy")
                    .font(.title3)
                    .foregroundColor(.gray)

                Spacer().frame(height : 22)

                Button(action : { onSelectTab(1) } ) { MenuButton(ICON : "magnifyingglass" , LABEL : "Search Recipes") }

                Button(action : { navigationPath.append("Saved") } ) { MenuButton(ICON : "heart.fill" , LABEL : "My Saved Recipes") }

                Button(action: { onSelectTab(2) } ) { MenuButton(ICON : "calendar" , LABEL : "Meal Planner") }

                Button(action : { onSelectTab(3) } ) { MenuButton(ICON : "cart.fill" , LABEL : "Shopping List") }

                Spacer()
            }
            .padding(.horizontal , 30)
            .navigationDestination(for : String.self) { D in
                
                switch D {
                    
                case "Saved":
                    SavedRecipesView()
                    
                default:
                    EmptyView()
                }
            }
        }

        .toolbar(.hidden , for : .tabBar)
    }
}

struct MenuButton : View {
    
    let ICON : String
    
    let LABEL : String

    var body : some View {
        
        HStack {
            
            Image(systemName : ICON)
                .font(.title2)

            Text(LABEL)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()
        }
        .frame(maxWidth : .infinity)
        .padding()
        .background(Color.orange)
        .foregroundColor(.white)
        .cornerRadius(15)
    }
}

