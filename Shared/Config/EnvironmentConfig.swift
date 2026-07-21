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
            return "https://eqigjryyhjwimadhzxzp.supabase.co"
        case .production:
            return "https://eqigjryyhjwimadhzxzp.supabase.co"
        }
    }
    
    static var supabaseAnonKey: String {
        switch AppEnvironment.current {
        case .debug, .staging:
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxaWdqcnl5aGp3aW1hZGh6eHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMTkyNTQsImV4cCI6MjA4ODc5NTI1NH0.9GkcBxvSgjsNpJy2yhg46dPTSNI7DkLgXOcdgSKWE0w"
        case .production:
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxaWdqcnl5aGp3aW1hZGh6eHpwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMyMTkyNTQsImV4cCI6MjA4ODc5NTI1NH0.9GkcBxvSgjsNpJy2yhg46dPTSNI7DkLgXOcdgSKWE0w"
        }
    }
    
    // MARK: - Razorpay
    
    static var razorpayKeyId: String {
        switch AppEnvironment.current {
        case .debug, .staging:
            return "rzp_live_SVYKaKxyYTtdAI" // Replace with your Razorpay test key
        case .production:
            return "rzp_live_SVYKaKxyYTtdAI" // Replace with your Razorpay live key
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
