import Foundation

class RecipeParser {
    enum ParserError: Error {
        case fileReadError
        case parsingError
    }
    
    func parseRecipeFile(at url: URL) throws -> Recipe {
        print("Parsing recipe file: \(url.lastPathComponent)")
        let htmlContent = try String(contentsOf: url, encoding: .utf8)
        print("Successfully read HTML content")
        
        // Extract recipe name from h1 tag with class "name"
        let name = extractValue(from: htmlContent, between: "<h1 itemprop=\"name\" class=\"name\">", and: "</h1>") ?? 
                   url.deletingPathExtension().lastPathComponent
        print("Extracted name: \(name)")
        
        // Extract prep time from metadata section
        let prepTimeStr = extractValue(from: htmlContent, between: "<b>Prep Time: </b><span itemprop=\"prepTime\">", and: "</span>") ?? "0 min"
        let prepTime = parseTimeString(prepTimeStr)
        print("Extracted prep time: \(prepTime) minutes")
        
        // Extract cook time from metadata section
        let cookTimeStr = extractValue(from: htmlContent, between: "<b>Cook Time: </b><span itemprop=\"cookTime\">", and: "</span>") ?? "0 min"
        let cookTime = parseTimeString(cookTimeStr)
        print("Extracted cook time: \(cookTime) minutes")
        
        // Extract difficulty (default to Medium if not found)
        let difficulty = "Medium"
        print("Using default difficulty: \(difficulty)")
        
        // Extract categories
        let categoriesStr = extractValue(from: htmlContent, between: "<p itemprop=\"recipeCategory\" class=\"categories\">", and: "</p>") ?? ""
        let categories = categoriesStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        print("Extracted categories: \(categories)")
        
        // Extract ingredients from p tags with class "line" and itemprop "recipeIngredient"
        let ingredients = extractIngredientsFromHTML(htmlContent)
        print("Extracted \(ingredients.count) ingredients")
        
        // Extract instructions from p tags with class "line" inside div with itemprop "recipeInstructions"
        let instructions = extractInstructionsFromHTML(htmlContent)
        print("Extracted \(instructions.count) instructions")
        
        return Recipe(
            name: name,
            prepTime: prepTime,
            cookTime: cookTime,
            difficulty: difficulty,
            ingredients: ingredients,
            instructions: instructions,
            categories: categories
        )
    }
    
    private func extractValue(from html: String, between start: String, and end: String) -> String? {
        guard let startRange = html.range(of: start),
              let endRange = html.range(of: end, range: startRange.upperBound..<html.endIndex) else {
            print("Could not find text between '\(start)' and '\(end)'")
            return nil
        }
        return String(html[startRange.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseTimeString(_ timeStr: String) -> Int {
        print("Parsing time string: \(timeStr)")
        let components = timeStr.components(separatedBy: " ")
        if components.count >= 2 {
            if let number = Int(components[0]) {
                if components[1].contains("hour") {
                    return number * 60
                } else if components[1].contains("min") {
                    return number
                }
            }
        }
        print("Could not parse time string: \(timeStr)")
        return 0
    }
    
    private func extractIngredientsFromHTML(_ html: String) -> [String] {
        // Find the ingredients section
        guard let ingredientsStart = html.range(of: "<div class=\"ingredients text\">"),
              let ingredientsEnd = html.range(of: "</div>", range: ingredientsStart.upperBound..<html.endIndex) else {
            print("Could not find ingredients section")
            return []
        }
        
        let ingredientsSection = String(html[ingredientsStart.upperBound..<ingredientsEnd.lowerBound])
        
        // Extract each ingredient line
        var ingredients: [String] = []
        var currentPosition = ingredientsSection.startIndex
        
        while let lineStart = ingredientsSection.range(of: "<p class=\"line\" itemprop=\"recipeIngredient\">", range: currentPosition..<ingredientsSection.endIndex),
              let lineEnd = ingredientsSection.range(of: "</p>", range: lineStart.upperBound..<ingredientsSection.endIndex) {
            
            let ingredientLine = String(ingredientsSection[lineStart.upperBound..<lineEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !ingredientLine.isEmpty {
                ingredients.append(ingredientLine)
            }
            
            currentPosition = lineEnd.upperBound
        }
        
        print("Found ingredients: \(ingredients)")
        return ingredients
    }
    
    private func extractInstructionsFromHTML(_ html: String) -> [String] {
        // Find the instructions section
        guard let instructionsStart = html.range(of: "<div itemprop=\"recipeInstructions\" class=\"directions text\">"),
              let instructionsEnd = html.range(of: "</div>", range: instructionsStart.upperBound..<html.endIndex) else {
            print("Could not find instructions section")
            return []
        }
        
        let instructionsSection = String(html[instructionsStart.upperBound..<instructionsEnd.lowerBound])
        
        // Extract each instruction line
        var instructions: [String] = []
        var currentPosition = instructionsSection.startIndex
        
        while let lineStart = instructionsSection.range(of: "<p class=\"line\">", range: currentPosition..<instructionsSection.endIndex),
              let lineEnd = instructionsSection.range(of: "</p>", range: lineStart.upperBound..<instructionsSection.endIndex) {
            
            let instructionLine = String(instructionsSection[lineStart.upperBound..<lineEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !instructionLine.isEmpty {
                instructions.append(instructionLine)
            }
            
            currentPosition = lineEnd.upperBound
        }
        
        print("Found instructions: \(instructions)")
        return instructions
    }
} 