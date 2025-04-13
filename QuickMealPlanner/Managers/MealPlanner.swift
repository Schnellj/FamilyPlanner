import Foundation
import EventKit
import SwiftUI
import UniformTypeIdentifiers

class MealPlanner: ObservableObject {
    private let recipeParser = RecipeParser()
    @Published var recipes: [Recipe] = []
    @Published var selectedRecipeDirectory: URL?
    @Published var weeklyPlan: [DaySchedule] = []
    @Published var historicalPlans: [HistoricalMealPlan] = []
    @Published var showingDirectoryPicker = false
    
    // Meal planning preferences
    private let maxQuickMealsPerWeek = 3
    private let maxMediumMealsPerWeek = 3
    private let minLongMealsPerWeek = 1
    
    private let userDefaults = UserDefaults.standard
    private let selectedDirectoryKey = "selectedRecipeDirectory"
    private let weeklyPlanKey = "weeklyPlan"
    private let historicalPlansKey = "historicalPlans"
    
    init() {
        loadSavedDirectory()
        loadSavedWeeklyPlan()
        loadHistoricalPlans()
    }
    
    private func loadHistoricalPlans() {
        if let data = userDefaults.data(forKey: historicalPlansKey),
           let decodedPlans = try? JSONDecoder().decode([HistoricalMealPlan].self, from: data) {
            historicalPlans = decodedPlans
        }
    }
    
    private func saveHistoricalPlans() {
        if let encodedData = try? JSONEncoder().encode(historicalPlans) {
            userDefaults.set(encodedData, forKey: historicalPlansKey)
        }
    }
    
    private func loadSavedWeeklyPlan() {
        if let data = userDefaults.data(forKey: weeklyPlanKey),
           let decodedPlan = try? JSONDecoder().decode([DaySchedule].self, from: data) {
            weeklyPlan = decodedPlan
        }
    }
    
    private func saveWeeklyPlan() {
        if let encodedData = try? JSONEncoder().encode(weeklyPlan) {
            userDefaults.set(encodedData, forKey: weeklyPlanKey)
        }
    }
    
