# RecipeScout

RecipeScout is a SwiftUI-powered recipe discovery and meal planning app.

## Features

- Search recipes by keyword, category, or area
- View detailed recipe instructions
- Save favorite recipes with SwiftData
- Plan meals with calendar-based organization
- Build shopping lists and find nearby stores

## Requirements

- Xcode 15+
- iOS 17+

## Setup

```bash
cp .env.template .env
```

Open `RecipeScout.xcodeproj` in Xcode and run the `RecipeScout` scheme on a simulator or device.

## Environment

`API_BASE_URL` is read from `.env`. The default uses TheMealDB public API endpoint. Update `.env` if you have a personal key or different backend.

## License

MIT
