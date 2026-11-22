//
//  SupabaseService.swift
//  MedNex
//
//  Supabase client for all data operations.
//  Wrapped in #if canImport so the project compiles before packages resolve.

#if canImport(Supabase)
import Foundation
import Supabase
import PostgREST

final class SupabaseService: @unchecked Sendable {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    private let log = LoggingService.shared
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: EnvironmentConfig.supabaseURL)!,
            supabaseKey: EnvironmentConfig.supabaseAnonKey
        )
    }
    
    // MARK: - User Profiles
    
    func createUserProfile(_ user: MedNexUser) async throws {
        log.data("Creating user profile: \(user.id)")
        try await client.from("users").insert(user).execute()
    }
    
    func fetchUserProfile(byId id: String) async throws -> MedNexUser {
        log.data("Fetching user profile: \(id)")
        let response: MedNexUser = try await client
            .from("users").select().eq("id", value: id).single().execute().value
        return response
    }
    
    func updateUserProfile(_ user: MedNexUser) async throws {
        log.data("Updating user profile: \(user.id)")
        try await client.from("users").update(user).eq("id", value: user.id).execute()
    }
    
    // MARK: - Staff Lookup
    
    func fetchStaffEmail(byStaffId staffId: String) async throws -> String {
        log.data("Looking up staff by ID: \(staffId)")
        struct StaffEmailResult: Decodable { let email: String }
        let result: StaffEmailResult = try await client
            .from("staff").select("email").eq("id", value: staffId).single().execute().value
        return result.email
    }
    
    // MARK: - Generic CRUD
    
    func fetch<T: Decodable>(from table: String, filters: [(column: String, value: String)] = []) async throws -> [T] {
        log.data("Fetching from \(table)")
        var query = client.from(table).select()
        for filter in filters { query = query.eq(filter.column, value: filter.value) }
        let response: [T] = try await query.execute().value
        return response
    }
    
    func fetchSingle<T: Decodable>(from table: String, id: String) async throws -> T {
        log.data("Fetching single from \(table): \(id)")
        let response: T = try await client
            .from(table).select().eq("id", value: id).single().execute().value
        return response
    }
    
    func insert<T: Encodable>(_ item: T, into table: String) async throws {
        log.data("Inserting into \(table)")
        try await client.from(table).insert(item).execute()
    }
    
    func update<T: Encodable>(_ item: T, in table: String, id: String) async throws {
        log.data("Updating in \(table): \(id)")
        try await client.from(table).update(item).eq("id", value: id).execute()
    }
    
    func delete(from table: String, id: String) async throws {
        log.data("Deleting from \(table): \(id)")
        try await client.from(table).delete().eq("id", value: id).execute()
    }
    
    func count(from table: String, filters: [(column: String, value: String)] = []) async throws -> Int {
        log.data("Counting from \(table)")
        var query = client.from(table).select("*", head: true, count: .exact)
        for filter in filters { query = query.eq(filter.column, value: filter.value) }
        let response = try await query.execute()
        return response.count ?? 0
    }
}
#endif