    func loadRecipes(from directory: URL) {
        print("Loading recipes from directory: \(directory.path)")
        
        // Start accessing the security-scoped resource
        let didStartAccessing = directory.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                directory.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            let htmlFiles = fileURLs.filter { $0.pathExtension.lowercased() == "html" }
            print("Found \(htmlFiles.count) HTML files")
            
            recipes = []
            var successfulLoads = 0
            var failedLoads = 0
            
            for fileURL in htmlFiles {
                do {
                    let recipe = try recipeParser.parseRecipeFile(at: fileURL)
                    recipes.append(recipe)
                    successfulLoads += 1
                    print("Successfully loaded recipe: \(recipe.name)")
                } catch {
                    failedLoads += 1
                    print("Error parsing recipe file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            print("Recipe loading summary:")
            print("- Total HTML files found: \(htmlFiles.count)")
            print("- Successfully loaded: \(successfulLoads)")
            print("- Failed to load: \(failedLoads)")
            
            // If we have a weekly plan, update it with the new recipes
            if !weeklyPlan.isEmpty {
                weeklyPlan = recommendMeals(for: weeklyPlan)
            }
        } catch {
            print("Error loading recipes: \(error.localizedDescription)")
        }
    }
    
    func recommendMeals(for schedules: [DaySchedule]) -> [DaySchedule] {
        var updatedSchedules = schedules
        var quickMealsUsed = 0
        var mediumMealsUsed = 0
        var longMealsUsed = 0
        
        // First, assign meals to busy days
        for (index, schedule) in schedules.enumerated() {
            if schedule.isBusy {
                // For busy days, prioritize quick meals
                if let quickMeal = recipes.filter({ $0.isQuickMeal }).randomElement() {
                    updatedSchedules[index].recommendedRecipe = quickMeal
                    quickMealsUsed += 1
                }
            }
        }
        
        // Then, fill in the rest of the week with a balanced mix
        for (index, schedule) in schedules.enumerated() {
            if updatedSchedules[index].recommendedRecipe == nil {
                var selectedRecipe: Recipe?
                
                // Try to maintain a balance of meal types
                if longMealsUsed < minLongMealsPerWeek {
                    selectedRecipe = recipes.filter({ $0.isLongMeal }).randomElement()
                    if selectedRecipe != nil {
                        longMealsUsed += 1
                    }
                } else if mediumMealsUsed < maxMediumMealsPerWeek {
                    selectedRecipe = recipes.filter({ $0.isMediumMeal }).randomElement()
                    if selectedRecipe != nil {
                        mediumMealsUsed += 1
                    }
                } else if quickMealsUsed < maxQuickMealsPerWeek {
                    selectedRecipe = recipes.filter({ $0.isQuickMeal }).randomElement()
                    if selectedRecipe != nil {
                        quickMealsUsed += 1
                    }
                } else {
                    // If we've hit our limits, just pick any recipe
                    selectedRecipe = recipes.randomElement()
                }
                
                updatedSchedules[index].recommendedRecipe = selectedRecipe
            }
        }
        
        return updatedSchedules
    }
    
    func generateWeeklyPlan(from schedules: [DaySchedule]) {
        print("Generating weekly plan from \(schedules.count) schedules")
        
        // Archive the current plan before generating a new one
        if !weeklyPlan.isEmpty {
            archiveCurrentPlan()
        }
        
        // Reset weekly plan
        weeklyPlan = []
        
        // Sort recipes by total time, filtering for dinner recipes only
        let dinnerRecipes = recipes.filter { $0.isDinner }
        let quickMeals = dinnerRecipes.filter { $0.isQuickMeal }
        let mediumMeals = dinnerRecipes.filter { $0.isMediumMeal }
        let longMeals = dinnerRecipes.filter { $0.isLongMeal }
        
        print("Found \(dinnerRecipes.count) dinner recipes")
        print("Of which: \(quickMeals.count) quick meals, \(mediumMeals.count) medium meals, \(longMeals.count) long meals")
        
        // Generate plan for each day
        for schedule in schedules {
            var dayPlan = schedule
            
            // Check if it's an early cooking day (before 4 PM)
            if schedule.isEarlyCooking {
                print("Early cooking detected for \(schedule.date) - selecting quick meal")
                // For early cooking, always use quick meals
                if !quickMeals.isEmpty {
                    dayPlan.recommendedRecipe = quickMeals.randomElement()
                } else if !mediumMeals.isEmpty {
                    dayPlan.recommendedRecipe = mediumMeals.randomElement()
                } else {
                    dayPlan.recommendedRecipe = longMeals.randomElement()
                }
            }
            // Check if it's a busy night
            else if schedule.isBusyNight {
                print("Busy night detected for \(schedule.date)")
                // For busy nights, prioritize quick meals
                if !quickMeals.isEmpty {
                    dayPlan.recommendedRecipe = quickMeals.randomElement()
                } else if !mediumMeals.isEmpty {
                    dayPlan.recommendedRecipe = mediumMeals.randomElement()
                } else {
                    dayPlan.recommendedRecipe = longMeals.randomElement()
                }
            } else {
                // For normal nights, use available time to determine meal type
                let availableTime = schedule.availableTime
                print("Available time: \(availableTime) minutes for \(schedule.date)")
                
                if availableTime >= 60 && !longMeals.isEmpty {
                    dayPlan.recommendedRecipe = longMeals.randomElement()
                } else if availableTime >= 30 && !mediumMeals.isEmpty {
                    dayPlan.recommendedRecipe = mediumMeals.randomElement()
                } else if !quickMeals.isEmpty {
                    dayPlan.recommendedRecipe = quickMeals.randomElement()
                }
            }
            
            weeklyPlan.append(dayPlan)
        }
        
        print("Generated plan with \(weeklyPlan.count) days")
        saveWeeklyPlan()
    }
    
    func saveSelectedDirectory(_ url: URL) {
        // Create a security-scoped bookmark
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            userDefaults.set(bookmarkData, forKey: selectedDirectoryKey)
            selectedRecipeDirectory = url
            loadRecipes(from: url)
        } catch {
            print("Error saving directory bookmark: \(error.localizedDescription)")
        }
    }
    
    func loadSavedDirectory() {
        if let bookmarkData = userDefaults.data(forKey: selectedDirectoryKey) {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                if isStale {
                    print("Bookmark is stale, need to request new access")
                    return
                }
                
                // Start accessing the security-scoped resource
                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                selectedRecipeDirectory = url
                loadRecipes(from: url)
            } catch {
                print("Error loading directory bookmark: \(error.localizedDescription)")
            }
        }
    }
    
