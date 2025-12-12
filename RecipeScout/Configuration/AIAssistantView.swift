//
//  AIAssistantView.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 12/12/25.
//

// Name: Shorya Raj
// Description: Main chat interface for the AI Assistant with modern UI/UX design

import SwiftUI
import SwiftData

struct AIAssistantView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AIAssistantViewModel?
    @State private var messageText = ""
    @State private var showingSettings = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let viewModel = viewModel {
                    VStack(spacing: 0) {
                        // Messages ScrollView
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubbleView(message: message)
                                            .id(message.id)
                                    }
                                    
                                    // Typing indicator
                                    if viewModel.isLoading {
                                        TypingIndicatorView()
                                    }
                                }
                                .padding()
                            }
                            .onChange(of: viewModel.messages.count) { _, _ in
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: viewModel.isLoading) { _, _ in
                                if viewModel.isLoading {
                                    withAnimation {
                                        proxy.scrollTo("typing", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Suggested queries (shown when chat is empty)
                        if viewModel.messages.count == 1 {
                            QuickActionButtons(
                                suggestions: viewModel.getSuggestedQueries(),
                                onTap: { query in
                                    messageText = query
                                    Task {
                                        await viewModel.sendMessage(query)
                                        messageText = ""
                                    }
                                }
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        
                        // Input bar
                        AIInputBar(
                            text: $messageText,
                            isLoading: viewModel.isLoading,
                            onSend: {
                                let text = messageText
                                messageText = ""
                                isInputFocused = false
                                Task {
                                    await viewModel.sendMessage(text)
                                }
                            }
                        )
                        .focused($isInputFocused)
                        .padding()
                    }
                } else {
                    ProgressView("Initializing AI Assistant...")
                        .tint(.orange)
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let vm = viewModel {
                            Section("Data Context") {
                                Toggle(isOn: Binding(
                                    get: { vm.includeSavedRecipes },
                                    set: { vm.includeSavedRecipes = $0; vm.refreshContext() }
                                )) {
                                    Label("Include Saved Recipes", systemImage: "heart.fill")
                                }
                                
                                Toggle(isOn: Binding(
                                    get: { vm.includeShoppingList },
                                    set: { vm.includeShoppingList = $0; vm.refreshContext() }
                                )) {
                                    Label("Include Shopping List", systemImage: "cart.fill")
                                }
                                
                                Toggle(isOn: Binding(
                                    get: { vm.includeMealPlan },
                                    set: { vm.includeMealPlan = $0; vm.refreshContext() }
                                )) {
                                    Label("Include Meal Plan", systemImage: "calendar")
                                }
                            }
                            
                            Section {
                                Button(role: .destructive, action: {
                                    vm.clearConversation()
                                }) {
                                    Label("Clear Conversation", systemImage: "trash")
                                }
                            }
                            
                            Section {
                                Button(action: { showingSettings = true }) {
                                    Label("About AI Assistant", systemImage: "info.circle")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.orange)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel {
                        ContextBadgeView(statistics: vm.statistics)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                AIAssistantInfoView()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AIAssistantViewModel(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Context Badge

struct ContextBadgeView: View {
    let statistics: UserStatistics
    
    var body: some View {
        if statistics.hasAnyData {
            HStack(spacing: 4) {
                Image(systemName: "brain.head.profile")
                    .font(.caption2)
                
                Text("\(statistics.savedRecipeCount + statistics.shoppingItemCount + statistics.upcomingMealsCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.orange.opacity(0.2))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Info View

struct AIAssistantInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title)
                                .foregroundStyle(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("AI Assistant")
                                    .font(.headline)
                                Text("Powered by Claude Sonnet 4")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text("Your personal cooking companion that helps with recipes, meal planning, and food questions.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("What I Can Help With") {
                    FeatureRow(icon: "magnifyingglass", title: "Recipe Ideas", description: "Get personalized recipe suggestions")
                    FeatureRow(icon: "calendar", title: "Meal Planning", description: "Plan your meals for the week")
                    FeatureRow(icon: "cart", title: "Shopping Lists", description: "Organize ingredients you need")
                    FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Substitutions", description: "Find ingredient alternatives")
                    FeatureRow(icon: "leaf", title: "Nutrition", description: "Learn about food and health")
                }
                
                Section("Privacy") {
                    Label("All conversations stay on your device", systemImage: "lock.shield")
                        .font(.subheadline)
                    
                    Label("Only selected data is shared with AI", systemImage: "checkmark.shield")
                        .font(.subheadline)
                    
                    Label("API requests are encrypted", systemImage: "network.badge.shield.half.filled")
                        .font(.subheadline)
                }
                .foregroundStyle(.green)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
