//
//  MedNexApp.swift
//  MedNex
//

import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif
#if canImport(StripePaymentSheet)
import StripePaymentSheet
#endif

@main
struct MedNexApp: App { 
    init() {
        // Initialize Firebase (only when SDK is available)
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
        
        // Initialize Stripe (only when SDK is available)
        #if canImport(StripePaymentSheet)
        StripeConfig.configure()
        #endif
        
        // One-time demo seeding (DEBUG only)
        #if DEBUG && canImport(FirebaseAuth)
        if !UserDefaults.standard.bool(forKey: "mednex_demo_seeded") {
            Task {
                await SeedDataService.shared.seedAllDemoAccounts()
                UserDefaults.standard.set(true, forKey: "mednex_demo_seeded")
            }
        }
        #endif
        // Segmented control: dark text for unselected, white for selected
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.darkGray, .font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected
        )
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1.0) // primary green
        
        // Tab bar: light translucent background
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundColor = UIColor(white: 0.98, alpha: 0.95)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Navigation bar: transparent so gradient bleeds through
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dataStore = DataStore.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataStore)
                .preferredColorScheme(.light)
                .transaction { transaction in
                    if reduceMotion {
                        transaction.animation = nil
                    }
                }
        }
    }
}
