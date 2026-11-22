//
//  StripeConfig.swift
//  MedNex
//
//  Stripe SDK initialisation.  Reads the publishable key from Config.plist
//  or falls back to an environment variable so CI/CD pipelines can inject it.
//
//  Add the stripe-ios SPM package to the project and this will compile
//  automatically thanks to the `#if canImport` guard.
//

#if canImport(StripePaymentSheet)
import Foundation
import StripePaymentSheet

enum StripeConfig {
    
    /// Call once in MedNexApp.init()
    static func configure() {
        STPAPIClient.shared.publishableKey = publishableKey
    }
    
    // MARK: - Key Resolution
    
    /// Reads from EnvironmentConfig (or CI env variable override)
    static var publishableKey: String {
        // CI/CD environment variable override
        if let key = ProcessInfo.processInfo.environment["STRIPE_PUBLISHABLE_KEY"],
           !key.isEmpty {
            return key
        }
        return EnvironmentConfig.stripePublishableKey
    }
}
#endif
