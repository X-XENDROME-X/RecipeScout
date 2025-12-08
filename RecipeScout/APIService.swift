//
//  APIService.swift
//  RecipeScout
//
//  Created by SHORYA RAJ on 11/10/25.
//

// Name: Shorya Raj
// Description: This file helps for the API service layer which handles all network requests to TheMealDB API and processes JSON responses using swift default json processing technique for this

import Foundation

import Combine

class APIService {

    static let shared = APIService()

    private let baseURL = EnvironmentConfig.shared.apiBaseURL

    private let session : URLSession

    private init() {
        
        let C = URLSessionConfiguration.default
        
        C.timeoutIntervalForRequest=30
        
        C.timeoutIntervalForResource=300
        
        self.session = URLSession(configuration : C)
    }

    struct MealsResponse : Codable {
        
        let meals : [MealAPIModel]?
    }

    struct MealAPIModel : Codable {

            let idMeal : String
            let strMeal : String
            let strCategory : String?
            let strArea : String?
            let strInstructions : String?
            let strMealThumb : String?
            let strYoutube : String?
            let strIngredient1 : String?
            let strIngredient2 : String?
            let strIngredient3 : String?
            let strIngredient4 : String?
            let strIngredient5 : String?
            let strIngredient6 : String?
            let strIngredient7 : String?
            let strIngredient8 : String?
            let strIngredient9 : String?
            let strIngredient10 : String?
            let strIngredient11 : String?
            let strIngredient12 : String?
            let strIngredient13 : String?
            let strIngredient14 : String?
            let strIngredient15 : String?
            let strIngredient16 : String?
            let strIngredient17 : String?
            let strIngredient18 : String?
            let strIngredient19 : String?
            let strIngredient20 : String?
            let strMeasure1 : String?
            let strMeasure2 : String?
            let strMeasure3 : String?
            let strMeasure4 : String?
            let strMeasure5 : String?
            let strMeasure6 : String?
            let strMeasure7 : String?
            let strMeasure8 : String?
            let strMeasure9 : String?
            let strMeasure10 : String?
            let strMeasure11 : String?
            let strMeasure12 : String?
            let strMeasure13 : String?
            let strMeasure14 : String?
            let strMeasure15 : String?
            let strMeasure16 : String?
            let strMeasure17 : String?
            let strMeasure18 : String?
            let strMeasure19 : String?
            let strMeasure20 : String?
        }
    
    func RecipesSearch(query : String) async throws -> [Recipe] {

        if let AR = try? await AreaSearch(area : query) , !AR.isEmpty { return AR }

        let ENDP = "\(baseURL)/search.php?s=\(query.addingPercentEncoding(withAllowedCharacters : .urlQueryAllowed) ?? query)"
        
        return try await RecipesGetter(from : ENDP)
    }

    func AreaSearch(area : String) async throws -> [Recipe] {
        
        let ENDP = "\(baseURL)/filter.php?a=\(area.addingPercentEncoding(withAllowedCharacters : .urlQueryAllowed) ?? area)"

        let BASICR = try await RecipesGetter(from : ENDP)

        var FULLR : [Recipe] = []
        
        for R in BASICR.prefix(20) {
            
            if let fullRecipe = try? await RecipeDetails(id : R.id) { FULLR.append(fullRecipe) }
        }
    
        return FULLR
    }

    func RandomRecipes(count : Int=10) async throws -> [Recipe] {

        var R : [Recipe] = []

        for _ in 0..<count {
            
            let ENDP = "\(baseURL)/random.php"
            
            let fetchedRecipes = try await RecipesGetter(from : ENDP)
            
            R.append(contentsOf : fetchedRecipes)
        }
        
        return R
    }

