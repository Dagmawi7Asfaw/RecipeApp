// Copyright © 2023 Big Mountain Studio. All rights reserved. Twitter: @BigMtnStudio

import Foundation
import SwiftData
import UIKit

@Model
class IngredientModel {
    var name: String
    var quantity: String = ""
    var recipes: [RecipeModel] = []
    
    init(name: String, quantity: String = "", recipes: [RecipeModel] = []) {
        self.name = name
        self.quantity = quantity
        self.recipes = recipes
    }
}

extension IngredientModel {
    var viewIngredient: String {
        if quantity.isEmpty {
            return name
        } else {
            return "\(quantity) \(name)"
        }
    }
    
    func scaledIngredient(baseServing: Int, targetServing: Int) -> String {
        guard baseServing > 0, targetServing > 0, baseServing != targetServing, !quantity.isEmpty else {
            return viewIngredient
        }
        
        let ratio = Double(targetServing) / Double(baseServing)
        
        // Parse leading numeric value or fraction in quantity string
        let regex = try? NSRegularExpression(pattern: #"^([0-9\.\s/½⅓⅔¼¾⅛]+)"#)
        let nsString = quantity as NSString
        if let match = regex?.firstMatch(in: quantity, options: [], range: NSRange(location: 0, length: nsString.length)) {
            let matchedNumStr = nsString.substring(with: match.range).trimmingCharacters(in: .whitespaces)
            let restStr = nsString.substring(from: match.range.length)
            
            if let scaledVal = parseAndScaleNumber(matchedNumStr, multiplier: ratio) {
                return "\(scaledVal)\(restStr) \(name)".trimmingCharacters(in: .whitespaces)
            }
        }
        
        return viewIngredient
    }
    
    func scaledQuantity(baseServing: Int, targetServing: Int) -> String {
        guard baseServing > 0, targetServing > 0, baseServing != targetServing, !quantity.isEmpty else {
            return quantity
        }
        
        let ratio = Double(targetServing) / Double(baseServing)
        let regex = try? NSRegularExpression(pattern: #"^([0-9\.\s/½⅓⅔¼¾⅛]+)"#)
        let nsString = quantity as NSString
        if let match = regex?.firstMatch(in: quantity, options: [], range: NSRange(location: 0, length: nsString.length)) {
            let matchedNumStr = nsString.substring(with: match.range).trimmingCharacters(in: .whitespaces)
            let restStr = nsString.substring(from: match.range.length)
            
            if let scaledVal = parseAndScaleNumber(matchedNumStr, multiplier: ratio) {
                return "\(scaledVal)\(restStr)".trimmingCharacters(in: .whitespaces)
            }
        }
        
        return quantity
    }
    
    private func parseAndScaleNumber(_ str: String, multiplier: Double) -> String? {
        var total: Double = 0
        let parts = str.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        for part in parts {
            if let val = Double(part) {
                total += val
            } else if part == "½" { total += 0.5 }
            else if part == "⅓" { total += 0.333 }
            else if part == "⅔" { total += 0.666 }
            else if part == "¼" { total += 0.25 }
            else if part == "¾" { total += 0.75 }
            else if part == "⅛" { total += 0.125 }
            else if part.contains("/") {
                let fracParts = part.components(separatedBy: "/")
                if fracParts.count == 2, let num = Double(fracParts[0]), let den = Double(fracParts[1]), den != 0 {
                    total += num / den
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        guard total > 0 else { return nil }
        let scaled = total * multiplier
        
        // Format neatly (integer if whole, 2 decimals max)
        if scaled.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", scaled)
        } else {
            return String(format: "%.1f", scaled)
        }
    }
}
