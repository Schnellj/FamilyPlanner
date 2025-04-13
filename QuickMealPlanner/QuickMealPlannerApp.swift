//
//  QuickMealPlannerApp.swift
//  QuickMealPlanner
//
//  Created by Joshua Schnell on 2025-04-06.
//

import SwiftUI

@main
struct QuickMealPlannerApp: App {
    init() {
        // Set minimum deployment target for calendar access
        if #available(macOS 14.0, *) {
            // We're on Sonoma or later
        } else {
            // Fallback for earlier versions
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
