import SwiftUI

struct HistoricalPlansView: View {
    @ObservedObject var mealPlanner: MealPlanner
    @Binding var selectedRecipe: Recipe?
    @Binding var showingRecipeDetail: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(mealPlanner.historicalPlans) { plan in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.weekLabel)
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(plan.daySchedules) { schedule in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(schedule.date, style: .date)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    if schedule.isBusy {
                                        Text("Busy")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                }
                                
                                if let recipe = schedule.recommendedRecipe {
                                    Button(action: {
                                        selectedRecipe = recipe
                                        showingRecipeDetail = true
                                    }) {
                                        HStack {
                                            Text(recipe.name)
                                                .foregroundColor(.white)
                                                .font(.subheadline)
                                                .bold()
                                            Spacer()
                                            Text(recipe.formattedTotalTime)
                                                .foregroundColor(.gray)
                                                .font(.caption)
                                        }
                                    }
                                } else {
                                    Text("No meal planned")
                                        .foregroundColor(.gray)
                                        .italic()
                                        .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        mealPlanner.loadHistoricalPlan(plan)
                        dismiss()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Historical Meal Plans")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 