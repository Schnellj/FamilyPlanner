import SwiftUI
import Foundation

struct WeeklyView: View {
    @ObservedObject var mealPlanner: MealPlanner
    @ObservedObject var calendarManager: CalendarManager
    @Binding var selectedRecipe: Recipe?
    @Binding var showingRecipeDetail: Bool
    @Binding var selectedDate: Date
    @Binding var selectedViewMode: ContentView.ViewMode
    @State private var showingRefreshAlert = false
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        if mealPlanner.weeklyPlan.isEmpty {
            VStack {
                Text("No meal plan available")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Make sure you have:")
                    .padding(.top)
                Text("1. Selected a recipe directory")
                Text("2. Granted calendar access")
                Text("3. Have events in your calendar")
            }
            .padding()
        } else {
            List {
                ForEach(mealPlanner.weeklyPlan) { schedule in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(schedule.date, style: .date)
                                .font(.headline)
                            Spacer()
                            if schedule.isBusy {
                                Text("Busy")
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let recipe = schedule.recommendedRecipe {
                            HStack {
                                Button(action: {
                                    selectedRecipe = recipe
                                    showingRecipeDetail = true
                                }) {
                                    HStack {
                                        Text(recipe.name)
                                            .foregroundColor(.primary)
                                            .font(.headline)
                                            .bold()
                                        Spacer()
                                        Text(recipe.formattedTotalTime)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Button(action: {
                                    mealPlanner.shuffleRecipeForDay(schedule.date)
                                }) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Shuffle recipe for this day")
                                
                                Button(action: {
                                    mealPlanner.clearRecipeForDay(schedule.date)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .imageScale(.large)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Clear recipe for this day")
                            }
                        } else {
                            HStack {
                                Text("No meal planned")
                                    .foregroundColor(.gray)
                                    .italic()
                                
                                Spacer()
                                
                                Button(action: {
                                    mealPlanner.shuffleRecipeForDay(schedule.date)
                                }) {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("Shuffle recipe for this day")
                            }
                        }
                        
                        ForEach(schedule.events, id: \.eventIdentifier) { event in
                            Text("\(event.title ?? "Unknown Event"): \(event.startDate, style: .time)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDateSelected(schedule.date)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Picker("View Mode", selection: $selectedViewMode) {
                            Text("Weekly").tag(ContentView.ViewMode.weekly)
                            Text("Daily").tag(ContentView.ViewMode.daily)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                        .onChange(of: selectedViewMode) { newMode in
                            if newMode == .daily {
                                // When switching to daily view, use the first day of the week
                                if let firstDay = mealPlanner.weeklyPlan.first?.date {
                                    selectedDate = firstDay
                                }
                            }
                        }
                        
                        Button("Refresh") {
                            showingRefreshAlert = true
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                }
            }
            .alert("Generate New Plan", isPresented: $showingRefreshAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Generate") {
                    calendarManager.fetchNextWeekEvents()
                    if !calendarManager.schedules.isEmpty {
                        mealPlanner.generateWeeklyPlan(from: calendarManager.schedules)
                    }
                }
            } message: {
                Text("Are you sure you want to generate a new food plan?")
            }
        }
    }
} 