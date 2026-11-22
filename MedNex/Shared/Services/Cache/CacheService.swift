//
//  CacheService.swift
//  MedNex
//
//  Local caching layer for offline-first data access using UserDefaults + file system.

import Foundation

final class CacheService: @unchecked Sendable {
    static let shared = CacheService()
    
    private let log = LoggingService.shared
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Default cache TTL: 1 hour
    private let defaultTTL: TimeInterval = 3600
    
    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths.first!.appendingPathComponent("com.mednex.cache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Cache Entry
    
    private struct CacheEntry<T: Codable>: Codable {
        let data: T
        let timestamp: Date
        let ttl: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ttl
        }
    }
    
    // MARK: - Save / Retrieve
    
    func save<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval? = nil) {
        let entry = CacheEntry(data: value, timestamp: Date(), ttl: ttl ?? defaultTTL)
        
        do {
            let data = try JSONEncoder().encode(entry)
            let url = cacheDirectory.appendingPathComponent(key.md5Hash + ".json")
            try data.write(to: url)
            log.data("Cached \(key)")
        } catch {
            log.error("Cache save failed for \(key)", error: error)
        }
    }
    
    func retrieve<T: Codable>(forKey key: String) -> T? {
        let url = cacheDirectory.appendingPathComponent(key.md5Hash + ".json")
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        do {
            let entry = try JSONDecoder().decode(CacheEntry<T>.self, from: data)
            
            if entry.isExpired {
                log.data("Cache expired for \(key)")
                try? fileManager.removeItem(at: url)
                return nil
            }
            
            log.data("Cache hit for \(key)")
            return entry.data
        } catch {
            log.error("Cache read failed for \(key)", error: error)
            return nil
        }
    }
    
    // MARK: - Cache with Fallback
    
    /// Returns cached data if available, otherwise fetches from network and caches result
    func withCache<T: Codable>(
        key: String,
        ttl: TimeInterval? = nil,
        fetch: () async throws -> T
    ) async throws -> T {
        // Check cache first
        if let cached: T = retrieve(forKey: key) {
            return cached
        }
        
        // Fetch from network
        let result = try await fetch()
        save(result, forKey: key, ttl: ttl)
        return result
    }
    
    // MARK: - Invalidation
    
    func invalidate(forKey key: String) {
        let url = cacheDirectory.appendingPathComponent(key.md5Hash + ".json")
        try? fileManager.removeItem(at: url)
        log.data("Cache invalidated for \(key)")
    }
    
    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        log.data("All cache cleared")
    }
    
    // MARK: - Cache Size
    
    func cacheSize() -> String {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return "0 KB"
        }
        
        let totalBytes = files.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return sum + size
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        return formatter.string(fromByteCount: Int64(totalBytes))
    }
}

// MARK: - String MD5 Helper

extension String {
    var md5Hash: String {
        // Simple hash using built-in hashValue for cache keys
        // (Using hashValue instead of CryptoKit to avoid extra import for cache keys)
        let hash = abs(self.hashValue)
        return String(hash, radix: 16)
    }
}
