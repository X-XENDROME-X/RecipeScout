# RecipeScout 🍳

**RecipeScout** is an iOS recipe discovery and meal planning app built with SwiftUI, designed to help you explore recipes, plan meals, create shopping lists, and find nearby grocery stores.

---

## ✨ Features

### 🔍 Recipe Discovery
- Search thousands of recipes by name, category, or cuisine
- Browse recipes from TheMealDB API
- View detailed recipe information including ingredients, instructions, and images

### ❤️ Saved Recipes
- Save your favorite recipes for quick access
- Persistent storage using SwiftData
- Manage your personal recipe collection

### 📅 Meal Planner
- Plan meals for breakfast, lunch, dinner, and snacks
- Calendar-based organization
- Drag and drop recipes into your meal plan

### 🛒 Shopping List
- Auto-generate shopping lists from your meal plans
- Add custom items manually
- Check off items as you shop
- Clear completed items

### 🗺️ Store Locator
- Find nearby grocery stores using MapKit
- View store locations on an interactive map
- Get directions to stores

---

## 🛠️ Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Persistent data storage (iOS 17+)
- **Combine** - Reactive programming for API calls
- **MapKit** - Location services and maps
- **CoreLocation** - User location tracking
- **TheMealDB API** - Recipe data source

---

## 📋 Requirements

- **Xcode**: 15.0 or later
- **iOS**: 17.0 or later
- **Swift**: 5.9 or later
- **macOS**: Sonoma (14.0) or later for development

---

## 🚀 Getting Started

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/X-XENDROME-X/RecipeScout.git
cd RecipeScout
```

### 2️⃣ Configure Environment Variables

Copy the template file and set your API configuration:

```bash
cp .env.template RecipeScout/Configuration/.env
```

Edit `RecipeScout/Configuration/.env` and add your API base URL:

```env
API_BASE_URL=<YOUR_MEALDB_BASE_URL>
```

> **Note**: Request your own MealDB endpoint (or proxy) and keep it private by storing it only in `.env`. Follow the [TheMealDB API docs](https://www.themealdb.com/api.php) to obtain the correct base URL for your account or tier.

### 3️⃣ Open in Xcode

```bash
open RecipeScout.xcodeproj
```

### 4️⃣ Add .env to Xcode Target

1. In Xcode, drag `RecipeScout/Configuration/.env` into the Project Navigator
2. In the dialog, **check** "RecipeScout" under "Add to targets"
3. Click "Finish"

### 5️⃣ Build and Run

- Select a simulator or device
- Press `⌘R` or click the Play button
- The app will launch with full functionality

---

## 📁 Project Structure

```
RecipeScout/
├── RecipeScout/
│   ├── RecipeScoutApp.swift          # App entry point
│   ├── APIService.swift               # Network layer for API calls
│   │
│   ├── Configuration/
│   │   ├── EnvironmentConfig.swift   # Environment variable loader
│   │   ├── .env.template             # Template for API configuration
│   │   └── .env                      # Your API config (gitignored)
│   │
│   ├── Models/
│   │   ├── Recipe.swift              # Recipe data model (API response)
│   │   ├── SavedRecipe.swift         # Saved recipe (SwiftData)
│   │   ├── MealPlanEntry.swift       # Meal plan entry (SwiftData)
│   │   └── ShoppingItem.swift        # Shopping list item (SwiftData)
│   │
│   ├── ViewModels/
│   │   └── RecipeViewModel.swift     # Recipe business logic
│   │
│   └── Views/
│       ├── ContentView.swift         # Tab bar container
│       ├── HomeView.swift            # Home screen
│       ├── SearchView.swift          # Recipe search
│       ├── RecipeDetailView.swift    # Recipe details
│       ├── SavedRecipesView.swift    # Saved recipes list
│       ├── MealPlannerView.swift     # Meal planning calendar
│       ├── ShoppingListView.swift    # Shopping list
│       └── MapView.swift             # Store locator map
│
├── RecipeScout.xcodeproj/            # Xcode project file
├── .gitignore                        # Git ignore rules
├── .env.template                     # Root env template
├── README.md                         # This file
└── LICENSE                           # License file
```

---

## 🔒 Security & Privacy

### Environment Variables
- **Never commit `.env` files** - They are gitignored by default
- The `.env.template` file shows required variables without exposing secrets
- Each developer/user must create their own `.env` file locally

### API Keys
- TheMealDB currently uses a free public API endpoint
- For production apps, obtain your own API key
- Store API keys in `.env`, never hardcode them in source files

### Location Privacy
- MapView requests location permission from the user
- Location data is only used for finding nearby stores
- No location data is stored or transmitted to external servers

---

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome! If you find issues or have ideas for improvements, feel free to open an issue.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Shorya Raj**

- GitHub: [@X-XENDROME-X](https://github.com/X-XENDROME-X)
- Project: [RecipeScout](https://github.com/X-XENDROME-X/RecipeScout)

---

## 🙏 Acknowledgments

- Recipe data provided by [TheMealDB](https://www.themealdb.com/)
- Icons and assets created for RecipeScout
- Built with ❤️ using SwiftUI

---

## 📱 Screenshots

*Coming soon - Screenshots of the app in action will be added here*

---

**Happy Cooking! 🍽️**