    func RecipesByCategory(category : String) async throws -> [Recipe] {
        
        let ENDP = "\(baseURL)/filter.php?c=\(category.addingPercentEncoding(withAllowedCharacters : .urlQueryAllowed) ?? category)"

        let BASICR = try await RecipesGetter(from : ENDP)

        var FULLR : [Recipe] = []
        
        for R in BASICR.prefix(20) {
            
            if let FULLr = try? await RecipeDetails(id : R.id) {
                
                FULLR.append(FULLr)
            }
        }
        return FULLR
    }

    func RecipeDetails(id : String) async throws -> Recipe? {
        
        let ENDP = "\(baseURL)/lookup.php?i=\(id)"
        
        let R = try await RecipesGetter(from : ENDP)
        
        return R.first
    }

    private func RecipesGetter(from URLSTR : String) async throws -> [Recipe] {
        
        guard let url = URL(string : URLSTR) else {
            
            throw ErrorfromAPI.INVALIDURL
        }

        do {
            
            let (D , R) = try await session.data(from : url)

            guard let HTTPResp = R as? HTTPURLResponse else {
                
                throw ErrorfromAPI.INVALIDRES
            }

            guard (200...299).contains(HTTPResp.statusCode) else {
                
                throw ErrorfromAPI.httpError(STSC : HTTPResp.statusCode)
            }

            let DECODE = JSONDecoder()
            
            let MEALSR = try DECODE.decode(MealsResponse.self , from : D)

            guard let M = MEALSR.meals else {
                
                return []
            }

            return M.compactMap { CRecipe($0) }

        } catch let error as DecodingError {
            
            throw ErrorfromAPI.DecodeERR(error)
            
        } catch {
            
            throw ErrorfromAPI.NetERR(error)
        }
    }

    private func CRecipe(_ MealsFromAPI : MealAPIModel) -> Recipe {

        let ING = IngredientsCollect(from : MealsFromAPI)

        let INS = ParseInstructions(MealsFromAPI.strInstructions ?? "")

        return Recipe(
            
            id : MealsFromAPI.idMeal ,
            
            name : MealsFromAPI.strMeal ,
            
            category : MealsFromAPI.strCategory ?? "Unknown" ,
            
            cuisine : MealsFromAPI.strArea ?? "International" ,
            
            imageURL : MealsFromAPI.strMealThumb ,
            
            prepTime : "30 min" ,
            
            cookTime : "45 min" ,
            
            servings : 4 ,
            
            difficulty : "Medium" ,
            
            ingredients : ING ,
            
            instructions : INS ,
            
            youtubeURL : MealsFromAPI.strYoutube
        )
    }
    
    private func ParseInstructions(_ rawText: String) -> [String] {
        guard !rawText.isEmpty else { return [] }
        
        let normalized = rawText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        let splitPattern = "(?:\\n|^)\\s*(?:STEP\\s+\\d+|Step\\s+\\d+|\\d+\\.|\\d+\\)|\\d+)\\s*[-:–—]?\\s*"
        
        if let regex = try? NSRegularExpression(pattern: splitPattern, options: []) {
            let range = NSRange(normalized.startIndex..., in: normalized)
            let matches = regex.matches(in: normalized, range: range)
            
            if !matches.isEmpty {
                var steps: [String] = []
                
                for (index, match) in matches.enumerated() {
                    let matchEnd = normalized.index(normalized.startIndex, offsetBy: match.range.upperBound)
                    
                    let nextStart: String.Index
                    if index < matches.count - 1 {
                        nextStart = normalized.index(normalized.startIndex, offsetBy: matches[index + 1].range.lowerBound)
                    } else {
                        nextStart = normalized.endIndex
                    }
                    
                    let stepText = String(normalized[matchEnd..<nextStart])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !stepText.isEmpty {
                        steps.append(stepText)
                    }
                }
                
                return steps.filter { !$0.isEmpty }
            }
        }
        
        let lines = normalized.components(separatedBy: "\n")
        var currentStep = ""
        var steps: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.isEmpty {
                if !currentStep.isEmpty {
                    steps.append(currentStep)
                    currentStep = ""
                }
            } else {
                if currentStep.isEmpty {
                    currentStep = trimmed
                } else {
                    let lastChar = currentStep.last
                    if lastChar == "." || lastChar == "!" || lastChar == "?" || lastChar == ":" {
                        steps.append(currentStep)
                        currentStep = trimmed
                    } else {
                        currentStep += " " + trimmed
                    }
                }
            }
        }
        
