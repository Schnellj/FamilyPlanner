import SwiftUI
import UniformTypeIdentifiers
import EventKit

struct ContentView: View {
    @StateObject private var calendarManager = CalendarManager()
    @StateObject private var mealPlanner = MealPlanner()
    @StateObject private var groceryListManager = GroceryListManager()
    @State private var showingDirectoryPicker = false
    @State private var showingRecipeDetail = false
    @State private var showingHistoricalPlans = false
    @State private var selectedRecipe: Recipe?
    @State private var selectedViewMode: ViewMode = .weekly
    @State private var selectedDate: Date = Date()
    @State private var expandedSections: Set<String> = ["summary", "generate"]
    @State private var showingRefreshAlert = false
    @State private var showingBankingDirectoryPicker = false
    
    enum ViewMode {
        case weekly
        case daily
    }
    
    private var quickMealCount: Int {
        mealPlanner.weeklyPlan.filter { $0.recommendedRecipe?.isQuickMeal == true }.count
    }
    
    private var mediumMealCount: Int {
        mealPlanner.weeklyPlan.filter { $0.recommendedRecipe?.isMediumMeal == true }.count
    }
    
    private var longMealCount: Int {
        mealPlanner.weeklyPlan.filter { $0.recommendedRecipe?.isLongMeal == true }.count
    }
    
