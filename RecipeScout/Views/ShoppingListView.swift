//
//  ShoppingListView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 10/26/25.
//


// Name: Shorya Raj
// Description: This file displays the Shopping List view where users can manage their grocery items that need to be purchased for recipes


import SwiftUI

import SwiftData

struct ShoppingListView : View {

    @Environment(\.dismiss) var dismiss

    @Environment(\.modelContext) private var modelContext

    @State private var ALERTFORCLEARALL = false

    @Query(sort : \ShoppingItem.dateAdded , order : .reverse)
    private var items : [ShoppingItem]

    var body : some View {
        
        NavigationStack {
            
            VStack(spacing : 16) {
                
                VStack(spacing : 15) {
                    
                    ZStack {

                        HStack(spacing : 8) {
                            
                            Spacer()

                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width : 40 , height : 40)

                            Text("Shopping List")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)

                            Spacer()
                        }

                        HStack {
                            
                            Spacer()

                            if !items.isEmpty {
                                
                                Button(action : { ALERTFORCLEARALL = true }) {
                                    
                                    Text("Clear All")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal , 12)
                                        .padding(.vertical , 6)
                                        .background(Color.red.opacity(0.9))
                                        .cornerRadius(14)
                                }
                            }
                        }
                    }
                    .padding(.top , 10)
                    .padding(.horizontal)

                    if items.isEmpty {
                        
                        Spacer()
                        
                        Image(systemName : "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("No items in your Shopping List")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.orange)
                        
                        Text("Use \"Add to List\" on a recipe or Generate from Meal Plan to add ingredients here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal , 40)
                        
                        Spacer()
                        
                    }
                    else {
                        
                        List {
                            
                            ForEach(items) { i in
                                
                                HStack {
                                    
                                    Button {
                                        
                                        i.isChecked.toggle()
                                        
                                        do {
                                            try modelContext.save()
                                        }
                                        
                                        catch {
                                            print("\(error)")
                                        }
                                    } label : {
                                        
                                        Image(systemName : i.isChecked ? "checkmark.circle.fill" : "circle")
                                        
                                            .foregroundColor(i.isChecked ? .green : .orange)
                                    }
                                    .buttonStyle(.plain)

                                    VStack(alignment : .leading , spacing : 2) {
                                        
                                        Text(i.name)
                                            .font(.headline)
                                            .strikethrough(i.isChecked , color : .gray)
                                        
                                        Text(i.quantity)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)

                                        if let RName=i.sourceRecipeName {
                                            
                                            Text(RName)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            .onDelete(perform : DeleteITEMS)
                        }
                        .listStyle(.plain)
                    }
                }
            }
        }
        .alert("Want to Clear all the items?" , isPresented : $ALERTFORCLEARALL) {
            
            Button("No" , role : .cancel) { }
            
            Button("Yes", role: .destructive) { ClearALL() }
        }
        
        message : { Text( "This will remove all items from your Shopping List." ) }
    }

    private func DeleteITEMS(at OFFS : IndexSet) {
        
        for INDX in OFFS {
            
            let i=items[INDX]
            
            modelContext.delete(i)
            
        }
    }

    private func ClearALL() {
        
        for i in items {
            
            modelContext.delete(i)
            
        }
    }
}
