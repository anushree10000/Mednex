//
//  LoggingService.swift
//  MedNex
//
//  Structured logging with OSLog for development and production.

import Foundation
import OSLog

final class LoggingService: Sendable {
    static let shared = LoggingService()
    
    private let logger = Logger(subsystem: "com.mednex.app", category: "general")
    private let authLogger = Logger(subsystem: "com.mednex.app", category: "auth")
    private let dataLogger = Logger(subsystem: "com.mednex.app", category: "data")
    private let networkLogger = Logger(subsystem: "com.mednex.app", category: "network")
    
    private init() {}
    
    // MARK: - General Logging
    
    func debug(_ message: String, file: String = #file, function: String = #function) {
        guard EnvironmentConfig.logLevel <= .debug else { return }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        logger.debug("[\(fileName):\(function)] \(message)")
    }
    
    func info(_ message: String) {
        guard EnvironmentConfig.logLevel <= .info else { return }
        logger.info("\(message)")
    }
    
    func warning(_ message: String) {
        guard EnvironmentConfig.logLevel <= .warning else { return }
        logger.warning("⚠️ \(message)")
    }
    
    func error(_ message: String, error: Error? = nil) {
        guard EnvironmentConfig.logLevel <= .error else { return }
        if let error {
            logger.error("❌ \(message): \(error.localizedDescription)")
        } else {
            logger.error("❌ \(message)")
        }
    }
    
    func critical(_ message: String) {
        logger.critical("🔴 CRITICAL: \(message)")
    }
    
    // MARK: - Domain-Specific Logging
    
    func auth(_ message: String) {
        authLogger.info("🔐 \(message)")
    }
    
    func authError(_ message: String, error: Error? = nil) {
        if let error {
            authLogger.error("🔐❌ \(message): \(error.localizedDescription)")
        } else {
            authLogger.error("🔐❌ \(message)")
        }
    }
    
    func data(_ message: String) {
        guard EnvironmentConfig.logLevel <= .debug else { return }
        dataLogger.debug("📦 \(message)")
    }
    
    func network(_ message: String) {
        guard EnvironmentConfig.logLevel <= .debug else { return }
        networkLogger.debug("🌐 \(message)")
    }
    
    func networkError(_ message: String, error: Error? = nil) {
        if let error {
            networkLogger.error("🌐❌ \(message): \(error.localizedDescription)")
        } else {
            networkLogger.error("🌐❌ \(message)")
        }
    }
}
