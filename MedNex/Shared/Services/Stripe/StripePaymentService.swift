//
//  StripePaymentService.swift
//  MedNex
//
//  Wraps Stripe iOS SDK for creating payment intents and presenting
//  the pre-built PaymentSheet.  The heavy lifting (PaymentIntent creation)
//  happens server-side via a Supabase Edge Function.
//

#if canImport(StripePaymentSheet)
import Foundation
import StripePaymentSheet
import SwiftUI
import Combine

// MARK: - Payment Result

enum StripePaymentResult {
    case success
    case cancelled
    case failed(Error)
}

// MARK: - Service

@MainActor
final class StripePaymentService: ObservableObject {
    
    static let shared = StripePaymentService()
    
    @Published var paymentSheet: PaymentSheet?
    @Published var isLoading = false
    @Published var lastResult: StripePaymentResult?
    
    /// The Supabase Edge Function endpoint that creates a PaymentIntent
    /// and returns { clientSecret, ephemeralKey, customerId }.
    private let edgeFunctionName = "create-payment-intent"
    
    private init() {}
    
    // MARK: - Prepare Payment Sheet
    
    /// Fetches a clientSecret from the backend and configures a PaymentSheet.
    /// Call this *before* presenting the sheet (e.g. when user taps "Pay").
    func preparePaymentSheet(
        amountInPaise: Int,
        currency: String = "inr",
        patientEmail: String,
        billId: String
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Call Supabase Edge Function
        let params: [String: Any] = [
            "amount": amountInPaise,
            "currency": currency,
            "email": patientEmail,
            "bill_id": billId
        ]
        
        let response = try await callEdgeFunction(name: edgeFunctionName, params: params)
        
        guard let clientSecret = response["clientSecret"] as? String else {
            throw StripeError.missingClientSecret
        }
        
        let customerId = response["customerId"] as? String
        let ephemeralKey = response["ephemeralKey"] as? String
        
        // Configure PaymentSheet
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "MedNex Hospital"
        config.allowsDelayedPaymentMethods = false
        config.defaultBillingDetails.email = patientEmail
        
        if let customerId, let ephemeralKey {
            config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKey)
        }
        
        paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
    }
    
    // MARK: - Handle Result
    
    func handlePaymentResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            lastResult = .success
            HapticManager.success()
        case .canceled:
            lastResult = .cancelled
        case .failed(let error):
            lastResult = .failed(error)
            HapticManager.error()
        }
    }
    
    // MARK: - Edge Function Caller
    
    private func callEdgeFunction(name: String, params: [String: Any]) async throws -> [String: Any] {
        // Build the Supabase Edge Function URL
        // Uses SupabaseService configuration for the base URL
        guard let supabaseURL = URL(string: supabaseEdgeFunctionURL(name: name)) else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: supabaseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        guard let response = httpResponse as? HTTPURLResponse,
              (200...299).contains(response.statusCode) else {
            throw StripeError.serverError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw StripeError.invalidResponse
        }
        
        return json
    }
    
    // MARK: - Supabase Helpers
    
    private func supabaseEdgeFunctionURL(name: String) -> String {
        "\(EnvironmentConfig.supabaseURL)/functions/v1/\(name)"
    }
    
    private var supabaseAnonKey: String {
        EnvironmentConfig.supabaseAnonKey
    }
}

// MARK: - Errors

enum StripeError: LocalizedError {
    case missingClientSecret
    case invalidURL
    case serverError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingClientSecret: return "Payment server did not return a valid session."
        case .invalidURL:          return "Invalid payment server URL."
        case .serverError:         return "Payment server error. Please try again."
        case .invalidResponse:     return "Unexpected response from payment server."
        }
    }
}
#endif
