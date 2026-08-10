import Foundation
import UIKit

struct ParsedWebRecipe {
    var title: String
    var description: String
    var imageUrl: String?
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var category: String
    var ingredients: [String]
    var instructions: [String]
}

class WebRecipeParser {
    static let shared = WebRecipeParser()
    
    func parseRecipe(from urlString: String) async throws -> ParsedWebRecipe {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        // 1. Try to find schema.org/Recipe JSON-LD
        if let recipe = parseJSONLD(html: html) {
            return recipe
        }
        
        // 2. Fallback to OpenGraph / Meta tags parsing
        return parseMetaTags(html: html, fallbackUrl: urlString)
    }
    
    private func parseJSONLD(html: String) -> ParsedWebRecipe? {
        let pattern = "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>([\\s\\S]*?)</script>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        
        for match in matches {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let jsonData = jsonString.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) else { continue }
            
            if let dict = jsonObject as? [String: Any], isRecipeType(dict) {
                return extractRecipeFromDict(dict)
            } else if let array = jsonObject as? [[String: Any]] {
                for dict in array where isRecipeType(dict) {
                    return extractRecipeFromDict(dict)
                }
            } else if let dict = jsonObject as? [String: Any], let graph = dict["@graph"] as? [[String: Any]] {
                for item in graph where isRecipeType(item) {
                    return extractRecipeFromDict(item)
                }
            }
        }
        return nil
    }
    
    private func isRecipeType(_ dict: [String: Any]) -> Bool {
        if let type = dict["@type"] as? String {
            return type.lowercased() == "recipe"
        } else if let types = dict["@type"] as? [String] {
            return types.contains { $0.lowercased() == "recipe" }
        }
        return false
    }
    
    private func extractRecipeFromDict(_ dict: [String: Any]) -> ParsedWebRecipe {
        let title = dict["name"] as? String ?? "Imported Recipe"
        let description = dict["description"] as? String ?? ""
        
        var imageUrl: String? = nil
        if let img = dict["image"] as? String {
            imageUrl = img
        } else if let imgArr = dict["image"] as? [String], let first = imgArr.first {
            imageUrl = first
        } else if let imgObj = dict["image"] as? [String: Any], let url = imgObj["url"] as? String {
            imageUrl = url
        }
        
        let prepTime = parseISO8601Duration(dict["prepTime"] as? String)
        let cookTime = parseISO8601Duration(dict["cookTime"] as? String)
        
        var servings = 4
        if let yield = dict["recipeYield"] as? String {
            servings = Int(yield.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 4
        } else if let yieldInt = dict["recipeYield"] as? Int {
            servings = yieldInt
        }
        
        let category = (dict["recipeCategory"] as? String) ?? (dict["recipeCuisine"] as? String) ?? "Imported"
        
        var rawIngredients: [String] = []
        if let ingList = dict["recipeIngredient"] as? [String] {
            rawIngredients = ingList
        }
        
        var rawInstructions: [String] = []
        if let instructions = dict["recipeInstructions"] as? [Any] {
            for item in instructions {
                if let str = item as? String {
                    rawInstructions.append(str)
                } else if let obj = item as? [String: Any], let text = obj["text"] as? String {
                    rawInstructions.append(text)
                }
            }
        }
        
        return ParsedWebRecipe(
            title: title,
            description: description,
            imageUrl: imageUrl,
            prepTimeMinutes: prepTime > 0 ? prepTime : 15,
            cookTimeMinutes: cookTime > 0 ? cookTime : 25,
            servings: max(servings, 1),
            category: category,
            ingredients: rawIngredients.isEmpty ? ["1 tbsp Olive Oil", "Salt and pepper to taste"] : rawIngredients,
            instructions: rawInstructions.isEmpty ? ["Prepare all ingredients and serve warm."] : rawInstructions
        )
    }
    
    private func parseMetaTags(html: String, fallbackUrl: String) -> ParsedWebRecipe {
        func getTagContent(_ property: String) -> String? {
            let pattern = "<meta[^>]+(?:property|name)=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html) else { return nil }
            return String(html[range])
        }
        
        let title = getTagContent("og:title") ?? getTagContent("twitter:title") ?? "Online Recipe"
        let description = getTagContent("og:description") ?? ""
        let image = getTagContent("og:image")
        
        return ParsedWebRecipe(
            title: title,
            description: description,
            imageUrl: image,
            prepTimeMinutes: 15,
            cookTimeMinutes: 20,
            servings: 4,
            category: "Web Import",
            ingredients: ["Fresh ingredients as described in source page"],
            instructions: ["Follow preparation instructions from \(fallbackUrl)"]
        )
    }
    
    private func parseISO8601Duration(_ duration: String?) -> Int {
        guard let duration else { return 0 }
        var minutes = 0
        if let hourRange = duration.range(of: "(\\d+)H", options: .regularExpression) {
            let hoursStr = String(duration[hourRange]).dropLast()
            minutes += (Int(hoursStr) ?? 0) * 60
        }
        if let minRange = duration.range(of: "(\\d+)M", options: .regularExpression) {
            let minsStr = String(duration[minRange]).dropLast()
            minutes += Int(minsStr) ?? 0
        }
        return minutes
    }
}