    func getMealPlanForDay(_ date: Date) -> DaySchedule? {
        return weeklyPlan.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func shuffleRecipeForDay(_ date: Date) {
        guard let index = weeklyPlan.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }
        let schedule = weeklyPlan[index]
        
        // Get appropriate recipes based on the day's schedule
        let dinnerRecipes = recipes.filter { $0.isDinner }
        let quickMeals = dinnerRecipes.filter { $0.isQuickMeal }
        let mediumMeals = dinnerRecipes.filter { $0.isMediumMeal }
        let longMeals = dinnerRecipes.filter { $0.isLongMeal }
        
        var selectedRecipe: Recipe?
        
        // Use the same logic as in generateWeeklyPlan
        if schedule.isEarlyCooking {
            if !quickMeals.isEmpty {
                selectedRecipe = quickMeals.randomElement()
            } else if !mediumMeals.isEmpty {
                selectedRecipe = mediumMeals.randomElement()
            } else {
                selectedRecipe = longMeals.randomElement()
            }
        } else if schedule.isBusyNight {
            if !quickMeals.isEmpty {
                selectedRecipe = quickMeals.randomElement()
            } else if !mediumMeals.isEmpty {
                selectedRecipe = mediumMeals.randomElement()
            } else {
                selectedRecipe = longMeals.randomElement()
            }
        } else {
            let availableTime = schedule.availableTime
            if availableTime >= 60 && !longMeals.isEmpty {
                selectedRecipe = longMeals.randomElement()
            } else if availableTime >= 30 && !mediumMeals.isEmpty {
                selectedRecipe = mediumMeals.randomElement()
            } else if !quickMeals.isEmpty {
                selectedRecipe = quickMeals.randomElement()
            }
        }
        
        weeklyPlan[index].recommendedRecipe = selectedRecipe
        saveWeeklyPlan()
    }
    
    func clearRecipeForDay(_ date: Date) {
        guard let index = weeklyPlan.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else { return }
        weeklyPlan[index].recommendedRecipe = nil
        saveWeeklyPlan()
    }
    
    func archiveCurrentPlan() {
        guard !weeklyPlan.isEmpty else { return }
        
        // Find the start and end dates of the current plan
        let startDate = weeklyPlan.map { $0.date }.min() ?? Date()
        let endDate = weeklyPlan.map { $0.date }.max() ?? Date()
        
        // Create a new historical plan
        let historicalPlan = HistoricalMealPlan(
            startDate: startDate,
            endDate: endDate,
            daySchedules: weeklyPlan
        )
        
        // Add to historical plans
        historicalPlans.append(historicalPlan)
        
        // Sort by date (newest first)
        historicalPlans.sort { $0.startDate > $1.startDate }
        
        // Save to UserDefaults
        saveHistoricalPlans()
    }
    
    func loadHistoricalPlan(_ plan: HistoricalMealPlan) {
        weeklyPlan = plan.daySchedules
        saveWeeklyPlan()
    }
} 