//
//  EnvironmentConfig.swift
//  MedNex
//
//  Environment-based configuration for Firebase, Supabase, and feature flags.

import Foundation

enum AppEnvironment: String {
    case debug
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .debug
        #else
        // Check for staging build flag
        if Bundle.main.object(forInfoDictionaryKey: "APP_ENVIRONMENT") as? String == "staging" {
            return .staging
        }
        return .production
        #endif
    }
}

enum EnvironmentConfig {
    
    // MARK: - Supabase
    
    static var supabaseURL: String {
        switch AppEnvironment.current {
        case .debug, .staging:
            return "https://xkgpsoywahhvgrfaxeaa.supabase.co"
        case .production:
            return "https://xkgpsoywahhvgrfaxeaa.supabase.co"
        }
    }
    
    static var supabaseAnonKey: String {
        switch AppEnvironment.current {
        case .debug, .staging:
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrZ3Bzb3l3YWhodmdyZmF4ZWFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNzc3ODgsImV4cCI6MjExMDk1Mzc4OH0.UEz1loy_GgdrOXy0XdyUzJcMV_JzN4xPM0ZKAjLfgY4"
        case .production:
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhrZ3Bzb3l3YWhodmdyZmF4ZWFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNzc3ODgsImV4cCI6MjExMDk1Mzc4OH0.UEz1loy_GgdrOXy0XdyUzJcMV_JzN4xPM0ZKAjLfgY4"
        }
    }
    
    // MARK: - Stripe
    
    static var stripePublishableKey: String {
        switch AppEnvironment.current {
        case .debug, .staging:
            return "pk_test_51OIEU1SC9AWZ6S66DUPKlbO5yNNwXb4NqCvCEbeuIbMwHsZHqNKltmRYqOj1NjGdFGBcJ0MOTY5qXLCck44yK2L800xEa3oER7" // Replace with your Stripe test key
        case .production:
            return "pk_test_51OIEU1SC9AWZ6S66DUPKlbO5yNNwXb4NqCvCEbeuIbMwHsZHqNKltmRYqOj1NjGdFGBcJ0MOTY5qXLCck44yK2L800xEa3oER7Y" // Replace with your Stripe live key
        }
    }
    
    // MARK: - Feature Flags
    
    static var isAnalyticsEnabled: Bool {
        AppEnvironment.current == .production
    }
    
    static var isCrashReportingEnabled: Bool {
        AppEnvironment.current != .debug
    }
    
    static var isOfflineModeEnabled: Bool {
        true // Available in all environments
    }
    
    static var isRealTimeEnabled: Bool {
        true // Supabase real-time subscriptions
    }
    
    static var sessionTimeoutMinutes: Int {
        switch AppEnvironment.current {
        case .debug: return 60 // Longer for development
        case .staging: return 30
        case .production: return 15
        }
    }
    
    // MARK: - Logging
    
    static var logLevel: LogLevel {
        switch AppEnvironment.current {
        case .debug: return .debug
        case .staging: return .info
        case .production: return .warning
        }
    }
}

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
