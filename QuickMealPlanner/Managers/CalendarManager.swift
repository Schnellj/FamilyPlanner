import Foundation
import EventKit

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var schedules: [DaySchedule] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() {
        // For macOS Sonoma (14.0+)
        if #available(macOS 14.0, *) {
            Task {
                do {
                    // Request full access to events
                    let granted = try await eventStore.requestFullAccessToEvents()
                    
                    // Update UI on main thread
                    await MainActor.run {
                        if granted {
                            self.authorizationStatus = .authorized
                            self.fetchNextWeekEvents()
                        } else {
                            self.authorizationStatus = .denied
                            print("Calendar access denied by user")
                        }
                    }
                } catch {
                    print("Error requesting calendar access: \(error.localizedDescription)")
                    await MainActor.run {
                        self.authorizationStatus = .denied
                    }
                }
            }
        } else {
            // Fallback for earlier macOS versions
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.authorizationStatus = .authorized
                        self?.fetchNextWeekEvents()
                    } else {
                        self?.authorizationStatus = .denied
                        if let error = error {
                            print("Calendar access error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func fetchNextWeekEvents() {
        let calendars = eventStore.calendars(for: .event)
        
        let now = Date()
        let calendar = Calendar.current
        guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: now) else { return }
        
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: endOfWeek,
            calendars: calendars
        )
        
        let events = eventStore.events(matching: predicate)
        
        // Group events by day
        var daySchedules: [DaySchedule] = []
        var currentDate = now
        
        while currentDate <= endOfWeek {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayEvents = events.filter { event in
                event.startDate >= dayStart && event.startDate < dayEnd
            }
            
            // Consider a day busy if there are evening events (after 4 PM)
            let isBusy = dayEvents.contains { event in
                let hour = calendar.component(.hour, from: event.startDate)
                return hour >= 16 // 4 PM
            }
            
            daySchedules.append(DaySchedule(
                date: currentDate,
                events: dayEvents,
                isBusy: isBusy,
                recommendedRecipe: nil
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        DispatchQueue.main.async {
            self.schedules = daySchedules
        }
    }
} 