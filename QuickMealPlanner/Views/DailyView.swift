import SwiftUI
import Foundation

struct DailyView: View {
    @ObservedObject var mealPlanner: MealPlanner
    @Binding var selectedRecipe: Recipe?
    @Binding var showingRecipeDetail: Bool
    let date: Date
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    var body: some View {
        VStack {
            // Date navigation
            HStack {
                Button(action: { moveDay(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                
                Text(dateFormatter.string(from: date))
                    .font(.headline)
                
                Button(action: { moveDay(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            if let mealPlan = mealPlanner.getMealPlanForDay(date) {
                List {
                    Section(header: Text("Schedule")) {
                        if mealPlan.isBusy {
                            Text("Busy Day")
                                .foregroundColor(.red)
                        }
                        
                        if let cookEvent = mealPlan.cookDinnerEvent {
                            Text("Cook Dinner: \(timeFormatter.string(from: cookEvent.startDate)) - \(timeFormatter.string(from: cookEvent.endDate))")
                        }
                        
                        ForEach(mealPlan.events, id: \.eventIdentifier) { event in
                            Text("\(event.title ?? "Unknown Event"): \(timeFormatter.string(from: event.startDate)) - \(timeFormatter.string(from: event.endDate))")
                        }
                    }
                    
                    if let recipe = mealPlan.recommendedRecipe {
                        Section(header: Text("Recommended Meal")) {
                            HStack {
                                Button(action: {
                                    selectedRecipe = recipe
                                    showingRecipeDetail = true
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Total Time: \(recipe.formattedTotalTime)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        mealPlanner.shuffleRecipeForDay(date)
                                    }) {
                                        Image(systemName: "arrow.clockwise.circle.fill")
                                            .foregroundColor(.blue)
                                            .imageScale(.large)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .help("Shuffle recipe for this day")
                                    
                                    Button(action: {
                                        mealPlanner.clearRecipeForDay(date)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .imageScale(.large)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .help("Clear recipe for this day")
                                }
                            }
                        }
                    } else {
                        Section(header: Text("Recommended Meal")) {
                            HStack {
                                Text("No meal planned for this day")
                                    .foregroundColor(.gray)
                                    .italic()
                                
                                Spacer()
                                
                                Button(action: {
                                    mealPlanner.shuffleRecipeForDay(date)
                                }) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Shuffle recipe for this day")
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Text("No meal plan for this day")
                        .foregroundColor(.gray)
                    Text("Select a date within the next week")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func moveDay(by value: Int) {
        // Since we're using a constant date, we'll need to handle navigation through a callback
        // This will be implemented when we add date navigation
    }
} 