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
    
    @Binding var showTabView: Bool
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AIAssistantViewModel?
    @State private var messageText = ""
    @State private var showingSettings = false
    @State private var contextUpdateNotification: String?
    @State private var showContextUpdate = false
    @State private var showContextChangeAlert = false
    @State private var contextChangeMessage = ""
    @State private var lastMealTimeCheck: TimeContextHelper.MealTime?
    @FocusState private var isInputFocused: Bool
    
    // Real-time queries for badge updates
    @Query private var savedRecipes: [SavedRecipe]
    @Query private var shoppingItems: [ShoppingItem]
    @Query private var mealPlanEntries: [MealPlanEntry]
    
    init(showTabView: Binding<Bool>) {
        self._showTabView = showTabView
    }
    
    // MARK: - Helper Methods
    
    /// Shows a context update notification banner
    private func showContextUpdateNotification(_ notification: String) {
        contextUpdateNotification = notification
        withAnimation {
            showContextUpdate = true
        }
        // Auto-hide after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showContextUpdate = false
            }
        }
    }
    
    /// Check if meal time has changed and refresh suggestions
    private func checkMealTimeChange() {
        let currentMealTime = TimeContextHelper.getCurrentMealTime()
        
        if let lastCheck = lastMealTimeCheck, lastCheck != currentMealTime {
            // Meal time changed! Update suggestions
            lastMealTimeCheck = currentMealTime
            
            // Only show notification if chat is active and not on welcome screen
            if let viewModel = viewModel, viewModel.messages.count > 1 {
                let notification = "It's \(currentMealTime.rawValue.lowercased()) time! 🍽️"
                showContextUpdateNotification(notification)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Check for API key before showing the assistant
            if let apiKey = EnvironmentConfig.shared.claudeAPIKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let viewModel = viewModel {
                    VStack(spacing: 0) {
                        // Custom Header
                        AIAssistantHeaderView(
                            viewModel: viewModel,
                            showingSettings: $showingSettings,
                            showTabView: $showTabView,
                            showContextChangeAlert: $showContextChangeAlert,
                            contextChangeMessage: $contextChangeMessage,
                            savedRecipeCount: savedRecipes.count,
                            shoppingItemCount: shoppingItems.count,
                            upcomingMealsCount: mealPlanEntries.count
                        )
                        
                        // Context update notification banner
                        if showContextUpdate, let notification = contextUpdateNotification {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundStyle(.orange)
                                
                                Text(notification)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        showContextUpdate = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Messages ScrollView
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubbleView(message: message)
                                            .id(message.id)
                                            .transition(.asymmetric(
                                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                                removal: .opacity
                                            ))
                                    }
                                    
                                    // Typing indicator
                                    if viewModel.isLoading {
                                        TypingIndicatorView()
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding()
                            }
                            .onChange(of: viewModel.messages.count) { _, _ in
                                if let lastMessage = viewModel.messages.last {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                            .onChange(of: viewModel.isLoading) { _, _ in
                                if viewModel.isLoading {
                                    withAnimation(.easeOut(duration: 0.3)) {
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
                    // Show error screen if API key is missing or invalid
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        
                        Text("Configuration Required")
                            .font(.title2.weight(.bold))
                        
                        Text("Sage requires an AI API key to work. Please add your API key to the .env file.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("Configuration/.env file:\nCLAUDE_API_KEY=your_key_here")
                            .font(.caption.monospaced())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                
                if viewModel == nil && EnvironmentConfig.shared.claudeAPIKey != nil {
                    ProgressView("Initializing Sage...")
                        .tint(.orange)
                }
            } else {
                // Show error screen if API key is missing or invalid
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text("Configuration Required")
                        .font(.title2.weight(.bold))
                    
                    Text("Sage requires an AI API key to work. Please add your API key to the .env file.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Configuration/.env file:\nCLAUDE_API_KEY=your_key_here")
                        .font(.caption.monospaced())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) {
            AIAssistantInfoView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .alert("Context Updated", isPresented: $showContextChangeAlert) {
            Button("Got It", role: .cancel) { }
            Button("Clear Chat", role: .destructive) {
                viewModel?.clearConversation()
            }
        } message: {
            Text(contextChangeMessage)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AIAssistantViewModel(modelContext: modelContext)
            }
            
            // Set initial meal time
            lastMealTimeCheck = TimeContextHelper.getCurrentMealTime()
            
            // Start timer to check for meal time changes
            Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
                checkMealTimeChange()
            }
        }
        .onChange(of: savedRecipes.count) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if let notification = viewModel?.refreshContextWithNotification() {
                showContextUpdateNotification(notification)
            }
        }
        .onChange(of: shoppingItems.count) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if let notification = viewModel?.refreshContextWithNotification() {
                showContextUpdateNotification(notification)
            }
        }
        .onChange(of: mealPlanEntries.count) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if let notification = viewModel?.refreshContextWithNotification() {
                showContextUpdateNotification(notification)
            }
        }
        // Also watch for changes in shopping item details (checking/unchecking)
        .onChange(of: shoppingItems.map { $0.isChecked }) { _, _ in
            // Silently refresh context when items are checked/unchecked
            viewModel?.refreshContext()
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
                                    Text("Sage")
                                        .font(.headline)
                                    Text("Your cooking companion")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Text("Sage helps you discover recipes, plan meals, organize shopping lists, and answer all your cooking questions.")
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
                    
                    Section("Privacy & Data") {
                        Label("Your app data stays on your device", systemImage: "lock.shield")
                            .font(.subheadline)
                        
                        Label("You control what Sage can see", systemImage: "checkmark.shield")
                            .font(.subheadline)
                        
                        Label("All connections are encrypted", systemImage: "network.badge.shield.half.filled")
                            .font(.subheadline)
                        
                        Label("Conversations are not stored by us", systemImage: "trash.slash")
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
    
    // MARK: - Custom Header View
    
    struct AIAssistantHeaderView: View {
        var viewModel: AIAssistantViewModel
        @Binding var showingSettings: Bool
        @Binding var showTabView: Bool
        @Binding var showContextChangeAlert: Bool
        @Binding var contextChangeMessage: String
        
        // Real-time counts
        let savedRecipeCount: Int
        let shoppingItemCount: Int
        let upcomingMealsCount: Int
        
        private var hasAnyData: Bool {
            savedRecipeCount > 0 || shoppingItemCount > 0 || upcomingMealsCount > 0
        }
        
        var body: some View {
            VStack(spacing: 0) {
                ZStack {
                    // Home button on the left
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
                    
                    // Centered title with icon and context badge
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.headline)
                                .foregroundStyle(.orange)
                            
                            Text("Sage")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        // Context badge showing active data sources
                        if hasAnyData {
                            HStack(spacing: 4) {
                                if savedRecipeCount > 0 {
                                    ContextPill(
                                        icon: "heart.fill",
                                        count: savedRecipeCount,
                                        isActive: viewModel.includeSavedRecipes
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                                if shoppingItemCount > 0 {
                                    ContextPill(
                                        icon: "cart.fill",
                                        count: shoppingItemCount,
                                        isActive: viewModel.includeShoppingList
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                                if upcomingMealsCount > 0 {
                                    ContextPill(
                                        icon: "calendar",
                                        count: upcomingMealsCount,
                                        isActive: viewModel.includeMealPlan
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .font(.caption2)
                            .animation(.spring(duration: 0.3), value: savedRecipeCount)
                            .animation(.spring(duration: 0.3), value: shoppingItemCount)
                            .animation(.spring(duration: 0.3), value: upcomingMealsCount)
                            .animation(.spring(duration: 0.3), value: viewModel.includeSavedRecipes)
                            .animation(.spring(duration: 0.3), value: viewModel.includeShoppingList)
                            .animation(.spring(duration: 0.3), value: viewModel.includeMealPlan)
                        }
                    }
                    
                    // Menu button on the right
                    HStack {
                        Spacer()
                        
                        Menu {
                            Section {
                                Text("Control what data Sage can see")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Section("Data Context") {
                                Toggle(isOn: Binding(
                                    get: { viewModel.includeSavedRecipes },
                                    set: { newValue in
                                        let oldValue = viewModel.includeSavedRecipes
                                        viewModel.includeSavedRecipes = newValue
                                        viewModel.refreshContext()
                                        
                                        // Show alert if there are existing messages and context changed
                                        if viewModel.messages.count > 1 && oldValue != newValue {
                                            if newValue {
                                                contextChangeMessage = "✓ Sage can now see your \(savedRecipeCount) saved recipe\(savedRecipeCount != 1 ? "s" : ""). This applies to new messages only."
                                            } else {
                                                contextChangeMessage = "✗ Sage can no longer see your saved recipes. Previous messages may still reference them."
                                            }
                                            showContextChangeAlert = true
                                        }
                                    }
                                )) {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Include Saved Recipes")
                                            if savedRecipeCount > 0 {
                                                Text("\(savedRecipeCount) recipe\(savedRecipeCount != 1 ? "s" : "")")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    } icon: {
                                        Image(systemName: "heart.fill")
                                    }
                                }
                                .disabled(savedRecipeCount == 0)
                                
                                Toggle(isOn: Binding(
                                    get: { viewModel.includeShoppingList },
                                    set: { newValue in
                                        let oldValue = viewModel.includeShoppingList
                                        viewModel.includeShoppingList = newValue
                                        viewModel.refreshContext()
                                        
                                        // Show alert if there are existing messages and context changed
                                        if viewModel.messages.count > 1 && oldValue != newValue {
                                            if newValue {
                                                contextChangeMessage = "✓ Sage can now see your \(shoppingItemCount) shopping item\(shoppingItemCount != 1 ? "s" : ""). This applies to new messages only."
                                            } else {
                                                contextChangeMessage = "✗ Sage can no longer see your shopping list. Previous messages may still reference it."
                                            }
                                            showContextChangeAlert = true
                                        }
                                    }
                                )) {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Include Shopping List")
                                            if shoppingItemCount > 0 {
                                                Text("\(shoppingItemCount) item\(shoppingItemCount != 1 ? "s" : "")")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    } icon: {
                                        Image(systemName: "cart.fill")
                                    }
                                }
                                .disabled(shoppingItemCount == 0)
                                
                                Toggle(isOn: Binding(
                                    get: { viewModel.includeMealPlan },
                                    set: { newValue in
                                        let oldValue = viewModel.includeMealPlan
                                        viewModel.includeMealPlan = newValue
                                        viewModel.refreshContext()
                                        
                                        // Show alert if there are existing messages and context changed
                                        if viewModel.messages.count > 1 && oldValue != newValue {
                                            if newValue {
                                                contextChangeMessage = "✓ Sage can now see your \(upcomingMealsCount) planned meal\(upcomingMealsCount != 1 ? "s" : ""). This applies to new messages only."
                                            } else {
                                                contextChangeMessage = "✗ Sage can no longer see your meal plan. Previous messages may still reference it."
                                            }
                                            showContextChangeAlert = true
                                        }
                                    }
                                )) {
                                    Label {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Include Meal Plan")
                                            if upcomingMealsCount > 0 {
                                                Text("\(upcomingMealsCount) meal\(upcomingMealsCount != 1 ? "s" : "")")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    } icon: {
                                        Image(systemName: "calendar")
                                    }
                                }
                                .disabled(upcomingMealsCount == 0)
                            }
                            
                            Section {
                                Button(role: .destructive, action: {
                                    viewModel.clearConversation()
                                }) {
                                    Label("Clear Conversation", systemImage: "trash")
                                }
                            }
                            
                            Section {
                                Button(action: { showingSettings = true }) {
                                    Label("About Sage", systemImage: "info.circle")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                
                Divider()
            }
        }
    }
    
    // MARK: - Context Pill Component
    
    struct ContextPill: View {
        let icon: String
        let count: Int
        let isActive: Bool
        
        var body: some View {
            HStack(spacing: 3) {
                Image(systemName: icon)
                Text("\(count)")
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isActive ? Color.orange.opacity(0.15) : Color.gray.opacity(0.1))
            .foregroundStyle(isActive ? .orange : .gray)
            .opacity(isActive ? 1.0 : 0.5)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isActive ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
