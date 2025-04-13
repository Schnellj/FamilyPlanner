import SwiftUI

struct StartPageView: View {
    @ObservedObject var mealPlanner: MealPlanner
    @ObservedObject var calendarManager: CalendarManager
    @ObservedObject var groceryListManager: GroceryListManager
    @Binding var selectedRecipe: Recipe?
    @Binding var showingRecipeDetail: Bool
    @Binding var selectedDate: Date
    @Binding var selectedViewMode: ContentView.ViewMode
    
    // Sample news items - in a real app, these would come from an API or database
    private let newsItems = [
        NewsItem(title: "Family Vacation Planning", description: "Start planning our summer vacation", link: "https://example.com/vacation"),
        NewsItem(title: "School Calendar", description: "Check upcoming school events", link: "https://example.com/school"),
        NewsItem(title: "Local Events", description: "Discover events happening in your area", link: "https://example.com/events")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Welcome section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to Quick Meal Planner")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Your family's meal planning assistant")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 10)
                
                // Quick actions
                HStack(spacing: 15) {
                    QuickActionButton(
                        title: "View Weekly Plan",
                        icon: "calendar",
                        action: {
                            selectedViewMode = .weekly
                        }
                    )
                    
                    QuickActionButton(
                        title: "Grocery List",
                        icon: "cart",
                        action: {
                            // Navigate to grocery list
                        }
                    )
                    
                    QuickActionButton(
                        title: "Add Recipe",
                        icon: "plus.circle",
                        action: {
                            // Add recipe action
                        }
                    )
                }
                .padding(.bottom, 10)
                
                // Meal plan overview
                if !mealPlanner.weeklyPlan.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("This Week's Meals")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(mealPlanner.weeklyPlan.prefix(5)) { meal in
                                    MealCard(meal: meal, selectedRecipe: $selectedRecipe, showingRecipeDetail: $showingRecipeDetail)
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                    .padding(.bottom, 10)
                }
                
                // Family news and links
                VStack(alignment: .leading, spacing: 10) {
                    Text("Family News & Links")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(newsItems) { item in
                            NewsCard(newsItem: item)
                        }
                    }
                }
                .padding(.bottom, 10)
                
                // Application alerts and overviews
                VStack(alignment: .leading, spacing: 10) {
                    Text("Overview & Alerts")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        // Grocery list alert
                        if !groceryListManager.currentList.items.isEmpty {
                            AlertCard(
                                title: "Grocery List",
                                description: "\(groceryListManager.currentList.items.count) items to buy",
                                icon: "cart.fill",
                                color: .blue
                            )
                        }
                        
                        // Calendar events
                        if !calendarManager.schedules.isEmpty {
                            AlertCard(
                                title: "Upcoming Events",
                                description: "\(calendarManager.schedules.count) events this week",
                                icon: "calendar.badge.clock",
                                color: .green
                            )
                        }
                        
                        // Quick meals count
                        if !mealPlanner.weeklyPlan.isEmpty {
                            let quickMealCount = mealPlanner.weeklyPlan.filter { $0.recommendedRecipe?.isQuickMeal == true }.count
                            AlertCard(
                                title: "Quick Meals",
                                description: "\(quickMealCount) quick meals this week",
                                icon: "bolt.fill",
                                color: .orange
                            )
                        }
                        
                        // Recipe count
                        if !mealPlanner.recipes.isEmpty {
                            AlertCard(
                                title: "Recipe Library",
                                description: "\(mealPlanner.recipes.count) recipes available",
                                icon: "book.fill",
                                color: .purple
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// Supporting views and models
struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let link: String
}

struct NewsCard: View {
    let newsItem: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(newsItem.title)
                .font(.headline)
            
            Text(newsItem.description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            Link("Learn More", destination: URL(string: newsItem.link)!)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AlertCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
        }
    }
}

struct MealCard: View {
    let meal: DaySchedule
    @Binding var selectedRecipe: Recipe?
    @Binding var showingRecipeDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(meal.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundColor(.gray)
            
            if let recipe = meal.recommendedRecipe {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(recipe.prepTime + recipe.cookTime) min")
                        .font(.caption)
                }
                .foregroundColor(.gray)
                
                Button("View Recipe") {
                    selectedRecipe = recipe
                    showingRecipeDetail = true
                }
                .font(.caption)
                .padding(.top, 4)
            } else {
                Text("No meal planned")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 180)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StartPageView_Previews: PreviewProvider {
    static var previews: some View {
        StartPageView(
            mealPlanner: MealPlanner(),
            calendarManager: CalendarManager(),
            groceryListManager: GroceryListManager(),
            selectedRecipe: .constant(nil),
            showingRecipeDetail: .constant(false),
            selectedDate: .constant(Date()),
            selectedViewMode: .constant(.weekly)
        )
    }
} 