        if !currentStep.isEmpty {
            steps.append(currentStep)
        }
        
        return steps.filter { !$0.isEmpty }
    }


    private func IngredientsCollect(from MealsFromAPI : MealAPIModel) -> [Ingredient] {
        
        var INGR:  [Ingredient] = []

        let PairsOFINGRED : [ (String? , String?) ] = [
            (MealsFromAPI.strIngredient1 , MealsFromAPI.strMeasure1) ,
            (MealsFromAPI.strIngredient2 , MealsFromAPI.strMeasure2) ,
            (MealsFromAPI.strIngredient3 , MealsFromAPI.strMeasure3) ,
            (MealsFromAPI.strIngredient4 , MealsFromAPI.strMeasure4) ,
            (MealsFromAPI.strIngredient5 , MealsFromAPI.strMeasure5) ,
            (MealsFromAPI.strIngredient6 , MealsFromAPI.strMeasure6) ,
            (MealsFromAPI.strIngredient7 , MealsFromAPI.strMeasure7) ,
            (MealsFromAPI.strIngredient8 , MealsFromAPI.strMeasure8) ,
            (MealsFromAPI.strIngredient9 , MealsFromAPI.strMeasure9) ,
            (MealsFromAPI.strIngredient10 , MealsFromAPI.strMeasure10) ,
            (MealsFromAPI.strIngredient11 , MealsFromAPI.strMeasure11) ,
            (MealsFromAPI.strIngredient12 , MealsFromAPI.strMeasure12) ,
            (MealsFromAPI.strIngredient13 , MealsFromAPI.strMeasure13) ,
            (MealsFromAPI.strIngredient14 , MealsFromAPI.strMeasure14) ,
            (MealsFromAPI.strIngredient15 , MealsFromAPI.strMeasure15) ,
            (MealsFromAPI.strIngredient16 , MealsFromAPI.strMeasure16) ,
            (MealsFromAPI.strIngredient17 , MealsFromAPI.strMeasure17) ,
            (MealsFromAPI.strIngredient18 , MealsFromAPI.strMeasure18) ,
            (MealsFromAPI.strIngredient19 , MealsFromAPI.strMeasure19) ,
            (MealsFromAPI.strIngredient20 , MealsFromAPI.strMeasure20)
        ]

        for (ingredient , measure) in PairsOFINGRED {
            
            if let ing=ingredient?.trimmingCharacters(in : .whitespaces) ,
               
               !ing.isEmpty,
               
               let meas=measure?.trimmingCharacters(in : .whitespaces) ,
               
               !meas.isEmpty {
                
                INGR.append( Ingredient(name : ing , quantity : meas) )
            }
        }

        return INGR
    }

    enum ErrorfromAPI : LocalizedError {
        
        case INVALIDURL
        
        case INVALIDRES
        
        case httpError(STSC : Int)
        
        case NetERR(Error)
        
        case DecodeERR(DecodingError)
        
        case NothingData

        var errorDescription : String? {
            
            switch self {
            
            case .INVALIDRES:
                
                return "Invalid server response"
                
            case .INVALIDURL:
                
                return "Invalid URL"
            
            case .httpError(let STSC):
                
                return "HTTP Error => \(STSC)"
                
            case .NetERR(let ERR):
                
                return "Network Error => \(ERR.localizedDescription)"
                
            case .DecodeERR(let ERR):
                
                return "Decoding Error => \(ERR.localizedDescription)"
                
            case .NothingData:
                
                return "No data received"
            }
        }
    }
}
