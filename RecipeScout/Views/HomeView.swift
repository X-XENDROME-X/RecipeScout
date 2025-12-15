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
    @State private var showContent = false
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
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0.0)

                Text("Recipe Scout")
                    .font(.system(size : 48 , weight : .bold))
                    .foregroundColor(.orange)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1.0 : 0.0)

                Text("Meals Made Easy")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .opacity(showContent ? 1.0 : 0.0)

                Spacer().frame(height : 22)

                VStack(spacing: 15) {
                    Button(action : { onSelectTab(0) } ) { MenuButton(ICON : "magnifyingglass" , LABEL : "Search Recipes") }
                        .buttonStyle(.plain)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .allowsHitTesting(showContent)

                    Button(action : { navigationPath.append("Saved") } ) { MenuButton(ICON : "heart.fill" , LABEL : "My Saved Recipes") }
                        .buttonStyle(.plain)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .allowsHitTesting(showContent)

                    Button(action: { onSelectTab(1) } ) { MenuButton(ICON : "calendar" , LABEL : "Meal Planner") }
                        .buttonStyle(.plain)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .allowsHitTesting(showContent)

                    Button(action : { onSelectTab(3) } ) { MenuButton(ICON : "cart.fill" , LABEL : "Shopping List") }
                        .buttonStyle(.plain)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .allowsHitTesting(showContent)
                    
                    Button(action : { onSelectTab(2) } ) { MenuButton(ICON : "brain.head.profile" , LABEL : "Sage") }
                        .buttonStyle(.plain)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .allowsHitTesting(showContent)
                }

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
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
        .onDisappear {
            showContent = false
        }
    }
}

struct MenuButton : View {
    
    let ICON : String
    
    let LABEL : String
    
    @State private var isPressed = false

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
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

