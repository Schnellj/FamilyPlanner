import Foundation

class GroceryListManager: ObservableObject {
    @Published var currentList: GroceryList = GroceryList()
    private let userDefaults = UserDefaults.standard
    private let groceryListKey = "groceryList"
    
    init() {
        loadSavedList()
    }
    
    func generateListFromRecipes(_ recipes: [Recipe]) {
        var groceryItems: [GroceryItem] = []
        
        for recipe in recipes {
            for ingredient in recipe.ingredients {
                // Extract quantity and name from ingredient string
                let (name, quantity) = parseIngredient(ingredient)
                
                // Check if we already have this item
                if let existingIndex = groceryItems.firstIndex(where: { $0.name.lowercased() == name.lowercased() }) {
                    // Update the recipe names for this item
                    var updatedItem = groceryItems[existingIndex]
                    if !updatedItem.recipeNames.contains(recipe.name) {
                        updatedItem.recipeNames.append(recipe.name)
                        groceryItems[existingIndex] = updatedItem
                    }
                } else {
                    // Add new item
                    let newItem = GroceryItem(
                        name: name,
                        quantity: quantity,
                        recipeNames: [recipe.name]
                    )
                    groceryItems.append(newItem)
                }
            }
        }
        
        // Sort items alphabetically by name
        groceryItems.sort { $0.name.lowercased() < $1.name.lowercased() }
        
        // Update the current list
        currentList = GroceryList(items: groceryItems)
        saveList()
    }
    
    func toggleItemChecked(_ item: GroceryItem) {
        if let index = currentList.items.firstIndex(where: { $0.id == item.id }) {
            currentList.items[index].isChecked.toggle()
            saveList()
        }
    }
    
    func clearCheckedItems() {
        currentList.items.removeAll { $0.isChecked }
        saveList()
    }
    
    private func parseIngredient(_ ingredient: String) -> (name: String, quantity: String) {
        // Remove HTML strong tags and clean up the ingredient string
        let cleanIngredient = ingredient.replacingOccurrences(of: "<strong>", with: "")
            .replacingOccurrences(of: "</strong>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split the ingredient into parts
        let parts = cleanIngredient.components(separatedBy: .whitespaces)
        
        // If we have at least 2 parts (quantity and ingredient name)
        if parts.count >= 2 {
            // The first part is typically the quantity
            let quantity = parts[0]
            
            // Check if the second part is a measurement unit
            let measurementUnits = ["cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp", "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs", "gram", "grams", "g", "kilogram", "kilograms", "kg", "ml", "milliliter", "milliliters", "l", "liter", "liters"]
            
            var finalQuantity = quantity
            var finalName = parts[1...].joined(separator: " ")
            
            // Check if the name starts with a measurement unit
            for unit in measurementUnits {
                if finalName.lowercased().hasPrefix(unit.lowercased()) {
                    let unitIndex = finalName.range(of: unit, options: .caseInsensitive)?.upperBound ?? finalName.startIndex
                    let remainingName = String(finalName[unitIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    finalQuantity = "\(quantity) \(unit)"
                    finalName = remainingName
                    break
                }
            }
            
            return (finalName, finalQuantity)
        }
        
        // If we can't parse it properly, return the whole string as the name
        return (cleanIngredient, "")
    }
    
    private func saveList() {
        if let encodedData = try? JSONEncoder().encode(currentList) {
            userDefaults.set(encodedData, forKey: groceryListKey)
        }
    }
    
    private func loadSavedList() {
        if let data = userDefaults.data(forKey: groceryListKey),
           let decodedList = try? JSONDecoder().decode(GroceryList.self, from: data) {
            currentList = decodedList
        }
    }
} 