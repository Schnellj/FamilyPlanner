import SwiftUI

struct MaintenanceTask: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let frequency: MaintenanceFrequency
    let category: MaintenanceCategory
    var isCompleted: Bool = false
    var lastCompletedDate: Date?
    var nextDueDate: Date?
    var notes: String = ""
}

enum MaintenanceFrequency: String, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}

enum MaintenanceCategory: String, CaseIterable {
    case hvac = "HVAC"
    case plumbing = "Plumbing"
    case electrical = "Electrical"
    case appliances = "Appliances"
    case exterior = "Exterior"
    case interior = "Interior"
    case safety = "Safety"
    case landscaping = "Landscaping"
    case other = "Other"
}

struct HomeMaintenanceView: View {
    @State private var selectedFrequency: MaintenanceFrequency = .daily
    @State private var selectedCategory: MaintenanceCategory?
    @State private var showingAddTask = false
    @State private var searchText = ""
    
    // Sample data - in a real app, this would come from a database
    private let maintenanceTasks: [MaintenanceTask] = [
        // Daily Tasks
        MaintenanceTask(
            title: "Check for water leaks",
            description: "Inspect under sinks, around toilets, and in the basement for any signs of leaks.",
            frequency: .daily,
            category: .plumbing
        ),
        MaintenanceTask(
            title: "Clean kitchen counters",
            description: "Wipe down all kitchen counters and surfaces with appropriate cleaner.",
            frequency: .daily,
            category: .interior
        ),
        MaintenanceTask(
            title: "Empty trash and recycling",
            description: "Empty all trash and recycling bins, especially in the kitchen and bathrooms.",
            frequency: .daily,
            category: .interior
        ),
        
        // Weekly Tasks
        MaintenanceTask(
            title: "Clean bathroom fixtures",
            description: "Clean toilets, sinks, showers, and tubs with appropriate cleaners.",
            frequency: .weekly,
            category: .interior
        ),
        MaintenanceTask(
            title: "Vacuum carpets and rugs",
            description: "Vacuum all carpets and rugs, including under furniture.",
            frequency: .weekly,
            category: .interior
        ),
        MaintenanceTask(
            title: "Mow lawn",
            description: "Mow the lawn to maintain proper height and health.",
            frequency: .weekly,
            category: .landscaping
        ),
        MaintenanceTask(
            title: "Clean refrigerator coils",
            description: "Vacuum the condenser coils on the back or bottom of the refrigerator.",
            frequency: .weekly,
            category: .appliances
        ),
        MaintenanceTask(
            title: "Test smoke detectors",
            description: "Test all smoke detectors to ensure they're working properly.",
            frequency: .weekly,
            category: .safety
        ),
        
        // Monthly Tasks
        MaintenanceTask(
            title: "Replace HVAC filter",
            description: "Replace the air filter in your HVAC system.",
            frequency: .monthly,
            category: .hvac
        ),
        MaintenanceTask(
            title: "Clean garbage disposal",
            description: "Clean the garbage disposal with ice cubes and citrus peels.",
            frequency: .monthly,
            category: .plumbing
        ),
        MaintenanceTask(
            title: "Clean range hood filter",
            description: "Remove and clean the filter in the range hood.",
            frequency: .monthly,
            category: .appliances
        ),
        MaintenanceTask(
            title: "Check water softener",
            description: "Check salt levels and add salt if needed.",
            frequency: .monthly,
            category: .plumbing
        ),
        MaintenanceTask(
            title: "Clean ceiling fans",
            description: "Dust and clean ceiling fan blades.",
            frequency: .monthly,
            category: .interior
        ),
        MaintenanceTask(
            title: "Inspect fire extinguishers",
            description: "Check that fire extinguishers are properly charged and accessible.",
            frequency: .monthly,
            category: .safety
        ),
        
        // Quarterly Tasks
        MaintenanceTask(
            title: "Clean gutters",
            description: "Remove debris from gutters and downspouts.",
            frequency: .quarterly,
            category: .exterior
        ),
        MaintenanceTask(
            title: "Test garage door sensors",
            description: "Test the safety sensors on the garage door.",
            frequency: .quarterly,
            category: .safety
        ),
        MaintenanceTask(
            title: "Clean dryer vent",
            description: "Clean the lint from the dryer vent hose and exterior vent.",
            frequency: .quarterly,
            category: .appliances
        ),
        MaintenanceTask(
            title: "Check water heater",
            description: "Inspect the water heater for leaks and proper operation.",
            frequency: .quarterly,
            category: .plumbing
        ),
        MaintenanceTask(
            title: "Clean window tracks",
            description: "Clean the tracks of windows and sliding doors.",
            frequency: .quarterly,
            category: .interior
        ),
        MaintenanceTask(
            title: "Inspect roof",
            description: "Check the roof for damaged or missing shingles.",
            frequency: .quarterly,
            category: .exterior
        ),
        
        // Yearly Tasks
        MaintenanceTask(
            title: "Service HVAC system",
            description: "Have a professional inspect and service your HVAC system.",
            frequency: .yearly,
            category: .hvac
        ),
        MaintenanceTask(
            title: "Clean chimney",
            description: "Have the chimney inspected and cleaned by a professional.",
            frequency: .yearly,
            category: .exterior
        ),
        MaintenanceTask(
            title: "Flush water heater",
            description: "Drain and flush the water heater to remove sediment.",
            frequency: .yearly,
            category: .plumbing
        ),
        MaintenanceTask(
            title: "Inspect foundation",
            description: "Check the foundation for cracks or signs of settling.",
            frequency: .yearly,
            category: .exterior
        ),
        MaintenanceTask(
            title: "Service garage door",
            description: "Lubricate garage door springs and rollers.",
            frequency: .yearly,
            category: .exterior
        ),
        MaintenanceTask(
            title: "Clean window screens",
            description: "Remove and clean all window screens.",
            frequency: .yearly,
            category: .interior
        ),
        MaintenanceTask(
            title: "Inspect electrical system",
            description: "Have an electrician inspect your electrical system.",
            frequency: .yearly,
            category: .electrical
        ),
        MaintenanceTask(
            title: "Service sump pump",
            description: "Test the sump pump and clean the pit.",
            frequency: .yearly,
            category: .plumbing
        ),
        MaintenanceTask(
            title: "Clean siding",
            description: "Wash the exterior siding of your home.",
            frequency: .yearly,
            category: .exterior
        ),
        MaintenanceTask(
            title: "Inspect attic",
            description: "Check the attic for proper ventilation and signs of leaks.",
            frequency: .yearly,
            category: .exterior
        )
    ]
    
    var filteredTasks: [MaintenanceTask] {
        var tasks = maintenanceTasks.filter { $0.frequency == selectedFrequency }
        
        if let category = selectedCategory {
            tasks = tasks.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            tasks = tasks.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) || 
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return tasks
    }
    
    var body: some View {
        VStack {
            // Frequency Picker
            Picker("Frequency", selection: $selectedFrequency) {
                ForEach(MaintenanceFrequency.allCases, id: \.self) { frequency in
                    Text(frequency.rawValue).tag(frequency)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button(action: {
                        selectedCategory = nil
                    }) {
                        Text("All")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == nil ? .white : .primary)
                            .cornerRadius(20)
                    }
                    
                    ForEach(MaintenanceCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search tasks", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Task List
            List {
                ForEach(filteredTasks) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(task.title)
                                .font(.headline)
                            Spacer()
                            Text(task.category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                            
                            if let lastCompleted = task.lastCompletedDate {
                                Text("Last completed: \(formatDate(lastCompleted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            if let nextDue = task.nextDueDate {
                                Text("Next due: \(formatDate(nextDue))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Home Maintenance")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    showingAddTask = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    HomeMaintenanceView()
} 