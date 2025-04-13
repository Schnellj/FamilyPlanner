import Foundation
import EventKit

struct HistoricalMealPlan: Identifiable, Codable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let daySchedules: [DaySchedule]
    
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

struct DaySchedule: Identifiable, Equatable, Codable {
    let id: UUID
    let date: Date
    let events: [EKEvent]
    let isBusy: Bool
    var recommendedRecipe: Recipe?
    
    enum CodingKeys: String, CodingKey {
        case id, date, isBusy, recommendedRecipe
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        isBusy = try container.decode(Bool.self, forKey: .isBusy)
        recommendedRecipe = try container.decodeIfPresent(Recipe.self, forKey: .recommendedRecipe)
        events = [] // Events will be reloaded from calendar
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(isBusy, forKey: .isBusy)
        try container.encodeIfPresent(recommendedRecipe, forKey: .recommendedRecipe)
    }
    
    init(date: Date, events: [EKEvent], isBusy: Bool, recommendedRecipe: Recipe? = nil) {
        self.id = UUID()
        self.date = date
        self.events = events
        self.isBusy = isBusy
        self.recommendedRecipe = recommendedRecipe
    }
    
    var cookDinnerEvent: EKEvent? {
        events.first { $0.title.lowercased().contains("cook dinner") }
    }
    
    var isEarlyCooking: Bool {
        guard let cookEvent = cookDinnerEvent else { return false }
        
        // Check if cooking event starts before 4 PM
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour], from: cookEvent.startDate)
        return components.hour ?? 0 < 16 // 16 = 4 PM
    }
    
    var availableTime: Int {
        // If no cook dinner event, default to 120 minutes (2 hours)
        guard let cookEvent = cookDinnerEvent else { return 120 }
        
        // If cooking before 4 PM, it's a rushed day - only 30 minutes available
        if isEarlyCooking {
            return 30
        }
        
        // Find events that start after the cook dinner event
        let eventsAfterCooking = events
            .filter { $0.startDate > cookEvent.startDate }
            .sorted { $0.startDate < $1.startDate }
        
        // If there's an event within 30 minutes after cooking, it's a busy night
        if let nextEvent = eventsAfterCooking.first,
           Calendar.current.dateComponents([.minute], from: cookEvent.endDate, to: nextEvent.startDate).minute ?? 0 < 30 {
            return 30 // Assume only 30 minutes available for a busy night
        }
        
        // If there's no event for 1+ hours after cooking, it's a normal night
        if eventsAfterCooking.isEmpty || 
           Calendar.current.dateComponents([.minute], from: cookEvent.endDate, to: eventsAfterCooking[0].startDate).minute ?? 0 >= 60 {
            return 120 // Assume 2 hours available for a normal night
        }
        
        // For other cases, use the actual time until the next event
        if let nextEvent = eventsAfterCooking.first {
            return Calendar.current.dateComponents([.minute], from: cookEvent.endDate, to: nextEvent.startDate).minute ?? 30
        }
        
        return 120 // Default to 2 hours if no next event
    }
    
    var isBusyNight: Bool {
        guard let cookEvent = cookDinnerEvent else { return false }
        
        // Early cooking (before 4 PM) is considered busy
        if isEarlyCooking {
            return true
        }
        
        // Find events that start after the cook dinner event
        let eventsAfterCooking = events
            .filter { $0.startDate > cookEvent.startDate }
            .sorted { $0.startDate < $1.startDate }
        
        // It's a busy night if there's an event within 30 minutes after cooking
        if let nextEvent = eventsAfterCooking.first,
           Calendar.current.dateComponents([.minute], from: cookEvent.endDate, to: nextEvent.startDate).minute ?? 0 < 30 {
            return true
        }
        
        return false
    }
    
    static func == (lhs: DaySchedule, rhs: DaySchedule) -> Bool {
        // Compare the essential properties that define equality
        return lhs.date == rhs.date &&
               lhs.isBusy == rhs.isBusy &&
               lhs.events.map { $0.eventIdentifier } == rhs.events.map { $0.eventIdentifier }
    }
}

struct Recipe: Identifiable, Codable {
    let id: UUID
    let name: String
    let prepTime: Int
    let cookTime: Int
    let difficulty: String
    let ingredients: [String]
    let instructions: [String]
    let categories: [String]
    
    init(name: String, prepTime: Int, cookTime: Int, difficulty: String, ingredients: [String], instructions: [String], categories: [String]) {
        self.id = UUID()
        self.name = name
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.difficulty = difficulty
        self.ingredients = ingredients
        self.instructions = instructions
        self.categories = categories
    }
    
    var isDinner: Bool {
        return categories.contains { $0.contains("Dinner") }
    }
    
    var totalTime: Int {
        return prepTime + cookTime
    }
    
    var formattedTotalTime: String {
        if totalTime < 60 {
            return "\(totalTime) min"
        } else {
            let hours = totalTime / 60
            let minutes = totalTime % 60
            if minutes == 0 {
                return "\(hours) hr"
            } else {
                return "\(hours) hr \(minutes) min"
            }
        }
    }
    
    var isQuickMeal: Bool {
        return totalTime <= 30
    }
    
    var isMediumMeal: Bool {
        return totalTime > 30 && totalTime <= 60
    }
    
    var isLongMeal: Bool {
        return totalTime > 60
    }
}

struct GroceryItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let quantity: String
    var isChecked: Bool
    var recipeNames: [String]
    
    init(id: UUID = UUID(), name: String, quantity: String, isChecked: Bool = false, recipeNames: [String] = []) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isChecked = isChecked
        self.recipeNames = recipeNames
    }
}

struct GroceryList: Identifiable, Codable {
    let id: UUID
    var items: [GroceryItem]
    var date: Date
    
    init(items: [GroceryItem] = [], date: Date = Date()) {
        self.id = UUID()
        self.items = items
        self.date = date
    }
} 