    private var calendarAccessDeniedView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar access denied")
                .foregroundColor(.red)
            Text("To enable calendar access:")
                .font(.subheadline)
            Text("1. Open System Settings")
            Text("2. Go to Privacy & Security")
            Text("3. Select Calendars")
            Text("4. Enable access for QuickMealPlanner")
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            List {
                // Home button to return to start page
                NavigationLink(destination: StartPageView(
                    mealPlanner: mealPlanner,
                    calendarManager: calendarManager,
                    groceryListManager: groceryListManager,
                    selectedRecipe: $selectedRecipe,
                    showingRecipeDetail: $showingRecipeDetail,
                    selectedDate: $selectedDate,
                    selectedViewMode: $selectedViewMode
                )) {
                    Label("Home", systemImage: "house")
                }
                .padding(.bottom, 8)
                
                if !mealPlanner.weeklyPlan.isEmpty {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("summary") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("summary")
                                } else {
                                    expandedSections.remove("summary")
                                }
                            }
                        ),
                        content: {
                            NavigationLink(destination: WeeklyView(mealPlanner: mealPlanner, calendarManager: calendarManager, selectedRecipe: $selectedRecipe, showingRecipeDetail: $showingRecipeDetail, selectedDate: $selectedDate, selectedViewMode: $selectedViewMode, onDateSelected: { date in
                                selectedDate = date
                                selectedViewMode = .daily
                            })) {
                                Label("View Weekly Plan", systemImage: "calendar")
                            }
                            .padding(.bottom, 4)
                            
                            Text("\(quickMealCount) quick meals")
                            Text("\(mediumMealCount) medium meals")
                            Text("\(longMealCount) long meals")
                            
                            Button("View Historical Plans") {
                                showingHistoricalPlans = true
                            }
                            .padding(.top, 4)
                        },
                        label: {
                            Text("Weekly Summary")
                                .font(.headline)
                        }
                    )
                } else if !mealPlanner.recipes.isEmpty {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("generate") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("generate")
                                } else {
                                    expandedSections.remove("generate")
                                }
                            }
                        ),
                        content: {
                            Text("No meal plan generated yet")
                                .foregroundColor(.gray)
                            Button("Generate Meal Plan") {
                                if !calendarManager.schedules.isEmpty {
                                    mealPlanner.generateWeeklyPlan(from: calendarManager.schedules)
                                } else {
                                    calendarManager.fetchNextWeekEvents()
                                }
                            }
                        },
                        label: {
                            Text("Generate Plan")
                                .font(.headline)
                        }
                    )
                }
                
                Section(header: Text("Errands")) {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("grocery") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("grocery")
                                } else {
                                    expandedSections.remove("grocery")
                                }
                            }
                        ),
                        content: {
                            NavigationLink(destination: GroceryListView(groceryListManager: groceryListManager)) {
                                Label("View Grocery List", systemImage: "list.bullet")
                            }
                        },
                        label: {
                            Label("Grocery List", systemImage: "cart")
                                .font(.headline)
                        }
                    )
                    
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("shopping") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("shopping")
                                } else {
                                    expandedSections.remove("shopping")
                                }
                            }
                        ),
                        content: {
                            NavigationLink(destination: Text("Shopping List View")) {
                                Label("View Shopping List", systemImage: "list.bullet")
                            }
                        },
                        label: {
                            Label("Shopping List", systemImage: "bag")
                                .font(.headline)
                        }
                    )
                }
                
                Section(header: Text("Financials")) {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("financials") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("financials")
                                } else {
                                    expandedSections.remove("financials")
                                }
                            }
                        ),
                        content: {
                            NavigationLink(destination: Text("Financial Summary")) {
                                Label("Summary", systemImage: "chart.pie")
                            }
                            NavigationLink(destination: FinancialReportsView()) {
                                Label("Reports", systemImage: "doc.text")
                            }
                            NavigationLink(destination: Text("Transactions")) {
                                Label("Transactions", systemImage: "creditcard")
                            }
                            NavigationLink(destination: ReceiptsView()) {
                                Label("Receipts", systemImage: "doc.text.viewfinder")
                            }
                        },
                        label: {
                            Label("Financials", systemImage: "dollarsign.circle")
                                .font(.headline)
                        }
                    )
                }
                
                Section(header: Text("Vehicles")) {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("vehicles") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("vehicles")
                                } else {
                                    expandedSections.remove("vehicles")
                                }
                            }
                        ),
                        content: {
                            NavigationLink(destination: Text("Vehicle Overview")) {
                                Label("Overview", systemImage: "chart.bar.doc.horizontal")
                            }
                            
                            NavigationLink(destination: Text("Gas Log View")) {
                                Label("Gas Log", systemImage: "fuelpump")
                            }
                            NavigationLink(destination: Text("Repairs & History View")) {
                                Label("Repairs & History", systemImage: "wrench.and.screwdriver")
                            }
                            NavigationLink(destination: Text("Mileage View")) {
                                Label("Mileage", systemImage: "speedometer")
                            }
                        },
                        label: {
                            Label("Vehicles", systemImage: "car")
                                .font(.headline)
                        }
                    )
                }
                
                Section(header: Text("Home")) {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("home") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("home")
                                } else {
                                    expandedSections.remove("home")
                                }
                            }
                        ),
                        content: {
                            NavigationLink(destination: Text("Home Overview")) {
                                Label("Overview", systemImage: "house")
                            }
                            
                            NavigationLink(destination: HomeMaintenanceView()) {
                                Label("Maintenance Schedule", systemImage: "calendar.badge.clock")
                            }
                            
                            NavigationLink(destination: Text("Repairs")) {
                                Label("Repairs", systemImage: "wrench.and.screwdriver.fill")
                            }
                        },
                        label: {
                            Label("Home", systemImage: "house.fill")
                                .font(.headline)
                        }
                    )
                }
                
                Section(header: Text("Settings")) {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("calendar") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("calendar")
                                } else {
                                    expandedSections.remove("calendar")
                                }
                            }
                        ),
                        content: {
                            if calendarManager.authorizationStatus == .notDetermined {
                                Button("Grant Calendar Access") {
                                    calendarManager.requestAccess()
                                }
                            } else if calendarManager.authorizationStatus == .denied {
                                calendarAccessDeniedView
                            } else {
                                Text("Calendar access granted")
                                    .foregroundColor(.green)
                            }
                        },
                        label: {
                            Text("Calendar Access")
                                .font(.headline)
                        }
                    )
                    
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("recipe") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("recipe")
                                } else {
                                    expandedSections.remove("recipe")
                                }
                            }
                        ),
                        content: {
                            if let directory = mealPlanner.selectedRecipeDirectory {
                                Text(directory.path)
                                Text("\(mealPlanner.recipes.count) recipes loaded")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Text("No recipe directory selected")
                                    .foregroundColor(.gray)
                            }
                            
                            Button("Select Recipe Directory") {
                                showingDirectoryPicker = true
                            }
                        },
                        label: {
                            Text("Recipe Directory")
                                .font(.headline)
                        }
                    )
                    
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("banking") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("banking")
                                } else {
                                    expandedSections.remove("banking")
                                }
                            }
                        ),
                        content: {
                            if let directory = UserDefaults.standard.url(forKey: "bankingDirectory") {
                                Text(directory.path)
                                Text("Banking transaction logs directory")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Text("No banking directory selected")
                                    .foregroundColor(.gray)
                            }
                            
                            Button("Select Banking Directory") {
                                showingBankingDirectoryPicker = true
                            }
                        },
                        label: {
                            Text("Banking Directory")
                                .font(.headline)
                        }
                    )
                    
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedSections.contains("vehicleSettings") },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert("vehicleSettings")
                                } else {
                                    expandedSections.remove("vehicleSettings")
                                }
                            }
                        ),
                        content: {
                            NavigationLink(destination: VehicleDetailsView()) {
                                Label("View Vehicles", systemImage: "car.fill")
                            }
                            
                            Button("Add Car") {
                                // This will be implemented later
                                print("Add car button tapped")
                            }
                            .padding(.top, 4)
                        },
                        label: {
                            Text("Vehicles")
                                .font(.headline)
                        }
                    )
                }
            }
            .listStyle(SidebarListStyle())
            
            // Main Content
            Group {
                if selectedViewMode == .daily {
                    DailyView(
                        mealPlanner: mealPlanner,
                        selectedRecipe: $selectedRecipe,
                        showingRecipeDetail: $showingRecipeDetail,
                        date: selectedDate
                    )
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button("Back to Week") {
                                selectedViewMode = .weekly
                            }
                        }
                    }
                } else {
                    WeeklyView(
                        mealPlanner: mealPlanner,
                        calendarManager: calendarManager,
                        selectedRecipe: $selectedRecipe,
                        showingRecipeDetail: $showingRecipeDetail,
                        selectedDate: $selectedDate,
                        selectedViewMode: $selectedViewMode,
                        onDateSelected: { date in
                            selectedDate = date
                            selectedViewMode = .daily
                        }
                    )
                }
            }
        }
        .navigationTitle("Quick Meal Planner")
        .toolbar {
            // Empty toolbar - removed refresh button
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
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Start accessing the security-scoped resource
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    mealPlanner.saveSelectedDirectory(url)
                    mealPlanner.loadRecipes(from: url)
                    if !calendarManager.schedules.isEmpty {
                        mealPlanner.generateWeeklyPlan(from: calendarManager.schedules)
                    } else {
                        calendarManager.fetchNextWeekEvents()
                    }
                }
            case .failure(let error):
                print("Error selecting directory: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingBankingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Start accessing the security-scoped resource
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if didStartAccessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    // Save the selected directory
                    UserDefaults.standard.set(url, forKey: "bankingDirectory")
                }
            case .failure(let error):
                print("Error selecting banking directory: \(error.localizedDescription)")
            }
        }
        .sheet(isPresented: $showingRecipeDetail) {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showingHistoricalPlans) {
            HistoricalPlansView(mealPlanner: mealPlanner, selectedRecipe: $selectedRecipe, showingRecipeDetail: $showingRecipeDetail)
        }
        .onAppear {
            mealPlanner.loadSavedDirectory()
            if calendarManager.authorizationStatus == .authorized {
                calendarManager.fetchNextWeekEvents()
            }
        }
        .onChange(of: calendarManager.schedules) { _ in
            if !calendarManager.schedules.isEmpty && !mealPlanner.recipes.isEmpty {
                mealPlanner.generateWeeklyPlan(from: calendarManager.schedules)
            }
        }
        .onChange(of: mealPlanner.weeklyPlan) { _ in
            // Generate grocery list whenever the weekly plan changes
            let selectedRecipes = mealPlanner.weeklyPlan.compactMap { $0.recommendedRecipe }
            groceryListManager.generateListFromRecipes(selectedRecipes)
        }
        .onChange(of: selectedViewMode) { newMode in
            if newMode == .daily {
                // If switching to daily view, ensure we have a selected date
                if selectedDate == Date() {
                    // If no specific date is selected, use today
                    selectedDate = Date()
                }
            }
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.name)
                    .font(.title)
                    .bold()
                
                HStack {
                    Label("\(recipe.prepTime) min prep", systemImage: "clock")
                    Spacer()
                    Label("\(recipe.cookTime) min cook", systemImage: "flame")
                    Spacer()
                    Label(recipe.difficulty, systemImage: "chart.bar")
                }
                .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredients")
                        .font(.headline)
                    
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                        Text("• \(ingredient)")
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Instructions")
                        .font(.headline)
                    
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                        Text("\(index + 1). \(instruction)")
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 